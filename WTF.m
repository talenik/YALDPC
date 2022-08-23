function res = WTF( code, enc, dec, sim )
% WTF - calculate watefall curve BER -vs- Eb/N0 
%		for BPSK modulation and AWGN channel
%		encoder is using 'array' data representation
%		works for all code parameters and both wifi and wimax standards
% 
%	sim = WTF()
%		return default simulation paramaters, many can be changed:
%		sim.minErr - minimum number of error collected per Eb/N0 point
%		sim.blkSize - nr. of codewords per block 
%				must be a multiple of dec.nthread
%		sim.impl - 'MEX' (default) or 'COM' for calling Communications Toolbox 
%		sim.plot - toggle automatic semilogy plot
%		sim.save - toggle automatic saving of results to a mat file (res subfolder)
%		sim.report - send an email with results to a given address
%					see reportEmail() for details
%		sim.prof - run the profiler
%		sim.single - just run one iteration (for debugging)
%
%	res = WTF( code, encoder, decoder, simulation )
%		actually perform simulation
%
%	results structure contains many parameters, just display it :)

	if nargin == 0
		%return default parameters
		sim.blkSize = 1 ;
		sim.minErr	= 100 ;
	
		sim.prof	= false ;	% profile code and show HTML report
		sim.single	= false ;	% just testrun one loop of the simulation
		sim.report	= false ;	% send email after each Eb/N0 iteration is finished
		sim.plot	= true ;	% plot waterfall figure in the end
		sim.save	= true ;	% save results to local .mat file immediately in WTF
		sim.impl	= 'MEX' ;	% use custom MEX file, run built-in COM toolbox functions 
		res = sim ;
		return ;
	end
	
	EBN0		= sim.EbN0 ;
	BLK			= sim.blkSize ;	
	
	NIter		= dec.nIter ;
	Lambda		= dec.lambda ;
	NThread		= dec.nthread ;
	
	K			= code.K ;
	N			= code.N ;
	R			= code.Rc ;	
	
	s			= size( EBN0 ) ;
	ERR			= zeros( s ) ;		% absolute nr. of errors after LDPC decoding
	BER			= zeros( s ) ;		% bit error ratio after LDPC decoding
	
	DBits		= zeros( s ) ;		% number of data bits simulated
	TElaps		= zeros( s ) ;		% elapsed time for each point
	ITER		= zeros( s ) ;		% average nr. of iterations

	com = strcmp( sim.impl, 'COM') ;

	if com
		% use MATLAB communications system toolbox implementation
		dec	= ldpcDecoderConfig( logical( code.Hs ) ) ;
		enc	= ldpcEncoderConfig( dec ) ;
		dec.Algorithm = 'norm-min-sum' ;
		disp( 'Running Communications System Toolbox Implementation.' ) ;
	else
		enc = QCLDPCEncode( enc ) ; 
		dec = QCLDPCDecode( dec ) ;
		
		saveLDPCheader( 'ldpc', code, enc, dec, 'MEX' ) ;
		buildMEXfile( enc ) ;
		buildMEXfile( dec ) ;
		disp( 'Running MEX Implementation.' ) ;
	end

	res.N			= N ;
	res.R			= R ;
	res.std			= code.std ;
	res.impl		= sim.impl ;
	res.lambda		= Lambda ;
	res.nIter		= NIter ;
	res.nThread		= NThread ;
	res.blockSize	= BLK ;
	res.EbN0		= EBN0 ;	

%% main simulation loop
	
	Tstart = tic ;
	tstart = tic ;
	
	if sim.prof
		profile on ;
	end
	
	for x = 1 : 1 : size( EBN0, 2 )
		res.x	= x ;
		
		EbN0	= EBN0( x ) ;
		snr     = 10 ^ ( EbN0 / 10 ) ;
		varCh	= 1 / ( 2 * snr * R ) ;	
		sigma	= sqrt( varCh ) ;
	
		nErr	= 0 ;
		nBlk	= 0 ;
	
		while nErr < sim.minErr
			
			if com
				Data	= logical( randi( [ 0 1 ], K, BLK ) ) ;
				CW		= ldpcEncode( Data, enc ) ;
			else
				Data	= randi( [ 0 1 ], K, BLK, 'uint8' ) ;
				CW		= QCLDPCEncode( Data, code, enc ) ;
			end
	
	
			TxBlock = -2 * single( CW ) + 1 ; % BPSK: 0 > +1, 1 > -1
			Noise	= sigma * randn( size( TxBlock ), 'single' ) ;
			RxBlock	= TxBlock + Noise ;
			LLRch	= ( 2 / varCh ) .* RxBlock ; 
			
			if com
				[ HD, Iter ] = ldpcDecode( LLRch, dec, NIter, MinSumScalingFactor=Lambda ) ;
				HD					= logical( HD ) ; 
			else
				[ ApLLR, Iter ] = QCLDPCDecode( LLRch, dec ) ;
				HD				= hardDecision( ApLLR, enc.type ) ;
				HD				= HD( 1 : K, : ) ;
			end

			
			nErr			= nErr + nnz( Data ~= HD ) ;
			nBlk			= nBlk + 1 ;
			ITER( x )		= ITER( x ) + sum( Iter ) ;
		end
	
		ERR( x )	= ERR( x ) + nErr ;
		DBits( x )	= DBits( x ) + nBlk * BLK * K ;
		BER( x )	= ERR( x ) / DBits( x ) ;
		ITER( x )	= ITER( x ) / ( nBlk * BLK ) ;

		% Immediate user printouts ---------------------------------------
		telapsed	= toc( tstart ) ;
		tstart		= tic ; 
		tstr		= datestr( datenum( 0, 0, 0, 0, 0, telapsed ), "DD:HH:MM:SS" ) ; 
		TElaps( x ) = telapsed ;
	
		fprintf( 'Eb/N0: %4.2f ITER: %4.2f Errors: %10d Bits: %15d BER: %e Tel: %s\n', ...
		EBN0( x ), ITER( x ), ERR( x ), DBits( x ), BER( x ), tstr )
	

		if sim.report && x < size( EBN0, 2 )
			res.EBN0	= EBN0 ;
			res.DBits	= DBits ;
			res.ERR		= ERR ;
			res.BER		= BER ;
			res.TElaps	= TElaps ;
			res.ITER	= ITER ;
			%msg = formatEmail( res ) ;
			%reportEmail( 'Simulation step done', msg, sim.emailCfg ) ;
		end
	
		if sim.single
			break ;
		end
	
	end
	

%% results processing 
	
	telapsed = toc( Tstart ) ;
	
	disp( [ 'Simulation finished in: ' datestr( datenum( 0, 0, 0, 0, 0, telapsed ), "HH:MM:SS" ) ] ) ;
	
	res.totalBits	= sum( DBits ) ;
	res.totalTime	= telapsed ;
	res.throughput	= ( res.totalBits * 1e-6 ) / res.totalTime ;
		
	res.ERR			= ERR ;
	res.BER			= BER ;
	res.ITER		= ITER ;
	res.DBits		= DBits ;
	res.TElaps		= TElaps ;

	if sim.save
		name	= [ 'wtf_' res.std '_n' num2str( N ) '_R' rate2str( R ) ] ;
		if strcmp( sim.impl, 'MEX' )
			name = [ name '_MEX_' dec.method ] ;
		else
			name = [ name '_COM'] ;
		end
		file	= [ 'res/' name '.mat'] ;
		eval( [ name ' = res ;' ] ) ;
		save( file, name, '-v7.3' ) ;
	end

	if sim.single
		whos
	else
		if sim.plot
			figure() ;
			semilogy( EBN0, BER ) ;
			grid on ;
		end
	end
	
% 	EBN0
% 	BER
	
	if sim.prof
		profile viewer ;
	end

	if sim.report
		msg = formatEmail( res ) ;
		reportEmail( 'Simulation completed', msg, sim.emailCfg ) ;
	end
end 











































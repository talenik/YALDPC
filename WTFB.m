function res = WTFB( code, enc, dec, sim )
% WTF - calculate watefall curve BER -vs- Eb/N0 
%		for BPSK modulation and AWGN channel 
%		using 'bitmap' data representation
%		works for select code parameters where N, K, Z are divisible by WB
%		and WB is a multiple of 8 (currently except 64)
% 
%	sim = WTFB()
%		return default simulation paramaters, many can be changed:
%		sim.minErr - minimum number of error collected per Eb/N0 point
%		sim.blkSize - nr. of codewords per block 
%				must be a multiple of dec.nthread
%		sim.plot - toggle automatic semilogy plot
%		sim.save - toggle automatic saving of results to a mat file (res subfolder)
%		sim.prof - run the profiler
%		sim.single - just run one iteration (for debugging)
%
%	res = WTFB( code, encoder, decoder, simulation )
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

	%update parameters structures
	enc = QCLDPCEncode( enc ) ; 
	dec = QCLDPCDecode( dec ) ;
	
	EBN0		= sim.EbN0 ;
	BLK			= sim.blkSize ;	

	NIter		= dec.nIter ;
	Lambda		= dec.lambda ;
	NThread		= dec.nthread ;
	
	KW			= code.K / enc.wb ;
	NW			= code.N / enc.wb ;
	R			= code.Rc ;	
	
	s			= size( EBN0 ) ;
	ERR			= zeros( s ) ;		% absolute nr. of errors after LDPC decoding
	BER			= zeros( s ) ;		% bit error ratio after LDPC decoding
	
	DBits		= zeros( s ) ;		% number of data bits simulated
	TElaps		= zeros( s ) ;		% elapsed time for each point
	ITER		= zeros( s ) ;		% average nr. of iterations


		
	saveLDPCheader( 'ldpc', code, enc, dec, 'MEX' ) ;
	buildMEXfile( enc ) ;
	buildMEXfile( dec ) ;

%% main simulation loop
	b = Bits( enc.type ) ;

	Tstart = tic ;
	tstart = tic ;
	
	if sim.prof
		profile on ;
	end
	
	for x = 1 : 1 : size( EBN0, 2 )
		
		EbN0	= EBN0( x ) ;
		snr     = 10 ^ ( EbN0 / 10 ) ;
		varCh	= 1 / ( 2 * snr * R ) ;	
		sigma	= sqrt( varCh ) ;
	
		nErr	= 0 ;
		nBlk	= 0 ;
	
		while nErr < sim.minErr
			
			DataB	= randui( KW, BLK, enc.type ) ;
			CWB		= QCLDPCEncode( DataB, code, enc ) ;
	
			CW		= b.bit2logical( CWB ) ;
			TxBlock = -2 * single( CW ) + 1 ; % BPSK: 0 > +1, 1 > -1
			Noise	= sigma * randn( size( TxBlock ), 'single' ) ;
			RxBlock	= TxBlock + Noise ;
			LLRch	= ( 2 / varCh ) .* RxBlock ; 
			
			[ ApLLR, Iter, HDB ] = QCLDPCDecode( LLRch, dec ) ;

			Data		= CW( 1 : code.K, : ) ;
			HD			= b.bit2logical( HDB ) ;
			DataE		= HD( 1 : code.K, : ) ;
			nErr		= nErr + nnz( Data ~= DataE ) ;
			nBlk		= nBlk + 1 ;
			ITER( x )	= ITER( x ) + sum( Iter ) ;
		end
	
		ERR( x )	= ERR( x ) + nErr ;
		DBits( x )	= DBits( x ) + nBlk * BLK * code.K ;
		BER( x )	= ERR( x ) / DBits( x ) ;
		ITER( x )	= ITER( x ) / ( nBlk * BLK ) ;

		% Immediate user printouts ---------------------------------------
		telapsed	= toc( tstart ) ;
		tstart		= tic ; 
		tstr		= datestr( datenum( 0, 0, 0, 0, 0, telapsed ), "DD:HH:MM:SS" ) ; 
		TElaps( x ) = telapsed ;
	
		fprintf( 'Eb/N0: %4.2f ITER: %4.2f Errors: %10d Bits: %15d BER: %e Tel: %s\n', ...
		EBN0( x ), ITER( x ), ERR( x ), DBits( x ), BER( x ), tstr )

		if sim.report
			reportMessage( title, msg ) ;
		end
	
		if sim.single 
			whos DataB CWB HDB Data CW HD DataE
			break ;
		end
	
	end
	

%% results processing 
	
	telapsed = toc( Tstart ) ;
	
	disp( [ 'Simulation finished in: ' datestr( datenum( 0, 0, 0, 0, 0, telapsed ), "HH:MM:SS" ) ] ) ;
	
	res.n			= code.N ;
	res.R			= R ;
	res.std			= code.std ;
	res.impl		= sim.impl ;
	res.lambda		= dec.lambda ;
	res.nIter		= dec.nIter ;
	res.nThread		= dec.nthread ;
	res.blkSize		= sim.blkSize ;
	res.EbN0		= EBN0 ;	

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
end 










































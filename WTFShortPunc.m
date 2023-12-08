function res = WTFShortPunc( code, enc, dec, sim, shortIdx, puncIdx )
% WTF2 - calculate watefall curve BER -vs- Eb/N0 
%		for BPSK modulation and AWGN channel
%		encoder is using 'array' data representation
%		works for all code parameters and both wifi and wimax standards
% 
%	sim = WTFShortPunc()
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
%	res = WTF2( code, encoder, decoder, simulation )
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
		sim.save	= false ;	% save results to local .mat file immediately in WTF
		sim.impl	= 'MEX' ;	% use custom MEX file, run built-in COM toolbox functions 
        sim.short   = false ;   % use code shortening, auto set from encoder
		sim.punc	= false ;	% use code puncturing, auto set from encoder
		res = sim ;
		return ;
	end

	if nargin < 6
		puncIdx = false ;
	end

	if nargin <  5
		shortIdx = false ;
	end
	
	EBN0		= sim.EbN0 ;
	BLK			= sim.blkSize ;	
	
	NIter		= dec.nIter ;
	Lambda		= dec.lambda ;
	NThread		= dec.nthread ;
	
	%original parameters : K, N, R
	K			= code.K ;
	N			= code.N ;
	R			= code.Rc ;	

	
	if shortIdx 
		%direct parameter overrides code structure:
		sim.short = true ;
		code.shortIdx = blockIndex2Range( shortIdx, code.z ) ;
		code.s	= size( code.shortIdx, 2 ) ;
	elseif code.s > 0
		%simulation automaticallu shortens the end of the data word
		sim.short = true ;
		code.shortIdx = [ K - code.s + 1 : K ] ;
	end

	if puncIdx 
		%direct parameter overrides code structure:
		sim.punc = true ;
		code.puncIdx = blockIndex2Range( puncIdx, code.z ) ;
		code.p	= size( code.puncIdx, 2 ) ;
	elseif code.p > 0
		%simulation automaticallu shortens the end of the code word
		sim.punc = true ;
		code.puncIdx = [ N - code.p + 1 : N ] ;
	end
	
	if sim.short
		%expecting only data-bits shortening
		Ks		= K - code.s ;
		Ns		= N - code.s ;
		Rs		= Ks / Ns ;

		assert( size( code.shortIdx, 2 ) == code.s ) ;
		assert( max( code.shortIdx ) <=  K ) ;	%can short only data bits 
	else
		Ks		= K ;
		Ns		= N ;
		Rs		= R ;
	end

	%paramaters after shortening: Ks, Ns, Rs (even if not applied)

	if sim.punc
		if min( code.puncIdx ) > K	%puncturing parity bits
			Kp	= Ks ;
		else						%puncturing data bits
			Kp	= Ks - code.p ;
		end
		Np		= Ns - code.p ;
		Rp		= Kp / Np ;

		assert( size( code.puncIdx, 2 ) == code.p ) ;	

	else
		Kp		= Ks ;
		Np		= Ns ;
		Rp		= Rs ;
	end

	%paramaters after shortening and puncturing: Kp, Np, Rp (even if not applied)

	assert( isempty( intersect( code.shortIdx, code.puncIdx) ) ) ;

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
		type	= 'logical' ;
		fp_max	= 1024 ;
		disp( 'Running COM Simulation.' ) ;
	else
		enc = QCLDPCEncode( enc ) ; 
		dec = QCLDPCDecode( dec ) ;

		saveLDPCheader( 'ldpc', code, enc, dec, 'MEX' ) ;
		if ~isequal( sim.impl, 'MIX')
			buildMEXfile( enc ) ;
			disp( 'Running MEX Encoder.' ) ;
		else
			disp( 'Running COM Encoder.' ) ;
		end
		buildMEXfile( dec ) ;
		disp( 'Running MEX Decoder.' ) ;
		type	= enc.type ;
		fp_max	= dec.fp_max ;
	end

	%TODO add shortening and puncturing to results
	res.N			= N ;
	res.R			= R ;
	res.std			= code.std ;
	res.s			= code.s ;
	res.p			= code.p ;
	res.impl		= sim.impl ;
	res.lambda		= Lambda ;
	res.nIter		= NIter ;
	res.nThread		= NThread ;
	res.blockSize	= BLK ;
	res.EbN0		= EBN0 ;	

	fprintf("code paramate: K : %d, N : %d, R : %6.4f, z: %d\n", K, N, R, code.z ) ;
	fprintf("shortening: %d, Ks: %d, Ns: %d, Rs: %6.4f, s: %d\n", sim.short, Ks, Ns, Rs, code.s ) ;
	fprintf("puncturing: %d, Kp: %d, Np: %d, Rp: %6.4f, p: %d\n", sim.punc, Kp, Np, Rp, code.p ) ;

%% main simulation loop
	
	Tstart = datetime(now,'ConvertFrom','datenum') ;
	fprintf( "Simulation start: %s\n", datestr( Tstart ) ) ;
	tstart = tic ;
	
	if sim.prof
		profile on ;
	end
	
	for x = 1 : 1 : size( EBN0, 2 )
		res.x	= x ;
		
		EbN0	= EBN0( x ) ;
		[ sigma, varCh ] = ebno2sigma( EbN0, Rp ) ; %code rate includes shortening and puncturing
	
		nErr	= 0 ;
		nBlk	= 0 ;
	
		while nErr < sim.minErr
			
			Data	= randi( [ 0 1 ], K, BLK, type ) ;
			if sim.short
				Data( code.shortIdx, : ) = zeros( code.s, BLK, type ) ;
			end
			if com
				CW	= ldpcEncode( Data, enc ) ;
			else
				CW	= QCLDPCEncode( Data, code, enc ) ;
			end
			%ugly hack - we don't actually neet to drop any bits in a simulation :)
			
			TxBlock = -2 * single( CW ) + 1 ; % BPSK: 0 > +1, 1 > -1
			Noise	= sigma * randn( size( TxBlock ), 'single' ) ;
			RxBlock	= TxBlock + Noise ;
			LLRch	= ( 2 / varCh ) .* RxBlock ; 
			
			if sim.short
				%insert hi-confidence zeros 
				LLRch( code.shortIdx, : ) = fp_max ; 
			end
			if sim.punc
				%insert zero-confidence zeros
				LLRch( code.puncIdx, : ) = 0 ;	%TODO type
			end

			if com
				[ HD, Iter ]	= ldpcDecode( LLRch, dec, NIter, MinSumScalingFactor=Lambda ) ;
				HD				= logical( HD ) ; 
			else
				[ ApLLR, Iter ] = QCLDPCDecode( LLRch, dec ) ;
				HD				= hardDecision( ApLLR, enc.type ) ;
				HD				= HD( 1 : K, : ) ;
			end

			if sim.short
				HD( code.shortIdx, : ) = zeros( code.s, BLK, type ) ;
				dbits = BLK * Ks ;
			else
				dbits = BLK * K ;
			end
			
			nErr			= nErr + nnz( Data ~= HD ) ;
			nBlk			= nBlk + 1 ;
			ITER( x )		= ITER( x ) + sum( Iter ) ;
		end
	
		ERR( x )	= ERR( x ) + nErr ;
		DBits( x )	= DBits( x ) + nBlk * dbits ;
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
	
	Tend = datetime(now,'ConvertFrom','datenum') ;
	disp( [ 'Simulation finished in: ' datestr( Tend - Tstart, "HH:MM:SS" ) ] ) ;
	Tend - Tstart
	
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











































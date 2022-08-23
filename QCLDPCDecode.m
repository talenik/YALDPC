function [ ApLLR, nIter, HD ] = QCLDPCDecode( LLch, dec )
	%QCLDPCDecode - decode data using one of the QC LDPC codes defined in WiMAX and WIFI6
	%	internally calls the QCLDPCDecodeMEX MEX file
	%
	%	dec = QCLDPCDecode()
	%		return default decoder options structure
	%		default decoder method is 'float'
	%		method 'fixed' has slightly worse error performance and is slightly faster
	%
	%	dec = QCLDPCDecode( dec )
	%		recompute dependent parameters 
	%		
	%	[ ApLLR, Iter [, HD ] ] =  QCLDPCDecode( LLch, dec )
	%		decode channel LLRs using given decoder parameters
	%
	%		LLch - column vector or matrix of column vectors of length N
	%					default type for fixed point is 'short int', 
	%					default type for floating point is 'float'
	%					native MATLAB 'double' type is auto-converted 
	%
	%		dec	- decoder options structure
	%					assuming MEX file is built with these parameters
	%				dec.nthreads - nr. of threads to run
	%					you need to process LLch in blocks of compatible
	%					size eg: size( LLch, 2 ) must be a multiple of
	%					dec.nthreads
	%				dec.nIter - nr. of decoder iterations
	%				dec.lambda - min-sum normalization factor 
	%								values from 0 to 1 ( default 1.0 )
	%				dec.beta - min-sum offset
	%								values from 0 (default 0.0 )
	%				dec.term - termination 'early' (default) or 'max'
	%		ApLLR	- posterior LLRs (soft-output) for ALL codeword symbols
	%		Iter	- actual number of iterations performed
	%		HD		- hard decision, aka decoded bits
	%					if ENCODER is set to 'bitmap' HD will be also
	%					if ENCODER is set to 'array' HD will be double
	%
	%		if dec.method == 'fixed' the quantisation of float to int can
	%		be fine-tuned by setting: 
	%			dec.qbits  - absolute value bits (excluding sign)
	%			dec.llrmax - trunc floating point LLR values above this treshold
	%			dec.fp_max - should be 2^qbits, ignore at own risk :)
	%			dec.lamba and dec.beta are ignored in this case
	%			
    %
	% compatible MEX file must first be built using: saveLDPCheader() and buildMEXfile()
	% see testDec for examples

%default options:

%runtime options:
dopts.dbglev	= 0 ;		% 0 > silent, only works with debug build

dopts.nIter		= 10 ;
dopts.lambda	= 1 ;		% min-sum normalization
dopts.beta		= 0 ;		%min-sum offset
dopts.term		= 'early' ;	% termination: 'early' > when converged 'max' > all iterations
dopts.hdbitmap	= false ;	% set this to true if using 'bitmap' encoder

%build-time options:
dopts.build		= 'release' ;
dopts.nthread	= 1 ;	%number of threads to use

%defaults for fixed-point implementation:
%assuming fixed point type is signed 16bit wide 'short int'
dopts.qbits		= 10 ;		% nr of quantization bits for LLR
dopts.fp_max	= 1024 ;	% quatized mag(LLR) will take on values 0 to 2^qbits - 1
dopts.llrmax	= 20 ;		% trunc larger channel LLR to this

%build options
dopts.method	= 'float' ; % 'float' or 'fixed' point arithmetic
dopts.mexfun	= 'QCLDPCDecodeMEX' ; 


dopts = setMethodParams( dopts.method, dopts ) ;


	if nargin == 0
		ApLLR = dopts ;	%returns default options instead
		return ;

	elseif nargin == 1 ;
		if ~isstruct( LLch )
			error('Usage: dec = QCLDPCDecode( dec )') ;
		end
		ApLLR = setMethodParams( LLch.method, LLch ) ;
		return ;

	end

	hd = 0 ;
	if nargout == 3
		hd = 1 ;
	end
		
	%call MEX file 
	term	= double( strcmp( dec.term, 'early' ) ) ;
	Options = [ dec.nIter, dec.lambda, dec.beta, dec.dbglev, term ] ;
	
	if strcmp( dec.method, 'fixed')
		t		= class( LLch ) ;
		LLchQ	= int16( float2int( LLch, dec.qbits, dec.fp_max ) ) ;
		
		if hd
			[ IApLLR, nIter, HD ] = QCLDPCDecodeMEX( LLchQ, Options ) ;
		else
			[ IApLLR, nIter ] = QCLDPCDecodeMEX( LLchQ, Options ) ;
		end
	
		%these will really be intXY values
		ApLLR	= cast( IApLLR, t ) ;
	else
		if isa( LLch, dec.type )
			if hd
				[ ApLLR, nIter, HD ] = QCLDPCDecodeMEX( LLch, Options ) ;
			else
				[ ApLLR, nIter ] = QCLDPCDecodeMEX( LLch, Options ) ;
			end
		else
			SLLch = single( LLch ) ;
			if hd
				[ SApLLR, nIter, HD ] = QCLDPCDecodeMEX( SLLch, Options ) ;
			else
				[ SApLLR, nIter ] = QCLDPCDecodeMEX( SLLch, Options ) ;
			end
			ApLLR = cast( SApLLR, dec.type ) ;
		end
	end

	if hd && ~dec.hdbitmap
		HD = double( HD ) ;
	end
end

function par = setMethodParams( method, par )

	if strcmp( method, 'float' )
		% floating point class setings for MEX file
		par.mexclass	= [ 'mxSINGLE_CLASS' ] ;
		par.mexget		= [ 'mxGetSingles' ] ;
	
		%default MEX decoder class is single-precision float
		par.ctype	= 'float' ;
		par.type	= 'single' ;
		%par.defines = [] ;
	
	else
		% fixed point aka: 'short int' class setings for MEX file
		par.mexclass	= [ 'mxINT16_CLASS' ] ;
		par.mexget		= [ 'mxGetInt16s' ] ;
	
		par.ctype	= 'int16_t' ;
		par.type	= 'int16' ;
	
		%par.defines = [ "FIXED" ] ;
	end

	if par.nthread == 1	
		par.sources	= [ "decoder.c" "debug.c" "ldpc.c" ] ;
	else
		par.sources	= [ "decoderMT.c" "debug.c" "ldpc.c" ] ;
	end

end
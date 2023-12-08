function CW = QCLDPCEncode( p1, p2, p3 )
	%QCLDPCEncode - encode data using one of the QC LDPC codes defined in WiMAX or WIFI6
	%	internally calls the QCLDPCEncodeMEX MEX file
	%
	%	enc = QCLDPCEncode()
	%		return default encoder options structure
	%		default encoder method is 'array'
	%		method 'bitmap' is valid only for select parameters
	%
	%	enc = QCLDPCEncode( enc )
	%		recompute dependent parameters 
	%		
	%	QCLDPCEncode( code, enc )
	%		test code and encoder parameters compatibility
	%		throws error if parameters configuration is unsupported/invalid
	%
	%	CW =  QCLDPCEncode( data, code, enc )
	%		encode Data using given parameters
	%
	%		data - column vector or matrix of column vectors 
	%			for 'array' type encoder:
	%			default data type is 'uint8', storing only values 0 or 1 
	%			other types are auto-converted 
	%			nr. of rows must == code.K
	%
	%			for 'bitmap' type encoder:
	%			only uint8, uint16, uint32 data types supported
	%			assumed to be bitmaps
	%			nr. of rows must == code.K / enc.wb
	%
	%		code - code options structure, see loadQCLDPC()
	%		enc - encoder options structure 
    %
	% compatible MEX file must first be built using saveLDPCheader() and buildMEXfile()
	% see testEnc for examples
	
	%default options:
	dopts.dbglev	= 0 ;		% 0 > silent, only works with debug build
	dopts.build		= 'release' ;

	%build options
	dopts.method	= 'array' ;	% 'array' or 'bitmap'
	dopts.mexfun	= 'QCLDPCEncodeMEX' ; 
	dopts.sources	= [ "encoder.c" "debug.c" "ldpc.c" ] ;
	
	%default options for the bitmap method:
	dopts.type		= 'uint8' ;
	dopts = bitmapParams( dopts.type, dopts ) ;

	%dopts = mergeStructs( dopts, bopts ) ;
	
	if nargin == 0
		%just return default options
		CW = dopts ;
	elseif nargin == 1
		if ~isstruct( p1 )
			error('Usage: enc = QCLDPCEncode( enc )') ;
		end
		CW = bitmapParams( p1.type, p1 ) ;		
	elseif nargin == 2
		%just test code and encoder parameters are set correctly
		CW = paramsOK( p1, p2 ) ;
	elseif nargin == 3
		%actual encoding
		if paramsOK( p2, p3 )
			code = p2 ;
			if isequal( code.std, 'ccsds' )
				%TODO: MEX file not yet implemented
				CW = mod( code.G' * p1, 2 ) ;
			else
				CW = encode( p1, p3 ) ;
			end
		end
	else
		error('Unsupported parameters combination. See help for usage.')
	end
end

function OK = paramsOK( code, enc )
	
	if strcmp( code.std, 'wifi6' )
		if strcmp( enc.method, 'bitmap' )
			error( "Bitmap encoding unsupported for WIFI parameters.") ;
		end
	elseif strcmp( code.std, 'wimax' ) || strcmp( code.std, 'ccsds' )
		if strcmp( enc.method, 'bitmap' )
			%only select subset of code parameters supported
			if mod( code.N, enc.wb ) ~= 0 || mod( code.K, enc.wb ) ~= 0 || mod( code.M, enc.wb ) ~= 0
				error( "Bitmap encoding unsupported parameters: N,K,M must be disible by WB.") ;
			end
		end
	else
		error( "Unsupported standard, set: 'wimax' of 'wifi6'.") ;
	end

	OK = true ;
end

function CW = encode( Data, enc )

	Options = [ enc.dbglev, 0 ] ;	%method option is unused now
	
	if strcmp( enc.method, 'array')
		%for 'array' encoder type auto-convert the Data to enc.type
		assert( isBinary( Data ) ) ;

		if ~isa( Data, enc.type )
			t		= class( Data ) ;
			UData	= cast( Data, enc.type ) ;
			UPar	= QCLDPCEncodeMEX( UData, Options ) ;
			Par		= cast( UPar, t ) ;
			CW		= [ Data ; Par ] ;
		else
			Par		= QCLDPCEncodeMEX( Data, Options ) ;
			CW		= [ Data ; Par ] ;
		end
	else
		if ~isa( Data, enc.type )
			error( "For bitmap encoding you must explicitly use the Data of encoder type.") ;
		end
		%no auto-datatype conversion performed for 'bitmap' encoder
		Par = QCLDPCEncodeMEX( Data, Options ) ;
		CW	= [ Data ; Par ] ;
	end
end

function encoder = bitmapParams( t , encoder )

	encoder.type = t ;

	switch t	
		case 'uint64' 
			w				= 64 ;
			encoder.ctype	= 'uint64_t' ;
		case 'uint32'
			w				= 32 ;
			encoder.ctype	= 'uint32_t' ;
		case 'uint16'
			w				= 16 ;
			encoder.ctype	= 'uint16_t' ;
		case 'uint8'
			w				= 8 ;
			encoder.ctype	= 'uint8_t' ;
		case 'single'
			w				= 32 ;
			encoder.ctype	= 'uint32_t' ;	%FIXME
		case 'double'
			w				= 64 ;
			encoder.ctype	= 'uint64_t' ;	%FIXME
		otherwise
			error('Unsupported type.') ;
	end

	ws = num2str( w ) ;
	encoder.wb			= w ;
	encoder.mextype		= [ 'mxUint' ws ]	;
	encoder.mexclass	= [ 'mxUINT' ws '_CLASS' ] ;
	encoder.mexget		= [ 'mxGetUint' ws 's' ] ;

end
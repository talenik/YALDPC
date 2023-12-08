function code = loadQCLDPC( std, R, L )
% loadQCLDPC - load all code parameters based on standard, coderate and N
% 
%	for 'wimax' and 'wifi6' standards:
%	code = loadQCLDPC( std, R, n )
%		R	- coderate is one of [ 1/2 2/3 3/4 5/6 ]
%		n	- codeword length in bits, must be one of:
%			[ 648, 1296, 1944 ] for wifi
%			[ 24 + 4 * [ 0 : 1 : 18 ] ] for wimax
%
%	for 'ccsds' standard:
%%	code = loadQCLDPC( std, R, k )
%		R	- coderate is one of [ 1/2 2/3 4/5 ]
%		k	- dataword length in bits, must be one of:
%			[ 1024, 4096, 16384 ]
%	note -	returns a base code with larger n that must
%			be punctured or shortened to get actual coderate R

if strcmp( std, 'wimax')
	n	 = L ;
	code = loadWIMAX_LDPC( R, n ) ;
	code.G_MAX = findGMAX( code.Hbm ) ;

elseif strcmp( std, 'wifi6')
	n	 = L ;
	code = loadWIFI6_LDPC( R, n ) ;
	code.G_MAX = findGMAX( code.Hbm ) ;

elseif strcmp( std, 'ccsds')
	cc	 = CCSDS_LDPC() ;
	k	 = L ;	
	code = cc.loadCCSDS_LDPC( k, R ) ;	
	z	 = code.M ; 
	zz	 = code.z ;
	code.z = z ;
	code.zz = zz ;
	[ code.M, code.N ] = size( code.H )	;
	code.K = code.N - code.M ;
	code.Rc = code.K / code.N ;
	
	code.Hs = sparse( code.H ) ;

	code.Hbm = sumCells( cc.getHbm( k, R ) ) ;
	[ code.Mb, code.Nb ] = size( code.Hbm )	;

	%also load CH_S and CH_IND arrays
	code.G_MAX = findGMAX( code.H ) ;

elseif strcmp( std, '5g')
	error('not implemented yet')
else
	error('Unsupported standard') ;
end

[ code.CH_S, code.CH_I ] = getIndices( code.H, code.G_MAX ) ;

code.Kb		= code.Nb - code.Mb ;
code.std	= std ;

code.s		= 0 ;		%default nr of shortened bits
code.p		= 0 ;		%defualt nr of punctured bits
code.shortIdx	= [] ;	%indices of shortened bits
code.puncIdx	= [] ;	%indices of punctured bits
end

function sA = sumCells( cA )
	[ R, C ] = size( cA ) ;
	sA = zeros( R, C ) ;

	for r = 1 : R
		for c = 1 : C
			sA( r, c ) = sum( cA{ r, c } ) ;
		end
	end
end

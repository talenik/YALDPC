function code = loadQCLDPC( std, R, N )
% loadQCLDPC - load all code parameters based on standard, coderate and N
% 
%	code = loadQCLDPC( std, R, N )
%		std - standard identified by string: 'wifi' or 'wimax'
%		R	- coderate is one of [ 1/2 2/3 3/4 5/6 ]
%		N	- codeword length in bits, must be one of:
%			[ 648, 1296, 1944 ] for wifi
%			[ 24 + 4 * [ 0 : 1 : 18 ] ] for wimax

if strcmp( std, 'wimax')
	code = loadWIMAX_LDPC( R, N ) ;
else
	code = loadWIFI6_LDPC( R, N ) ;
end

code.std = std ;
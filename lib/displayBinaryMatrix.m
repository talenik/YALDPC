function displayBinaryMatrix( H, zf )
% Display a QC-LDPC code parity check matrix
% (or any binary matrix with this structure)
% as a matlab figure.

global DBGLEV ; 
if ~exist('DBGLEV','var') || isempty( DBGLEV ) 
	DBGLEV = 0 ;
elseif DBGLEV == -1
	return 
end


[ M, N ] = size( H ) ;
mb		= M / zf ;
nb		= N / zf ;
I 		= ones( M, N ) ;
	
for r = 1:1:mb
	I( zf * r, : ) = 0.5 ;
end
for c = 1:1:nb
	I( :, zf * c ) = 0.5 ;
end
I( find( H ) ) = 0 ;

%figure() ;
imagesc( I,[ 0 1 ] ) ;
colormap( gray ) ;
	
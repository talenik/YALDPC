function [ MI, OF ] = float2int( MF, bits, fpmax )
% float2int - saturating convert floating point matrix to 
%		integer / fixed-point representation
%
%	[ MI, OF ] = float2int( MF, bits [, fpmax ] )
%		MF - matrix of floating-point values
%		MI - matrix of truncated and integer-converted samples, 
%			stored as double, must typecast manually
%
%		fpmax - optional saturation threshold
%		bits - nr. of bits to sample the absolute values, sign excluded
%		OF - the number of saturated values

if nargin == 0
	MI = unitTest() ;
	return ;
end

if nargin == 2
	fpmax	= max( abs( MF ), [], 'all') ;
end

	uoi = MF > fpmax ;
	loi = MF < -fpmax ;
	OF  = nnz( uoi ) + nnz( loi ) ;
	
	MF( uoi )	= fpmax ;
	MF( loi )	= -fpmax ;
	
	imax = 2 ^ bits - 1 ;
	
	a = imax / fpmax ;
	
	MI = round( a * MF ) ;
	
	assert( all( MI <= imax, 'all' ) ) ;

end

function ok = unitTest()
	
	A = [ 1 -1 0 99 100 101 -99 -100 -101 1000 -1000 ]
	B = float2int( A, 7, 100 )

	if isequal( B, [ 1 -1 0 126 127 127 -126 -127 -127 127 -127 ] )
		disp( 'Unit test OK' ) ;
		ok = true ;
	else
		disp( 'Unit test FAILED' ) ;
		ok = false ;
	end
end


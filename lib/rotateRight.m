function rotated = rotateRight( vector, shift )
% rotateRight - perform cyclic shift of vectors elements - the ROR operation.
%
% rotated = rotateRight( vector, shift )
% Performs horizontal ROR, if a matrix is supplied, rotate all rows.
% The scalar shift specifies how many positions to rotate
%	if negative, a ROL operation is performed.

[ y, x ] = size( vector ) ;


if x == 1
	%column vector - shift down
	sh	= sht( shift, y ) ;
	s	= y - sh ;
	rotated = [ vector( s + 1 : end ) ; vector( 1 : s ) ] ;
else
	%row vector or matrix - shift right
	sh = sht( shift, x ) ;
	s	= x - sh ;
	rotated = [ vector( :, s + 1 : end ) vector( :, 1 : s ) ] ;
end

end

function sn = sht( s, n )
	if s < 0
		%implement left shift as negative shift
		s = n + s ;
	end 
	sn	= mod( s, n ) ;
end

	

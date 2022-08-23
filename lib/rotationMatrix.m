function M = rotationMatrix( Size, Shift )
% Generate a square permutation matrix if size Size.
% 
% M = rotationMatrix( Size, Shift )
%	The permutation is a right rotation - the ROR operation.
%	That is the right-multiplication of a vector by this matrix performs 
%	a cyclic shift of vector's position - the ROR operation.
%	The scalar shift specifies how many positions to rotate
%	If negative, a ROL operation is performed.

Perm	= rotateRight( [ 1:1:Size ], Shift ) ;
I		= eye( Size ) ;
M		= I( :, Perm ) ;
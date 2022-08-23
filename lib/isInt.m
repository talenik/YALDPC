function r = isInt( M, tol )
% isInt - determines if matrix contains approximate integer values
%	don't confuse this with isInteger()
%
% r = isInt( Matrix, [ tol ] ) 
%		expecting Matrix of a floating-point type
%		tol - tolerance, default tolerance is 1e-10 
%
%	will return true if all Matrix elements are closer than tol to integer

if nargin == 1
	tol = 1e-10 ;
end

R = round( M, 0 ) ;
D = abs( R - M ) ;
f = nnz( D > tol ) ;

r = ( f == 0 ) ;


function vs = n2s( v, lab )
%n2s - convert a variable or expression to string, usually for debug output
%	the string is a valid MATLAB code
%
%	s = n2s( A )
%		produces a string: 'A = value-of-A'
%		this will not work if A is an expression
%	s = n2s( A, label )
%		produces a string 'label = value-of-A'
%		this will work when A is an expression
%
%	works for A scalar, or vector, not matrix

if nargin == 1
	lab = inputname( 1 ) ;
end

if size( v, 1 ) > size( v, 2 )
	v = v.' ;
end
	
s	= num2str( v ) ;

if size( v, 2 ) == 1
	vs = [ ' ' lab ' = ' s ' ' ] ;
else
	if ischar( v )
		vs = [' ' lab ' = ''' s ''' ' ] ;
	else
		vs = [ ' ' lab ' = [ ' s ' ] ' ] ;
	end
end

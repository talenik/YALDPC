function vs = n2s( v, lab )
%n2s - convert a variable or expression to character array or string, 
%	usually for debug output, the string is a valid MATLAB code
%
%	s = n2s( A )
%		produces a char array: 'A = value-of-A'
%		this will not work if A is an expression
%	s = n2s( A, "string" )
%		produces a string: "A = value-of-A"
%		this will not work if A is an expression
%	s = n2s( A, 'label' )
%		produces 
%			a char array: 'label = value-of-A' if 'label' is char array
%			or string: "labe = value-of-A" if "label" is string
%		this will work when A is an expression
%
%	Caveat: works for A scalar or vector, not matrix.

if nargin == 1
	lab		= inputname( 1 ) ;
	type	= 'char' ;
	sp		= ' ' ;
elseif nargin == 2
	if isstring( lab ) || isequal( lab, 'string' )
		type = 'str' ;
		sp = '' ;
	else
		type = 'char' ;
		sp = ' ' ;
	end
	if isequal( lab, 'string' )
		lab = string( inputname( 1 ) ) ; 
	end
end

%convert column vector to row vector
if size( v, 1 ) > size( v, 2 )
	v = v.' ;
end

s	= num2str( v ) ;

if size( v, 2 ) == 1
	%v is a scalar
	if isequal( type, 'str' )
		vs = join( [ lab "=" string( s ) ], "" ) ;
	else
		vs = [ sp lab sp '=' sp s sp ] ;	
	end
else
	%v is a vector
	if ischar( v )
		vs = [' ' lab ' = ''' s ''' ' ] ;
	elseif isequal( type, 'str')
		vs = join( [ lab "=[" string( s ) "]" ], "" ) ;
	else
		vs = [ ' ' lab ' = [ ' s ' ] ' ] ;
	end
end



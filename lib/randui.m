function MTX = randui( R, C, type )
% randui -	generate pseudo random bitmap matrix stored as unsigned int
%			Fixes bug in randi for uint64 data type.
%
% M = randui( rows, columns, type )
%		type - 'uint8', 'uint16', 'uint32', 'uint64', 'double'
%			if 'double' then same as randi( [ 0 1 ], R, C )


if nargin == 0
	unitTest()
	MTX = [] ;
end

if nargin == 2
	type = 'double' ;
end

if nargin > 1
	code() ;
end

	function code()
		
		if isequal( type, 'uint64' )
			w	= 32 ;
			A32 = randi( [ 0 2 ^ w - 1 ], R, C, 'uint32' ) ;
			B32 = randi( [ 0 2 ^ w - 1 ], R, C, 'uint32' ) ;
			A	= bitshift( uint64( A32 ), 32, type ) ;
			B	= uint64( A32 ) ;
			MTX = bitor( A, B ) ;
		elseif isequal( type, 'double')
			%binary integeres stored as double
			MTX = randi( [ 0 1 ], R, C ) ;
		else
			w	= bitWidth( type ) ;
			MTX = randi( [ 0 2 ^ w - 1 ], R, C, type ) ;
		end
	end

	function unitTest()
		disp('Running unit test.')
		R		= 10 ;
		C		= 5 ;
		type	= 'uint64' ;
		code() ;
		v		= uint64( intmax( 'uint32' ) ) ;
		if( nnz( MTX > v ) < 10 )
			disp('Test: suspicious.') ;
		else
			disp('Test: OK.') ;
		end
		whos 
		MTX
		disp(MTX)
	end
end



classdef Bits
%class for converting between various representations of binary data
%	such as: 
%		mat - standard MATLAB matrices (double) holding only values 0 and 1
%		bit - bitmaps stored as uintXY MATLAB types: 8, 16, 32, 64- bit wide
%		logical - logical matrices
%	
%	b = Bits( 'type' )
%		initialize object for 'type' - string: 'uint8','uint16' , ...
%
%	B = b.logical2bit( A )
%		convert logical matrix A to compressed bitmap form column-wise
%		nr. rows of A must be divisible by type bit-width
%
%	B = b.mat2bit( A )
%		convert double matrix A holding binary values
%		to compressed bitmap form column-wise
%		nr. rows of A must be divisible by 'type' bit-width
%
%	L = b.bit2Logical( B )
%		convert bitmap matrix B of type 'type' to a logical matrix column-wise
%		nr. of rows of L will be == size( B, 1 ) * 'type' bit-width  
%
%	L = b.bit2mat( B )
%		convert bitmap matrix B of type 'type' to a binary double matrix column-wise
%		nr. of rows of L will be == size( B, 1 ) * 'type' bit-width  

properties
	type = 'uint64' ;
end
methods
	function o = Bits( t )
		if nargin == 0
			t = 'uint64' ;
		end
		switch t
			case 1
				o.test1() ;
			case 2
				o.test2() ;
			case 3
				o.test3() ;
			case 4
				o.test4() ;
			otherwise
				% expecting 'uintXY'
				o.type = t ;
		end
	end

	function w = typeWidth( o, type )
		if nargin == 1
			type = o.type ;
		end
		
		switch type		%set bits per word
			case 'uint64' 
				w = 64 ;
			case 'uint32'
				w = 32 ;
			case 'uint16'
				w = 16 ;
			case 'uint8'
				w = 8 ;
			otherwise
				error('Unsupported native type.') ;
		end
	end
	
	function B = logical2bit( o, A, type )
	%convert logical matrix to compressed uintXY form column-wise
	%bits of a column will be converted to uintXY words
	
		if nargin < 3
			type = o.type ;
		end
	
		if ~islogical( A )
			error('Matrix not logical.')
		end
	
		bpw = o.typeWidth( type ) ;
	
		[ r, c ] = size( A ) ;
		if mod( r, bpw ) ~= 0
			error('Rows must exactly fit to words.')
		end
		ru = r / bpw ;
		B = zeros( ru, c, type ) ;
	
		for j = 1 : c
			for i = 1 : ru
				si = ( i - 1 ) * bpw + 1 ;
				ei = i * bpw ;
				B( i, j ) = o.vector2bits( A( si : ei, j ), type ) ;
			end
		end
	
	end

	function B = mat2bit( o, A, type )
	%convert matrix of any type (primarily double) holding binary values
	%to uintXY

		if nargin < 3
			type = o.type ;
		end
		
		if ~islogical( A )
			if ~isBinary( A )
				error('matrix contains nonbinary entries') ;
			end
		end

		B = o.logical2bit( logical( A ), type ) ;

	end

	function L = bit2logical( o, B ,type )
	
		if nargin < 3
			type = o.type ;
		end
		if ~isa( B, type )
			error('Binary matrix not of given type.')
		end
		bpw = o.typeWidth( type ) ;
		[ r, c ] = size( B ) ;
		ru = r * bpw ;
		L = zeros( ru, c, 'logical' ) ;
		for j = 1 : c
			for i = 1 : r
				si = ( i - 1 ) * bpw + 1 ;
				ei = i * bpw ;
				L( si : ei, j ) =  o.bits2vector( B( i, j ), type ) ;
			end
		end
	end

	function M = bit2mat( o, B, type )
		if nargin < 3
			type = o.type ;
		end
		L = o.bit2logical( B, type ) ;
		M = double( L ) ;
	end
	
	function B = vector2bits( o, vL, type )
	%converts vector of logical values to single uintXY scalar
		L = length( vL ) ;
		assert( mod( L, 8 ) ==  0 ) ;
	
		B = zeros( 1, 1, type ) ;
		for i = 1 : L
			%indexing bits: 1 > LSb
			B = bitset( B, L - i + 1, vL( i ), type ) ;
		end
	end
	
	function vL = bits2vector( o, B, type )
		L = o.typeWidth( type ) ;
		assert( mod( L, 8 ) ==  0 ) ;

		vL = zeros( L, 1, 'logical' ) ;
		for i = 1 : L
			vL( i ) = logical( bitget( B, L - i + 1, type ) ) ;
		end
	end

	function OK = test1( o )
		A	= logical( randi( [0 1], 8, 3 ) ) 
		B	= o.logical2bit( A, 'uint8')
		OK	= 1 ;	% set manually
	end

	function OK = test2( o )
		%left-msb means index 1 is MSb
		A = logical( de2bi( [ 0 : 255 ].', 8, 'left-msb' ).' ) ;
		B = o.logical2bit( A, 'uint8' ) ;
		C = o.bit2logical( B, 'uint8' ) ;
		whos A B C ;
		OK = isequal( A, C ) 
		A( :, 1 : 10 )
		B( :, 1 : 10 )
		C( :, 1 : 10 )
	end

	% test longer integers
	function OK = test3( o )
		T = [ "uint8", "uint16", "uint32", "uint64" ] ;
		W = [ 8, 16, 32, 64 ] ;
		N = 256 ;

		for i = 1 : size( W, 2 )
			w	= W( i )
			t	= T( i )
			mx	= 2 ^ w ;
			s	= mx / N ;
			sv	= mx - 1
			ev  = sv - s * ( N - 1 )
			V	= [ sv : -s : ev ] ;
			V( 1 )
			V( end )
			if w == 64
				% because of de2bi bugs we have to test bitwidth 64 separately
				A = ones( 64, 10 )  ;
				A( 64, 2:end ) = zeros( 1, 9 ) ;
				A( 63, 3:end ) = zeros( 1, 8 ) ;
				A = logical( A ) ;
			else
				A	= logical( de2bi( V.', w, 'left-msb' ).' ) ;
			end
			B	= o.logical2bit( A, t ) ;
			C	= o.bit2logical( B, t ) ;
			whos A B C ;
			OK = isequal( A, C ) 
			A( :, 1 : 10 ) ;
			B( :, 1 : 10 ) ;
			C( :, 1 : 10 ) ;
		end

	end

	% test bigger matrices
	function OK = test4( o )
		T = [ "uint8", "uint16", "uint32", "uint64" ] ;
		W = [ 8, 16, 32, 64 ] ;
		R	= 17 ;
		Col	= 111 ;
		for i = 1 : size( W, 2 ) 
			w	= W( i )
			t	= T( i ) 
			wR	= w * R 
			A	= logical( randi( [ 0 1 ], wR, Col ) ) ;
			B	= o.logical2bit( A, t ) ;
			C	= o.bit2logical( B, t ) ;
			whos A B C 
			OK = isequal( A, C )
		end

	end

end
end

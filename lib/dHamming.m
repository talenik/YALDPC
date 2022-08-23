function d = dHamming( U, V )
%dHamming - calculates Hamming distance between two binary matrices.
%
%	d = dHamming( U, V )
%		matrices must be of equal size
%		matrices may be stored as:
%			a) floating point single/double type
%			b) integer uint8 / logical type
%			c) uintXY bitmaps

	if nargin == 0
		d = unitTest() ;
		return ;
	end
	
	[ ru, cu ] = size( U ) ;
	[ rv, cv ] = size( V ) ;
	
	if ru ~= rv || cu ~= cv
		whos
		error("Input sizes not equal.") ;
	end
	
	if ~isfloat( U ) && ~isfloat( V )
		% assuming bitmap storage
		if ~strcmp( class( U ), class( V ) )
			whos
			error("Inputs of different class.") ;
		end
		if ~islogical( U )
			B = Bits( class( U ) ) ;
			U = B.bit2logical( U ) ;
			V = B.bit2logical( V ) ;
		end
	end
	
	if ~isBinary( U ) || ~isBinary( V )
		whos
		error("Input not binary") ;
	end
	d = nnz( U ~= V ) ;
end 

function ok = unitTest()
	ok = 0 ;
	A = eye( 3 ) ;
	B = [ 1 1 0 ; 0 1 0 ; 1 1 1 ] ;
	if dHamming( A, B ) ~= 3
		disp('test double storage FAIL') ;
	else
		disp('test double storage PASS') ;
		ok = ok + 1 ;
	end
	
	A = logical( A ) ;
	B = logical( B ) ; 
	if dHamming( A, B ) ~= 3
		disp('test logical storage FAIL') ;
	else
		disp('test logical storage PASS') ;
		ok = ok + 1 ;
	end

	A = [ zeros( 3, 5, 'logical') A ]' ;
	B = [ zeros( 3, 5, 'logical') B ]' ;
	b = Bits( 'uint8' ) ;
	A = b.logical2bit( A ) ;
	B = b.logical2bit( B ) ;
	if dHamming( A, B ) ~= 3
		disp('test logical storage FAIL') ;
	else
		disp('test logical storage PASS') ;
		ok = ok + 1 ;
	end

	ok = ( ok == 3 ) ;
end


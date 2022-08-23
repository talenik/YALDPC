function [ E, H, D ] = equal( A, B )
% equal - test if two matrices contain equal values
%
%	E = equal( A, B )
%		same as isequal( A, B )
%
%	[ E, H, D ] = equal( A, B )
%		E - boolean flag indicating matrices equal
%		H - hamming distance of matrices
%		D - euclidean distance of matrices

	%if isequal() true > nothing to to do:
	if isequal( A, B )
		E = true ;
		H = 0 ;
		D = 0 ;
		return 
	end
	
	% if different sizes > TODO what to do ?
	if size( A ) ~= size( B )
		E = false ;
		H = -1 ;	
		D = -1 ;
		return 
	end
	
	E = false ;
	H = hamming() ;
	D = euclid() ;


	function h = hamming( )
		h = nnz( A ~= B ) ;
	end

	function d = euclid()
		d  = sum( ( A - B ) .^ 2, 'all' ) ;
	end

end




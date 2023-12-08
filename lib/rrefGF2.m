function [ MREF, rank ] = rrefGF2( varargin )
% rrefGF2   Reduced row echelon form over GF2 
% 
% 	R = rrefGF2( A ) produces the reduced row echelon form of A over GF2.
% 
% 	[ R, r ] = rrefGF2( A ) also returns a scalar r - rank of the matrix A
% 
% 	rrefGF2() runs a unit test (includes rebuilding for debug)
% 
% 	Note1:	This function calls a MEX file wrapped by matGF2().
% 			For a succesfull run, the MEX file must be first built.
% 			See: help matGF2 for instructions.
%
%	Note2:	The preferred data type is logical, other types will be
%			auto-converted, which will introduce overhead.


	if isempty( varargin )
		MREF = unitTest() ;	%actually boolean flag
		rank = false ;
	else
		%actual arguments processing anf mex call
		[ MREF, rank ] = matGF2( @rrefGF2, varargin ) ;
	end
end

function ok = unitTest()
	nok = 0 ;
	print('refGF2: Running unit test:') ;
	
	print('Get default options:') ;
	o = rrefGF2('options')
		
	print('trying rebuild with defaults:') ;
	rrefGF2('rebuild')
	
	print('Trying invertible matrix:') ; 
	M = [	0, 0, 1, 1, 1, 1 ; ...
			0, 1, 1, 1, 1, 1 ; ... 
			1, 1, 1, 0, 1, 1 ; ...
			1, 1, 1, 0, 1, 0 ; ...
			1, 1, 1, 1, 0, 0 ; ...
			0, 1, 1, 0, 1, 0 ] 

	[ MR, r ] = rrefGF2( M )
	if isequal( r, rank( M ) )
		print('Matrix rank test OK') ;
		nok = nok + 1 ;
	else
		print('Matrix rank test FAILED') ;
	end

	print('Trying singular matrix:') ; 
	M = [	0, 0, 1, 1, 1, 1 ; ...
			0, 1, 1, 1, 1, 1 ; ... 
			1, 1, 1, 0, 1, 1 ; ...
			1, 1, 1, 0, 1, 0 ; ...
			1, 1, 1, 1, 0, 0 ; ...
			0, 0, 1, 1, 1, 1 ] 

	[ MR, r ] = rrefGF2( M )
	if isequal( r, rank( M ) )
		print('Matrix rank test OK') ;
		nok = nok + 1 ;
	else
		print('Matrix rank test FAILED') ;
	end

	print( 'Testing non-square matrix:') ;
	M = [	0, 0, 1, 1, 1, 1 ; ...
			0, 1, 1, 1, 1, 1 ; ... 
			1, 1, 1, 0, 1, 1 ; ...
			1, 1, 1, 0, 1, 0 ]

	[ MR, r ] = rrefGF2( M )
	if isequal( r, rank(M) )
		print('Matrix rank test OK') ;
		nok = nok + 1 ;
	else
		print('Matrix rank test FAILED') ;
	end

	print('Trying debugging:') ;
	o.verbose = 1 ;
	o.build = 'debug' ;
	[ MR, r ] = rrefGF2( M, o )


	ok = nok == 3 ;
	
	if ok
		print('Unit test ALL OK') ;
	else
		print('Unit test FAILED') ;
	end
end
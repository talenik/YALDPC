function [ MI, status ] = invGF2( varargin )
% invGF2   Find inverse matrix over GF2 
% 
% 	AI = invGF2( A ) produces an inverse matrix to A over GF2.
% 
% 	[ AI, r ] = invGF2( A ) also returns a scalar r - rank of the matrix A
%	TODO: calculation of r is currently broken
% 
% 	invGF2() runs a unit test 
% 
% 	Note1:	This function calls a MEX file wrapped by matGF2().
% 			For a succesfull run, the MEX file must be first built.
% 			See: help matGF2 for instructions.
%
%	Note2:	The preferred data type is logical, other types will be
%			auto-converted, which will introduce overhead.
	
	if isempty( varargin )
		MI = unitTest() ;
		status = false ;
	else
		%actual arguments processing anf mex call
		[ MI, status ] = matGF2( @invGF2, varargin ) ;
	end
end

function ok = unitTest()
	nok = 0 ;
	print('invGF2: Running unit test:') ;
	
	print('Get default options:') ;
	o = invGF2('options')
	
	print('trying rebuild with defaults:') ;
	invGF2('rebuild')
	
	print('Trying invertible matrix:') ; 
	M = [	0, 0, 1, 1, 1, 1 ; ...
			0, 1, 1, 1, 1, 1 ; ... 
			1, 1, 1, 0, 1, 1 ; ...
			1, 1, 1, 0, 1, 0 ; ...
			1, 1, 1, 1, 0, 0 ; ...
			0, 1, 1, 0, 1, 0 ] 

	[ MI, nr ] = invGF2( M )
	if isequal( nr, 6 )
		print('Status indicator test OK') ;
		nok = nok + 1 ;
	else
		print('Status indicator test FAILED') ;
	end

	MI = double( MI ) ;
	if isequal( mod( M * MI, 2 ), eye( size( M ) ) ) 
		print( 'MI inverse to M > test OK') ;
		nok = nok + 1 ;
	else
		print( 'MI not inverse to M > test FAILED') ;
	end

	print('Trying singular matrix:') ; 
	M = [	0, 0, 1, 1, 1, 1 ; ...
			0, 1, 1, 1, 1, 1 ; ... 
			1, 1, 1, 0, 1, 1 ; ...
			1, 1, 1, 0, 1, 0 ; ...
			1, 1, 1, 1, 0, 0 ; ...
			0, 0, 1, 1, 1, 1 ] 

	[ MI, nr ] = invGF2( M )
	if ~isequal( nr, 6 )
		print('Status indicator test OK') ;
		nok = nok + 1 ;
	else
		print('Status indicator test FAILED') ;
	end

	ok = nok == 3 ;
	if ok
		print('Unit test ALL OK') ;
	else
		print('Unit test FAILED') ;
	end
end
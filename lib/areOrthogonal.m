function ort = areOrthogonal( G, H )
% ort = areOrthogonal( G, H ) 
%	tests orthogonality of GF(2) matrices ( or vectors) G and H.
%	returns 1 is matrices are orthogonal, 0 otherwise

	[ rg, cg ] = size( G ) ;
	[ rh, ch ] = size( H ) ;

	if ~isBinary( G )
		error("G not binary") ;
	end

	if ~isBinary( H )
		error("H not binary")
	end

	%work around uintXY/logical types limitations
	G = double( G ) ;
	H = double( H ) ;

	if cg == rh
		R = G * H ;
	elseif cg == ch
		R = G * H.' ;
	elseif cg == 1
		R = H * G ;
	elseif rg == ch
		R = H * G ;
	else
		error('Incompatible matrix sizes.') ;
	end
	
	S = nnz( mod( R, 2 ) ) ;
	ort = ( S == 0 ) ;

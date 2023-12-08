function [ q, r ] = divmod( s, d )
	q = floor( s / d ) ;
	r = mod( s, d ) ;
	if s ~= ( q * d + r )
		error('not integer numbers') ;
	end
end
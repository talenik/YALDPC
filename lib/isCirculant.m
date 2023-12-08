function cir =  isCirculant( M )
	[ r, c ] = size( M ) ;
	if r ~= c 
		cir = false ;
		return ;
	end
	R1R = rotateRight( M( 1,: ), 1 ) ;
	R1L = rotateRight( M( 1,: ), -1 ) ;

	if isequal( M( 2, : ), R1R )
		s = 1 ;
	elseif isequal( M( 2, : ), R1L )
		s = -1 ;
	else
		%TODO: maybe also step more than 1 per row ???
		cir = false ;
		return ;
	end
	
	
	RR = M( 1, : ) ;
	for i = 2 : r
		RR = rotateRight( RR, s ) ;
		if ~isequal( RR, M( i, : ) ) 
			cir = false ;
			return ;
		end
	end
	cir = true ;
end
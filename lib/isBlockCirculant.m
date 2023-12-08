function [ bc, qr, qc ] = isBlockCirculant( M, z )
	[ r, c ] = size( M ) ;
	[ qr, rr ] = divmod( r, z ) ;
	[ qc, rc ] = divmod( c, z ) ;
	
	if rr ~= 0 ||  rc ~= 0
		error('Matrix size not a multiple of z') ;
	end

	for i = 1 : qr
		for j = 1 : qc
			T = M( ( i - 1 ) * z + 1 : i * z , ( j - 1 ) * z + 1 : j * z ) ;
			assert( isequal( size( T ), [ z z ] ) ) ;
			if ~isCirculant( T )
				bc = false ;
				return
			end
		end
	end
	bc = true ;
end
function IR  = blockIndex2Range( IB, z )
%convert block index to a range of linear indices for subblock size z
%	IR  = blockIndex2Range( ib, z )
%		is a range of indices
%		ib may also be a vector

	IR = [] ;
	for i = 1 : length( IB )
		ib = IB( i ) ;
		IR = [ IR [ ( ib - 1 ) * z + 1 : ib * z ] ] ;
	end
	IR = sort( IR ) ;

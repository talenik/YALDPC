function C = str2char( SA )
% convert string array to one char array

	cl	= convertStringsToChars( SA ) ;
	if size( SA, 1 ) == size( SA, 2 )
		C = cl ;
	else
		C	= horzcat( cl{ : } ) ;
	end


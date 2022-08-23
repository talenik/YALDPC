function s = rate2str( r )
% rate2str - convert code rate (double) to nice string representation
% 
%	s = rate2str( r )
%		supported rates: 1/2, 2/3, 3/4, 5/6

	if r == 1 / 2
		s = '12' ;
	elseif r == 2 / 3
		s = '23' ;
	elseif r == 3 / 4
		s = '34' ;
	elseif r == 5 / 6
		s = '56' ;
	else
		error('Rate unsupported.') ;
	end
end
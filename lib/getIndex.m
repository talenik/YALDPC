function i = getIndex( haystack, needle, label )
% getIndex - find the index of the first occurence of a value in a vector
% 
% i = getIndex( haystack, needle [,label ] )
%	returns the index of first needle in haystack
%	optional label for custom error message

	if nargin == 2
		label = 'value' ;
	end

	i = find( haystack == needle, 1 ) ;
	if isempty( i )
		error( [ 'Unsupported ' label ] ) ;
	end
end
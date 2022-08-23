function b = isBinary( M )
%isBnary - test if matrix contains only zeros and ones, 
%	regardless of storage (double, intXY, logical)
% 
%	b = isBinary( M )

if nargin == 0
	unitTest() ;
	return ;
end

	b = all( M == 1 | M == 0, 'all') ;

end

function unitTest()
	A = randi( [ 0 1 ], 10 ) ;
	if isBinary( A )
		disp('test double storage PASS') ;
	else
		disp('test double storage FAIL') ;
	end
	
	A = randi( [ 0 1 ], 10, 'uint8' ) ;
	if isBinary( A )
		disp('test uint storage PASS') ;
	else
		disp('test uint storage FAIL') ;
	end
	A = logical( A ) ;
	if isBinary( A )
		disp('test logical storage PASS') ;
	else
		disp('test logical storage FAIL') ;
	end
end
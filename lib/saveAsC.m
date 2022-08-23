function saveAsC( M, filename, cdef, format, mode, perLine )
% saveAsC - save variable in a C/C++ source file
% saveAsC( M, filename, cdef, format, mode, perLine )
%	M - MATLAB workspace variable (scalar, vector, matrix), real only
%	filename - C source file
%	cdef	 - C definition fopr the variable
%	format	 - C format string for sprintf 
%	mode	 - file mode 'w' or 'a'
%	perLine	 - for vectors/matrices - array elements per one line of source code
%
%	for usage examples see saveLDPCheader.m

if nargin < 6
	perLine = 20 ;
end

if ischar( filename )
	f = fopen( filename, mode ) ;
else
	%filename is an allready open file descriptor
	f = filename ;
end

if f == -1
	error('Could not open file') ;
end
[ r, c ]	= size( M ) ;

if c == 1
	M = M.' ;
	[ r, c ] = size( M ) ;
end

if r == 1 
	fprintf( f, [ cdef '[' num2str( c ) '] = {\n\t\t'] ) ;
	
	for j = 1 : c-1
		fprintf( f, [ format ', '], M( j ) ) ;
		if mod( j, perLine ) == 0
			fprintf( f, '\n\t\t  ' ) ;
		end
	end
	
	fprintf( f, [ format ' } ;\n\n'] , M( c ) ) ;
	
else
%2D arrays separately
	fprintf( f, [ cdef '[' num2str( r ) '][' num2str( c ) '] = {\n'] ) ;

	for i = 1 : r
		fprintf( f, '\t\t{ ' ) ;

		for j = 1 : c - 1
			fprintf( f, [ format ', '], M( i, j ) ) ;
			if mod( j, perLine ) == 0
				fprintf( f, '\n\t\t  ' ) ;
			end
		end

		fprintf( f, [ format ' },\n'] , M( i, c ) ) ;
	end

	fprintf( f, '\t} ;\n\n' ) ;
end

if ischar( filename )
	fclose( f ) ;
end
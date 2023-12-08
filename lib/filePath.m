function [ filename, path ] = filePath( fullpath )

pos = strfind( fullpath, filesep ) ;

if isempty( pos )
	filename = fullpath ;
	path	 = filesep ;
else
	p = pos( end ) ;
	filename = fullpath( p + 1 : end ) ;
	path = fullpath( 1 : p - 1 ) ;
end

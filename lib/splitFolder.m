function [ folder, filename ] = splitFolder( filepath )

if ispc	% windows
	sep = '\' ;
else	% linux
	sep = '/' ;
end

ind			= find( filepath == sep, 1, "last" ) ;
folder		= filepath( 1 : ind ) ;
filename	= filepath( ind + 1 : end ) ;
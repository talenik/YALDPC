function ok = buildMEXfile( desc )
%buildMEXfile - build a MEX module out of a descriptor desc
%
%	buildMEXfile( desc )
%		assumes C/C++ sources for MEX are in a subfolder '../MEX' 
%
%		desc is a structure with fields:
%		mandatory:
%		desc.mexfun - name of the MEX function to build
%			also name of the source C/C++ file withouth extension
%		desc.build - 'release' (default) or 'debug'
%			toggles DEBUG/NDBENUG macros, compiler optimizations, and assertions
%
%		optional:
%		desc.sources - list of additional source file names 
%		desc.nthreads - if set and > 1 turns on POSIX threading
%		desc.defines - if set defines compiler macros
%
%	for more details and assumptions see: edit buildMEXfile 

	cwd = pwd ;
	if isfield( desc, 'mexpath')
		cd( desc.mexpath ) ;
	else
		cd MEX ;
	end

	clear( desc.mexfun ) ;
	mexfile = [ desc.mexfun '.' mexext ] ;
		
	if isfile( mexfile )
		delete( mexfile ) ;
	end

	mexsrc = [ desc.mexfun '.cc' ] ;
	if isfile( mexsrc )
		ext = '.cc' ;
	else
		ext = '.c' ;
	end

	cmd = 'mex -R2018a ' ;

	if isfield( desc, 'verbose' ) 
		if desc.verbose == 1
			cmd = [ cmd ' -v' ] ;
		end
	end

	if strcmp( desc.build, 'debug')	
		disp("Building DEBUG MEX") ;
		cmd = [ cmd ' -g -DDEBUG=1' ] ;	
	else
		disp("Building RELEASE MEX") ;
		cmd = [ cmd ' -O -DNDEBUG=1 -UDEBUG' ] ;
	end

	if isfield( desc, 'defines' ) 
		for d = desc.defines
			cmd = [ cmd ' -D' char( d ) ] ;
		end
	end

	if isfield( desc, 'nthread' ) && desc.nthread > 1
		cmd = [ cmd ' -lpthread' ] ;
	end
	
	src = convertCharsToStrings( [ desc.mexfun ext ] ) ;
	cmd = [ cmd src ] ;

	if isfield( desc, 'sources' ) 
		for s = desc.sources
			cmd = [ cmd s ] ;
		end
	end
	
	cmd = strjoin( cmd ) ;
	disp( cmd ) ;
	eval( cmd ) ;
	
	cd( cwd ) ; %TODO: return to current dir fails even if MEX fails
	ok = true ;
end


function [ out, out2 ] = matGF2( varargin )
%main entry point to MEX file common for various GF2 functions
%	not to be called directly, but if you must:
%
%	matGF2( @funhandle, string )
%	where function handle may be: @invGF2 or @rrefGF2
%	the supprted string values are: 
%		'options'	- return default options structure
%		'size'		- return compiled-in limits
%		'rebuild'	- rebuild the MEX file with default options
%
%	matGF2( @funhandle, M )
%	where M is a matrix containing binary values, where preferred type 
%	is 'logical', other types ('double','intXY') will be automatically 
%	converted to 'logical' which may be slow
%
%	matGF2( @funhadle, options )
%	rebuild MEX file given the options structure with compile-time options:
%		o.maxrows
%		o.maxcols
%	It also contains run-time options to be passed to MEX file. 
%	Currently supported are:
%		o.verbose	MEX file debug level
%		o.report	dont run any MEX method, just return compiled-in limits
%		o.method	(choose from: 1 > rrefGF2, 2 > invGF2 )
%
%		o.verbose	also turns on MEX build details printout
%
%	matGF2( @funhandle, M, options )
%	where M is a matrix containing binary values and options is an options
%	structure. Used for debugging for combined rebuild and run.
%
%	matGF2( @funhandle, size, 'rebuild' )
%	where size is a [ y, x ] size vector
%	this serves to rebuild the MEX file with specified limits
%	these limits will be compiled-in
%
%	See also: rrefGF2, invGF2

	out2 = false ;
	if isempty( varargin )
		out = unitTest() ;
		return
	end

	o = defaultOptions() ;
	l = length( varargin{ 2 } ) ;
	f = varargin{ 1 } ;			%function handle
	p1 = varargin{ 2 }{ 1 } ;	%actual first parameter
	o.method = methodIndex( f ) ;	% numeric method index for MEX file

	[ filename, path ] = filePath( mfilename('fullpath') ) ;
	addpath( [ path filesep 'MEX' ] ) ;
	fun = str2func( o.mexfun ) ;

	if l == 1
		%one actual user parameter
		
		if isStr( p1 )
			if isequal( p1, 'options' )
				%return options structure
				out = o ;
			elseif isequal( p1, 'size' )
				%MEX call: query compiled-in limits
				[ r, c ] = fun( 0, [ o.verbose 1 o.method ] ) ;
				out = [ r, c ] ;
			elseif isequal( p1, 'rebuild' )
				%rebuild MEX with default options
				out2 = [ o.maxrows, o.maxcols ] ;
				out = rebuild( out2 , o ) ;
			else
				error('Unsupported parameter, see help.') ;
			end
		elseif isstruct( p1 )
			%force rebuild MEX file
			o = p1 ;
			out2 = [ o.maxrows o.maxcols ] ;
			out  = rebuild( out2, o ) ;
		else
			if ~isBinary( p1 )
				error( 'Matrix not binary.' ) ;
			end
			if ~islogical( p1 )
				p1 = logical( p1 ) ;
			end
			if isempty( which( o.mexfun ) )
				error( 'MEX file not found. Please rebuild.' ) ;
			end
			%actual MEX call of the main routine
			[ out, out2 ] = fun( p1, [ o.verbose o.report o.method ] ) ;
		end

	elseif l == 2
		%two actual user parameters
		p2 = varargin{ 2 }{ 2 } ;

		if isstruct( p2 )
			%debugging mode:
			%p2 is options structure > p1 is matrix
			o = p2 ;
			rebuild( size( p1 ), o ) ;
			if ~islogical( p1 )
				p1 = logical( p1 ) ;
			end
			[ out, out2 ] = fun( p1, [ o.verbose o.report o.method ] ) ;
		else
			% p1 actually contains a size vector
			s = p1 
			if ~isequal( size( s ), [ 1 2 ] )
				error('First argument should be a size vector') ;
			end			
			if ~isequal( p2, 'rebuild')
				error('Unsupported parameter, see help') ;
			end
			
			% test first if rebuild necessary and then rebuild (or not)
			if isempty( which( o.mexfun ) )
				rebuild( s, o ) ;
			else
				%MEX call: query compiled-in limits
				[ r, c ] = fun( 0, [ o.verbose 1 o.method ] ) ;
				ok	= r >= s( 1 ) && c >= s( 2 ) ;
				
				if ~ok %rebuild only if necessary
					rebuild( s, o ) ;
				end
			end		
			out = s ;	%return compiled-in size
		end
	else
		error('Invalid number of parameters.') ;
	end

end

function ok = rebuild( s, o ) 
	o.defines	= [ n2s( s( 1 ), "R" ) n2s( s( 2 ), "C" ) ] ;
	ok = buildMEXfile( o ) ; % MEX will throw an error if necessary
end

function index = methodIndex( handle )
	if isequal(	handle, @rrefGF2 )
		index = 1 ;		
	elseif isequal( handle, @invGF2 )
		index = 2 ;
	else 
		%MEX file will not run anything, just
		index = 0 ;
	end
end

function o = defaultOptions()

	n = dbstack().name ;
	p = which( n ) ; 
	f = splitFolder( p ) ;

	o.mexfun	= 'matGF2MEX' ;
	o.mexpath	= [ f 'MEX' ] ;
	o.maxrows	= 256 ;	%gets compiled into the MEX file
	o.maxcols	= 256 ; %gets compiled into the MEX file
	o.defines	= [ n2s( o.maxrows, "R" ) n2s( o.maxcols, "C" ) ] ;
	o.build		= 'release' ;
	%these run-time options get passed further to the MEX file as doubles
	o.verbose	= 0 ;	%turns MEX debug mesages on
	o.report	= 0 ;	%MEX just returns compiled-in params
	o.method	= 0 ;	%run GF2 inverse of REF method
end

function ok = unitTest()
	print( 'Running unit test:') ;
	print( "rrefGF2('options'):" ) ;
	o = matGF2( @rrefGF2, { 'options' } )
	print( "rrefGF2('rebuild'):" ) ;
	s = matGF2( @rrefGF2, { 'rebuild' } )	%rebuild with default options
	print( "rrefGF2('size'):" ) ;
	s = matGF2( @rrefGF2, { 'size' } )


	print('') ;
	print( "invGF2('options'):\n" ) ;
	o = matGF2( @invGF2, { 'options' } )
	print( "invGF2('rebuild'):" ) ;
	s = matGF2( @invGF2, { 'rebuild' } )	%rebuild with default options
	print( "invkGF2('size'):" ) ;
	s = matGF2( @invGF2, { 'size' } )

	ok = true ; %TODO
end
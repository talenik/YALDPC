function out =  print( level, message, target)

	if nargin == 3
		if will( level )
			if iscell( message ) 
				out = appendCell( message, target ) ;
			elseif isstring( message )
				out = appendString( message, target ) ;
			elseif ischar( message ) 
				out = appendChar( message, target ) ;
			else
				%throw an error perhaps ?
				out = target ;
			end
		else
			out = target ;
		end
		return ;

	elseif nargin == 2
		%no target set > will be printing according to level
	elseif nargin == 1
		%no level set > defaults to 1 (normal print)
		message = level ;
		level	= 1 ;
	else
		%call unit test
	end

	if will( level )
		if iscell( message ) 
			printCell( message ) ;
		elseif isstring( message )
			printString( message ) ;
		elseif ischar( message ) 
			printChar( message ) ;
		else
			printMatrix( message ) ;
		end
	end
	out = [] ;
end

function doit = will( lev )

	global VERBOSITY ;

	if ~exist( 'VERBOSITY', 'var' ) || isempty( VERBOSITY ) || VERBOSITY == 1
		% verbosity not set or set to 1 > normal print
		doit = true ;
	elseif VERBOSITY == 0
		% verbosity defined and == 0 > silent operation
		doit = false ;
	elseif VERBOSITY >= lev
		% verbostiy > 1	> means really debug level
		doit = true ;
	end
end


function o = appendCell( msg, tgt )
	%assuming tgt not a cell matrix
	x = size( tgt, 2 ) ;
	if x == 1
		o = [ tgt ; msg ] ;
	else
		o = [ tgt msg ] ;
	end
end

function o = appendString( msg, tgt )
	%assuming not a string matrix
	x = size( tgt, 2 ) ;
	if x == 1
		o = [ tgt ; msg ] ;
	else
		o = [ tgt msg ] ;
	end
end

function o = appendChar( msg, tgt )
	%assuming not a string matrix
	x = size( tgt, 2 ) ;
	if x == 1
		o = [ tgt ; msg ] ;
	else
		o = [ tgt ' ' msg ] ;
	end
end

function printCell( msg )
	% msg may even be a cell matrix
	disp( msg ) ;
	[ y, x ] = size( msg ) ;
	for i = 1 : y
		for j = 1 : x 
			
		end
	end
end

function printString( msg )
	% msg may even be a string matrix
	[ y, x ] = size( msg ) ;
	if min( x, y ) > 1
		disp( msg ) ;
	else
		%join vector elements together
	end
	
end

function printChar( msg )
	disp( msg ) ;
end

function printMatrix( msg )
	% msg may even be a matrix
	disp( msg ) ;
	% display each element with it's own precition
end




% print to screen as usual
% turn off all printouts if necessary by one switch
% optionally specify target as string arrray or cell array



%usage: set global variable in main program VERBOSITY = X



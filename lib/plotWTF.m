function h = plotWTF( RES, std, R, N )
% plotWFT - plot several waterfall curves using semilogy
%
% handle = plotWTF( res )
%		plot several curves stores in a cell array of result structures
%		automatically create a new figure
%		return figure handle
%
% handle = plotWTF( res, title )
%		plot one curve stored in a results structure
%		title - any string to serve as figure title
%
% handle = plotWTF( res, handle )
%		plot one or several curve, given an existing figure handle
%		res - results structure or cell array of structures
%
% see WTF.m for details on res structure fields


	if nargin == 1
		if isstruct( RES )
			r = RES ;
		else
			r = RES{ 1 } ;
		end
		std = r.std ;
		R	= r.R ;
		N	= r.n ; 
	end
	if nargin == 2
		if ischar( std )
			tit = std ;
		else
			%assuming 2nd parameter is a figure handle object
			h = std ;
		end
	else
		tit = [] ;
	end

	if ~exist('h', 'var')
		h = figure( ) ;
	end

	if iscell( RES )
	
		semilogy( RES{ 1 }.EbN0, RES{ 1 }.BER ) ;
		hold on ;
		for i = 2 : size( RES, 2 )
			semilogy( RES{ i }.EbN0, RES{ i }.BER ) ;
		end
		
	else
		semilogy( RES.EbN0, RES.BER ) ;
	end

	xlabel('Eb/N0') ;
	ylabel('BER') ;
	grid on ;

	if exist( 'tit', 'var' )
		title( tit ) ;
	end

end
function s = mergeStructs( x, y )
% mergeStructs - merge two structures
%
% s = mergeStructs( x, y )
%		structure s contains all fields from structures x and y
%		field names must not overlap

cx	= struct2cell( x ) ;
cy	= struct2cell( y ) ;

fx	= fieldnames( x ) ;
fy	= fieldnames( y ) ;

s	= cell2struct( [ cx ; cy ], [ fx ; fy ] ) ;

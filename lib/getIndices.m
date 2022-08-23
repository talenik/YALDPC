function [ CH_S, CH_I ] = getIndices( H, g )
% getIndices - calculate index structures for graph LDPC decoders
%
%	[ CH_S, CH_I ] = getIndices( H, g )
%		H - LDPC parity check matrix
%		g - initial G_MAX ( max check node degree) estimate 
% 
%		CH_S - neighborhood sizes (degrees) for all check node
%		CH_I - neighborhood indices for all check nodes
%			indices start from zero as in C

[ m, n ] = size( H ) ;

CH_S = zeros( m, 1 ) ;
CH_I = zeros( m, g ) ;

	for r = 1 : m
		Hr	= H( r, : ) ;
		ind = find( Hr ) - 1 ;	% C indexes start at zero
		CH_S( r ) = size( ind, 2 ) ;
		CH_I( r, : ) = fillzero( ind, g ) ;
	end
end

function U = fillzero( V, n )
	s = size( V, 2 ) ;
	U = [ V zeros( 1, n - s ) ] ;
end
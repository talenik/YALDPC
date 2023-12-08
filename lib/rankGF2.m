function r = rankGF2( A )
% rankGF2   Rank of a GF2 matrix
% 
% 	R = rankGF2( A ) calculates the rank of a binary matrix A.
%
% 	Note1:	This function is just a wrapper for rrefGF2(). 
%			See help rrefGF2 for details.

[ ~, r ] = rrefGF2( A ) ;

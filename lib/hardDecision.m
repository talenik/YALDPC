function bits = hardDecision( LLR, type )
%hardDecision - Performs hard decision on supplied LLR values.
%
%	bits = hardDecision( LLR [, type ] )
%		bits are GF(2) values of bits, stored as doubles
%		if type string is supplied, also casts to desired data type
%
% Assumes BPSK modulation 0 > + 1, 1 > -1 as defined in min-sum paper.
% See README for more.

if nargin < 2
	type = 'double' ;
end

b =  LLR < 0  ; %logical
bits = cast( b, type ) ;

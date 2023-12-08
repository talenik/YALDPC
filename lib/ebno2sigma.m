function [ sig, varc ] =  ebno2sigma( ebn0, R )
%convert Eb/N0 id dB to noise variance
% ebno2sigma( ebn0 ) assuming:
%	binary modulation
%	real AWGN channel
%	code rate R = 1
%	TODO: other assumptions
% ebno2sigma( ebn0, R )
%	also use code rate R
% TODO : implement further parameters for various options

if nargin < 2
	R = 1 ;
end

	snr		= 10 ^ ( ebn0 / 10 ) ;
	varc	= 1 / ( 2 * snr * R ) ;	
	sig		= sqrt( varc ) ;
end
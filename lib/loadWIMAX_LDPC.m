function code = loadWIMAX_LDPC( R, n, id )
%Don't run this file directly. Call loadQCLDPC( ) instead.

% code = loadWIMAX_LDPC( R, n, [id] )
%	loads code structure with all code parameters
%	code variants Rate 2/3 B and 3/4 B must be specified
%	explicitly by mapping id > codes:
%	[0 > 5/6, 1 > 3/4A, 2 > 3/4B, 3 > 2/3A, 4 > 2/3B, 5 > 1/2] 

	if nargin == 2
		id  = getCodeId( R ) ;
	end

	k			= round( n * R ) ;
	code		= WiMAXCodeParams( n, id ) ;
	code.z		= code.TierSize ;
	code.HbmZ0	= code.Hbm ;
	code.Hbm	= rescaleHbm( code.Hbm, code.z, id ) ;
	if code.Rc ~= R
		error('Code parameters FAIL.') ;
	end

	code.Hs		= LDPCUncompressH( code.Hbm, code.z ) ;
	code.H		= full( code.Hs ) ;
	code.std	= 'wimax' ;
end

function id = getCodeId( R )
	Rates	= [ 1/2 2/3 3/4 5/6 ] ;
	Ids		= [ 5 3 1 0 ] ;  
	ri		= getIndex( Rates, R, 'R' ) ;
	id		= Ids( ri ) ;
end

function [ codeParam ]  = WiMAXCodeParams( N, CodeId )
%Prepare and validate various parameters needed for WiMax LDPC decoding.
%	arguments: 
%		N		- codeword size 
%		CodeId	- specify, which one of the WiMax LDPC codes to use:
%				0 for the weakest code Rate 5/6
%				5 for the most powerfull code Rate 1/2
%				6 for no ECC - just copy input LLR to output
%
%	returns:
%		codeParam - structure of various code parameters

	%WiMax codewords sizes
	legalCodewordSizes = 576 + 96 * [0:1:18] ; 
	if isempty(find(legalCodewordSizes == N, 1))
		error('Not a legal codeword size for WiMax.') ;
	end 
	
	RcS			= [5/6 3/4 3/4 2/3 2/3 1/2 1] ;
	Rc			= RcS( CodeId + 1 ) ;
	
	Mbs			= [ 4, 6, 6, 8, 8, 12 0] ;
	Mb			= Mbs( CodeId + 1 ) ;
	
	Nb			= 24 ;
	TierSize	= N / Nb ;
	
	M			= Mb * TierSize ;
	K			= N - M ;
	
	%WiMax Z ( Tiersize ) sizes
	legalZSizes = 24 + 4 * [0:1:18] ; 
	if isempty(find(legalZSizes == TierSize, 1))
		error('Not a legal TierSize for WiMax.') ;
	end 
	
	%pack everything in a nice structure
	codeParam.N			= N ;
	codeParam.K			= K ;
	codeParam.M			= M ;
	codeParam.TierSize	= TierSize ;
	codeParam.Nb		= Nb ;
	codeParam.Mb		= Mb ;
	codeParam.Rc		= Rc ;
	codeParam.CodeId	= CodeId ;
	codeParam.Hbm		= IEEE80216_LDPC( CodeId ) ;
end

function Hs  = rescaleHbm( Hbm, zf, codeId )

	z0	= 96 ;
	
	%these position need to be rescaled 
	ind	= find( Hbm > 0 ) ;
	
	%rescale the model matrix for a given codeword size
	if codeId == 3	
		% the expansion procedure is slightly different for the Rate 2/3A code
		Hbm( ind )	= mod( Hbm( ind ), zf ) ;
	else
		Hbm( ind )	= floor( Hbm( ind ) .* ( zf / z0 ) ) ;
	end 
	
	Hs = Hbm ;
end


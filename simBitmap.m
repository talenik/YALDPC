% This file runs the waterfall simulations for selected WiMAX LDPC
% codes all with the 'bitmap' type encoder/decoder.
%
% Run and add/remove sections as needed. 
%
% Set sim.minErr to determine how many errors need to be collected for each Eb/N0 point
% Extend sim.EbN0 vectors to get to low BER area.
% High SNR values vill take a long time.

clear ;
clc ;
format compact ;

path( 'lib', path ) ;
path( 'MEX', path ) ;

type		= 'uint8' ;			%WORD type used in encoder and decoder
enc			= QCLDPCEncode() ; 		
enc.method	= 'bitmap' ;	
enc.type	= type ;		
enc.build	= 'release' ;
enc.dbglev	= 1 ;
enc			= QCLDPCEncode( enc ) ;	%recalculate dependent paramaters

dec			= QCLDPCDecode() ;
dec.nIter	= 10 ;
dec.nthread = 32 ;
dec.build	= enc.build ;
dec.dbglev	= enc.dbglev ;

dec.qbits	= 10 ;		% nr of quantization bits for LLR
dec.fp_max	= 2 ^ dec.qbits ;	
dec.hdbitmap = true ;	% decoder returns bitmap output
dec			= QCLDPCDecode( dec ) ; %recalculate dependent paramaters

sim			= WTFB() ;
sim.blkSize	= 10 * dec.nthread ;
sim.minErr	= 100 ;	%set 10000 for reliable results
sim.prof	= false ;	%profile code and show HTML report
sim.report	= false ;	%send email after each iteration is finished
sim.plot	= false ;	%plot waterfall figure in the end
sim.save	= false ;	%save results to local .mat file immediately in WTF

if strcmp( enc.build, 'debug' )
	sim.single	= true ;	%just testrun one loop of the simulation
end

whos

%% compatible bitmap encoder - smallest codeword size for wb
% N,K,Z must be divisible by WB

RES	= {} ;
t	= tic ;		

std			= 'wimax' ;
N			= 576 
R			= 5 / 6   
cod			= loadQCLDPC( std, R, N ) ;
K			= cod.K	
Z			= cod.z	
WB			= enc.wb

if mod( N, WB ) ~= 0 || mod( K, WB ) ~= 0 || mod( Z, WB ) ~= 0
	error('Unsupported parameter combination') ;
end

sim.impl	= 'MEX' ;
dec.method  = 'float' ;
sim.EbN0	= [ 3.2 : 0.2 : 4.0 ] ;
RES{ end + 1 } 	= WTFB( cod, enc, dec, sim ) ;

dec.method  = 'fixed' ;
sim.EbN0	= [ sim.EbN0 sim.EbN0( end ) + 0.1 ] ;
RES{ end + 1 } 	= WTFB( cod, enc, dec, sim ) ;

disp( datestr( datenum( 0, 0, 0, 0, 0, toc( t )), "DD:HH:MM:SS" ) ) ;

if ~sim.single 
	plotWTF( RES ) ;
end

%% compatible bitmap encoder
% N,K,Z must be divisible by WB

RES	= {} ;
t	= tic ;		

type		= 'uint32' ;	
std			= 'wimax' ;
N			= 2304 ;
R			= 5 / 6   ;
cod			= loadQCLDPC( std, R, N ) ;
enc.type	= type ;	

sim.impl	= 'MEX' ;
dec.method  = 'fixed' ;
sim.EbN0	= [ 3.2 : 0.2 : 3.8 ] ;
RES{ end + 1 } 	= WTFB( cod, enc, dec, sim ) ;

disp( datestr( datenum( 0, 0, 0, 0, 0, toc( t )), "DD:HH:MM:SS" ) ) ;

if ~sim.single 
	plotWTF( RES ) ;
end



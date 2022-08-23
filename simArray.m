% This file runs the waterfall simulations for various WiFi 6 and WiMAX LDPC
% codes all with the 'array' type encoder. 
%
% Run and add/remove sections as needed. 
%
% Set sim.minErr to determine how many errors need to be collected for each Eb/N0 point
% Extend sim.EbN0 vectors to get to low BER area.
% High SNR values vill take a long time.

clear ;
clc ;
format compact ;

path( '../', path )	;	%path for secret email config
path( 'lib', path ) ;
path( 'MEX', path ) ;

enc = QCLDPCEncode() ; 		

dec = QCLDPCDecode() ;
dec.nIter	= 10 ;
dec.nthread = 32 ;
dec.build	= 'release' ;
dec.dbglev	= 1 ;
dec.qbits	= 9 ;		% nr of quantization bits for LLR
dec.fp_max	= 512 ;	

sim = WTF() ;
sim.blkSize	= 10 * dec.nthread ;

%minimum nr. of errors for each Eb/N0 point, set 10000 for reliable results:
sim.minErr	= 100 ;		

sim.prof	= false ;	%profile code and show HTML report
sim.single	= false ;	%just testrun one loop of the simulation
sim.report	= false ;	%send email after each iteration is finished
sim.plot	= false ;	%plot waterfall figure in the end
sim.save	= false ;	%save results to local .mat file immediately in WTF

sim

%first maybe check if all OK on one run
if false
	std = 'wimax' ;
	N	= 2304 ;
	R	= 5 / 6   ;
	sim.save	= false ;
	sim.plot	= false ;
	sim.report	= true ;
	sim.prof	= false ;
	cod	= loadQCLDPC( std, R, N ) ;
	sim.EbN0 = [ 2 : 1 : 3 ] ;

	if sim.report
		if exist('secretEmailCfg.m', 'file')
			sim.emailCfg = secretEmailCfg() ;
		else
			disp('No email config provided.') ;
			sim.report = false ;
		end
	end

	res = WTF( cod, enc, dec, sim ) 
	return ;
end


T = tic ;

%% Simulation 1: the weakest WIMAX code - floating -vs- fixed point decoder

RES	= {} ;
t	= tic ;										

std			= 'wimax' ;
N			= 576 ;
R			= 5 / 6   ;
cod			= loadQCLDPC( std, R, N ) ;

disp( [ 'Running sim for: ' std, ' with: ' n2s( R ) n2s( N ) ] ) ;

sim.plot	= false ;
sim.impl	= 'COM' ;
sim.EbN0	= [ 3.2 : 0.2 : 3.8 ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;


sim.impl	= 'MEX' ;
dec.method  = 'float' ;

sim.EbN0	= [ sim.EbN0 sim.EbN0( end ) + 0.2 ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

dec.method		= 'fixed' ;

sim.EbN0	= [ sim.EbN0 sim.EbN0( end ) + 0.1 ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

disp( datestr( datenum( 0, 0, 0, 0, 0, toc( t )), "DD:HH:MM:SS" ) ) ;

plotWTF( RES, 'WIMAX', R, N ) ;

RES_WIMAX_56 = RES ;

%% Simulation 2: the strongest WIMAX code - floating -vs- fixed point decoder

RES  = {} ;
t	= tic ;	

std			= 'wimax' ;
N			= 2304 ;
R			= 1 / 2   ;
cod			= loadQCLDPC( std, R, N ) ;
disp( [ 'Running sim for: ' std, ' with: ' n2s( R ) n2s( N ) ] ) ;

sim.impl	= 'COM' ;
sim.EbN0	= [ 1.8 : 0.2 : 2.2 ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;


sim.impl	= 'MEX' ;
dec.method  = 'float' ;

sim.EbN0	= [ sim.EbN0 sim.EbN0( end ) + 0.2 ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

dec.method	= 'fixed' ;
sim.EbN0	= [ sim.EbN0 sim.EbN0( end ) + 0.1 ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

disp( datestr( datenum( 0, 0, 0, 0, 0, toc( t )), "DD:HH:MM:SS" ) ) ;

plotWTF( RES, 'WIMAX', R, N ) ;

RES_WIMAX_12 = RES ;

%% Simulation 3: the weakest WIFI6 code - floating -vs- fixed -vs- toolbox decoder
% Requires Communications Toolbox

RES  = {} ;
t	= tic ;	

std			= 'wifi' ;
N			= 648;
R			= 5 / 6   ;
cod			= loadQCLDPC( std, R, N ) ;
disp( [ 'Running sim for: ' std, ' with: ' n2s( R ) n2s( N ) ] ) ;

sim.impl	= 'COM' ;
sim.EbN0	= [ 3.4 : 0.2 : 4.4 ]  ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;


sim.impl	= 'MEX' ;
dec.method  = 'float' ;

sim.EbN0	= [ sim.EbN0 sim.EbN0( end ) + 0.2 ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

dec.method	= 'fixed' ;
sim.EbN0	= [ sim.EbN0 sim.EbN0( end ) + 0.1 ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

disp( datestr( datenum( 0, 0, 0, 0, 0, toc( t )), "DD:HH:MM:SS" ) ) ;

plotWTF( RES, 'WIFI6', R, N ) ;

RES_WIFI_56 = RES ;

%% Simulation 4: the strongest WIFI6 code - floating -vs- fixed -vs- toolbox decoder
% Requires Communications Toolbox

RES		= {} ;
t		= tic ;	

std = 'wifi' ;
N	= 1944 ;
R	= 1 / 2 ;
cod	= loadQCLDPC( std, R, N ) ;
disp( [ 'Running sim for: ' std, ' with: ' n2s( R ) n2s( N ) ] ) ;

sim.minErr	= 100 ; %set 10000 for reliable results
sim.impl	= 'COM' ;
sim.EbN0	= [ 1.8 : 0.2 : 2.0 ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;


sim.impl	= 'MEX' ;
dec.method  = 'float' ;
sim.EbN0	= [ sim.EbN0 sim.EbN0( end ) + 0.2 ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

dec.method	= 'fixed' ;
sim.EbN0	= [ sim.EbN0 sim.EbN0( end ) + 0.1 ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

disp( datestr( datenum( 0, 0, 0, 0, 0, toc( t )), "DD:HH:MM:SS" ) ) ;

plotWTF( RES, 'WIFI6', R, N ) ;

RES_WIFI_56 = RES ;

%% Simulation 5: compare floating & fixed point decoder for different coderates

RES	= {} ;
t	= tic ;										

sim.save	= false ;
sim.minErr	= 100 ; %set 10000 for reliable results
std			= 'wimax' ;

N			= 576 ;
R			= 5 / 6   ;
cod			= loadQCLDPC( std, R, N ) ;
disp( [ 'Running FIXED point sim for: ' std, ' with: ' n2s( R ) n2s( N ) ] ) ;
sim.EbN0	= [ 3.2 : 0.2 : 4.2 ] ;

sim.impl	= 'MEX' ;
dec.method  = 'float' ;

sim.EbN0	= [ sim.EbN0 sim.EbN0( end ) ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

dec.method	= 'fixed' ;
sim.EbN0	= [ sim.EbN0 sim.EbN0( end ) + 0.1 ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

N			= 2304 ;
R			= 5 / 6   ;
cod			= loadQCLDPC( std, R, N ) ;
sim.EbN0	= [ 3.2 : 0.2 : 4.0 ] ;

sim.EbN0	= [ sim.EbN0 sim.EbN0( end ) ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

dec.method	= 'fixed' ;
sim.EbN0	= [ sim.EbN0 sim.EbN0( end ) + 0.1 ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

N			= 576 ;
R			= 1 / 2   ;
cod			= loadQCLDPC( std, R, N ) ;
sim.EbN0	= [ 1.8 : 0.2 : 2.8 ] ;

sim.impl	= 'MEX' ;
dec.method  = 'float' ;

sim.EbN0	= [ sim.EbN0 sim.EbN0( end ) ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

dec.method	= 'fixed' ;
sim.EbN0	= [ sim.EbN0 sim.EbN0( end ) + 0.1 ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

disp( datestr( datenum( 0, 0, 0, 0, 0, toc( t )), "DD:HH:MM:SS" ) ) ;

plotWTF( RES, 'WIMAX', R, N ) ;

RES_WIMAX_56_2F = RES ;

%% Simulation 6: compare WIMAX different rate codes with same N

RES		= {} ;
t		= tic ;	

sim.minErr	= 100 ; %set 10000 for reliable results
sim.impl	= 'MEX' ;
sim.report	= false ;
dec.method  = 'float' ;
std			= 'wimax' ;
N			= 1344 ;
step		= 0.2 ; 
disp( [ 'Running sim for ALL: ' std, ' with: ' n2s( N ) ] ) ;

R			= 1 / 2 ;
cod			= loadQCLDPC( std, R, N ) ;
sim.EbN0	= [ 2.0 : step : 2.8 ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

R			= 2 / 3 ;
cod			= loadQCLDPC( std, R, N ) ;
ex			= sim.EbN0( end ) ;
sim.EbN0	= [ sim.EbN0 ex + step * [ 1 2 ] ] ; 
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

R			= 3 / 4 ;
cod			= loadQCLDPC( std, R, N ) ;
ex			= sim.EbN0( end ) ;
sim.EbN0	= [ sim.EbN0 ex + step * [ 1 2 3 ] ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

R			= 5 / 6 ;
cod			= loadQCLDPC( std, R, N ) ;
ex			= sim.EbN0( end ) ;
sim.EbN0	= [ sim.EbN0 ex + step * [ 1 2 3 ] ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;


disp( datestr( datenum( 0, 0, 0, 0, 0, toc( t )), "DD:HH:MM:SS" ) ) ;

plotWTF( RES, 'WIMAX' ) ;

RES_WIMAX_N_1344 = RES ;

%% Simulation 7: compare WIFI different rate codes with same N
%Optionally also send results by email when simulation is done.

RES		= {} ;
t		= tic ;	

sim.minErr	= 100 ;	%set 10000 for reliable results
sim.impl	= 'MEX' ;
sim.report	= true ;
sim.save	= true ;
dec.method  = 'float' ;
std			= 'wifi' ;
N			= 1944 ;
step		= 0.2 ; 
disp( [ 'Running sim for ALL: ' std, ' with: ' n2s( N ) ] ) ;

	if sim.report
		if exist('secretEmailCfg.m', 'file')
			sim.emailCfg = secretEmailCfg() ;
		else
			disp('No email config provided.') ;
			sim.report = false ;
		end
	end

R			= 1 / 2 ;
cod			= loadQCLDPC( std, R, N ) ;
sim.EbN0	= [ 2.0 : step : 2.2 ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

R			= 2 / 3 ;
cod			= loadQCLDPC( std, R, N ) ;
ex			= sim.EbN0( end ) ;
sim.EbN0	= [ sim.EbN0 ex + step * [ 1 2 ] ] ; 
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

R			= 3 / 4 ;
cod			= loadQCLDPC( std, R, N ) ;
ex			= sim.EbN0( end ) ;
sim.EbN0	= [ sim.EbN0 ex + step * [ 1 2 3 ] ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

R			= 5 / 6 ;
cod			= loadQCLDPC( std, R, N ) ;
ex			= sim.EbN0( end ) ;
sim.EbN0	= [ sim.EbN0 ex + step * [ 1 2 3 ] ] ;
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;


disp( datestr( datenum( 0, 0, 0, 0, 0, toc( t )), "DD:HH:MM:SS" ) ) ;

plotWTF( RES, 'WIFI' ) ;

RES_WIFI_N_1944 = RES ;

%% Simulation 8: compare min-sum algorithm with different parameters

RES		= {} ;
t		= tic ;	

sim.minErr	= 100 ;	%set 10000 for reliable results
sim.impl	= 'MEX' ;
sim.report	= false ;
sim.save	= false ;
dec.method  = 'float' ;
std			= 'wifi' ;
N			= 1944 ;
step		= 0.2 ; 
disp( [ 'Running sim for ALL: ' std, ' with: ' n2s( N ) ] ) ;

R			= 3 / 4 ;
cod			= loadQCLDPC( std, R, N ) ;
sim.EbN0	= [ 2.0 : step : 3.4 ] ;

dec.lambda	= 1.0
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

dec.lambda	= 0.75		%normalized min-sum
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

dec.lambda	= 0.5
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

dec.lambda	= 1.0		%offset min-sum
dec.beta	= 1.0
RES{ end + 1 } 	= WTF( cod, enc, dec, sim ) ;

disp( datestr( datenum( 0, 0, 0, 0, 0, toc( t )), "DD:HH:MM:SS" ) ) ;

plotWTF( RES, 'MIN-SUM variants' ) ;

RES_MIN_SUM_VAR = RES ;

%% total simulation time

disp( datestr( datenum( 0, 0, 0, 0, 0, toc( T )), "DD:HH:MM:SS" ) ) ;




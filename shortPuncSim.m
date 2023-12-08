clear ;
clc ;
format compact ;

path( '../', path )	;	%path for secret email config
path( 'lib', path ) ;
path( 'MEX', path ) ;
path( 'MAT', path ) ;

%set code parameters -----------------------------------------------------
std		= 'wifi6' ;
R		= 5 / 6
n		= 1944
code	= loadQCLDPC( std, R, n ) 
k		= code.K
m		= code.M

%set encoder parameters --------------------------------------------------
enc = QCLDPCEncode() 

%set decoder parameters --------------------------------------------------
dec = QCLDPCDecode() 
dec.nthread = 20

%set simulation parameters ----------------------------------------------
sim = WTFShortPunc() ;

sim.blkSize	= 100 * dec.nthread ;
sim.prof	= false ;	%profile code and show HTML report
sim.single	= false ;	%just testrun one loop of the simulation
sim.report	= false ;	%send email after each iteration is finished
sim.plot	= false ;	%plot waterfall figure in the end
sim.save	= false ;	%save results to local .mat file immediately in WTF

sim

%% Simulation 1:  shortening Wi-Fi 6 LDPC code
std		= 'wifi6' ;
R		= 5 / 6
n		= 1944
code	= loadQCLDPC( std, R, n ) 
k		= code.K
m		= code.M

sim.minErr	= 100 ;		%minimum nr. of errors for each Eb/N0 point	
disp( [ 'Running sim for ALL: ' std, ' with: ' n2s( R ) ' and: ' n2s( n ) ] ) ;
t	= tic ;	
RES	= {} ;

%no shortening and no puncturing:
code.s	= 0 ;
code.p	= 0 ;
sim.EbN0	= [ 2 : 1 : 4 ] ;		%for rate R = 5/6
%sim.EbN0	= [ 1.6 : 0.2 : 2 ] ;	%for rate R = 1/2
RES{ end + 1 } = WTFShortPunc( code, enc, dec, sim ) ;


for i = [ 1 : 3 ] 
	shortIdx = [ code.Kb - i + 1 : code.Kb ] 
	RES{ end + 1 } = WTFShortPunc( code, enc, dec, sim, shortIdx ) ;
end

%disp( datestr( datenum( 0, 0, 0, 0, 0, toc( t )), "DD:HH:MM:SS" ) ) ;
plotWTF( RES, [ std ': ' n2s( R ) n2s( n ) ' with shortening' ]) ;


%% Simulation 2: - puncturing Wi-Fi 6 LDPC code parity bits

std		= 'wifi6' ;
R		= 1 / 2
n		= 1944
code	= loadQCLDPC( std, R, n ) 
k		= code.K
m		= code.M
sim.minErr	= 100 ;		%minimum nr. of errors for each Eb/N0 point	
disp( [ 'Running sim for ALL: ' std, ' with: ' n2s( R ) ' and: ' n2s( n ) ] ) ;
t	= tic ;	
RES	= {} ;

%no shortening and no puncturing:
code.s	= 0 ;
code.p	= 0 ;
sim.EbN0	= [ 1.2 : 0.2 : 2 ] ;	%rate for R = 1/2
RES{ end + 1 } = WTFShortPunc( code, enc, dec, sim ) ;

%code puncturing - of data bits
puncIdx = [ 1 ] 
RES{ end + 1 } = WTFShortPunc( code, enc, dec, sim, false, puncIdx ) ;

%code puncturing - of parity bits
for i = [ 1 : 3 ] 
	puncIdx = [ code.Nb - i + 1 : code.Nb ] 
	sim.EbN0	= [ [ sim.EbN0 ]  sim.EbN0( end ) + 0.3 ] ;
	RES{ end + 1 } = WTFShortPunc( code, enc, dec, sim, false, puncIdx ) ;
end

for i = [ 4 : 6 ] 
	puncIdx = [ code.Nb - i + 1 : code.Nb ] 
	sim.EbN0	= [ [ sim.EbN0 ]  sim.EbN0( end ) + 0.4 ] ;
	RES{ end + 1 } = WTFShortPunc( code, enc, dec, sim, false, puncIdx ) ;
end

disp( datestr( datenum( 0, 0, 0, 0, 0, toc( t )), "DD:HH:MM:SS" ) ) ;
plotWTF( RES, [ std ': ' n2s( R ) n2s( n ) ' puncturing parity' ]) ;

%% 3. Simulation 2: - puncturing Wi-Fi 6 LDPC code data bits

std		= 'wifi6' ;
R		= 1 / 2
n		= 1944
code	= loadQCLDPC( std, R, n ) 
k		= code.K
m		= code.M
sim.minErr	= 100 ;		%minimum nr. of errors for each Eb/N0 point	
disp( [ 'Running sim for ALL: ' std, ' with: ' n2s( R ) ' and: ' n2s( n ) ] ) ;
t	= tic ;	
RES	= {} ;


%no puncturing
%sim.EbN0	= [ 2 : 1 : 4 ] ;		%for rate R = 5/6
sim.EbN0	= [ 1.6 : 0.2 : 2 ] ;	%for rate R = 1/2
RES{ end + 1 } = WTFShortPunc(  code, enc, dec, sim ) ;


puncIdx = [ 1 ] 
sim.EbN0	= [  2 : 1 : 3  ] ;	
RES{ end + 1 } = WTFShortPunc( code, enc, dec, sim, false, puncIdx ) ;

puncIdx = [ 2 ] 
RES{ end + 1 } = WTFShortPunc( code, enc, dec, sim, false, puncIdx ) ;

puncIdx = [ 3 ] 
RES{ end + 1 } = WTFShortPunc(  code, enc, dec, sim, false, puncIdx ) ;

disp( datestr( datenum( 0, 0, 0, 0, 0, toc( t )), "DD:HH:MM:SS" ) ) ;
plotWTF( RES, [ std ': ' n2s( R ) n2s( n ) ' puncturing data' ]) ;


















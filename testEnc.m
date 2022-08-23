%This file runs a couple of test for the QCLDPCEncode() function.
%You need to have MEX configured properly first.
%It should not produce any errors, and all tests should run OK.
%Can be used as example how to use the encoder in MATLAB.
%
% Tested on MATLAB R2021b on Ubuntu 20.04 LTS

clc ;
clear ;
format compact ;

path( 'lib', path ) ;
path( 'MEX', path ) ;

% settings start -------------------------------------

std			= 'wimax'	% 'wimax' or 'wifi'
R			= 5 / 6 ;
n			= 2304 ;	% wimax
cod			= loadQCLDPC( std, R, n ) % get code params
k			= cod.K
chan		= 10			% parallel channels/ words in one block

enc = QCLDPCEncode()  		% get default options
dec = QCLDPCDecode() ;		% get default options
saveLDPCheader( 'ldpc', cod, enc, dec, 'MEX' ) ;
buildMEXfile( enc ) ;

%% Test 1: call release build with no debug output
Data = randui( k, 1 ) ;
CW	 = QCLDPCEncode( Data, cod, enc ) ;

if areOrthogonal( CW, cod.H ) disp('Encoder test 1 OK') ; else disp('Encoder test 1 FAIL') ; end

%% Test 2: call release build with no debug output, multiple words in block
Data = randui( k, chan ) ;
CW	 = QCLDPCEncode( Data, cod, enc ) ;

if areOrthogonal( CW, cod.H ) disp('Encoder test 2 OK') ; else disp('Encoder test 2 FAIL') ; end

%% Test 3: call debug build with MEX debug output
Data = randui( k, chan ) ;
enc.build	= 'debug' ;
enc.dbglev	= 1 ;
buildMEXfile( enc ) ;

CW	 = QCLDPCEncode( Data, cod, enc ) ;

if areOrthogonal( CW, cod.H ) disp('Encoder test 3 OK') ; else disp('Encoder test 3 FAIL') ; end

%% Test 4: try 'array' encoder with different data type
t = "uint32" ;
enc = QCLDPCEncode( )
enc.type = t
enc = QCLDPCEncode( enc )  
saveLDPCheader( 'ldpc', cod, enc, dec, 'MEX' ) ;
buildMEXfile( enc ) ;

Data = randui( k, 10 ) ;
Data = cast( Data, t ) ;
CW	 = QCLDPCEncode( Data, cod, enc ) ;

if areOrthogonal( CW, cod.H ) disp('Encoder test 4 OK') ; else disp('Encoder test 4 FAIL') ; end
whos Data CW

%% Test 5: try 'array' encoder with all wimax codes
std		= 'wimax' ;
nOK		= 0 ;
nFail	= 0 ;
for R = [ 1/2 2/3 3/4 5/6]
	for n = 576 + 96 * [ 0 : 1 : 18 ]
		cod	= loadQCLDPC( std, R, n ) ;
		enc = QCLDPCEncode( ) ;
		dec = QCLDPCDecode( ) ;	
		saveLDPCheader( 'ldpc', cod, enc, dec, 'MEX' ) ;
		buildMEXfile( enc ) ;
		Data = randui( cod.K, 10 ) ;
		CW	 = QCLDPCEncode( Data, cod, enc ) ;

		if areOrthogonal( CW, cod.H ) 
			fprintf( "Encoder test for K:%4d N:%4d Rc:%f OK\n", cod.K, cod.N, cod.Rc ) ;
			nOK =  nOK + 1 ; 
		else 
			fprintf( "Encoder test for K:%4d N:%4d Rc:%f FAIL\n", cod.K, cod.N, cod.Rc ) ;
			nFail = nFail + 1 ;
		end
	end
end
fprintf("Test OK: %d, test FAILED: %d\n", nOK, nFail ) ; 


%% Test 6: try 'array' encoder with WIFI codes
std			= 'wifi'	% 'wimax' or 'wifi'
R			= 1 / 2 ;
n			= 1944 ;	% wimax
cod			= loadQCLDPC( std, R, n ) % get code params
k			= cod.K

enc = QCLDPCEncode( )
dec = QCLDPCDecode( ) ;	
saveLDPCheader( 'ldpc', cod, enc, dec, 'MEX' ) ;
buildMEXfile( enc ) ;

Data = randui( k, 10 ) ;
CW	 = QCLDPCEncode( Data, cod, enc ) ;

if areOrthogonal( CW, cod.H ) disp('Encoder test 6 OK') ; else disp('Encoder test 6 FAIL') ; end

%% Test 7: try 'array' encoder with all wifi codes
std		= 'wifi' ;
nOK		= 0 ;
nFail	= 0 ;
for R = [ 1/2 2/3 3/4 5/6]
	for n = [ 648 1296 1944 ] 
		cod	= loadQCLDPC( std, R, n ) ;
		enc = QCLDPCEncode( ) ;
		dec = QCLDPCDecode( ) ;	
		saveLDPCheader( 'ldpc', cod, enc, dec, 'MEX' ) ;
		buildMEXfile( enc ) ;
		Data = randui( cod.K, 10 ) ;
		CW	 = QCLDPCEncode( Data, cod, enc ) ;

		if areOrthogonal( CW, cod.H ) 
			fprintf( "Encoder test for K:%4d N:%4d Rc:%f OK\n", cod.K, cod.N, cod.Rc ) ;
			nOK =  nOK + 1 ; 
		else 
			fprintf( "Encoder test for K:%4d N:%4d Rc:%f FAIL\n", cod.K, cod.N, cod.Rc ) ;
			nFail = nFail + 1 ;
		end
	end
end
fprintf("Test OK: %d, test FAILED: %d\n", nOK, nFail ) ; 

%% Test 8: try 'bitmap' encoder with selected parameters
std		= 'wimax'	% 'wifi' is not compatible
R		= 1 / 2 ;
n		= 2304;	
cod		= loadQCLDPC( std, R, n ) % get code params
k		= cod.K

chan	= 1		
enc		= QCLDPCEncode( ) ;

t = 'uint16' 
enc.method	= 'bitmap' ;	
enc.type	= t ;		% only tunable with 'bitmap' method
enc.build	= 'release' ;
enc			= QCLDPCEncode( enc ) 

saveLDPCheader( 'ldpc', cod, enc, dec, 'MEX' ) ;
buildMEXfile( enc ) ;

kw		= k / enc.wb
DataB	= randui( kw, chan, t ) ;
CWB		= QCLDPCEncode( DataB, cod, enc ) ;

b		= Bits( t ) ;
Data	= b.bit2logical( DataB ) ;
CW		= b.bit2logical( CWB ) ;
whos Data CW DataB CWB
if areOrthogonal( CW, cod.H ) disp('Encoder test 8 OK') ; else disp('Encoder test 8 FAIL') ; end

%% Test 9: test 'bitmap' encoder with all possible combinations
std		= 'wimax' ;
t		= 'uint32' 
nOK		= 0 ;
nFail	= 0 ;

for R = [ 1/2 2/3 3/4 5/6 ]
	for n = 576 + 96 * [ 0 : 1 : 18 ]
		cod			= loadQCLDPC( std, R, n ) ;
		enc			= QCLDPCEncode( ) ;
		enc.method	= 'bitmap' ;	
		enc.type	= t ;	
		enc			= QCLDPCEncode( enc ) ;
		wb			= enc.wb ; 
		if mod( cod.N, wb ) ~= 0 || mod( cod.K, wb ) ~= 0 || mod( cod.M, wb ) ~= 0 || mod( cod.z, wb ) ~= 0
			continue ;
		end

		dec = QCLDPCDecode( ) ;	
		saveLDPCheader( 'ldpc', cod, enc, dec, 'MEX' ) ;
		buildMEXfile( enc ) ;
		fprintf("Testing params: N: %d, K: %d, M: %d, Z: %d, WB: %d\n", cod.N, cod.K, cod.M, cod.z, wb ) ;

		kw		= cod.K / enc.wb
		DataB	= randui( kw, chan, t ) ;
		CWB		= QCLDPCEncode( DataB, cod, enc ) ;

		b		= Bits( t ) ;
		Data	= b.bit2logical( DataB ) ;
		CW		= b.bit2logical( CWB ) ;

		if areOrthogonal( CW, cod.H ) 
			fprintf( "Encoder test for K:%4d N:%4d Rc:%f OK\n", cod.K, cod.N, cod.Rc ) ;
			nOK =  nOK + 1 ; 
		else 
			fprintf( "Encoder test for K:%4d N:%4d Rc:%f FAIL\n", cod.K, cod.N, cod.Rc ) ;
			nFail = nFail + 1 ;
		end
	end
end
fprintf("Test OK: %d, test FAILED: %d\n", nOK, nFail ) ; 






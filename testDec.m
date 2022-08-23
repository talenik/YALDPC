%This file runs a couple of test for the QCLDPCDecode() function.
%You need to have MEX configured properly first.
%Some test compare our code with toolbox ldpcDecode() so you need to 
%have Communications Toolbox installed.
%It should not produce any errors, and all tests should run OK.
%Can be used as example how to use the decoder in MATLAB.
%
% Tested on MATLAB R2021b on Ubuntu 20.04 LTS

clc ;
clear ;
format compact ;

path( 'lib', path ) ;
path( 'MEX', path ) ;

%% Test 1 : build Single Thread layered floating point decoder

std			= 'wimax'	
R			= 1 / 2 
n			= 2304 	
cod			= loadQCLDPC( std, R, n ) 

enc			= QCLDPCEncode() ; 
dec			= QCLDPCDecode() ; % get default options
dec.nIter	= 8 ;
dec.dbglev	= 1 ;
dec.build	= 'debug' ;
dec.method  = 'float' ;
%dec.sources = [ "decoderL.cpp" "debug.cpp" "ldpc.cpp" ] ;
dec         = QCLDPCDecode( dec ) % refresh parameters

saveLDPCheader( 'ldpc', cod, enc, dec, 'MEX' ) ;

buildMEXfile( dec )

%% Test 2 : compare Single Thread floating point decoder with MATLAB COM decoder
format compact ;

%MATLAB communications system toolbox encoder
COMdec	= ldpcDecoderConfig( logical( cod.Hs ) ) ;
COMenc	= ldpcEncoderConfig( COMdec ) ;
COMdec.Algorithm = 'norm-min-sum' ;

BlockSize = 10

Data	= randui( cod.K, BlockSize ) ;
CW		= ldpcEncode( logical( Data ), COMenc ) ;

varCh	= 0.5 ;
sigma	= sqrt( varCh ) ;

TxBlock = -2 * CW + 1 ; % another BPSK modulated 0 > +1, 1 > -1
Noise	= sigma * randn( size( TxBlock ) ) ;
RxBlock	= TxBlock + Noise ;
LLRch	= ( 2 / varCh ) .* RxBlock ;

[ ApLLR1, Iter1 ] = QCLDPCDecode( LLRch, dec ) ;
HD1	= hardDecision( ApLLR1 ) ;

[ ApLLR2, Iter2 ] = ldpcDecode( LLRch, COMdec, dec.nIter, ...
		OutputFormat="whole", DecisionType="soft", MinSumScalingFactor=dec.lambda ) ;
HD2	= hardDecision( ApLLR2 ) ;
whos ApLLR1 ApLLR2 Iter1 Iter2 HD1 HD2
% for varCH == 0.5 these should all be equal:
Iter1
Iter2 
A1 = ApLLR1( 1 : 10, 1 : 10 )
A2 = ApLLR2( 1 : 10, 1 : 10 )
H1 = HD1( 1 : 10, 1 : 10 )
H2 = HD2( 1 : 10, 1 : 10 )
[ Eq, Hd ] = equal( HD1, HD2 )	%bit values should be equal
[ Eq, ~, Ed ] = equal( ApLLR1, ApLLR2 ) % LLR values are not strictly equal, but close

%% Test 3 : try compiling Single Thread layered fixed point decoder with wifi code

std			= 'wifi'	
R			= 1 / 2 
n			= 1944	
cod			= loadQCLDPC( std, R, n ) 

dec			= QCLDPCDecode() ; % get default options
dec.nIter	= 8 ;
dec.dbglev	= 1 ;
dec.build	= 'debug' ;
dec.method	= 'fixed' ;

dec         = QCLDPCDecode( dec ) % refresh parameters

saveLDPCheader( 'ldpc', cod, enc, dec, 'MEX' ) ;

buildMEXfile( dec )

%% Test 4 : compare Single Thread fixed point decoder with MATLAB COM decoder - wifi code

%MATLAB communications system toolbox encoder
COMdec	= ldpcDecoderConfig( logical( cod.Hs ) ) ;
COMenc	= ldpcEncoderConfig( COMdec ) ;
COMdec.Algorithm = 'norm-min-sum' ;

BlockSize = 10

Data	= randui( cod.K, BlockSize ) ;
CW		= ldpcEncode( logical( Data ), COMenc ) ;

varCh	= 0.3 ;
sigma	= sqrt( varCh ) ;

TxBlock = -2 * CW + 1 ; % another BPSK modulated 0 > +1, 1 > -1
Noise	= sigma * randn( size( TxBlock ) ) ;
RxBlock	= TxBlock + Noise ;
LLRch	= ( 2 / varCh ) .* RxBlock ;

[ ApLLR1, Iter1 ] = QCLDPCDecode( LLRch, dec ) ;
HD1	= hardDecision( ApLLR1 ) ;

[ ApLLR2, Iter2 ] = ldpcDecode( LLRch, COMdec, dec.nIter, ...
		OutputFormat="whole", DecisionType="soft", MinSumScalingFactor=dec.lambda ) ;
HD2	= hardDecision( ApLLR2 ) ;
whos ApLLR1 ApLLR2 Iter1 Iter2 HD1 HD2
% for varCH == 0.5 these should all be equal:
Iter1
Iter2 
A1 = ApLLR1( 1 : 10, 1 : 10 )
A2 = ApLLR2( 1 : 10, 1 : 10 )
H1 = HD1( 1 : 10, 1 : 10 )
H2 = HD2( 1 : 10, 1 : 10 )
[ Eq, Hd ] = equal( HD1, HD2 ) %bit values should be similar
[ Eq, ~, Ed ] = equal( ApLLR1, ApLLR2 ) % LLR values completely different

%% Test 5 : try compiling Single Thread layered fixed point decoder

std			= 'wifi'	
R			= 2 / 3		%try different code rate
n			= 1944	
cod			= loadQCLDPC( std, R, n ) 

dec			= QCLDPCDecode() ; % get default options
dec.nIter	= 8 ;
dec.method  = 'fixed' ;

dec         = QCLDPCDecode( dec ) % refresh parameters

saveLDPCheader( 'ldpc', cod, enc, dec, 'MEX' ) ;

buildMEXfile( dec )


%% Test 6 : compare Single Thread layered fixed point decoder with MATLAB COM decoder
format compact ;

%MATLAB communications system toolbox encoder
COMdec	= ldpcDecoderConfig( logical( cod.Hs ) ) ;
COMenc	= ldpcEncoderConfig( COMdec ) ;
COMdec.Algorithm = 'norm-min-sum' ;

BlockSize = 10

Data	= randui( cod.K, BlockSize ) ;
CW		= ldpcEncode( logical( Data ), COMenc ) ;

varCh	= 0.3 ;
sigma	= sqrt( varCh ) ;

TxBlock = -2 * CW + 1 ; % another BPSK modulated 0 > +1, 1 > -1
Noise	= sigma * randn( size( TxBlock ) ) ;
RxBlock	= TxBlock + Noise ;
LLRch	= ( 2 / varCh ) .* RxBlock ;

[ ApLLR1, Iter1 ] = QCLDPCDecode( LLRch, dec ) ;
HD1	= hardDecision( ApLLR1 ) ;

[ ApLLR2, Iter2 ] = ldpcDecode( LLRch, COMdec, dec.nIter, ...
		OutputFormat="whole", DecisionType="soft", MinSumScalingFactor=dec.lambda ) ;
HD2	= hardDecision( ApLLR2 ) ;
whos ApLLR1 ApLLR2 Iter1 Iter2 HD1 HD2
% for varCH == 0.5 the decoded bits should all be equal, LLRs not so much
Iter1
Iter2 
A1 = ApLLR1( 1 : 10, 1 : 10 )
A2 = ApLLR2( 1 : 10, 1 : 10 )
H1 = HD1( 1 : 10, 1 : 10 )
H2 = HD2( 1 : 10, 1 : 10 )
[ Eq, Hd ] = equal( HD1, HD2 ) %bit values should be similar
[ Eq, ~, Ed ] = equal( ApLLR1, ApLLR2 ) %LLR values will now be completely different

%% Test 7 :compile multithreaded floating point decoder
clear ;
clc ;

std			= 'wimax'	% 'wimax' or 'wifi'
R			= 1 / 2 ;
n			= 2304 ;	% wimax
cod			= loadQCLDPC( std, R, n ) % get code params

enc = QCLDPCEncode() ; 	
dec = QCLDPCDecode() ;		% get default options
dec.nIter	= 8 ;
dec.dbglev	= 1 ;
dec.build	= 'debug' ;
dec.method  = 'float' ;
dec.nthread = 32 ;
dec = QCLDPCDecode( dec ) 


saveLDPCheader( 'ldpc', cod, enc, dec, 'MEX' ) ;

buildMEXfile( dec )


%% Test 8: check how close the decoder is to toolbox implementation

R	= 1 / 2   ;
N	= 2304 ;
std = 'wimax' ;

%MEX options
rebuild	= true ;
dbglvl	= 0 ;
verbose	= false ;
build	= 'release' ;	% 'debug' or 'release'

prof	= false ;		%profile the code

%decoder params:
nIter		= 8
Lambda		= 1.0 ;
Offset		= 0.0 ;
method		= 'float' ;	% 'fixed or 'float'
nthread		= 10 ; 

%simulation params:
EbNo		= [ 1 : 0.1 : 2 ]
BlockSize	= 10 * nthread ;
bMul		= 1 ;

Nblocks		= bMul * [ 1 : 1 : size( EbNo, 2 ) ]

%end o settings-------------------------------------

cod	= loadQCLDPC( std, R, N ) ;
K	= cod.K ;
enc = QCLDPCEncode() ; 		
dec = QCLDPCDecode() ;
dec.method	= method ; 
dec.build	= build ;
dec.nthread = nthread ;
dec.nIter	= nIter ;


dec         = QCLDPCDecode( dec ) % refresh parameters

saveLDPCheader( 'ldpc', cod, enc, dec, 'MEX' ) ;

if rebuild
	enc.build	= build ;
	buildMEXfile( enc )

	dec.build	= build ;
	buildMEXfile( dec )
end

enc.dbglev = dbglvl ;

dec.niter	= nIter ;
dec.dbglev	= dbglvl ;
dec.lambda	= Lambda ;
dec.beta	= Offset ;

%MATLAB communications system toolbox encoder
COMdec	= ldpcDecoderConfig( logical( cod.Hs ) ) ;
COMdec.Algorithm = 'norm-min-sum' ;
MinSumScalingFactor = Lambda ;
COMenc	= ldpcEncoderConfig( COMdec ) ;

if verbose
	code	= cod
	MEXenc	= enc
	MEXdec	= dec
	Cenc	= COMenc
	Cdec	= COMdec
end

assert( COMdec.NumInformationBits == cod.K ) ;
assert( COMdec.NumParityCheckBits == cod.M ) ;
assert( COMdec.BlockLength == cod.N ) ;


% actual WTF simulation --------------------------------------------------

nCodewords	= Nblocks * BlockSize ;
bits		= nCodewords * K ;					% number of bits processed

s = size( EbNo, 2 ) ;
ERR			= zeros( 3, s ) ;		% absolute number of errors
BER			= zeros( 3, s ) ;		% BER
ITER		= zeros( 2, s ) ;		% average Nr of iterations
 
%BPSK transmitter -------------------------
tstart = tic ;

if prof
	profile on ;
end

for x = 1 : 1 : size( EbNo, 2 )
		
	ebno	= EbNo( x ) ;
	snr     = 10 ^ ( ebno / 10 ) ;
	varCh	= 1 / ( 2 * snr * cod.Rc ) ;	% account for coderate in noise variance
	sigma	= sqrt( varCh ) ;
	
	for t = 1 : 1 : Nblocks( x )

		Data	= randui( K, BlockSize ) ;
		CW1		= QCLDPCEncode( Data, cod, enc ) ; %type uint8
		if ~areOrthogonal( CW1, cod.H ) 
			whos N K BlockSize Data CW1
			error('MEX encoder FAIL') ; 
		end 
		CW2 = ldpcEncode( logical( Data ), COMenc ) ;	%type logical
		if ~equal( CW1, CW2 )
			whos CW1 CW2
			enc
			COMenc
			error('Encoders differ') ;
		end

		TxBlock = -2 * single( CW1 ) + 1 ; % another BPSK modulated 0 > +1, 1 > -1
		Noise	= sigma * randn( size( TxBlock ), 'single' ) ;
		RxBlock	= TxBlock + Noise ;
		LLRch	= ( 2 / varCh ) .* RxBlock ; %TODO test withouth
		EData	= hardDecision( LLRch( 1 : K, : ) ) ; %no ECC
		ERR( 1, x ) = ERR( 1, x ) + dHamming( EData, Data ) ;
		
		%MEX implementation - uses signle/float type
		[ ApLLR, Iter1 ] = QCLDPCDecode( LLRch, dec ) ;
		HD1				= hardDecision( ApLLR, enc.type ) ;
		HD1				= HD1( 1 : K, : ) ;
		ERR( 2, x )		= ERR( 2, x ) + dHamming( CW1( 1 : K, : ), HD1 ) ;
		ITER( 1, x )	= ITER( 1, x ) + sum( Iter1 ) ;
		
		%COM implementation
		[ HD2, Iter2, ApLLR2 ] = ldpcDecode( LLRch, COMdec, nIter, MinSumScalingFactor=Lambda ) ;
		ERR( 3, x )		= ERR( 3, x ) +  dHamming( CW2( 1 : K, : ), logical( HD2 ) ) ;
		ITER( 2, x )	= ITER( 2, x ) + sum( Iter2 ) ;
		
	end

	ITER( :, x ) = ITER( :, x ) / nCodewords( x ) ; 
	BER( :, x )	= ERR( :, x ) ./ bits( x ) ;
	
	fprintf( 'Eb/No: %4.2f ITER: %4.2f %4.2f Errors: %8d %8d %8d Bits: %8d BER: %f %f %f\n', ...
		EbNo( x ), ITER( :, x )', ERR( :, x )', bits( x ), BER( :, x )' )
end

telapsed	= toc( tstart ) ;
tstr		= datestr( datenum( 0, 0, 0, 0, 0, telapsed ), "HH:MM:SS" ) 

figure() ;
semilogy( EbNo, BER( 2 : end, : ) ) ;
grid on ;

EbNo
BER

if prof
	profile viewer ;
end

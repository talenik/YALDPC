%% test bitmap encoder and decoder

%this will only work for select code parameters, such as when N,K,Z is
%divisible by word bit width

clc ;
clear ;
format compact ;

path( 'lib', path ) ;
path( 'MEX', path ) ;

std		= 'wimax'	% 'wifi' is not compatible
R		= 1 / 2 ;
n		= 2304;	
cod		= loadQCLDPC( std, R, n ) % get code params
k		= cod.K

chan	= 10		
enc		= QCLDPCEncode( ) ;

t = 'uint16' 
enc.method	= 'bitmap' ;	
enc.type	= t ;		% only tunable with 'bitmap' method
enc.build	= 'release' ;
enc			= QCLDPCEncode( enc ) 

dec			= QCLDPCDecode() ; % get default options
dec.nIter	= 8 ;
dec.dbglev	= 1 ;
dec.build	= 'debug' ;
dec.method  = 'fixed' ;

dec.hdbitmap = true ;	%this is how the decoder knows encoder was BITMAP
dec         = QCLDPCDecode( dec ) % refresh parameters

saveLDPCheader( 'ldpc', cod, enc, dec, 'MEX' ) ;
buildMEXfile( enc ) ;
buildMEXfile( dec ) ;

%% test bitmap encoder

kw		= k / enc.wb
DataB	= randui( kw, chan, t ) ;
CWB		= QCLDPCEncode( DataB, cod, enc ) ;

b		= Bits( t ) ;
Data	= b.bit2logical( DataB ) ;
CW		= b.bit2logical( CWB ) ;
%whos Data CW DataB CWB
if areOrthogonal( CW, cod.H ) disp('Encoder test OK') ; else disp('Encoder test FAIL') ; end

%%test bitmap decoder

varCh	= 0.5 ;
sigma	= sqrt( varCh ) ;

TxBlock = -2 * CW + 1 ; % another BPSK modulated 0 > +1, 1 > -1
Noise	= sigma * randn( size( TxBlock ) ) ;
RxBlock	= TxBlock + Noise ;
LLRch	= ( 2 / varCh ) .* RxBlock ;

[ ApLLR1, Iter1, HDB ] = QCLDPCDecode( LLRch, dec ) ;
HD1		= hardDecision( ApLLR1 ) ;
HD2		= double(b.bit2logical( HDB )) ;
if equal( HD1, HD2 ) disp('Decoder test OK') ; else disp('Decoder test FAIL') ; end
%whos HD1 HD2 HDB

whos DataB CWB HDB
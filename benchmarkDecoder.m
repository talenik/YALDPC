%This file runs a benchmark for the QCLDPCDecode() function or toolbox
%ldpcDecode() so you need to have Communications Toolbox installed.
%Also you need to have MEX configured properly first.

clear ;
format compact ;

path( './lib', path ) ;
path( './MEX', path ) ;

%only need to modify these values ----------------------------------------

R			= 5 / 6  ;
N			= 2304 ;
test		= 'COM' ;		% 'MEX' or Toolbox 'COM' decoder
nIter		= 10 ;
N_TH		= 32			% nr. of MEX decoer threads
blocksize	= 10 * N_TH ;
cycles		= 100 ;

%only need to modify these values ----------------------------------------

cod	= loadQCLDPC( 'wimax', R, N ) ;

%MEX implementation
enc = QCLDPCEncode() ; 		
dec = QCLDPCDecode() ;

dec.method	= 'float' ; % 'fixed or 'float'
dec.build	= 'release' ;
dec.dbglev	= 1 ;

dec.nIter	= nIter ;
dec.term	= 'max' ;
dec.nthread = N_TH ;

dec = QCLDPCDecode( dec ) ;

saveLDPCheader( 'ldpc', cod, enc, dec, 'MEX' ) ;

if strcmp( test, 'MEX' ) 
	buildMEXfile( dec ) ;
end


%MATLAB communications system toolbox encoder
COMdec	= ldpcDecoderConfig( logical( cod.Hs ) ) ;
COMenc	= ldpcEncoderConfig( COMdec ) ;
if strcmp( test, 'COM' ) 
	COMdec.Algorithm = 'norm-min-sum' ;
	COMdec
else
	cod
	dec
end


Data	= randui( cod.K, blocksize ) ;
CW		= ldpcEncode( logical( Data ), COMenc ) ;

varCh	= 0.01 ;
sigma	= sqrt( varCh ) ;

TxBlock = -2 * CW + 1 ; % another BPSK modulated 0 > +1, 1 > -1
Noise	= sigma * randn( size( TxBlock ) ) ;
RxBlock	= TxBlock + Noise ;
LLRch	= ( 2 / varCh ) .* RxBlock ;


ITE = 0 ;


tstart = tic ;
disp( [ 'Starting benchmark... ' ] ) ;
for c = 1 : cycles

	if strcmp( test, 'COM' ) 
		[ HD2, Iter1, ApLLR2 ] = ldpcDecode( LLRch, COMdec, nIter, ...
			Multithreaded = N_TH > 1, Termination = 'max'  ) ;
	else
		[ ApLLR, Iter1 ] = QCLDPCDecode( LLRch, dec ) ;
		if( nnz( Iter1 < 0 ) > 0 )
			disp("Threading errors.") ;
		end
	end
	if mod( c, 100 ) == 0
		c
	end
	ITE = ITE + sum( Iter1 ) ;
end
telapsed	= toc( tstart ) ;
avgIter		= ITE / ( cycles * blocksize )
tstr		= datestr( datenum( 0, 0, 0, 0, 0, telapsed ), "HH:MM:SS" ) 
Bits		= cod.K * blocksize * cycles
ThP			= 1e-6 * Bits / telapsed  ; % Mbps
disp( [ 'Bits: ' num2str(Bits) ' Throughtput: ' num2str( ThP ) ' Mbps' ] ) ;

if exist('QCLDPCDecodeMEX_MTX')
	QCLDPCDecodeMEX_MTX() ; % cleanup - end all worker threads
end

% Test 1: loading CCSDS H and G matrices from precalculated MAT file.
% Test 2: Check orthogonality for each parameters combination - loaded from MAT files
% Test 3: Setup for MEX file debugging
% Test 4: Calculating G matrices out of H 

%% Test 1: loading CCSDS H and G matrices from precalculated MAT file.

clear ;
clc ;
path( 'lib', path ) ;
format compact ;
pwd ;

cc	= CCSDS_LDPC()
k	= 1024 ;
R	= 1 / 2 ;
code =  cc.loadCCSDS_LDPC( k, R )	%load from MAT file
n = code.n ;
k = code.k ;
M = code.M ;
R = k / n

%base matrices
G = code.G ;
H = code.H ;

fprintf("Actual parameters of the base code:\nn = %d, k = %d, M = %d, R = %4.2f\n", n, k, M, R ) ;

ok		= areOrthogonal( G, H )
G_MAX	= findGMAX( H ) 

[ CH_S, CH_I ] = getIndices( H, G_MAX ) ;


figure( 1 ) ;
displayBinaryMatrix( H, M ) ;

figure( 2 ) ;
displayBinaryMatrix( G, M ) ;

% Gsmall = G( 1 : M,  k + 1 : k + M ) ;
% F = 8 ;
% Hsmall = H( [ 1 : F : size( H, 1 ) ], [ 1 : F : size( H, 2 ) ] ) ;
% 
% figure( 3 )
% displayBinaryMatrix( Hsmall, M/F ) ;
% 
% figure( 4 )
% displayBinaryMatrix( Gsmall, M/4 ) ;



%% Test 2: Check orthogonality for each parameters combination - loaded from MAT files

clear ;
clc ;
path( 'lib', path ) ;
path( 'MEX', path ) ;
path( 'MAT', path ) ;
format compact ;
pwd ;

cc	= CCSDS_LDPC()

for R = [ 1/2 2/3 4/5 ]
		for k = [ 1024 4096 16384 ] 
		c	=  cc.loadCCSDS_LDPC( k, R ) ;	

		%base code - before puncturing:
		G	= c.G ;
		H	= c.H ;
		M	= c.M ;
		z	= c.z ; 
		R	= c.R ; 

		[ k , n ] = size( G ) ;
		Rb	= k / n ;	%actual coderate of the base code is < R
		m	= n - k ;

		P	= G( :, k + 1 : end ) ;

		disp( [ n2s(R) n2s(k) n2s(M) n2s(n) n2s(Rb) n2s(z)  ] ) ;
		
		if ~isBlockCirculant( P, z )
			error('P not block-circulant');
		end

		if ~areOrthogonal( G, H ) 
			error('G and H not orthogonal');
		end
		
		print('OK') ;
		clear c G H P ;
	end
end

%% Test 3: Setup for MEX file debugging

clc ;
clear ;
path( 'lib', path ) ;
path( 'MEX', path ) ;
path( 'MAT', path ) ;
format compact ;
pwd ;

k			= 1024
R			= 4 / 5
std			= 'ccsds'
code		= loadQCLDPC( std, R, k )
Rc			= code.Rc		%actual rate of the base code 

enc			= QCLDPCEncode() ;
enc.type	= 'single' ;	%TODO until MEX implementation

dec			= QCLDPCDecode() ;

dec.dbglev  = 1 ;
dec.build	= 'debug' ;
dec.nthread = 1 ;

%recalculate dependent parameters
enc = QCLDPCEncode( enc ) ; 
dec = QCLDPCDecode( dec ) ;

%rebuild MEX files
saveLDPCheader( 'ldpc', code, enc, dec, 'MEX' ) ;
buildMEXfile( enc ) ;
buildMEXfile( dec ) ;

%displayBinaryMatrix( code.H, code.z ) ;

EbN0		= 5 
[sigma, varCh] = ebno2sigma( EbN0, code.Rc ) ;

Data	= randi( [ 0 1 ], code.k, 1, enc.type ) ;
CW		= QCLDPCEncode( Data, code, enc ) ;
TxBlock = -2 * single( CW ) + 1 ; % BPSK: 0 > +1, 1 > -1
Noise	= sigma * randn( size( TxBlock ), 'single' ) ;
RxBlock	= TxBlock + Noise ;
LLRch	= ( 2 / varCh ) .* RxBlock ; 

[ ApLLR, Iter ] = QCLDPCDecode( LLRch, dec ) ;
HD				= hardDecision( ApLLR, enc.type ) ;
HD				= HD( 1 : code.k, : ) ;

nErr	= nnz( Data ~= HD ) 
BER		= nErr / code.k

%% Test 5: Calculating G matrices out of H 

clear ;
clc ;
path( 'lib', path ) ;
format compact ;
pwd ;



invGF2() ;		% run unit test for GF2 matrix inversion MEX 
opt = invGF2('options')
opt.maxrows = 512 ;
opt.maxcols = 512 ;
	
invGF2( opt )	% rebuild MEX file with larger matrix size

cc	= CCSDS_LDPC()

for k = [ 1024 4096 ] % 16k will take some time (and RAM)

	for R = [ 1/2 2/3 4/5 ] 

		H = cc.getHmatrix( k, R ) ;
		G = cc.getGMatrix( k, R ) ; 
		
		OK = areOrthogonal( G, H ) ;

		Hs = size( H ) ;
		Gs = size( G ) ;
		disp( [ n2s( k ) n2s( R ) n2s( Hs ) n2s( Gs ) ] ) ;
		if ~OK
			error('Calculated matrices NOT orthogonal') ;
		end
		print('OK') ;
	end
end

s = invGF2('size')







































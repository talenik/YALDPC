%Use this file to generate the code, encoder, and decoder paramaters
%header/source C file to be used with or withouth MEX.
%Tested on GNU Octave 5.2.0

path( 'lib', path ) ;

%only need to set basic parameters
std = 'wimax'	% set 'wimax' or 'wifi'
R   = 1 / 2		% valid code rates: 1/2, 2/3, 3/4, 5/6

if strcmp('wifi')
	% valid N: 648, 1296, 1944
	N   = 1944	
else
	% valid N: 576, 672, 768, 864, 960, 1056, 1152, 1248, 1344, 1440, 1536, 
	%			1632, 1728, 1824, 1920, 2016, 2112, 2208, 2304
	N   = 2304  
end


code = loadQCLDPC( std, R, N ) ;

%disp( code ) will also print the large H matrices in Octave, making it useless
%Octave workaround:

N   = code.N
K   = code.K
M   = code.M
Z   = code.z
Nb  = code.Nb
Mb  = code.Mb
R   = code.Rc
Hbm = code.Hbm ;
Hs  = code.Hs ;
H   = code.H ;


%get default encoder and decoder parameters
enc = QCLDPCEncode()
dec = QCLDPCDecode()

enc.method  = 'bitmap' %switch to 'bitmap' encoder from default 'array'

dec.method  = 'fixed' %switch to fixed-point implementation
dec.nthread = 32      %switch to multithreaded decoder implementation

%recalculate dependent parameters:
enc = QCLDPCEncode( enc )
dec = QCLDPCDecode( dec )

whos

%saves ldpc.h and ldpc.c
saveLDPCheader( 'ldpc', code, enc, dec )



clear ;
clc ;
path( 'lib', path ) ;
path( 'MEX', path ) ;
path( 'MAT', path ) ;

std		= 'ccsds'
cc		= CCSDS_LDPC() ;
R		= 1 / 2 
k		= cc.Ks( 1 )
code	= loadQCLDPC( std, R, k ) 
code.G	= single( code.G );	%TODO until MEX is implemented

enc		= QCLDPCEncode() ;
enc.type = 'single' ;	%TODO until MEX is implemented

dec		= QCLDPCDecode() ;

% dec.dbglev  = 1 ;
% dec.build	= 'debug' ;
% dec.nthread = 1 ;

sim			= WTFShortPunc( ) ;


% no shortening, no puncturing smallest k = 1024, all rates 
dec.dbglev  = 0 ;
dec.build	= 'release' ;
dec.nthread = 10 ;

sim.plot	= false ;
sim.blkSize	= 10 * dec.nthread ;
sim.minErr	= 10 ;	
sim.impl	= 'MIX' ;
RES			= {}

dec.code	= code ;

R			= cc.Rates( 1 )
k			= cc.Ks( 1 )
code		= loadQCLDPC( std, R, k ) 
sim.EbN0	= [ 1 : 1 : 8] ;
RES{ end + 1 } = WTFShortPunc( code, enc, dec, sim, false, false ) ;
%plotWTF( RES, [ 'CCSDS sim:' sim.impl n2s(R) n2s(k) ] ) ;

R			= cc.Rates( 2 )
k			= cc.Ks( 1 )
code		= loadQCLDPC( std, R, k ) 
sim.EbN0	= [ 1 : 0.5 : 3.5 ] ;
RES{ end + 1 } = WTFShortPunc(  code, enc, dec, sim, false, false ) ;

R			= cc.Rates( 3 )
k			= cc.Ks( 1 )
code		= loadQCLDPC( std, R, k ) 
sim.EbN0	= [ 1 : 0.5 : 4.5 ] ;
RES{ end + 1 } = WTFShortPunc(  code, enc, dec, sim, false, false ) ;


plotWTF( RES, [ 'CCSDS LDPC codes: ' sim.impl n2s( k ) ] ) ;















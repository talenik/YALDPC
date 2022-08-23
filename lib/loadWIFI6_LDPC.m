function code = loadWIFI6_LDPC( R, n )
%Don't run this file directly. Call loadQCLDPC( ) instead.
  
% code = loadWIFi6_LDPC( R, n, [id] )
%	loads code structure with all code parameters
	
	Ks = [ 324 432 486 540 648 864 972 1080 1296 1458 1620 ] ;
	Rs = [ 1/2 2/3 3/4 5/6 ] ;
	Ns = [ 648 1296 1944] ;

	k  = round( n * R ) ;
	ri = getIndex( Rs, R, 'R' ) ;
	ki = getIndex( Ks, k, 'k' ) ;
	ni = getIndex( Ns, n, 'n' ) ;

	[ Hbm, z ] = IEEE80211_code( ri, ni ) ;
	
	code.N			= n ;
	code.K			= k ;
	code.M			= n - k ;
	code.TierSize	= z ;
	code.Nb			= 24 ;
	code.Mb			= code.M / z ;
	code.Rc			= R ;
	code.CodeId		= getCodeId( R ) ;
	code.Hbm		= Hbm ; 
	code.z			= z ;
	code.HbmZ0		= Hbm ;
	code.Hs			= LDPCUncompressH( Hbm, z ) ;
	code.H			= full( code.Hs ) ;
	code.std		= 'wifi' ;

end

function [ Hbm, Z ] = IEEE80211_code( ri, ni )
	IEEE80211_2020_LDPC ;
	HN	= H_IEEE80211{ ni } ;
	Hbm = HN{ ri } ;
	Z	= Z_IEEE80211( ni ) ;
end

%this is really here just for compatibility with WIMAX encoder
function id = getCodeId( R )
	Rates	= [ 1/2 2/3 3/4 5/6 ] ;
	Ids		= [ 5 3 1 0 ] ;  
	ri		= getIndex( Rates, R, 'R' ) ;
	id		= Ids( ri ) ;
end
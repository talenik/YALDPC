function filename = getMatFilename( k, R )
	[ ri, ki ] = getriki( k, R ) ;
	KS = [ "1024" "4096" "16384" ] ;
	RS = [ "12" "23" "45" ] ;
	filename = "CCSDS_LDPC_matrices_K" + KS( ki ) + "_R" + RS( ri ) + ".mat" ;
end
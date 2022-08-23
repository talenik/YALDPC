function gmax = findGMAX( Hbm )
%findGMAX - the maximum check node degree of an QC-LDPC code H matrix 
%	where H is stored in compressed form as the model matrix Hbm
%
%	GMAX = findGMAX( Hbm )

Gs		= sum( Hbm > -1, 2 ) ;
gmax	= max( Gs ) ;
function Hs = LDPCUncompressH( Hc, zf, CodeId )
	%Don't run this file directly. Call loadQCLDPC( ) instead.
  
  %Uncompress the model matrix Hc to binary sparse matrix H.
	% arguments( for explanation see the IEEE 802.16e standard ):
	%	Hc		- model matrix specifies H in a compressed integer format.
	% 	zf		- tier size
	%	CodeId	- specify, which one of the WiMax LDPC codes to use:
	%				0 for the weakest code Rate 5/6
	%				5 for the most powerfull code Rate 1/2
	%
	% returns:
	%	Hs 	- sparce binary parity check matrix of size M x N
	
	[ mb, nb ]	= size( Hc ) ;
	N 			= nb * zf ;
	M 			= mb * zf ;
	
	
	%construct the binary parity check matrix
	H 			= zeros( M, N ) ;
	Iz 			= eye( zf ) ;
	
	for r = 1:1:mb
		for c = 1:1:nb
			shift = Hc( r,c ) ;
			stamp = expandShift( shift, zf ) ;
	
			H( ( ( r - 1 ) * zf ) + 1 : r * zf, ( (c - 1 ) * zf ) + 1 : c * zf ) = stamp ;
		end
	end
	Hs 		= sparse( H ) ;
end

function P = expandShift( s, z )

	if s == -1
		P = zeros( z ) ;
	elseif s == 0
		P = eye( z ) ;
	elseif s > 0 
		P = rotationMatrix( z, s ) ;
	else
		error('shift error') ;
	end
end
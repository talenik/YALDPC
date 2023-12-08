classdef CCSDS_LDPC
%class for generating CCSDS BlueBook 2017 defined LDPC codes
%	defined in section 7.4.
%	generates sparse H and corresponding dense G for the base code
%	TODO: implement proper puncturing

properties
	Rates	= [ 1/2 2/3 4/5 ] ;
	Ks		= [ 1024 4096 16384 ] ;
	Ms		= [	512  256  128	; ...
				2048 1024  512	; ...
				8192 4096 2048 ] ;

	KKs = [ 2, 4, 8 ] ;					%defined in 7.4.3.2
	

	KS = [ "1024" "4096" "16384" ] ;	%k strings
	RS = [ "12" "23" "45" ] ;			%R strings
end

methods
	function o = CCSDS_LDPC()
	end

	function code = loadCCSDS_LDPC( o, k, R )
		
		% code rate 7/8 not supported yet

		filename = str2char( o.getMatFilename( k, R )) ;
		load( [ './MAT/' filename ] ) ;

		code.file	= filename ;
		% code.GL	= GL ;
		% code.GpL	= GpL ;
		% code.HL	= HL ;
		% code.HpL	= HpL ;
		% [ kp, np ]= size( GpL ) ;
		%code.M		= o.getM( k, R ) ;

		code.G		= cO.G ; 
		code.H		= cO.H ;

		code.R		= cO.R ;
		code.M		= cO.M ;
		code.z		= cO.z ;

		[ code.k, code.n ]	= size( code.G ) ;

	end

	function filename = getMatFilename( o, k, R )
		[ ri, ki ] = o.getriki( k, R ) ;

		filename = "CCSDS_LDPC_matrices_K" + o.KS( ki ) + "_R" + o.RS( ri ) + ".mat" ;
	end

	function i = getIndex( o, haystack, needle )
		i = find( haystack == needle, 1 ) ;
		if isempty( i )
			error( [ 'Index of value not found ' num2str( needle ) ] ) ;
		end
	end

	function [ ri, ki ] = getriki( o, k ,R )
		%returns:
		%	ri - rate index ri > R mapping: 1 > 1/2, 2 > 2/3, 3 > 4/5
		%   ki - k index ki > k mapping: 1 > 1024, 2 > 4096, 3 > 16384

		ri		= o.getIndex( o.Rates, R ) ;
		ki		= o.getIndex( o.Ks, k ) ;
	
		%some sanity checking
		assert( ri > 0 && ri < 4 ) ;
		assert( ki > 0 && ki < 4 ) ;	
	end

	function [ M, ri, ki ] = getM( o, k, R )
		%returns M - size of the submatrix
	
		[ ri, ki ] = o.getriki( k, R ) ;
		
		M = o.Ms( ki, ri ) ;
	end

	function Kk = getKk( o, k, R )
		ri = o.getriki( k, R ) ;
		
		Kk	= o.KKs( ri ) ;	% different K and k, see 7.4.3.2
	end

	function [ N, K, Nb, Kb ] = getNK( o, k, R )
		% returns: [ N, K, Nb, Kb ]
		%	N - punctured codeword length
		%	K - punctured data word length
		%	Nb - base code codeword length
		%	Kb - base code data word length
	
		M	= o.getM( k, R ) ;
		Kk	= o.getKk( k, R ) ;
		
		N	= M * ( Kk + 2 ) ;
		K	= M * Kk ;
	
		Nb	= M * ( Kk + 3 ) ;
		Kb	= M * Kk ;
	
	end

	function Hbm = getHbm( o, k, R )

		[ M, ri ] = o.getM( k, R ) ;
		%Carefull, change from section 7.4.2.2:
		% redefined mapping of matrix scalars to:
		%  -1 > zero matrix
		%   0 > identity matrix
		%  +i > permutation matrix P(i)
	
		H12b =	{  -1      -1   0      -1    [ 0 1 ] ; ...
					0	    0  -1       0  [ 2 3 4 ] ; ...
					0 [ 5 6 ]  -1 [ 7 8 ]          0 } ;
	
		H23bp = {          -1             -1 ; ...
			  	  [ 9 10 11 ]              0 ; ...
			            	0   [ 12 13 14 ] } ; 
	
		H23b = horzcat( H23bp, H12b ) ; 
	
		H45bp = {	        -1           -1           -1           -1 ; ...
			  	  [ 21 22 23 ]            0 [ 15 16 17 ]            0 ; ...
				           	 0 [ 24 25 26 ]            0 [ 18 19 20 ] } ;
	
		H45b = horzcat( H45bp, H23b ) ;

		if ri == 1		% R = 1/2
			Hbm = H12b ;
		elseif ri == 2	% R = 2/3
			Hbm = H23b ;
		else			% R = 4/5
			Hbm = H45b ;
		end
	end


	function [ G ] = getGMatrix( o, k, R )
		M = o.getM( k, R ) ;
		K = o.getKk( k, R ) ;
		H = o.getHmatrix( k, R ) ;
		
		Pd		 = H( :, end - ( 3 * M ) + 1 : end ) ;
		Pg		 = logical( Pd ) ;
		[ y, x ] = size( Pg ) ;
	
		assert( y == 3 * M ) ;
		assert( x == 3 * M ) ;

		% running/rebuilding MEX file, mod( inv( P ), 2 ) won't do :)

		s = invGF2('size') ;	%get compiled-in limits
		if s( 1 ) < y || s( 2 ) < x
			opt = invGF2('options')
			opt.maxrows = 3 * M ;
			opt.maxcols = 3 * M ;
			invGF2( opt ) ;			%rebuilding MEX
		end

		[ PIg, r ]	= invGF2( Pg ) ;
		PI		= double( PIg ) ;
	
		Q		= H( :, 1 : M * K ) ;
		W		= mod( ( PI * Q )', 2 ) ;
		G		= [ eye( M * K ) W ] ;
		
		if ~isBinary( PI )
			error('Generated PI not binary') ;
		end
		if ~isBinary( W )
			error('Generated W not binary') ;
		end
		if ~isBinary( G )
			error('Generated G not binary') ;
		end
	end

	function [ H, M, Hpunc ] = getHmatrix( o, k, R )

		[ M, ri ] = o.getM( k, R ) ;	
		Hb		= o.getHbm( k, R ) ;
	
		H		= o.expandH( Hb, M ) ;
		%TODO: is this really what 7.4.2.5 says ???
		Hpunc	= H( :, 1 : end - M ) ;
	
		if ~isBinary( H )
			error('Generated H not binary') ;
		end
	end

	function H = expandH( o, Hb, M )
		%HB is a cell array
		[ R, C ] = size( Hb ) ;
		H = zeros( R * M, C * M, 'logical' ) ;
	
		for r = 1 : R
			for c = 1 : C
				p = Hb{ r, c } ;
				l = length( p ) ;
				if l > 1 
					% p is a vector of perm matrix indices for combining
					PM = o.combine( p, M ) ;
				else
					% p is a scalar defining exact matrix
					if p == -1
						PM = zeros( M, 'logical' ) ;
					elseif p == 0
						PM = eye( M, 'logical' ) ;
					else
						error('Invalid scalar in Hb') ;
					end
				end
				H( ( ( r - 1 ) * M ) + 1 : r * M, ( (c - 1 ) * M ) + 1 : c * M ) = PM ;
			end
		end
	end

	function PM = combine( o, CMs, M )
		% assuming the symbol used in 7.4.2.2 is actually xor
		PM = zeros( M, 'logical' ) ;
		for k = CMs
			assert( k >= -1 && k < 27 ) ;
			if k == -1
				P = zeros( M, 'logical' ) ;
			elseif k == 0
				P = eye( M, 'logical' ) ;
			else
				P = logical( o.getPMatrix( k, M ) ) ;
			end
			PM = xor( PM, P ) ;
		end
	end

	function PM = getPMatrix( o, k, M )

		PM = zeros( M ) ;
		
		%carefull: row index i is defined starting at 0
		for i = 0 : 1 : M - 1
			pki  = o.getPerm( k, i, M ) ;
			assert( pki >= 0 && pki < M ) ;
	
			PM( i + 1, pki + 1 ) = 1 ;	% MATLAB indexing starts at 1
		end
	end

	function pki = getPerm( o, k, i, M )
		%implements perm definition in section 7.4.2.4
		assert( i >= 0 && i < M ) ;

		THETA = [ 3 0 1 2 2 3 0 1 0 1 2 0 2 3 0 1 2 0 1 2 0 1 2 1 2 3 ] ; 
		tk	= THETA( k ) ;
		
		M4	= M / 4 ;
		t1	= M4 * mod( tk + floor( ( 4 * i ) / M ), 4 ) ;
		
		phi = o.getPhi(k, floor( ( 4 * i ) / M ), M ) ;
		t2  = mod( phi + i, M4 ) ;
	
		pki = t1 + t2 ;
	end

	function ph = getPhi( o, k, j, M )
		Mv = [ 128, 256, 512, 1024, 2048, 4096, 8192 ] ;
		x = find( Mv == M ) ;
		assert( x >= 1 && x < 8 ) ;
		assert( k >= 1 && k < 27 ) ;
		assert( j >= 0 && j < 4 ) ;
		z = j + 1 ;
		
		%will be indexed by: ( k, M, j ) > ( k, x, z )
		PHI = -ones( 26, 7, 4 ) ;
	
		% PHIk(j=0,M), carefull Matlab indexes z(j) starting at 1 !!! 
		PHI( :, :, 1 ) = [ ... 
	 	 1 59  16 160 108 226 1148 ; ...
		22 18 103 241 126 618 2032 ; ...
	 	 0 52 105 185 238 404  249 ; ...
		26 23   0 251 481  32 1807 ; ...
	 	 0 11  50 209  96 912  485 ; ...
		10  7  29 103  28 950 1044 ; ...
	 	 5 22 115  90  59 534  717 ; ...
		18 25  30 184 225  63  873 ; ...
	 	 3 27  92 248 323 971  364 ; ...
		22 30  78  12  28 304 1926 ; ...
	 	 3 43  70 111 386 409 1241 ; ...
	 	 8 14  66  66 305 708 1769 ; ...
		25 46  39 173  34 719  532 ; ...
		25 62  84  42 510 176  768 ; ...
	 	 2 44  79 157 147 743 1138 ; ...
		27 12  70 174 199 759  965 ; ...
	 	 7 38  29 104 347 674  141 ; ...
	 	 7 47  32 144 391 958 1527 ; ...
		15  1  45  43 165 984  505 ; ...
		10 52 113 181 414  11 1312 ; ...
	 	 4 61  86 250  97 413 1840 ; ...
		19 10   1 202 158 925  709 ; ...
	 	 7 55  42  68  86 687 1427 ; ...
	 	 9  7 118 177 168 752  989 ; ...
		26 12  33 170 506 867 1925 ; ...
		17  2 126  89 489 323  270 ] ;
	
		% PHIk(j=1,M), carefull Matlab indexes z(j) starting at 1 !!! 
		PHI( :, :, 2 ) = [ ... 
	 	 0  0   0   0   0    0    0 ; ...
		27 32  53 182 375  767 1822 ; ...
		30 21  74 249 436  227  203 ; ...
		28 36  45  65 350  247  882 ; ...
	 	 7 30  47  70 260  284 1989 ; ...
	 	 1 29   0 141  84  370  957 ; ...
	 	 8 44  59 237 318  482 1705 ; ...
		20 29 102  77 382  273 1083 ; ...
		26 39  25  55 169  886 1072 ; ...
		24 14   3  12 213  634  354 ; ...
	 	 4 22  88 227  67  762 1942 ; ...
		12 15  65  42 313  184  446 ; ...
		23 48  62  52 242  696 1456 ; ...
		15 55  68 243 188  413 1940 ; ...
		15 39  91 179   1  854 1660 ; ...
		22 11  70 250 306  544 1661 ; ...
		31  1 115 247 397  864  587 ; ...
	 	 3 50  31 164  80   82  708 ; ...
		29 40 121  17  33 1009 1466 ; ...
		21 62  45  31   7  437  433 ; ...
	 	 2 27  56 149 447   36 1345 ; ...
	 	 5 38  54 105 336  562  867 ; ...
		11 40 108 183 424  816 1551 ; ...
		26 15  14 153 134  452 2041 ; ...
	 	 9 11  30 177 152  290 1383 ; ...
		17 18 116  19 492  778 1790 ] ;  
	
		% PHIk(j=2,M), carefull Matlab indexes z(j) starting at 1 !!! 
		PHI( :, :, 3 ) = [ ...
	 	 0  0   0   0   0   0    0 ; ... 
		12 46   8  35 219 254  318 ; ...
		30 45 119 167  16 790  494 ; ...
		18 27  89 214 263 642 1467 ; ...
		10 48  31  84 415 248  757 ; ...
		16 37 122 206 403 899 1085 ; ...
		13 41   1 122 184 328 1630 ; ...
	 	 9 13  69  67 279 518   64 ; ...
	 	 7  9  92 147 198 477  689 ; ...
		15 49  47  54 307 404 1300 ; ...
		16 36  11  23 432 698  148 ; ...
		18 10  31  93 240 160  777 ; ...
	 	 4 11  19  20 454 497 1431 ; ...
		23 18  66 197 294 100  659 ; ...
	 	 5 54  49  46 479 518  352 ; ...
	 	 3 40  81 162 289  92 1177 ; ...
		29 27  96 101 373 464  836 ; ...
		11 35  38  76 104 592 1572 ; ...
	 	 4 25  83  78 141 198  348 ; ...
	 	 8 46  42 253 270 856 1040 ; ...
	 	 2 24  58 124 439 235  779 ; ...
		11 33  24 143 333 134  476 ; ...
		11 18  25  63 399 542  191 ; ...
	 	 3 37  92  41  14 545 1393 ; ...
		15 35  38 214 277 777 1752 ; ...
		13 21 120  70 412 483 1627 ] ;  
	
		% PHIk(j=3,M), carefull Matlab indexes z(j) starting at 1 !!! 
		PHI( :, :, 4 ) = [ ...
	 	0   0   0   0   0    0    0 ; ...
		13 44  35 162 312  285 1189 ; ...
		19 51  97   7 503  554  458 ; ...
		14 12 112  31 388  809  460 ; ...
		15 15  64 164  48  185 1039 ; ...
		20 12  93  11   7   49 1000 ; ...
		17  4  99 237 185  101 1265 ; ...
	 	 4  7  94 125 328   82 1223 ; ...
	 	 4  2 103 133 254  898  874 ; ...
		11 30  91  99 202  627 1292 ; ...
		17 53   3 105 285  154 1491 ; ...
		20 23   6  17  11   65  631 ; ...
	 	 8 29  39  97 168   81  464 ; ...
		22 37 113  91 127  823  461 ; ...
		19 42  92 211   8   50  844 ; ...
		15 48 119 128 437  413  392 ; ...
	 	 5  4  74  82 475  462  922 ; ...
		21 10  73 115  85  175  256 ; ...
		17 18 116 248 419  715 1986 ; ...
	 	 9 56  31  62 459  537   19 ; ...
		20  9 127  26 468  722  266 ; ...
		18 11  98 140 209   37  471 ; ...
		31 23  23 121 311  488 1166 ; ...
		13  8  38  12 211  179 1300 ; ...
	 	 2  7  18  41 510  430 1033 ; ...
		18 24  62 249 320  264 1606 ] ;  
	
		if ~all( PHI >= 0 )
			error('PHI table contains negative values') ;
		end
	
		ph = PHI( k, x, z ) ;
	end
end

end
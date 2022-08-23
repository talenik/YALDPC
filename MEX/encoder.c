/* ==========================================================================
QC LDPC decoder

Copyrigth (C) 2022 Tomas Palenik, All rights reserved.

This file is part of YALDPC MATLAB/C99 MEX Toolkit.
	
SRC code and documentation: https://github.com/talenik/YALDPC

Released under the BSD 3-Clause License:

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

========================================================================== */

#include <assert.h>
#include <math.h>
#include <memory.h>
#include <stdint.h>

#ifdef MATLAB_MEX_FILE
	#include "mex.h"
	#include "matrix.h"
#else
	#include <stdio.h>
	#include <stdlib.h>
#endif

#include "ldpc.h"
#include "debug.h"
#include "encoder.h"

static BLOCK Si[ MB ] ;

//local functions prototypes--------------------------------------------

WORD XOR( WORD x, WORD y ) ;
void vXOR( WORD *v1, WORD *v2, WORD *dst ) ;
void vNUL( WORD *v, int num ) ;
void vCPY( WORD *dst, WORD *src, int len ) ;
int checkShift( int shift ) ;
void aROR( WORD *v, WORD *res, int shift, int z ) ;
int modWB( int i ) ;
void baROR( WORD *v, WORD *res, int shift ) ;
void vROR( WORD *v, WORD *res, int shift, int z ) ;


//global functions prototypes--------------------------------------------

/*
	non-bitmap encoder: check the data is binary:
	contains only zeros and ones stored as WORD

	bitmap encoder: input may contain any value

	returns 1 on success, 0 on failure
*/
int CheckEncoderInput( WORD *in, int r, int c ){
	int i ;

	for( i = 0 ; i < r * c ; i++ ){
		if( in[ i ] != 0U && in[ i ] != 1U )
			return 0 ;
	}
 	return 1 ;
}

/*
	based on the data vector in (of length K or KW (bitmap))
	produces the parity part out ( of length M or MW (bitmap) )
	encodes one word
*/
void QCLDPCEncode( WORD *in, WORD *out ){
	int i, j, p0, shift ;
	BLOCK_P u ;
	BLOCK_P v ;

	BLOCK t ;	
	BLOCK sum ;

	dbg( 2, "encode: sizeof( WORD ): %dB, sizeof( BLOCK): %dB, Z x WB : %dB,  sizeof( Si ): %dB, MB x Z: %dB \n",
		sizeof( WORD ), sizeof( BLOCK ), Z * WB/8,  sizeof( Si ), MB * Z ) ;

	//find the non-paired value for inversion
	p0 = 0 ;
	for( i = 1 ; i < MB - 1 ; i++ ){
		if( HBM[ i ][ KB ] > -1 ){
			assert( p0 == 0 ) ;
			p0 = HBM[ i ][ KB ] ; 
		}
	}

	
	assert(p0 >= 0) ; // only Rate2/3A code has zero, others positive
	if(p0 > 0 ){
		p0	= Z - p0 ;
	}

	u = ( BLOCK_P ) in ;
	v = ( BLOCK_P ) out ;
	
	vNUL( (WORD *)Si, MB ) ;

	//calculate the double sum in eq. G.1
	vNUL( sum, 1 ) ;
	
	for( i = 0 ; i < MB ; i++ ){
		vNUL( t, 1 ) ;
		for( j = 0 ; j < KB ; j++ ){
			shift = HBM[ i ][ j ] ;
			if( shift != -1 ){
				vROR( u[ j ], t, shift, Z ) ;
			 	vXOR( Si[ i ], t, Si[ i ] ) ;
			}
		}
		vXOR( Si[ i ], sum, sum ) ;
	}


	//finish eq. G.1 by inverse rotation, first parity block v(0) ready
	vROR( sum, v[ 0 ], p0, Z ) ;

	//calculate v(1) as in eq. G.2
	shift = HBM[ 0 ][ KB ] ;

	if( shift == -1 ){
		vNUL( sum, 1 ) ;
	}else{
		vROR( v[ 0 ], sum, shift, Z ) ; //overwrites sum
	} 

	//eq. G.2 finished
	vXOR( Si[ 0 ], sum, v[ 1 ] ) ;

	//eq. G.3
	for( i = 1 ; i < MB - 1 ; i++ ){
		vCPY( sum, v[ i ], Z ) ; 	//init sum

		shift = HBM[ i ][ KB ] ;
		if( shift != -1 ){
			vROR( v[ 0 ], t, shift, Z ) ;
			vXOR( t, sum, sum ) ;
		}
		vXOR( Si[ i ], sum, v[ i + 1 ] ) ; //overwrites v[i+1]
	}

}


//local functions definitions


// also do some checking
WORD XOR( WORD x, WORD y ){
	#ifndef BITMAP
		assert( x == 0U || x == 1U ) ;
		assert( y == 0U || y == 1U ) ;
	#endif

	return x ^ y ;
}

//works on blocks of size Z
void vXOR( WORD *v1, WORD *v2, WORD *dst ){
int i, z ;
	#ifdef BITMAP
		z = ZW ;
	#else
		z = Z ;
	#endif

	for( i = 0 ; i < z ; i++ )
		dst[ i ] = XOR( v1[ i ], v2[ i ] ) ;
}

//works on blocks of size Z
void vNUL( WORD *v, int num ){
	memset( (void *)v, 0U, num * sizeof( BLOCK ) ) ; 
}

//copy len elements
void vCPY( WORD *dst, WORD *src, int len ){
	#ifdef BITMAP
		// len represents value in bits, assuming 8bits bytes
		assert( len % 8 == 0 ) ;
		len = len / 8 ;
	#else
		// len represents value in array elements
		len = len * sizeof( WORD ) ;
	#endif

	if( memcpy( (void *)dst, (const void *)src, len ) == NULL ){
		dbg( 1, "memcpy FAIL'\n" ) ;
	}
}

int checkShift( int shift ){

	#ifdef MATLAB_MEX_FILE
		shift = -shift ;	//MATLAB ROR/ROL confusion fix
	#endif

	shift = shift % Z ;

	assert( shift > -Z && shift < Z ) ;

	if( shift < 0 ){
		shift = Z + shift ;	//ROL (shift is negative)
	}

	assert( shift >= 0 && shift < Z ) ;

	return shift ;
}

/*
 * rotate array of elements - each bit is stored in one array element
 * shift is the nr. of array elements, each carrying one bit
 * uses general block size z array elements (not compiled-in Z )
 * */
void aROR( WORD *v, WORD *res, int shift, int z ){
	
	shift = checkShift( shift ) ;

	if( shift == 0 ){
		vCPY( res, v, z ) ;
		return ;
	}

	vCPY( res, v + z - shift, shift ) ;
	vCPY( res + shift, v, z - shift ) ;
}

/*
 * modulo power of two
 * */
int modWB( int i ){
	return i & ( ( 1 << WBE ) - 1 ) ;
}

/*
 * rotate array of bits stored in a bitmap - each array element stores WB bits
 * shift is the number of bits
 * uses compiled in block size Z, ZW, WB, WBE
 * limitations:
 * 		blocksize Z bits must be divisible by WB
 * 		memory accesses must be aligned to word boundary
 */
void baROR( WORD *v, WORD *res, int shift ){
	int sW ; // shift in WORDs
	int sb ; // shift in bits within a WORD

	int i, j ;
	WORD curSW, preSW, hi, lo ;

	shift = checkShift( shift ) ;

	if( shift == 0 ){
		vCPY( res, v, Z ) ; // Z gets divided by WB inside
		return ;
	}

	sW = shift >> WBE ; 	// shift / WB, WB power of 2
	sb = modWB( shift ); 	// shift % WB
	dbg( 2, "s: %d, sW: %d, sb: %d\n", shift, sW, sb ) ;

	if( sb == 0 ){
		//aROR cannot be used here
		for( i = 0 ; i < ZW ; i++ ){
			j = ( i + sW ) % ZW ;
			res[ j ] = v[ i ] ;
		}
		return ;
	}

	preSW = v[ ZW - 1 ] ;

	for( i = 0 ; i < ZW ; i++ ){
		j 		= ( i + sW ) % ZW ;	//not a power of 2
		curSW 	= v[ i ] ;
		hi 		= preSW << ( WB - sb ) ;
		lo 		= curSW >> sb ;
		res[j] 	= hi | lo ;
		preSW 	= v[ i ] ;
	}

}

void vROR( WORD *v, WORD *res, int shift, int z ){
	#ifdef BITMAP
		baROR( v, res, shift ) ; 	//bitmap aligned ROR
	#else
		aROR( v, res, shift, z ) ;	//array ROR
	#endif
}






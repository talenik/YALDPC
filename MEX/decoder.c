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
	#include "ldpc.h"	//All parameters are compiled-in using a MATLAB-generated header file. 
#else
	#include <stdio.h>
	#include <stdlib.h>
	#include "ldpc.h"
#endif

#include <float.h>
#include "decoder.h"
#include "debug.h"

#define sign( x ) ( ( x ) < 0 ? 1U : 0U )
#define mag( x )  ( ( x ) >= 0 ? ( x ) : -( x ) )
#define max( x, y ) ( ( x ) > ( y ) ? ( x ) : ( y ) )

//run-time global parameters supplied by MATLAB
static int 	NIter 		= 0 ;		//number of iterations
static FP 	Lambda		= 1.0 ;		//normalization factor
static FP 	Beta  		= 0.0 ;		//offset
static int 	Termination = 1 ;		// 1 > terminate when converged, 0 > allways do all iterations


//indices to H matrix for easy access:
static int8_t 	CH_S[ M ] ;				//actual N(m) sizes for each check
static int16_t 	CH_IND[ M ][ G_MAX ] ;	//absolute indices of variables for each check

static FP ZNold[ N ] ;				// aka Zn(k-1)

static FP ZT[ MB ][ N ] ;			//temporary sums Znew for each tier

static FP ZNnew[ N ] ;				// aka Zn(k)
static WORD HD[ N ] ;

static FP *Zold = NULL ;
static FP *Znew = NULL ;

//storing Lmn(k) values:
static FP LM[ M ][ 2 ] ;			//2 minimal magnitude values for all checks
static uint32_t LS[ M ] ; 			//signs of all N(m) elements for all checks stored as a bitmap
static uint8_t LI[ M ] ;			//relative index of minimal magnitude variable for all checks

//local functions
static int orthogonal( void ) ;
static void checkMinSum( int m, int mb, int iter ) ;
static void initCheckIndices( void ) ;

static void sumTiers( void ) ;

static unsigned getSign( uint32_t signBuf, int index ) ;
static unsigned setSign( uint32_t signBuf, unsigned bit, int index ) ;


//global functions definitions-------------------------------------------------

/*
 * retrieve an unsigned signum value from a bitmap
 * */
static unsigned getSign( uint32_t signBuf, int index){
	unsigned sign ;

	assert( index < G_MAX ) ;

	sign = ( signBuf >> index ) & 1U  ;

	assert( sign == 1U || sign == 0U ) ;

	return sign ;
}

/*
 * store a sign bit to bitmap storage
 * returns updated bitmap
 * */
static unsigned setSign( uint32_t signBuf, unsigned bit, int index ){

	assert( bit == 0U || bit == 1U ) ;

	if( bit == 0U ){
		//clear bit
		signBuf &= ~( 1U << index ) ;
	} else {
		//set bit
		signBuf |= ( 1U << index ) ;
	}

	return signBuf ;
}


void MSInitDecoder( int niter, FP norm, FP offset, int termination ){
	NIter 		= niter ;
	Lambda 		= norm ;
	Beta 		= offset ;
	Termination = termination ;

	Zold 	= ZNold ;
	Znew 	= ZNnew ;
	
	dbg( 1, "NITer: %d, Lambda: %f, Beta: %f \n", NIter, Lambda, Beta ) ;

	initCheckIndices() ;
}

/*
* LLch are the channel log likelihoods for the received block
* HD is the Hard Decision decoded binary block
* NIter is the maximal number of iterations
*
* returns: number of iterations if decode converged, 0 otherwise, -1 on error
*/
int MSDecode( FP *LLch, FP *ApLLR, int t ){
	int iter, m, n, mb ;
	FP *tmp ;

	memset( ( void * )LM, 0U, sizeof( LM ) ) ;
	memset( ( void * )LS, 0U, sizeof( LS ) ) ;
	memset( ( void * )LI, 0U, sizeof( LI ) ) ;
	
	memcpy( ( void * )ZNold, ( void * )LLch, sizeof( ZNold ) ) ;

	assert( sizeof( ZNold ) == N * sizeof( FP ) ) ;
	assert( sizeof( ZNnew ) == sizeof( ZNold ) ) ;

	Zold = ZNold ;
	Znew = ZNnew ;

	memset( ( void * )ZT, 0U, sizeof( ZT ) ) ;

	for( iter = 0 ; iter < NIter ; iter++ ){

		memcpy( ( void * )Znew, ( void * )LLch, sizeof( ZNnew ) ) ;

		for( mb = 0 ; mb < MB ; mb++ ){
			memcpy( ( void * )Znew, ( void * )LLch, sizeof( ZNnew ) ) ;
			memset( ( void * )ZT[ mb ], 0U, sizeof( ZT[ mb ] ) ) ;

			for( m = 0 ; m < Z ; m++ ){
				checkMinSum( Z * mb + m, mb, iter ) ; //updates ZT for current tier
			}

			sumTiers( ) ;	//carefull - tiers from previous iteration are also used

			memcpy( ( void * )Zold, ( void * )Znew, sizeof( ZNnew ) ) ;
		}
		
		if( iter == 0 ) {
			assert( Znew == ZNnew ) ;
		}

		for( n = 0 ; n < N ; n++ ){
			HD[ n ] = sign( Znew[ n ] ) ;  
		}

		if( orthogonal( ) ){
			memcpy( ( void * )ApLLR, ( const void * )Znew, N * sizeof( FP ) ) ;
			if( Termination ){
				return iter + 1 ;
			}
		}

		tmp = Zold ;
		Zold = Znew ;
		Znew = tmp ;
	}

	memcpy( ( void * )ApLLR, ( const void * )Zold, N * sizeof( FP ) ) ;
	return iter ;
}

/*
 * convert LLR values to bits
 *
 * TODO: this will not work if WORD is wider than unsigned eg. 64 bit wide WORD
 * */
void HardDecision( FP *LLr, WORD *CW, int el ) {
	int i, wi, ii ;

	assert( sizeof( WORD ) <= sizeof( unsigned ) ) ;

	for( i = 0 ; i < el ; i++ ){
		#ifndef BITMAP
			CW[ i ] = sign( LLr[ i ] ) ;
		#else
			assert( el % WB == 0 ) ;
			wi = i / WB ;
			ii = i % WB ;
			CW[ wi ] = setSign( CW[ wi ], sign( LLr[ i ] ), WB - ii - 1 ) ;
		#endif

	}
}

/*
 * convert float values to fixed point representation
 * this is more conveniently done in MATLAB if MEX file is used
 * */
void Float2Fixed( float *in, FP *out, int col ){
	float fv, a ;

	//TODO: these values are present and correct in ldpc.h only if FIXED is set
	float fp_max = 20.0f ;
	float lmx 	= 1023 ;

	a = fp_max / lmx ;

	for( int i = 0 ; i < N * col ; i++ ){
		fv  = ( in[ i ] > lmx ) ? lmx : in[ i ] ;
		out[ i ] = ( FP )( a * fv ) ;
	}
}

/*
 * check if codeword CW satisfies all the check equations
 * TODO: CW will likely be a matrix, need to do this for all columns
 * */
int Orthogonal( WORD *CW, int t ) {
	if( CW == NULL )
		return 0 ;

	if( CW != HD )
		memcpy( ( void * )HD, (void *)CW, N * sizeof( WORD ) ) ;

	return orthogonal() ;
}

//local functions definitions---------------------------------------------------

/*
 * sum the tiers for layered decoding
 * carefull: ZT values from previous iteration are also used
 * */
static void sumTiers( void ){
	int n, mb ;

	for( mb = 0 ; mb < MB ; mb++ ){
		for( n = 0 ;  n < N ; n++ ){
			Znew[ n ] += ZT[ mb ][ n ] ;
		}
	}
}


static void checkMinSum( int m, int mb, int iter ){
	FP min1 = FP_MAX ;
	FP min2 = FP_MAX ;
	FP zmn, lmn, a, tmp ;

	int i, n, midx ;
	unsigned s, sgnPrd = 0U ;

	//finds the updated minimums

	for( i = 0 ; i < CH_S[ m ] ; i++ ){
		n = CH_IND[ m ][ i ] ;

		if( iter == 0 ){
			//in first iteration just read the channel values, and no subtraction
			zmn = Zold[ n ] ;
		}else{
			//reconstruct old values from compressed form
			a = ( ( i == LI[ m ] ) ? LM[ m ][ 1 ] : LM[ m ][ 0 ] ) ;

			s 	= getSign( LS[ m ], i ) ;

			#ifndef FIXED
				tmp = ( s ? -1.0f : 1.0f ) * a ;
			#else
				tmp = ( s ? -a : a ) ;
			#endif

			zmn = Zold[ n ] - tmp  ; 			// Eq. (3) subtraction

		}

		//compute two minimal values in array Lmn
		s = sign( zmn ) ;
		a = mag( zmn ) ;

		LS[ m ] = setSign( LS[ m ], s, i ) ;
		sgnPrd  ^= s ;

		if( a <= min1 ){
			min2 = min1 ;
			min1 = a ;
			midx = i ;
		}else{
			if( a < min2 ){
				min2 = a ;
			}
		}
	}

	LM[ m ][ 0 ] = min1 ;
	LM[ m ][ 1 ] = min2 ;
	LI[ m ] = midx ;

	//calculate extrinsic messages
	for( i = 0 ; i < CH_S[ m ] ; i++ ){
			n = CH_IND[ m ][ i ] ;
			a = ( ( i == midx ) ? min2 : min1 ) ;

			s = getSign( LS[ m ], i ) ^ sgnPrd ;

			#ifndef FIXED
				lmn = Lambda * ( s ? -1.0f : 1.0f ) * max( a - Beta, 0.0f ) ;
			#else
				lmn = s ? -a : a ;
			#endif

			LS[ m ] = setSign( LS[ m ], sign( lmn ), i ) ;
			ZT[ mb ][ n ] = lmn ; // assuming max column weight == 1 foir each tier
	}

}

static int orthogonal( void ){
	int m, i ;
	unsigned sum, b ;

	for( m = 0 ; m < M ; m++ ){
		sum = 0U ;
		for( i = 0 ; i < CH_S[ m ] ; i++ ){
			b = HD[ CH_IND[ m ][ i ] ] ; 
			sum ^= b ;
		}
		if( sum != 0 ){
			dbg( 2, "ORT: CH %d FAILED, sum(m): %d \n", m, sum ) ;
			return 0 ;
		}
	}

	dbg( 2, "WORD ORTHOGONAL\n") ;

	return 1 ;
}

/*
initialize CH_S and CH_IND based on the HBM matrix
	assuming HB is already scaled
*/

static void initCheckIndices( void ) {
		int r, c ; 		//indices to the block model matrix
		int shift, offx, offy ;
		int k ; 		//relative index inside the submatrix
		int row, col ; 	//absolute indices to the binary H matrix

		memset( ( void * )CH_S, 0, M * sizeof( int8_t ) ) ;

		for( r = 0 ; r < MB ; r++ ){
			offy = r * Z ;
			for( c = 0 ; c < NB ; c++ ){
				offx = c * Z ;
				shift = HBM[ r ][ c ] ;
				if( shift == -1 ){
					continue ;
				}
				assert( shift >= 0 && shift < Z ) ;

				for( k = 0 ; k < Z ; k++ ){

					col = offx + k ;
					row = ( ( k + Z - shift ) % Z ) + offy ;
	
					CH_IND[ row ][ CH_S[ row ] ] = col ;
					CH_S[ row ] += 1 ;

					assert( row >= 0 && row < M ) ;
					assert( col >= 0 && col < N ) ;
					assert( col < INT16_MAX ) ;
					assert( CH_S[ row ] <= NB ) ;
				}
			}
		}

}



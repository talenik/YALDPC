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

#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include "ldpc.h"
#include "debug.h"
#include "encoder.h"
#include "decoder.h"

int n, k, m, z ;
int b = 1000 ;	//block size
int r = 1000 ; //rounds to run
WORD *data, *code, *acc ;
FP *llch, *apll ;

int benchE = 0 ;	//benchmark encoder
int benchD = 1 ;	//benchmark decoder

int NIter 	= 10 ;
FP Norm 	= 1.0f ;
FP Offs 	= 0.0f ;
int Term 	= 0	;	// 0 > max, 1 > early


void randI( WORD *buf, int r, int c ){
	for( int i = 0 ; i < r * c ; i++ ){
		buf[ i ] = rand() % 2 ;
	} 
}

void randN( FP *buf, int r, int c ){
	for( int i = 0 ; i < r * c ; i++ ){
		buf[ i ] = 1e-3 * (FP)(rand() % 1000) ;
	}
}

void randF( float *buf, int r, int c ){
	for( int i = 0 ; i < r * c ; i++ ){
		buf[ i ] = 1e-3 * ( float )(rand() % 1000) ;
	}
}

unsigned long long sum( WORD *dst, WORD *b, int el ){
	unsigned long long s = 0 ;

	for( int i = 0 ; i < el ; i++ ){
		dst[ i ] += b[ i ] ;
		s += b[ i ] ;
	}
	return s ;
}


int main( int argc, char *argv[] ){
int i, j ;
unsigned long long s ;

clock_t t ;
double bits, sec, thr ;


#ifdef BITMAP
	n = NW ;
	k = KW ;
	m = MW ;
	z = ZW ;
#else
	n = N ;
	k = K ;
	m = M ;
	z = Z ;
#endif
	
	data = (WORD *)calloc( k * b, sizeof( WORD ) ) ;
	code = (WORD *)calloc( n * b, sizeof( WORD ) ) ;
	acc  = (WORD *)calloc( n * b, sizeof( WORD ) ) ;
	
	llch = (FP *)calloc( n * b, sizeof( FP ) ) ;
	apll = (FP *)calloc( n * b, sizeof( FP ) ) ;

	//rudimentary transmitter:

	randI( data, b, k ) ;
	if( !CheckEncoderInput( data, k, b ) ){
		printf( "Random data generator FAIL.\n" ) ;
		return 1 ;
	} 

	t = clock() ;
	if( benchE ){	//benchmark encoder
		for( i = 0 ; i < r ; i++ ){
			for( j = 0 ; j < b ; j++ ){
				QCLDPCEncode( data + j * k , code + j * n ) ;
				sum( acc + j * n, code + j * n, n ) ;
			}
		}
	}else{	//just run encoder once
		for( j = 0 ; j < b ; j++ ){
			QCLDPCEncode( data + j * k , code + j * n ) ;
			if( !Orthogonal( code + j * n, -1 ) ){
				printf( "Encoder FAIL at: %d.\n", j ) ;
				return 1 ;
			}
			sum( acc + j * n, code + j * n, n ) ;
		}
	}
	t 		= clock() - t ;
	sec 	= (double)t / CLOCKS_PER_SEC ;
	bits 	= (double)( k * b ) * (double)r ; 
	thr  	= 1e-6 * bits / sec ;
	s 		= sum( acc, acc, n * b ) ;

	printf( "Encoder: data bits: %10.0lf, took: %lf seconds, throughput: %lf Mbps, checksum: %llu.\n", bits, sec, thr, s ) ;
	
	//even more rudimentary channell model:
	for( j = 0 ; j < b ; j++ ){
		randN( llch, b, n ) ;	//now contains "AWGN noise"

		for( i = 0 ; i < n ; i++ ){
			llch[ j * n + i ] += code[ j * n + i ] ;
		}
	}

	//rudimentary receiver:

	s = 0 ;
	r /= 10 ;
	memset( (void *)code, 0, n * b * sizeof( WORD ) ) ;

	MSInitDecoder( NIter, Norm, Offs, Term ) ;

	t = clock() ;
	if( benchD ){	//benchmark decoder
		for( i = 0 ; i < r ; i++ ){
			for( j = 0 ; j < b ; j++ ){
				MSDecode( llch + j * n, apll + j * n, 1 ) ;
				HardDecision( apll + j * n, code + j * n, N ) ;
			}
		}
	}else{	//just run decoder once
		for( j = 0 ; j < b ; j++ ){
			MSDecode( llch + j * n, apll + j * n, 1 ) ;
			HardDecision( apll + j * n, code + j * n, N ) ;
		}
	}

	t 		= clock() - t ;
	sec 	= (double)t / CLOCKS_PER_SEC ;
	bits 	= (double)( k * b ) * (double)r ;
	thr  	= 1e-6 * bits / sec ;

	s = sum( acc, acc, n * b ) ;
	printf( "Decoder: data bits: %10.0lf, took: %lf seconds, throughput: %lf Mbps, checksum: %llu.\n", bits, sec, thr, s ) ;


	free( data ) ;
	free( code ) ;
	free( acc ) ;
	free( llch ) ;
	free( apll ) ;

	return 0 ;
}

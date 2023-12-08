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
#include <stdarg.h>
#include <string.h>
#include <stdint.h>

#ifdef MATLAB_MEX_FILE
	#include "mex.h"
	#include "matrix.h"
	#include "ldpc.h"
#else
	#include <stdio.h>
	#include <stdlib.h>
	//#include "test.h"
	#include "ldpc.h"
#endif

#include "debug.h"

int Debug 	= DBGLEV ;		// global debug level controls debug output

//some helpful debug functions--------------------------------------------------
void debug( int l, const char *format, ... ){
	if( Debug < l )
		return ;

	char buf[ MAX_LINE ] ;

	va_list args ;
	va_start( args, format ) ;
	vsnprintf( buf, MAX_LINE, format, args ) ;
	print( "%s", buf ) ;
	va_end( args ) ;
}

void debugArray( int l, const char *name, int *array, int r, int c, int w ){
	char format[10] ;
	sprintf( format, " %%%dd", w ) ;

	dbg( l, "%s\n", name ) ;
	for( int i = 0 ; i < r ; i++ ){
		for( int j = 0 ; j < c ; j++ ){
				dbg( l, format, (int)(*array) ) ;
			array++ ;
		}
		dbg( l, "\n") ;
	}
	dbg( l, "\n") ;
}

void debugI8Array( int l, const char *name, int8_t *array, int r, int c, int w ){
	char format[10] ;
	sprintf( format, " %%%dd", w ) ;

	dbg( l, "%s\n", name ) ;
	for( int i = 0 ; i < r ; i++ ){
		for( int j = 0 ; j < c ; j++ ){
				dbg( l, format, (int8_t)(*array) ) ;
			array++ ;
		}
		dbg( l, "\n") ;
	}
	dbg( l, "\n") ;
}

void debugI16Array( int l, const char *name, int16_t *array, int r, int c, int w ){
	char format[10] ;
	sprintf( format, " %%%dd", w ) ;

	dbg( l, "%s\n", name ) ;
	for( int i = 0 ; i < r ; i++ ){
		for( int j = 0 ; j < c ; j++ ){
				dbg( l, format, (int16_t)(*array) ) ;
			array++ ;
		}
		dbg( l, "\n") ;
	}
	dbg( l, "\n") ;
}

void word2string( unsigned char *str, WORD val, unsigned width ) {
	char c[2] = { '0', '1' } ;
	int i ;
	WORD mask ;

	for( i = width - 1 ; i >= 0 ; i-- ){
		mask = 1U << i ;
		mask = val & mask ;
		mask = mask >> i ;
		assert( mask == 0 || mask == 1 ) ;
		*str = c[ mask ] ;
		str++ ;
	}
	*str = '\0' ;
}

void debugBinary( int l, WORD *A, int size, const char *lab ){
	int i ;
	unsigned char buf[ 65 ] ;	// max WB == 64 for unsigned long long

	if( lab != NULL ){
		dbg( l, "%s:\n", lab ) ;
	}
	for( i = 0 ; i < size ; i++ ){
		word2string( buf, A[ i ], WB ) ;
		dbg( l, "%s ", buf ) ;
	}
	dbg( l, "\n") ;
}



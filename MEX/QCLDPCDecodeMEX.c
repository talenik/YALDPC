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

/*
	dont forget build switch for multithreaded version:
	CLI: -pthread
	MEX: -lpthread
*/

#include <pthread.h>
#include <assert.h>
#include <string.h>
#include <stdarg.h>
#include <errno.h>
#include <stdint.h>

#include "mex.h"
#include "matrix.h"
#include "ldpc.h"
#include "debug.h"
#include "decoder.h"

int NChan = 1 ;			//nr. of channels (MATLAB columns) to process
int NIter ;
FP Lambda ;				// normalization factor, ignored in fixed-point implementation
FP Beta ;				// offset, ignored in fixed-point implementation
int Termination = 1 ;	// 1 > early, 0 > after all NIter
int HD = 0 ;			// also return decoded bits
int No = 0 ;			// the number of output array elements is BITMAP dependent

typedef struct thread_args {
	pthread_t 	id ;
	int 		idx ;
	int 		c ;		// nr. columns to process per thread
	FP			*in ;	// chanell LLRs block for this thread
	FP			*out ;	// posterior LLRs
	WORD 		*hd ;	// decoded bits
	double 		*ite ;	// nr. of actual iterations

} THREAD_ARGS ;

THREAD_ARGS args[ N_TH ] ;

#define handle_error( en, msg ) do { errno = en ; print( msg ) ; return -1 ; } while ( 0 )

void *fun( void *args ){
	THREAD_ARGS a = *(THREAD_ARGS *)args ;

	//carefull: print statements here only work in CLI, will crash MATLAB

	for( int i = 0 ; i < a.c ; i++ ){
		a.ite[ i ] = ( double )MSDecode( a.in + i * N , a.out + i * N, a.idx ) ;
		if( a.hd != NULL ){
			HardDecision( a.out + i * N, a.hd + i * No, N ) ;
		}
	}

	pthread_exit( NULL ) ;
}

int decodeMT( FP *in, FP *out, double *ite, int n, int c, WORD *hd ){
	int t, r, cpt ;

 	assert( c % N_TH == 0 ) ;
 	assert( n == N ) ;

	cpt = c / N_TH ;	//columns per thread

	dbg(1, "Running %d threads, each processing %d columns.\n", N_TH, cpt ) ;
	for( t = 0 ; t < N_TH ; t++ ){
		args[ t ].idx 	= t ;
		args[ t ].c 	= cpt ;
		args[ t ].in 	= in + t * N * cpt ;
		args[ t ].out 	= out + t * N * cpt ;
		args[ t ].ite 	= ite + t * cpt ;
		args[ t ].hd 	= ( hd == NULL ) ? NULL : hd + t * No * cpt ;

		if( ( r = pthread_create( &( args[ t ].id ) , NULL, &fun, (void *)( args + t ) ) ) != 0 )
			handle_error( r, "pthread_create" ) ;

	}
	dbg( 1, "All threads created OK.\n" ) ;

	for( t = 0 ; t < N_TH ; t++ ){

		if(	( r = pthread_join( args[ t ].id, NULL ) )  != 0 )
			handle_error( r, "pthread_join") ;

	}
	dbg( 1, "All threads joined OK.\n" ) ;
	return 0 ;
}


#ifdef MATLAB_MEX_FILE

/*	
	MATLAB call: [ aLLR, nIter ] = QCLDPCDecodeMEX( LLCh,  Options ) ;
	Assuming: 
		Codewords is a column vector or matrix where NChan vectors are stored column-wise.
		The number of rows must be equal to N that is compiled in the auto-generated header file ldpc.h
		Options is a row vector of normal MATLAB variables (stored as double)
		Options = [ NIter, Lambda, Beta, Debuglevel ]

		TODO: Method can also be used to run unit tests
*/
	
	void getOptions( const mxArray *prhs[], int i ){
		double *opts 	= NULL ;
		
		if( !mxIsDouble( prhs[ i ] ) || mxIsComplex( prhs[ i ] ) || !( mxGetM( prhs[ i ] ) == 1 && mxGetN( prhs[ i ] ) == 5 ) ) {
			mexErrMsgIdAndTxt("LDPCEncodeMEX:optsFail", "Options vector not of size == [ 1, 5 ].") ;
		}
		if( ( opts = ( double * ) mxGetDoubles( prhs[ i ] ) ) == NULL ){
			mexErrMsgIdAndTxt("LDPCEncodeMEX:optsFail", "Options vector access failed.") ;
		}
		NIter 	= ( int )( opts[ 0 ] ) ;
		Lambda	= ( FP )( opts[ 1 ] ) ;
		Beta 	= ( FP )( opts[ 2 ] ) ;
		Debug	= ( int )( opts[ 3 ] ) ;		//global variable Debug defined in debug.h
		Termination = ( int )( opts[ 4 ] ) ;
	}
	

	void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
		FP *llrch 	= NULL ;
		FP *allr 	= NULL ;
		WORD *hd 	= NULL ;

		int i, n ;
		double *iter = NULL ;
		int singleOne = -1 ;

		if( nrhs != 2 ) {
			mexErrMsgIdAndTxt("LDPCMSDecodeMEX:nrhs", "Two inputs required: channel LLR and options.") ;
		}

		if( nlhs < 2 || nlhs > 3 ) {
			mexErrMsgIdAndTxt("LDPCMSDecodeMEX:nlhs", "Two or three outputs required: posterior LLR, nIter [,HD ] .") ;
		}
		
		if( mxGetClassID( prhs[ 0 ] ) != FP_CLASS ){
			mexErrMsgIdAndTxt("LDPCMSDecodeMEX:notFP_CLASS", "The first input must be of FP type.") ;
		}
		
    		llrch 	= ( FP * ) GET_FP( prhs[ 0 ] ) ;
		
		n		= ( int ) mxGetM( prhs[ 0 ] ) ;
		NChan	= ( int ) mxGetN( prhs[ 0 ] ) ;

		HD = 0 ;
		if( nlhs == 3 ){
			HD = 1 ;
			#ifdef BITMAP
				No = NW ;
			#else
				No = N ;
			#endif

			if( ( plhs[ 2 ] = mxCreateNumericMatrix( No, NChan, UINTXY_CLASS, mxREAL ) ) == NULL ){
				mexErrMsgIdAndTxt("LDPCMSDecodeMEX:outputFail", "Allocating HD.") ;
			}
		}


		if( n != N ){
			mexErrMsgIdAndTxt("LDPCMSDecodeMEX:rows", "Number of rows not equal to compiled N.") ;
		}

		getOptions( prhs, 1 ) ;

		dbg( 1, "Runtime params: LLCh size: %d x %d, NIter: %d, Lambda: %f, Beta: %f, Debug: %d, termination: %d, HD: %d\n", n, NChan, NIter, Lambda, Beta, Debug, Termination, HD ) ;

		dbg( 1, "Compiled in params:\n  N: %d, K: %d, M: %d, Z: %d, NB: %d, KB: %d, MB: %d, G_MAX: %d, N_TH: %d \n", N, K, M, Z, NB, KB, MB, G_MAX, N_TH ) ;
		
		debugI8Array( 1, "HBM:", ( int8_t * ) HBM, MB, NB, 3 ) ;

		if( ( plhs[ 0 ] = mxCreateNumericMatrix( n, NChan, FP_CLASS, mxREAL ) ) == NULL ){
			mexErrMsgIdAndTxt("LDPCMSDecodeMEX:outputFail", "Allocating output matrix aLLR for MATLAB failed.") ;
		}

		if( ( plhs[ 1 ] = mxCreateDoubleMatrix( 1, NChan, mxREAL ) ) == NULL ){
			mexErrMsgIdAndTxt("LDPCMSDecodeMEX:outputFail", "Allocating output vector iter for MATLAB failed.") ;
		}

		allr = ( FP * )GET_FP( plhs[ 0 ] ) ;
		iter = mxGetDoubles( plhs[ 1 ] ) ;
		
		
		singleOne = ( STD < 2 ? 1 : 0 ) ;
		
		MSInitDecoder( NIter, Lambda, Beta, Termination, singleOne ) ;
		
		//TODO maybe debug also CH_S and CH_IND buffers


		if( N_TH == 1 ){
			dbg( 1, "Decoding single thread.\n") ;
			for( i = 0 ; i < NChan ; i++ ){
				iter[ i ] = ( double )MSDecode( llrch + i * N , allr + i * N, 1 ) ;
			}

			if( HD ){
				hd = ( WORD * )GET_UINTXY( plhs[ 2 ] ) ;
				for( i = 0 ; i < NChan ; i++ ){
					HardDecision( allr + i * N, hd + i * No, N ) ;
				}
			}
		}else{
			if( NChan % N_TH != 0 ){
				mexErrMsgIdAndTxt("LDPCMSDecodeMEX:outputFail", "Nr. of columns must be dividible by nr. of threads.") ;
			}
			hd = HD ? ( WORD * )GET_UINTXY( plhs[ 2 ] ) : NULL ;
			decodeMT( llrch, allr, iter, n, NChan, hd ) ;
		}

	}
#endif








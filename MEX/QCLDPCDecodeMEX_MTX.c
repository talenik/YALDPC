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
	This is an experimental file, might need a little fiddling,
	sucessfully tested some time ago :)

*/

#include <pthread.h>
#include <stdarg.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <errno.h>

#include "mex.h"
#include "matrix.h"
#include "ldpc.h"
#include "debug.h"
#include "decoder.h"

//options from MATLAB
int NChan = 1 ;		//nr. of channels (MATLAB columns)  to process s
int NIter ;
FP Lambda ;
FP Beta ;
int Termination = 1 ;	// 1> early termination 0 > max iter termination

//output to MATLAB
volatile double *Iter = NULL ;

char EBuf[ 128 ] ;

volatile int Ran[ N_TH ] ;

volatile int Terminate = 0 ;
pthread_mutex_t Term_MTX = PTHREAD_MUTEX_INITIALIZER ;

volatile int Done = 0 ;
pthread_mutex_t Done_MTX  = PTHREAD_MUTEX_INITIALIZER ;
pthread_cond_t  Done_Cond = PTHREAD_COND_INITIALIZER ;

volatile int WTD[ N_TH ] ;
pthread_cond_t  WTD_COND = PTHREAD_COND_INITIALIZER ;
pthread_mutex_t WTD_MTX  = PTHREAD_MUTEX_INITIALIZER ;

typedef struct thread_args {
	pthread_t 	id ;
	int 		idx ;
	int 		c ;		// nr. columns to process per thread
	volatile FP	*in ;	// chanell LLRs block for this thread
	volatile FP	*out ;	// posterior LLRs
	volatile double *ite ;	// nr. of actual iterations

} THREAD_ARGS ;

THREAD_ARGS Args[ N_TH ] ;

//this assumes existence of a global output buffer EBuf, and local copy of int r
#define runSafeVerbose( code, msg ) if( ( r = code ) != 0 ) do {\
	errno = r ;\
	sprintf( EBuf, "MAINT: Error %d on line: %d: %s. Exiting.\n", r, __LINE__, msg ) ;\
	dbg( 1, EBuf ) ;\
	return ; } while ( 0 )

//this assumes existence of a global output buffer Iter, and local copy of int r
#define runSafeSilent( t, code, enr ) if( ( r = code ) != 0 ) do {\
	Iter[ t ] = -enr ;\
	pthread_exit( NULL ) ; } while ( 0 )


int checkTerminate( int t ){
	int r, term ;

	runSafeSilent( t, pthread_mutex_lock( &Term_MTX ), 4 ) ;
	term = Terminate ;
	runSafeSilent( t, pthread_mutex_unlock( &Term_MTX ), 5 ) ;
	return term ;
}

void *fun( void *arg ){
	THREAD_ARGS a = *(THREAD_ARGS *)arg ;
	int r ;

	//carefull: print statements here only work in CLI, will crash MATLAB
	while( 1 ) {

		runSafeSilent( a.idx, pthread_mutex_lock( &WTD_MTX), 1 ) ;

			while( WTD[ a.idx ] == 0 ) {
				runSafeSilent( a.idx, pthread_cond_wait( &WTD_COND, &WTD_MTX ), 2 ) ;
			}

		runSafeSilent( a.idx, pthread_mutex_unlock( &WTD_MTX), 3 ) ;

		if( checkTerminate( a.idx ) > 0 )
			break ;
		a = *(THREAD_ARGS *)arg ;
		
		Ran[ a.idx ] += 1 ;

		for( int i = 0 ; i < a.c ; i++ ){
			a.ite[ i ] = ( double )MSDecode( a.in + i * N , a.out + i * N, a.idx ) ;
		}

		runSafeSilent( a.idx, pthread_mutex_lock( &Done_MTX ), 6 ) ;
			WTD[ a.idx ] = 0 ;
			Done++ ;
			if( Done == N_TH )
				runSafeSilent( a.idx, pthread_cond_signal( &Done_Cond ), 7 ) ;

		runSafeSilent( a.idx, pthread_mutex_unlock( &Done_MTX ), 8 ) ;

		if( checkTerminate( a.idx ) > 0 )
			break ;

	}

	pthread_exit( NULL ) ;
}


//only main thread will caall this
void cleanup( void ){
	static int runTimes = 0 ;
	int t, r = 0 ;

	if( runTimes > 0 ){
		return  ;
	}
	runTimes++ ;

	Terminate = 1 ;
	for( t = 0 ; t < N_TH ; t++ ){
		WTD[ t ] = 1 ;
	}

	runSafeVerbose( pthread_cond_broadcast( &WTD_COND ), "pthread_cond_broadcast" ) ;
	dbg(1, "Terminating %d threads.\n", N_TH ) ;
	sleep( 1 ) ;

	pthread_mutex_destroy( &Term_MTX ) ;
	pthread_mutex_destroy( &Done_MTX ) ;
	pthread_mutex_destroy( &WTD_MTX ) ;
	pthread_cond_destroy( &WTD_COND ) ;

}

void init( volatile FP *in, volatile FP *out, volatile double *ite, int cpt ){
	static int runTimes = 0 ;
	int r, c, t ;
	
	if( runTimes > 0 ){
		return ;
	}

	mexAtExit( cleanup ) ;

	dbg(1, "Running %d threads, each processing %d columns.\n", N_TH, cpt ) ;
	for( t = 0 ; t < N_TH ; t++ ){
		Args[ t ].idx 	= t ;
		Args[ t ].c 	= cpt ;
		Args[ t ].in 	= in + t * N * cpt ;
		Args[ t ].out 	= out + t * N * cpt ;
		Args[ t ].ite 	= ite + t * cpt ;

		runSafeVerbose( pthread_create( &( Args[ t ].id ) , NULL, &fun, (void *)( Args + t ) ), "pthread_create" ) ;
	}
	dbg( 1, "All threads created OK.\n" ) ;
	sleep( 0.5 ) ;
}


void decodeMT( volatile FP *in, volatile FP *out, volatile double *ite, int n, int c ){
	static int runTimes = 0 ;
	int t, r, cpt ;

 	assert( c % N_TH == 0 ) ;
 	assert( n == N ) ;

	cpt = c / N_TH ;	

	if( runTimes == 0 ){	//start up the threads
		init( in, out, ite, cpt ) ;
		runTimes++ ;
		pthread_yield( ) ;
	}

	//TODO: assuming threads are allready started and are waiting
	runSafeVerbose( pthread_mutex_lock( &WTD_MTX), "pthread_mutex_lock" ) ;
		for( t = 0 ; t < N_TH ; t++ ){
			Args[ t ].in	= in + t * N * cpt ;
			Args[ t ].out	= out + t * N * cpt ;
			Args[ t ].ite 	= ite + t * cpt ;
			WTD[ t ] = 1 ;
		}

		runSafeVerbose( pthread_cond_broadcast( &WTD_COND ), "pthread_cond_broadcast" ) ;

	runSafeVerbose( pthread_mutex_unlock( &WTD_MTX), "pthread_mutex_unlock" ) ;

	
	//wait for the workers to finish
	runSafeVerbose( pthread_mutex_lock( &Done_MTX ), "pthread_mutex_lock" ) ;
		
		while( Done < N_TH ) {
			runSafeVerbose( pthread_cond_wait( &Done_Cond, &Done_MTX ), "pthread_cond_wait" ) ;
		}
		Done = 0 ;

	runSafeVerbose( pthread_mutex_unlock( &Done_MTX ), "pthread_mutex_unlock" ) ;	
	
	return ;
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
			mexErrMsgIdAndTxt("LDPCEncodeMEX:optsFail", "Options vector not of size == [ 1, 4 ].") ;
		}
		if( ( opts = ( double * ) mxGetDoubles( prhs[ i ] ) ) == NULL ){
			mexErrMsgIdAndTxt("LDPCEncodeMEX:optsFail", "Options vector access failed.") ;
		}
		NIter 	= ( int )( opts[ 0 ] ) ;
		Lambda	= ( FP )( opts[ 1 ] ) ;
		Beta 	= ( FP )( opts[ 2 ] ) ;
		Debug	= ( int )( opts[ 3 ] ) ;	//TODO: Debug defined in debug.h
		Termination = ( int )( opts[ 4 ] ) ;
	}
	

	void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
		FP *llrch 	= NULL ;
		FP *allr 	= NULL ;
		int i, n ;
		

		if( nrhs == 0 ) {
			//MATLAB call: QCLDPCDecodeMEX() with no in/out params > terminate all threads (if any)
			cleanup() ;
			return ;
		}
		
		/* check for proper number of arguments */
		if( nrhs != 2 ) {
			mexErrMsgIdAndTxt("LDPCMSDecodeMEX:nrhs", "Two inputs required: channel LLR and options.") ;
		}

		if( nlhs != 2 ) {
			mexErrMsgIdAndTxt("LDPCMSDecodeMEX:nlhs", "Two outputs required: posterior LLR and nIter .") ;
		}
		
		if( mxGetClassID( prhs[ 0 ] ) != FP_CLASS ){
			mexErrMsgIdAndTxt("LDPCMSDecodeMEX:notFP_CLASS", "The first input must be of FP type.") ;
		}
		
		/* create a pointer to the data in the input matrix */
    		llrch 	= ( FP * ) GET_FP( prhs[ 0 ] ) ;
		
		n		= ( int ) mxGetM( prhs[ 0 ] ) ;
		NChan	= ( int ) mxGetN( prhs[ 0 ] ) ;

		if( n != N ){
			mexErrMsgIdAndTxt("LDPCMSDecodeMEX:rows", "Number of rows not equal to compiled N.") ;
		}

		getOptions( prhs, 1 ) ;

		dbg( 1, "Runtime params: LLCh size: %d x %d, NIter: %d, Lambda: %f, Beta: %f, Debug: %d, termination: %d\n", n, NChan, NIter, Lambda, Beta, Debug, Termination ) ;

		dbg( 1, "Compiled in params:\n  N: %d, K: %d, M: %d, Z: %d, NB: %d, KB: %d, MB: %d, G_MAX: %d, N_TH: %d \n", N, K, M, Z, NB, KB, MB, G_MAX, N_TH ) ;
		
		debugArray( 2, "HBM:", ( int * ) HBM, MB, NB, 3 ) ;

		/*
		//debug: return index structure back to MATLAB for comparison
		if( ( plhs[ 0 ] = mxCreateNumericMatrix( G_MAX, M, mxUINT32_CLASS, mxREAL ) ) == NULL ){
			mexErrMsgIdAndTxt("LDPCMSDecodeMEX:outputFail", "Allocating CH_IND.") ;
		}
		*/


		if( ( plhs[ 0 ] = mxCreateNumericMatrix( n, NChan, FP_CLASS, mxREAL ) ) == NULL ){
			mexErrMsgIdAndTxt("LDPCMSDecodeMEX:outputFail", "Allocating output matrix aLLR for MATLAB failed.") ;
		}

		if( ( plhs[ 1 ] = mxCreateDoubleMatrix( 1, NChan, mxREAL ) ) == NULL ){
			mexErrMsgIdAndTxt("LDPCMSDecodeMEX:outputFail", "Allocating output vector iter for MATLAB failed.") ;
		}

		allr = ( FP * )GET_FP( plhs[ 0 ] ) ;
		Iter = mxGetDoubles( plhs[ 1 ] ) ;

		/*
		//debug: just test parameter passing:
		memcpy( (void *) allr, ( void * ) llrch, n * NChan * sizeof( FP ) ) ;
		memset( (void *) iter, 0, NChan * sizeof( double ) ) ;
		*/

		MSInitDecoder( NIter, Lambda, Beta, Termination ) ;
		dbg( 1, "Index structures initialized.\n") ;
		//debugArray( 2, "CH_IND", ( int * )CH_IND, Z, G_MAX, 5 ) ;

		/*
		//debug: return index structure back to matlab for comparison
		memcpy( (void *) mxGetUint32s( plhs[ 0 ] ), ( void * ) CH_IND, sizeof( CH_IND ) ) ;
		*/

		debugFPArray( 2, "LLRch:", llrch, 10, NChan, 10 ) ;
		//debugFPArray( 1, "ApLLR:", allr, 10, NChan, 10 ) ;
		//debugDoubleArray( 1, "Iter:", Iter, 1, NChan, 3 ) ;

		if( N_TH == 1 ){
			dbg( 1, "Decoding single thread.\n") ;
			for( i = 0 ; i < NChan ; i++ ){
				Iter[ i ] = ( double )MSDecode( llrch + i * N , allr + i * N, 1 ) ;
			}
		}else{
			if( NChan % N_TH != 0 ){
				mexErrMsgIdAndTxt("LDPCMSDecodeMEX:outputFail", "Nr. of columns must be dividible by nr. of threads.") ;
			}
			decodeMT( llrch, allr, Iter, n, NChan ) ;
		}

		debugVArray( 1, "RunTimes:", Ran, 1, N_TH, 3 ) ;
		debugFPArray( 2, "ApLLR:", allr, 10, NChan, 10 ) ;
		debugDoubleArray( 2, "Iter:", Iter, 1, NChan, 3 ) ;

	}
#endif








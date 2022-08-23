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
#include <string.h>
#include <stdarg.h>
#include <stdint.h>

#include "mex.h"
#include "matrix.h"
#include "ldpc.h"
#include "debug.h"
#include "encoder.h"


#ifdef MATLAB_MEX_FILE
/*	
	MATLAB call: Codewords = QCLDPCEncodeMEX( Datawords,  Options ) ;
	Assuming: 
		Datawords is a column vector or matrix where data vectors 
		are stored column-wise. 
		The number of rows must be equal to (K * MWF) / WB  that is compiled in header file.
		Options is a row vector of normal MATLAB veriables (int stored as double)
		Options = [ Debuglevel, Method ]	
		Method can also be used to run unit tests TODO		
*/
	
	void getOptions( const mxArray *prhs[], int i ){
		double *opts 	= NULL ;
		
		if( !mxIsDouble( prhs[ i ] ) || mxIsComplex( prhs[ i ] ) || !( mxGetM( prhs[ i ] ) == 1 && mxGetN( prhs[ i ] ) == 2 ) ) {
			mexErrMsgIdAndTxt("LDPCEncodeMEX:optsFail", "Options vector not of size == [ 1, 2 ].") ;
		}
		if( ( opts = ( double * ) mxGetDoubles( prhs[ i ] ) ) == NULL ){
			mexErrMsgIdAndTxt("LDPCEncodeMEX:optsFail", "Options vector access failed.") ;
		}
		Debug 	= ( int )( opts[ 0 ] ) ;	// global variable defined in debug.cpp
	}
	

	void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
		WORD *data 	= NULL ;
		WORD *par 	= NULL ;
		
		int chan, k, m, i ; 
		
		if(  nrhs != 2 ) {
			mexErrMsgIdAndTxt("LDPCEncodeMEX:nrhs", "Two inputs required: column uintXY vector or matrix and options.") ;
		}

		if( nlhs != 1 ) {
			mexErrMsgIdAndTxt("LDPCEncodeMEX:nlhs", "One output required: codeword column uintXY vector or matrix .") ;
		}
		
		if( mxGetClassID( prhs[ 0 ] ) != UINTXY_CLASS ){
			mexErrMsgIdAndTxt("LDPCEncodeMEX:notUINTXY", "The first input must be of compiled-in UINTXY type. Rebuild MEX file.") ;
		}

    	data 	= ( WORD * ) GET_UINTXY( prhs[ 0 ] ) ;
		
		k		= ( int ) mxGetM( prhs[ 0 ] ) ;		
		chan	= ( int ) mxGetN( prhs[ 0 ] ) ;

		if( chan > 1 && k == 1 ){
			mexErrMsgIdAndTxt("LDPCEncodeMEX:columns", "Row vector data are not supported.") ;
		}

		getOptions( prhs, 1 ) ;
		
		dbg( 1, "Compiled-in parameters:\n  N = %d, K = %d, M = %d, Z = %d, NB = %d, KB = %d, MB = %d\n", N, K, M, Z, NB, KB, MB ) ;
		dbg( 1, "Runtime parameters:\n Data: %d rows , %d columns , Options: %d \n", k, chan, Debug ) ;
		
		#ifdef BITMAP
			if( K % WB != 0  || N % WB != 0 || M % WB != 0 || Z % WB != 0){
				mexErrMsgIdAndTxt("LDPCEncodeMEX:parameterFail", "Bitmap encoder: N,K,M,Z must be divisible by WB.") ;
			}
			if( k != KW ){
				mexErrMsgIdAndTxt("LDPCEncodeMEX:K", "BItmap encoder: runtime k different from compiled-in KW. Rebuild MEX file.") ;
			}
			m = MW ;
		#else
			if( k != K ){
				mexErrMsgIdAndTxt("LDPCEncodeMEX:K", "Array encoder: runtime k different from compiled-in K. Rebuild MEX file.") ;
			}
			if( !CheckEncoderInput( data, k, chan ) ){
				mexErrMsgIdAndTxt("LDPCEncodeMEX:inputValuesFail", "Input not binary.") ;
			} 
			m = M ;
		#endif

		if( ( plhs[ 0 ] = mxCreateNumericMatrix( m, chan, UINTXY_CLASS, mxREAL ) ) == NULL ){
			mexErrMsgIdAndTxt("LDPCEncodeMEX:outputFail", "Allocating output parity matrix for MATLAB failed.") ;
		}
		par	= ( WORD * )GET_UINTXY( plhs[ 0 ] ) ;

		/*
		dbg( 1, "Allocated output buffer of size: M x NChan: %d x %d\n", M, NChan ) ;
		debugArray( 1, "HBM:", ( int * ) HBM, MB, NB, 3 ) ;
		*/

		for( i = 0 ; i < chan ; i++ ){
			QCLDPCEncode( data + k * i , par + m * i ) ;
		}
	}
	
#endif

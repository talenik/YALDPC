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
 This file is used with both:
	single-threaded decoderdecode.c
	multi-threaded decoder decodeMT.c
*/

#ifndef QCLDPCDEC
#define QCLDPCDEC

// initialize decoder parameters and index arrays
extern void MSInitDecoder( int niter, FP norm, FP offset, int termination, int singleOne ) ;

//extern int MSInitIndices( int rs, int8_t *ch_s, int ci, int16_t *ch_i ) ;

/*
 	 actuall layered single-scan min-sum
 	 t is only used in multithreaded implementation
 */
extern int MSDecode( FP *LLch, FP *ApLLR, int t ) ;

// 	 el is the number of codewords in block
extern void HardDecision( FP *LLr, WORD *CW, int el ) ;

// 	 convert floating point to fixed point representation
extern void Float2Fixed( float *in, FP *out, int col ) ;


/*
	check if codeword CW satisfies all the check equations
	t is only used in multithreaded implementation
*/
extern int Orthogonal( WORD *CW, int t ) ;

#endif

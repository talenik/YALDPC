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

#ifndef DEBUG_LIB

	#ifdef NDEBUG
		//aka Release build: disable all output at compile time
		#undef print
		#define print   
		#undef dbg
		//TODO: ugly hack that produces compiler warnings, but unnecessary code gets thrown out :)
		#define dbg
	#else
		//aka Debug build: enable all output compile time
		#ifdef MATLAB_MEX_FILE
			#define print mexPrintf
		#else
			#define print printf
		#endif

		#define dbg debug
	#endif
	
	#ifndef DBGLEV
		#define DBGLEV 0
	#endif
	
	#define MAX_LINE 256		// debug output buffer length
	
	extern int Debug ; // global debug level controls debug output
	
	extern void debug( int l, const char *format, ... ) ;

	extern void debugArray( int l, const char *name, int *array, int r, int c, int w ) ;

	extern void word2string( unsigned char *str, WORD val, unsigned width ) ;
	extern void debugBinary( int l, WORD *A, int size, const char *lab ) ;

#endif

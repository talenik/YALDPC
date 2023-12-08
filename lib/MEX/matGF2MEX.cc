#include <string.h>
#include <assert.h>

#ifdef MATLAB_MEX_FILE
	#include "mex.h"
	#include "matrix.h"

	#define print mexPrintf
#else
	#include <stdio.h>
	#include <assert.h>

	#define print printf
#endif

// R and C must be defined as CLI paramters to MEX

// maximal compile-time row number
#ifndef R
	#ifdef MATLAB_MEX_FILE
		#define R 128
	#else
		#define R 6 // small value for debugging - see unit tests 
	#endif
#endif

#ifndef C
	#ifdef MATLAB_MEX_FILE
		#define C 128
	#else
		#define C 8 // small value for debugging - see unit tests 
	#endif
#endif

#define C2 ( 2 * C )	

// actual size of the input from MATLAB
int M = 0 ;		//rows
int N = 0 ;		//columns

typedef bool logical ;

//the buffer for inversion calculation
logical Matrix[ R ][ C2 ] ;
logical T[ C2 ] ;

//options are used only in debugging stage
int ODebug 	= 0 ; // O[ 0 ] ;
int OReport	= 0 ; // O[ 1 ] ;
int OMethod 	= 0 ; // O[ 2 ] ;	0 > NOP, 1 > invGF, 2 > refGF, 3 > ... 


// some debugging functions ----------------------------------------------
void printMatrix( int r, int c ){
	print("Matrix:\n") ;
	for( int i = 0 ; i < r ; i++ ){
		for( int j = 0 ; j < c ; j++ ){
			print(" %d", (int)Matrix[ i ][ j ] ) ;
		}
		print("\n") ;
	}
	print("\n") ;
}

void printArray( char *name, logical *array, int r, int c ){
	print("%s\n", name ) ;
	for( int i = 0 ; i < r ; i++ ){
		for( int j = 0 ; j < c ; j++ ){
			print(" %d",(int)(*array)) ;
			array++ ;
		}
		print("\n") ;
	}
	print("\n") ;
}

//actual routines -------------------------------------------------------



inline void switchrows( int r, int c ){
	assert( r > c ) ;

	memcpy( (void *)T, (const void *)Matrix[ r ], sizeof( T ) ) ;
	memcpy( (void *)Matrix[ r ], (const void *)Matrix[ c ], sizeof( T ) ) ;
	memcpy( (void *)Matrix[ c ], (const void *)T, sizeof( T ) ) ;
}

inline void xorrows( int d, int s ){
	//xor src row to dst row from the column index equal to src row index
	for( int j = s ; j < 2 * N ; j++ ){
		Matrix[ d ][ j ] ^= Matrix[ s ][ j ] ;
	}
}



/* 
    find the row with the first leftmost one
    starting at r, c
*/
int findPivot( int r, int c ){
	int i, j ;
	
	for( j = c ; j < N ; j++ ){
		for( i = r ; i < M ; i++ ){
			if( Matrix[ i ][ j ] == 1 )
				return i ;
		}
	}
	return M ;
}

/*
	find row-echelon form
	return true rank - nr. of linearly independent rows
*/
int refGF2( int sc ) {
	int i ; // row index
	int j ; // column index
	
	for( j = sc ; j < N ; j++ ){
		i = findPivot( j, j ) ;
		if( i == M )
			return j ;
		
		if( i != j )
			switchrows( i, j ) ;
		
		//force zero in this column to all rows below 
		for( i = j + 1 ; i < M ; i++ ){
			if( Matrix[ i ][ j ] == 1 ){
				xorrows( i, j ) ;
			}
		}
	}
	return M ;
}


int invertGF2( void ){
	int i ; // row index
	int j ; // column index

	//first create upper triangular matrix on the left
	for( j = 0 ; j < M ; j++ ){
		i = j ;
		for( i = j ; i < M ; i++ )
			if( Matrix[ i ][ j ] == 1)
				break ;

		if( i == M ){
			// Matrix singular - find REF for the rest of matrix
			return i + refGF2( j ) ;	// return actual rank 
		}

		if( i != j )
			switchrows( i, j ) ;

		for( i = j + 1 ; i < M ; i++ ){
			if( Matrix[ i ][ j ] == 1 ){
				xorrows( i, j ) ;
			}
		}
	}

	//second clear all the elements above main diagonal
	for( j = M - 1 ; j > 0 ; j-- ){
		for( i = j - 1 ; i >= 0 ; i-- ){
			if( Matrix[ i ][ j ] == 1 )
				xorrows( i, j ) ;
		}
	}

	return M ;	//return full rank
}

// MEX routines -----------------------------------------------------------


void copyToMatrix( logical *input ) {
	int t ;
	for( int i = 0 ; i < M ; i++ ){
		for( int j = 0 ; j < N ; j++ ){
			//convert from MATLAB column-major to C row-major
			t = j * M + i ;
			assert( t < M * N ) ;
			Matrix[ i ][ j ] = input[ t ] ;
		}
		//also set up the identity matrix on the right side
		Matrix[ i ][ N + i ] = 1 ;
	}
}

void copyFromMatrix( logical *output, int start ){
	int t ;
	for( int i = 0 ; i < M ; i++ ){
		for( int j = start ; j < start + N ; j++ ){
			t = ( j - start ) * M + i ;
			assert( t < M * N + start ) ;
			output[ t ]  = Matrix[ i ][ j ] ;
		}
	}
}

void clearMatrix(){
	memset( (void *)Matrix, 0, R * C2 * sizeof( logical ) ) ;
}

#ifdef MATLAB_MEX_FILE
  //computational routine for MEX wrapper

  /* The gateway function:
		mex file must allways be called from matlab wrapper:
		[ MI, r ] = matGF2MEX( M, o )

		where:
			M - input matrix to be inverted
			O - options	vector (integer):
				O[0] - debug level (controls debugging output)
						0 > zero debug output
						1 > print debug output
				O[1] - report compiled-in parameters
						0 > dont report
						1 > report > MI will be a scalar  
				O[2] - select MEX function to call:
						0 > no method call, usefull for argument passing test
						1 > GF2 inverse 
						2 > GF2 row-echelon form  

			MI - output inverted matrix if M invertable or REF form of M
			r  - INV:NON-rank of M, REF:rank of M 
	*/
	void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
		logical *input 	= NULL ;
		logical *output 	= NULL ;
		mxLogical *minput 	= NULL ;
		double *opts 		= NULL ;

		int rank = -1 ;

		assert( sizeof( logical ) == sizeof( mxLogical ) ) ;


		/* check for proper number of arguments */
		if( nrhs != 2 ) {
			mexErrMsgIdAndTxt("matGF:nrhs", "Two inputs required: GF2 matrix to process and options vector.") ;
		}

		if( nlhs != 2 ) {
			mexErrMsgIdAndTxt("matGF:nlhs", "Two outputs required: Matrix and status.") ;
		}
		
		/* Check basic options parameters */
		if( !mxIsDouble( prhs[ 1 ] ) || mxIsComplex( prhs[ 1 ] ) || !( mxGetM( prhs[1] ) == 1 && mxGetN( prhs[1] ) == 3 ) ) {
			mexErrMsgIdAndTxt("matGF:optsFail", "Options vector not of size == [ 1, 3 ].") ;
		}
		if( ( opts = mxGetDoubles( prhs[ 1 ] ) ) == NULL ){
			mexErrMsgIdAndTxt("matGF:optsFail2", "Options vector access failed.") ;
		}
		ODebug  	= ( int )( opts[ 0 ] ) ;
		OReport 	= ( int )( opts[ 1 ] ) ;
		OMethod 	= ( int )( opts[ 2 ] ) ;
		
		if( OReport == 1 ){
		/* don't calculate anythig, just report the compiled-in R and C */
			if( ( plhs[ 0 ] = mxCreateDoubleScalar( ( double )R ) ) == NULL ){
				mexErrMsgIdAndTxt("matGF:coutputScalar", "Creating output scalar for MATLAB failed.") ;
			}
			if( ( plhs[ 1 ] = mxCreateDoubleScalar( ( double )C ) ) == NULL ){
				mexErrMsgIdAndTxt("matGF:coutputScalar", "Creating output scalar for MATLAB failed.") ;
			}
			return ;
		}

		/* Check basic input matrix parameters */
    		M = mxGetM( prhs[ 0 ] ) ;
		N = mxGetN( prhs[ 0 ] ) ;

		if( !mxIsLogical( prhs[ 0 ] ) ){
			mexErrMsgIdAndTxt("matGF:notLogical", "The first input must be a logical matrix.") ;
		}

		if( M > R || N > C ){
			mexErrMsgIdAndTxt("matGF:tooBig", "Input matrix size too large. Rebuild MEX file.") ;
		}

		/* create a pointer to the logical data in the input matrix */
    		minput = mxGetLogicals( prhs[ 0 ] ) ;
		input  = (logical *)minput ;

    		/* create the output matrix for inversion: */
		plhs[ 0 ] = mxCreateLogicalMatrix( M, N ) ;
		if( plhs[ 0 ] == NULL ){
			mexErrMsgIdAndTxt("matGF:outputFail", "Allocating output matrix for MATLAB failed.") ;
		}

		output	= (logical *)mxGetData( plhs[ 0 ] ) ;

		clearMatrix() ;

    		copyToMatrix( input ) ;

		
		if( ODebug ){
			print("MEX options: ODebug = %d, OReport = %d, OMethod = %d \n", ODebug, OReport, OMethod ) ;
			printMatrix( M, 2 * N ) ;
		}
		
		if( OMethod == 1 ){
			rank = refGF2( 0 ) ;				// actual rank
			copyFromMatrix( output, 0 ) ; // return row-echelon form
		}
		if( OMethod == 2 ){
			rank = invertGF2() ;	// success indicator: rank
			copyFromMatrix( output, N ) ; // return inverse matrix 
		}
		
		if( ( plhs[ 1 ] = mxCreateDoubleScalar( (double)rank ) ) == NULL ){
			mexErrMsgIdAndTxt("matGF:coutputScalar", "Creating output scalar for MATLAB failed.") ;
		}
		
	}

#endif

#ifndef MATLAB_MEX_FILE

	void run( logical *in, logical *out, int method ){
		int r ;
		printArray( (char *)&"input", in, M, N ) ;
		copyToMatrix( in ) ;
		printMatrix( M, 2 * N ) ;
		
		if( method == 2 )
			r = invertGF2() ;
		else
			r = refGF2( 0 ) ;
		
		print("rank == %d\n", r ) ;
		printMatrix( M, 2 * N ) ;

		copyFromMatrix( out, 0 ) ;
		printArray((char *)&"output", out, M, N ) ;

	}

	void test1( void ){
		M = 4 ;
		N = M ;
		assert( M == R ) ;
		assert( N <= C ) ;
		//this is a rank 3 matrix
		logical input[4][4]  = {{ 0, 1, 0, 1 }, { 1, 0, 1, 1 },{ 0, 0 ,1 ,0 },{ 1, 1, 0, 0 } } ;
		logical output[4][4] = {{ 0, 0, 0, 0 }, { 0, 0, 0, 0 },{ 0, 0 ,0 ,0 },{ 0, 0, 0, 0 } } ;
		run( (logical *)input, (logical *)output, 0 ) ;
	}

	void test2( void ){
		M = 4 ;
		N = M ;
		assert( M == R ) ;
		assert( N <= C ) ;
		//this is a full rank matrix
		logical input[ M ][ M ]  = {{ 0, 0, 0, 1 }, { 0, 0, 1, 0 },{ 0, 1 ,0 ,0 },{ 1, 0, 0, 0 } } ;
		logical output[ M ][ M ] = {{ 0, 0, 0, 0 }, { 0, 0, 0, 0 },{ 0, 0 ,0 ,0 },{ 0, 0, 0, 0 } } ;
		run( (logical *)input, (logical *)output, 0 ) ;
	}

	void test3( void ){
		M = 6 ;
		N = M ;
		assert( M == R ) ;
		assert( N <= C ) ;
		logical input[ M ][ N ]  = {
			{ 0, 0, 1, 1, 1, 1 },
			{ 0, 1, 1, 1, 1, 1 },
			{ 1, 1, 1, 0, 1, 1 },
			{ 1, 1, 1, 0, 1, 0 },
			{ 1, 1, 1, 1, 0, 0 },
			{ 0, 1, 1, 0, 1, 0 }
		} ;
		logical output[ M ][ N ] = {
			{ 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 0, 0, 0, 0 }
		} ;
		run( (logical *)input, (logical *)output, 0 ) ;

	}
	
	void test4( void ){
		M = 4 ;
		N = 6 ;
		assert( M <= R ) ;
		assert( N <= C ) ;
		logical input[ M ][ N ]  = {
			{ 0, 0, 1, 1, 1, 1 },
			{ 0, 1, 1, 1, 1, 1 },
			{ 1, 1, 1, 0, 1, 1 },
			{ 1, 1, 1, 0, 1, 0 }
		} ;
		logical output[ M ][ N ] = {
			{ 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 0, 0, 0, 0 }
		} ;		
		
		run( (logical *)input, (logical *)output, 1 ) ;
	}
		

	int main( int argc, char *arg[] ){
		printf("Running unit tests.\n") ;

		test4() ;

		return 0 ;
	}
#endif

//legacy code:



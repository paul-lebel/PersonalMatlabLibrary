#include "mex.h"
#include <omp.h>

// Once compiled as a MEX file, gsolve2d.c can be used as a 
// Matlab function with accelerated performance for image stacks. The function takes 
// a linearized stack of images as input (as well as a vector containing 
// the single frame dimensions), and outputs the fitted parameters into an 
// array with dimensions nFrames x 6, where nFrames is the number of images in the stack 
// and 6 is the number of fitted parameters. The least squares minimization
// is executed simultaneously on all images in the stack, minimizing
// the number of slow data transfer events between RAM and the CPU. 

// Usage from Matlab: 
// stats = gsolve2d(imageVector, dims)

// Input arguments:
// imageVector is a linear vector of image data, as would be produced by
// entering imageStack(:), where imageStack is a 3D array of images with 
// dimensions [nRows nCols nFrames]

// dims are the dimensions of a single frame; dims = [nRows nCols]

// Output arguments:
// stats is an array of dimensions [nFrames 6], where each row contains the 
// Gaussian fitting parameters for each corresponding frame. 
// Stats columns:   1 = c
//                  2 = A
//                  3 = xo
//                  4 = yo
//                  5 = sigma_x
//                  6 = sigma_y
// Where f = c + A*exp( -((x-xo)^2)/(2*sigma_x^2) - ((y-yo)^2)/(2*sigma_y^2) 

// Example usage:
// stats = gsolve2d(imageStack(:),[10 10]);
// where size(imageStack) = [10 10 10000]
//
// Author: Paul Lebel

void mexFunction( int nlhs, mxArray *left[]
                , int nrhs, const mxArray *right[]) {

	int num_row, num_col, num_pix, num_frm, img_size, i, j, k, m, iter, conv;	
	mxArray *pmx_Images, *pmx_Parms;
	double *pd_Images, *pd_Parms, *pd_Output;
	double **A, **B, **Img, **K, **X, **R, *pd_x, *pd_y;
	double *pd_Atempj, *pd_Atempk, *pd_Ktemp, *pd_Ltemp;
	double *pd_inv_sig_x_sq, *pd_inv_sig_y_sq, *pd_inv_sig_x_cu, *pd_inv_sig_y_cu, *fact;
	double temp, temp1, temp2, temp1s, temp2s, tol = 0.01;
	
	// Check for proper number of arguments
	if (nrhs != 2) {
		mexErrMsgTxt("(gsolve2d) ");
	} else if (nlhs > 1) {
		mexErrMsgTxt("(gsolve2d) ");
	}
	
	// Access input data
	pmx_Images   = right[0];
	num_pix      = mxGetM(pmx_Images);
	num_col      = mxGetN(pmx_Images);
	pd_Images    = mxGetData(pmx_Images);
	if (num_col != 1) {
		mexErrMsgTxt("(gsolve2d) Incorrect Image Array");
	}
	
	pmx_Parms  = right[1];
	num_row    = mxGetM(pmx_Parms);
	num_col    = mxGetN(pmx_Parms);
	pd_Parms   = mxGetData(pmx_Parms);
	if (num_col < 2) {
		mexErrMsgTxt("(gsolve2d) Image Size Parameter missing");
	}
	if (num_col >= 3) {
		tol = pd_Parms[2];
	}
	img_size = (int)(pd_Parms[0] * pd_Parms[1]);
	num_frm = num_pix / img_size;
	if(num_frm * img_size != num_pix) {
		mexErrMsgTxt("(gsolve2d) Total pixels are inconsistent with image frame size specified");
	}
	
	A               = mxCalloc(img_size * 6, sizeof(double*));  // Gradients
	B               = mxCalloc(img_size    , sizeof(double*));  // Image error
	Img             = mxCalloc(img_size    , sizeof(double*));  // Reshaped image
	K               = mxCalloc(36          , sizeof(double*));  // Squared Gradient array
	pd_x            = mxCalloc(img_size    , sizeof(double));  // Pixel x coordinate
	pd_y            = mxCalloc(img_size    , sizeof(double));  // Pixel y coordinate
	pd_inv_sig_x_sq = mxCalloc(num_frm     , sizeof(double));  // Sigma x squared
	pd_inv_sig_y_sq = mxCalloc(num_frm     , sizeof(double));  // Sigma y squared
	pd_inv_sig_x_cu = mxCalloc(num_frm     , sizeof(double));  // Sigma x squared
	pd_inv_sig_y_cu = mxCalloc(num_frm     , sizeof(double));  // Sigma y squared
	
	fact = pd_inv_sig_x_sq;   // The same space is used for a scaling factor
	
	// X is: [0]=offset, [1]=peak value, [2]=peak x, [3]=peak y, [4]=sigma x, [5]=sigma y
	X   = mxCalloc(6           , sizeof(double*));
	
	// R is for  "A'" * "B"
	R   = mxCalloc(6           , sizeof(double*));
	
	for(i = 0 ; i < 6 ; i++){
		X[i] = mxCalloc(num_frm, sizeof(double));
		R[i] = mxCalloc(num_frm, sizeof(double));
		for(j = 0 ; j < 6 ; j++){
			K[i + j * 6] = mxCalloc(num_frm, sizeof(double));
		}
	}
	
	// temp is for initial estimate of sigma
	temp = pow((double)img_size, 0.5) / 5;
	for(i = 0 ; i < img_size ; i++){
		Img[i] = mxCalloc(num_frm, sizeof(double));
		B[i]   = mxCalloc(num_frm, sizeof(double));
		for(j = 0 ; j < 6 ; j++){
			A[i + j * img_size] = mxCalloc(num_frm, sizeof(double));
		}
		pd_y[i] = (double)(i / (int) pd_Parms[1]);
		pd_x[i] = (double)(i - (int)((pd_y[i] * pd_Parms[1])));
		
		// Initialise first "guess" of X's
		for(j = 0 ; j < num_frm ; j++){
			(Img[i])[j] = pd_Images[j * img_size + i];
			if(((Img[i])[j]) > (X[1])[j]){
				(X[0])[j] = 0;
				(X[1])[j] = Img[i][j];
				(X[2])[j] = pd_x[i];
				(X[3])[j] = pd_y[i];
				(X[4])[j] = temp;
				(X[5])[j] = temp;
			}
		}
	}
	

		mexPrintf("\n");

	
	// Start of solution loop
	for(iter = 0 ; iter < 60 ; iter++){
		conv = 1;
		
		// Values that are independent of the x and y and get reused a lot
		for(k = 0 ; k < num_frm ; k++){
			pd_inv_sig_x_sq[k] = 1.0 / (X[4][k] * X[4][k]);
			pd_inv_sig_y_sq[k] = 1.0 / (X[5][k] * X[5][k]);
			pd_inv_sig_x_cu[k] = 1.0 / (X[4][k] * X[4][k] * X[4][k]);
			pd_inv_sig_y_cu[k] = 1.0 / (X[5][k] * X[5][k] * X[5][k]);
		}
		
		// Calculate gradients "A" and error "B"
		for(i = 0 ; i < img_size ; i++){    // Each pixel
			
			for(k = 0 ; k < num_frm ; k++){    // Each image
				
				// Values that get reused for this pixel location
				temp1 = pd_x[i] - X[2][k];
				temp1s = temp1 * temp1;
				temp2 = pd_y[i] - X[3][k];
				temp2s = temp2 * temp2;
				
				temp  = exp(-temp1s * 0.5 * pd_inv_sig_x_sq[k] - temp2s * 0.5 * pd_inv_sig_y_sq[k]); // expensive calculation
				
				// Constant derivative
				A[i][k] = 1;
				
				// Magnitude derivative
				A[i + img_size][k]     = temp;
				
				// X derivative
				A[i + 2 * img_size][k] = X[1][k] * temp1 * temp * pd_inv_sig_x_sq[k];  
				
				// Y derivative
				A[i + 3 * img_size][k] = X[1][k] * temp2 * temp * pd_inv_sig_y_sq[k];  
				
				// sig_x derivative
				A[i + 4 * img_size][k] = X[1][k] * temp1s * pd_inv_sig_x_cu[k] * temp; 
				
				// sig_y derivative
				A[i + 5 * img_size][k] = X[1][k] * temp2s * pd_inv_sig_y_cu[k] * temp;  
				
				// B (error term)
				B[i][k] = Img[i][k] - (X[0][k] + X[1][k] * temp); 
			}
			
		}
		
		
		
		// This squares the A matrix = A' * A, Using A' as input  - A' means the transpose of A
		for(j = 0 ; j < 6 ; j++){
			
			for(k = j ; k < 6 ; k++){  // Only need upper triangular; matrix is symmetric
				pd_Ktemp  = K[6*j + k];
				pd_Ltemp  = K[6*k + j];
				
				// Zero "k" array
				for(m = 0 ; m < num_frm ; m++){    // Each image
					pd_Ktemp[m] = 0;
				}
				
				for(i = 0 ; i < img_size ; i++){    // Each pixel
					pd_Atempj = A[i + j*img_size];
					pd_Atempk = A[i + k*img_size];
					
					for(m = 0 ; m < num_frm ; m++){    // Each image
						pd_Ktemp[m] += pd_Atempj[m] * pd_Atempk[m];
					}
				}
				
				if(k != j) {
					for(m = 0 ; m < num_frm ; m++){
						pd_Ltemp[m] = pd_Ktemp[m];
					}
				}
			}
			
			// Calculate A' * B
			pd_Ktemp  = R[j];
			
			// Zero "R" array
			for(m = 0 ; m < num_frm ; m++){    // Each image
				pd_Ktemp[m] = 0;
			}
			
			for(i = 0 ; i < img_size ; i++){    // Each pixel
				pd_Atempj = A[i + j*img_size];
				pd_Atempk = B[i];
				
				for(m = 0 ; m < num_frm ; m++){    // Each image
					pd_Ktemp[m] += pd_Atempj[m] * pd_Atempk[m];
				}
			}
		}
		

		
		
		// Use elimination approach to solve
		// forward elimination
		for(i = 0 ; i < 6 ; i++){
			
			// Normalise current row
			pd_Ktemp  = K[7*i];  // diagonal element
			for(m = 0 ; m < num_frm ; m++){    // Each image
				fact[m] = 1 / pd_Ktemp[m];
			}
			for(j = i ; j < 6 ; j++){
				pd_Ktemp  = K[6*i+j];  // first element of row below i's diagonal
				for(m = 0 ; m < num_frm ; m++){    // Each image
					pd_Ktemp[m] = pd_Ktemp[m] * fact[m];
				}
			}
			for(m = 0 ; m < num_frm ; m++){    // Each image
				R[i][m] = R[i][m] * fact[m];
			}
			
			// Each row below current (normalised) one
			for(j = i+1 ; j < 6 ; j++){    // row j
				pd_Ktemp = K[6*j+i];     // ith element of row j;
				for(m = 0 ; m < num_frm ; m++){    // Each image
					fact[m] = -pd_Ktemp[m];  // Factor
				}
				for(k = i ; k < 6 ; k++){  // The rest of row j
					pd_Ltemp =  K[6*i+k];  // kth element of row i
					pd_Ktemp  = K[6*j+k];  // kth element of current row
					for(m = 0 ; m < num_frm ; m++){    // Each image
						pd_Ktemp[m] = pd_Ktemp[m] + fact[m] * pd_Ltemp[m];
					}
				}
				for(m = 0 ; m < num_frm ; m++){    // Each image
					R[j][m] = R[j][m] + fact[m] * R[i][m];
				}
			}
		}
		
		
		// backward elimination
		for(i = 5 ; i > 0 ; i--){
			
			// Each row above current one
			for(j = 0 ; j < i ; j++){    // row j
				pd_Ktemp = K[6*j+i];     // ith element of row j;
				for(m = 0 ; m < num_frm ; m++){    // Each image
					fact[m] = -pd_Ktemp[m];  // Factor
				}
				k = i;
				pd_Ltemp =  K[6*i+k];  // kth element of row i+1
				pd_Ktemp  = K[6*j+k];  // kth element of current row
				for(m = 0 ; m < num_frm ; m++){    // Each image
					pd_Ktemp[m] = pd_Ktemp[m] + fact[m] * pd_Ltemp[m];
				}
				for(m = 0 ; m < num_frm ; m++){    // Each image
					R[j][m] = R[j][m] + fact[m] * R[i][m];
				}
			}
		}
		
		// Update X's
		for(m = 0 ; m < num_frm ; m++){    // Each image
			if(abs(R[4][m]) > 0.001){
				fact[m] = 0.3 * abs(X[4][m] / R[4][m]);
				fact[m] = fact[m] > 1 ? 1 : fact[m];
			} else {
				fact[m] = 1;
			}
			if(abs(R[5][m]) > 0.001){
				temp = 0.3 * abs(X[5][m] / R[5][m]);
				fact[m] = temp < fact[m] ? temp : fact[m];
			}
			if(abs(R[2][m]) > 0.001){
				temp = 0.3 * abs(X[2][m] / R[2][m]);
				fact[m] = temp < fact[m] ? temp : fact[m];
			}
			if(abs(R[3][m]) > 0.001){
				temp = 0.3 * abs(X[3][m] / R[3][m]);
				fact[m] = temp < fact[m] ? temp : fact[m];
			}
			if(abs(R[1][m]) > 0.001){
				temp = 0.3 * abs(X[1][m] / R[1][m]);
				fact[m] = temp < fact[m] ? temp : fact[m];
			}
		}
		for(i = 0 ; i < 6 ; i++){
			for(m = 0 ; m < num_frm ; m++){    // Each image
				X[i][m] = X[i][m] + R[i][m] * fact[m];
				if(abs(R[i][m]) > tol) conv = 0;
			}
		}
		

		if(conv == 1) break;
		
	}
	mexPrintf("\n Least squares converged after %i iterations\n", iter);
	
	if(nlhs>0){
		left[0] = mxCreateDoubleMatrix(num_frm, 6,  mxREAL);
		pd_Output   = mxGetData(left[0]);
		for(i = 0 ; i < 6 ; i++){
			j = i * num_frm;
			for(m = 0 ; m < num_frm ; m++){    // Each image
				pd_Output[j + m] = X[i][m];
			}
		}
	}
	
	
	for(i = 0 ; i < 6 ; i++){
		mxFree(X[i]);
		mxFree(R[i]);
		for(j = 0 ; j < 6 ; j++){
			mxFree(K[i + j * 6]);
		}
	}
	
	for(i = 0 ; i < img_size ; i++){
		mxFree(Img[i]);
		mxFree(B[i]);
		for(j = 0 ; j < 5 ; j++){
			mxFree(A[i + j * img_size]);
		}
	}
	
	mxFree(A);
	mxFree(X);
	mxFree(R);
	mxFree(B);
	mxFree(Img);
	mxFree(pd_x);
	mxFree(pd_y);
	mxFree(pd_inv_sig_x_sq);
	mxFree(pd_inv_sig_y_sq);
	mxFree(pd_inv_sig_x_cu);
	mxFree(pd_inv_sig_y_cu);
}

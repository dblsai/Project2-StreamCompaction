#include <cuda.h>
#include <thrust/copy.h>
#include "ParallelReductioin.h"
#include "stdio.h"

// #if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ < 200) 
// # error printf is only supported on devices of compute capability 2.0 and higher, please compile with -arch=sm_20 or higher 
// #endif

cudaEvent_t start, stop;
float timeDuration;
int * OUTd, * INd, * TMPd;
int LEN;
int * SUMS;   //auxilary memory to store the sums for each block

struct is_odd
  {
    __host__ __device__
    bool operator()(const int x)
    {
      return (x % 2) == 1;
    }
  };

__device__ int predictCondition(int a){
	if( a % 2 == 0 ){   //the condition here
		return 0;
	}
	else{
		return 1;
	}
}

//parallelize this using a series of kernel calls
//NOT allowed to use shared memory
__global__ void globalReduction(int* INd, int * OUTd, int * TMPd, int LENd){
	int index = threadIdx.x + blockIdx.x * blockDim.x;

	int p2 = 0, p1 = 1, tmp; 
	//predict
	if(index<LENd){
		TMPd[index] = (threadIdx.x==0 && blockIdx.x ==0)? 0:predictCondition (INd[index-1]);
	}
	__syncthreads();

	//scan
	int round = (int)ceil( log2( (double)LENd ) );
	for(int d =1; d<=round; d++){
		//swap left and right buffer
		tmp = p2; p2 = 1-tmp;p1 = tmp;  
		int num = (int)std::pow((float)2,(float)(d-1));
		if(index<LENd){
			if(index>=num){
				
				TMPd[p2*LENd + index] = TMPd[ p1*LENd + index ] + TMPd[ p1*LENd + index - num];
			}
			else{
				TMPd[p2*LENd + index] = TMPd[ p1*LENd + index ];
			}
		}
		__syncthreads();
	}

	//scatter
	//OUTd[index] = TMPd[p2*LENd + index];
	if( index < LENd && predictCondition (INd[index]) == 1 ){
		//OUTd[index] = TMPd[p2*LENd + index];
		OUTd[TMPd[p2*LENd + index]] = INd[index];
	}
	
}

//works on a single block
//shared memory
__global__ void sharedReductionSingle(int *INd, int * OUTd, int LENd){
	extern __shared__ int sharedOUT[];  // allocated on invocation, double buffer  
	int tx = threadIdx.x;

	int p2 = 0, p1 = 1, tmp; 
	//sharedOUT [ p2*LENd + tx ] = OUTd[tx];  
	//sharedOUT [ p2*LENd + tx ] = (tx > 0) ? INd[tx-1] : 0;   //shift to right, store in left buffer
	if(tx<LENd){
		sharedOUT [ p2*LENd + tx ] = (tx>0) ? predictCondition(INd[tx-1]) : 0;
	}
	__syncthreads(); 

	//scan
	int round = ceil( log2( (double)LENd ) );
	for(int d =1; d<=round; d++){
		//swap left and right buffer
		tmp = p2; p2 = 1-tmp; p1 = tmp;  
		int num = (int)std::pow((float)2,(float)(d-1));
		if(tx<LENd){
			if(tx>=num){
				sharedOUT[p2*LENd + tx] = sharedOUT[ p1*LENd + tx ] + sharedOUT[ p1*LENd + tx - num];
			}
			else{
				sharedOUT[p2*LENd + tx] = sharedOUT[ p1*LENd + tx ];
			}
		}
		__syncthreads();
	}

	//scatter
	if(tx<LENd && predictCondition (INd[tx]) == 1){
		OUTd[sharedOUT[ p2*LENd + tx]] = INd[tx];
	}
}


/*__global__ void prescan(int *g_odata, int *g_idata, int n)  
{  
	extern __shared__ float temp[];  // allocated on invocation  
	int thid = threadIdx.x;  
	int offset = 1;  

	temp[2*thid] = g_idata[2*thid]; // load input into shared memory  
	temp[2*thid+1] = g_idata[2*thid+1];

	 // build sum in place up the tree	
	for (int d = n>>1; d > 0; d >>= 1){  
		__syncthreads();  
		if (thid < d)  {  
			int ai = offset*(2*thid+1)-1;  
			int bi = offset*(2*thid+2)-1;  
			temp[bi] += temp[ai];  
		}  
		offset *= 2;  
	}
	if (thid == 0) { temp[n - 1] = 0; } // clear the last element  
                 
	// traverse down tree & build scan 
	for (int d = 1; d < n; d *= 2){  
		 offset >>= 1;  
		 __syncthreads();  
		 if (thid < d){  
			int ai = offset*(2*thid+1)-1;  
			int bi = offset*(2*thid+2)-1;  
			float t = temp[ai];  
			temp[ai] = temp[bi];  
			temp[bi] += t;   
		  }  
	}  
	 __syncthreads();  

	g_odata[2*thid] = temp[2*thid]; // write results to device memory  
	g_odata[2*thid+1] = temp[2*thid+1];  
 	
}  */

//fit for length bigger that a block capacity
//shared memory
__global__ void sharedReductionMultiple(int * INd,  int * OUTd, int LENd, int * SUMS){

	extern __shared__ int sharedOUT2[];
	//int half = (int)ceil(((float)BlockSize)/((float)2));
	int half = blockDim.x;
	int tx = threadIdx.x;
	int bx = blockIdx.x;
	int index = tx + bx*half;   //index to access global memory
	int p2 = 0, p1 = 1, tmp; 
	 
	//establish shared memory
	if(index < LENd ){
		sharedOUT2 [ p2*half+ tx ] = (tx==0 && bx==0)? 0:predictCondition (INd[index - 1]);
	}
	__syncthreads();

	//scan for a block
	int round = ceil( log2( (double)half) );
	for(int d =1; d<=round; d++){
		//swap left and right buffer
		tmp = p2; p2 = 1-tmp; p1 = tmp;  
		int num = (int)std::pow((float)2,(float)(d-1));
		if( tx<half ){
			if(tx>=num){
				sharedOUT2[ p2*half + tx] = sharedOUT2[ p1*half + tx ] + sharedOUT2[ p1*half + tx - num];
			}
			else{
				sharedOUT2[ p2*half + tx] = sharedOUT2[ p1*half + tx ];
			}
		}
		__syncthreads();
	}

	//add auxilary sum
	SUMS[bx] = sharedOUT2[ p2*half + half-1] ;
	if(bx>0){
		for(int k =0; k < bx; k++){
			sharedOUT2[ p2*half + tx] += SUMS[k];
			sharedOUT2[ p1*half + tx] += SUMS[k];
		}
	}
	__syncthreads();
	//scatter
	if( index < LENd && predictCondition (INd[index]) ==1 ){
		OUTd[ sharedOUT2[ p2*half + tx ] ] = INd[ index ];
	}
	
}

void ParallelReduction(int * IN, int * OUT, int Len, int OPERATION){
	LEN = Len;

	//load OUT device memory
	const int size = LEN*sizeof(int);
	cudaMalloc((void**)&OUTd, size);
	cudaMemcpy(OUTd, OUT, size, cudaMemcpyHostToDevice);
	cudaMalloc((void**)&INd, size);
	cudaMemcpy(INd, IN, size, cudaMemcpyHostToDevice);
	cudaMalloc((void**)&TMPd, 2*size);   //double buffer array

	//cuda timer event
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	//kernel invocation
	switch(OPERATION){

	case GLOBAL_MEM:     //parallel reduction in global memory
		{
			cudaEventRecord( start, 0 );
			dim3 dimGrid((int)ceil((float)LEN/(float)BLOCK_SIZE),1);    //blocks per grid
			dim3 dimBlock(BLOCK_SIZE,1);    //threads per block
			globalReduction<<<dimGrid, dimBlock>>>(INd, OUTd, TMPd, LEN);
			cudaEventRecord( stop, 0 );
			cudaEventSynchronize( stop );
			cudaEventElapsedTime( &timeDuration, start, stop );
			printf("\n\n\n*****************************************************\n");
			printf("Time Taken for GPU Global Memory : %f ms\n",timeDuration);
			printf("*****************************************************\n");
			break;
		}
	case SHARED_MEM_1:   //parallel reduction on shared memory with single block
		{
			dim3 dimGrid1(1,1);    //blocks per grid
			dim3 dimBlock1(LEN,1);    //threads per block

			cudaEventRecord( start, 0 );
			sharedReductionSingle<<<dimGrid1, dimBlock1, 2*size>>>(INd, OUTd, LEN);
			cudaEventRecord( stop, 0 );
			cudaEventSynchronize( stop );
			cudaEventElapsedTime( &timeDuration, start, stop );
			printf("\n\n\n*****************************************************\n");
			printf("Time Taken for GPU Shared Memory Single: %f ms\n",timeDuration);
			printf("*****************************************************\n");
			break;
		}
	case SHARED_MEM_N:
		{
			int blocknum = 2* (int)ceil((float)LEN/(float)BLOCK_SIZE);
			dim3 dimGrid2(blocknum,1);    //blocks per grid, N/B
			dim3 dimBlock2((int)ceil((float)BLOCK_SIZE/(float)2),1);    //threads per block, B/2
			cudaMalloc((void**)&SUMS, blocknum*sizeof(int));
			cudaEventRecord( start, 0 );
			sharedReductionMultiple<<<dimGrid2, dimBlock2, BLOCK_SIZE*sizeof(int)>>>(INd, OUTd, LEN , SUMS);
			cudaEventRecord( stop, 0 );
			cudaEventSynchronize( stop );
			cudaEventElapsedTime( &timeDuration, start, stop );
			printf("\n\n\n*****************************************************\n");
			printf("Time Taken for GPU Shared Memory Multiple: %f ms\n",timeDuration);
			printf("*****************************************************\n");
			break;
		}

		case THRUST:
		{
			cudaEventRecord( start, 0 );
			thrust::copy_if(IN, IN + LEN, OUT, is_odd());
			cudaEventRecord( stop, 0 );
			cudaEventSynchronize( stop );
			cudaEventElapsedTime( &timeDuration, start, stop );
			printf("\n\n\n*****************************************************\n");
			printf("Time Taken for Thrust Method: %f ms\n",timeDuration);
			printf("*****************************************************\n");
			break;
		}

	}

	//read OUT from device
	cudaMemcpy(OUT, OUTd, size, cudaMemcpyDeviceToHost);

	//free memory
	cudaFree(OUTd);
	cudaFree(INd);
	cudaFree(SUMS);
	cudaFree(TMPd);

	//destroy timer event
	cudaEventDestroy( start );
	cudaEventDestroy( stop );
}
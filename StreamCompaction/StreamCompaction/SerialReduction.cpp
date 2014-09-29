#include "SerialReduction.h"



int ExclusiveScanInSequential(int * inArray,    // input array 
							int * outArray,	    // output array
							int len)            // length of input array
{
	int * flagArray = new int[len];   //stores condiction check results
	int * scanArray = new int[len];    //stores scan results
	//predict
	for(int i=0; i<len; i++){
		flagArray[i] = checkCondition(inArray[i]);
	}
	//scan
	scanArray[0] = 0;   //exclusive scan always start with 0
	if(len>1){
		for(int i=1; i<len+1; i++){
			scanArray[i] = flagArray[i-1] + scanArray[i-1];
		}
	}
	//scatter
	for(int k=0; k<len;k++){
		if(flagArray[k]==1){
			outArray[scanArray[k]] = inArray[k];
		}
	}

	/*outArray[0] = 0;   
	if(len>1){
		for(int i=1; i<len+1; i++){
			outArray[i] = inArray[i-1] + outArray[i-1];
		}
	}*/

	return findMax(scanArray, len);
}

/*void ScatterInSequential(int * inputArray,    // condition array 
						int * scanArray,	    // scanned array
						int * resultArray,	   // result array
						int len)            // length of initial array
{
	for(int k=0; k<len;k++){
		resultArray[scanArray[k]] = inputArray[k];
	}
}*/


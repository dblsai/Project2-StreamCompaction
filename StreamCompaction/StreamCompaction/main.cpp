// StreamCompaction.cpp : Defines the entry point for the console application.
//

#include <sstream>
#include <stdio.h>
#include <iostream>
#include <time.h>
//#include <boost/chrono.hpp>
//#include <chrono>
//#include <ctime>
#include "ParallelReductioin.h"
#include "SerialReduction.h"
#include "utility.h"

#define ARGUMENTS 0   // 1/0 to on/off command line arguments
#define COMMAND 0   // 1/0 to on/off command line input
#define FIXED 1   // 1/0 to on/off fixed input {3 1 7 0 4 1 6 3}

// CPU sequential version of stream compaction
// exclusive scan


int main(int argc, char* argv[])
{
	int LEN;
	int * input,*output, *result, *condition;
	std::stringstream buffer;
	
	//fixed array
	if(FIXED){
	/*	LEN = 8;
		input = new int[LEN];
		output = new int[LEN+1];
		condition = new int[LEN];
		input[0] = 3; input[1] = 1; input[2] = 7; input[3] = 0;
		input[4] = 4; input[5] = 1; input[6] = 6; input[7] = 3;*/

		LEN = 300;
		input = new int[LEN];
		//condition = new int[LEN];
		output = new int[LEN+1];
		for(int i =0; i<LEN; i++){
			input[i] = i+1;
		}
		
	}

	//initialize from command line arguments
	else if(ARGUMENTS){
		LEN = atoi(argv[1]);    //argv[0] is program name
		if(argc != LEN + 2){
			std::cout<<"Incorrecgt Command Line Augument."<<std::endl;
			return 1;
		}
		input = new int[LEN];
		output = new int[LEN+1];
		for(int i=0; i<LEN; i++){
			input[i] = atoi(argv[i+2]);
		}
	}

	//inintialize array from command line input
	else if(COMMAND){
		std::cout << "Please input the length of input array " << std::endl;
		std::cin >> LEN;
		input = new int[LEN];
		output = new int[LEN+1];
		std::cout << "Length of input array is " << LEN << std::endl;
		std::cout << "Now please enter each element of the array " << std::endl;
		for(int i=0; i<LEN; i++){
			std::cin >> input[i];
		}
	}
	//CPU version
	//boost::timer timer;
	//timer_start = std::time(NULL);   //get current time
	clock_t timer_start = clock();
	//auto timer_start = boost::chrono::high_resolution_clock::now();
	int newLEN = ExclusiveScanInSequential(input, output, LEN+1);
	//auto timer_stop = boost::chrono::high_resolution_clock::now();
	//auto miliseconds = timer_stop - timer_start;
	clock_t timer_stop = clock() - timer_start;
	float miliseconds = ((float)timer_stop) ;
	//timer_stop = std::time(NULL); 
	//seconds = std::difftime(std::time(NULL), timer_start);
	printf("*****************************************************\n");
	std::cout<<"Time Taken for CPU Version : "<< miliseconds<<" ms"<<std::endl;
	printf("*****************************************************\n");
	printArray("CPU Sequential",input,output, LEN, newLEN);
	writeToFile("CPUSequential.txt", input, output,LEN, newLEN);
	
	//execute the stream compaction on GPU
	//global memory first
	//shiftArray(input, output, LEN+1);
	ParallelReduction(input, output, LEN, GLOBAL_MEM);
	printArray("GPU Global Memory",input,output, LEN, newLEN);
	writeToFile("GPUGlobal.txt", input, output,LEN,newLEN);

	//shared memory + single block
	//shiftArray(input, output, LEN+1);
	ParallelReduction(input, output, LEN, SHARED_MEM_1);
	printArray("GPU Shared Memory Single Block",input,output, LEN, newLEN);
	writeToFile("GPUSharedSingle.txt", input, output,LEN,newLEN);

	//shared memory + multiple block
	//shiftArray(input, output, LEN+1);
	ParallelReduction(input, output, LEN, SHARED_MEM_N);
	printArray("GPU Shared Memory Multiple Block",input,output, LEN,newLEN);
	writeToFile("GPUSharedMultiple.txt", input, output,LEN,newLEN);

	//thrust method
	ParallelReduction(input, output, LEN, THRUST);
	printArray("Thrust Method",input,output, LEN,newLEN);
	writeToFile("Thrust.txt", input, output,LEN,newLEN);

	//delete input;
	//delete output;
	return 0;
}



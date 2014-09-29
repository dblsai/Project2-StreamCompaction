#include <sstream>
#include <stdio.h>
#include <iostream>
#include <fstream>




int findMax(int * a, int len){
	int max = 0;
	for(int i=0; i<len; i++){
		max = (a[i] > max)? a[i] : max;
	}
	return max;
}


int checkCondition(int a){
	if( a % 2 == 0 ){   //the condition here
		return 0;
	}
	else{
		return 1;
	}

}

void printArray(std::string msg, int *in, int *out, int len_in, int len_out){
	std::stringstream buffer;
	std::cout << "-------------------- "<<msg <<" -------------------"<<std::endl;
	/*std::cout << "Input array: "<<std::endl;
	buffer.str("");
	for(int i=0; i<len_in; i++){
		buffer << in[i] << " ";
	}
	std::cout <<buffer.str() << std::endl;*/

	std::cout << "output array: "<<std::endl;
	buffer.str("");
	for(int i=0; i<len_out; i++){
		buffer << out[i] << " ";
	}
	std::cout <<buffer.str() << std::endl;
}


void shiftArray(int *from, int *to, int len){
	to[0]=0;
	for(int i=1; i<len; i++){
		to[i] = from[i-1];
	}
}

void copyArray(int *from, int *to, int len){

	for(int i=0; i<len; i++){
		to[i] = from[i];
	}
}

void writeToFile(std::string fileName, int * in, int * out, int len_in, int len_out){
	std::ofstream myfile;
	myfile.open (fileName);
	//myfile << "Writing this to a file.\n";
	std::stringstream buffer;

	myfile << "-------------------" << fileName << "-------------------"<<std::endl;
/*	myfile << "------------------- Input array -------------------"<<std::endl;
	buffer.str("");
	for(int i=0; i<len_in; i++){
		buffer << in[i] << std::endl;
	}
	//std::cout <<buffer.str() << std::endl;
	myfile << buffer.str() << std::endl;*/

	myfile << "------------------- Output array -------------------"<<std::endl;
	buffer.str("");
	for(int i=0; i<len_out; i++){
		buffer << out[i] <<std::endl;
	}
	//std::cout <<buffer.str() << std::endl;
	myfile << buffer.str() << std::endl;

	myfile.close();
}
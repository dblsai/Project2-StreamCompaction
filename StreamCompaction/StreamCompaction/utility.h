#ifndef UTILITY_H
#define UTILITY_H


#include <cmath>
#include <iostream>
#include <sstream>
#include <stdio.h>
#include <iostream>



int findMax(int * a, int l);

int checkCondition(int a);  
void printArray(std::string msg, int *in, int *out, int len_in, int len_out);

void shiftArray(int *from, int *to, int len);

void copyArray(int *from, int *to, int len);
void writeToFile(std::string fileName, int * in, int * out, int len_in, int len_out);
#endif
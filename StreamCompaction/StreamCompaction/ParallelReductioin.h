#ifndef PARALLELREDUCTION_H
#define PARALLELREDUCTION_H

#include <cuda.h>
#include <cmath>
#include <iostream>
#include "utility.h"

#define GLOBAL_MEM 0
#define SHARED_MEM_1 1
#define SHARED_MEM_N 2
#define THRUST 3

#define BLOCK_SIZE 128

void ParallelReduction(int * IN, int * OUT, int LEN, int OPERATION);
//int findMax(int * a, int l);
//int checkCondition(int a);      

#endif

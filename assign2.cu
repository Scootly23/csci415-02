//CSCI415 - Assignment 2
//Original by: Saeed Salem, 2/25/2015
//Updated by: Otto Borchert, 2/20/2017
//To compile: make clean; make
//To run: ./assign2

#include <stdio.h>
#include <iostream>
#include <fstream>
#include <vector>
#include <math.h>
#include <iomanip>
#include <string>
#include <sys/time.h>

typedef std::vector< std::vector<int> > AdjacencyMatrix;
AdjacencyMatrix adjMatrix;

int threads_per_block = 256;
int blocks = (int)(5000/threads_per_block+1);
int n;

void printAdjMatrix(AdjacencyMatrix adjMatrix)
{
    for (int i=0; i<adjMatrix.size(); i++)
    {
        for (int j=0; j<adjMatrix[i].size(); j++) 
        {
            std::cout << adjMatrix[i][j] << " ";
        }
        std::cout << std::endl;
    }
}
__global__ void clustCoeff_Parallel(int *matrix, float *output,int n)
{
    double totalC = 0.0;
    int x = blockDim.x * blockIdx.x + threadIdx.x;

    if(x < n)
    {
	const int size = (n*n);
	
        int *temp = new int[size];
        int nCount = 0;
        int mCount = 0;
        for(int y = 0;y<n;y++)
        {
	    int b = matrix[x*n+y];
            if(b==1)
            {
                temp[nCount]=y;
                nCount++;
            }

        }
       
        for(int p =0;p<nCount;p++ )
        {
            for(int q =0;q<n;q++)
            {
                if(matrix[temp[p]*n+q] == 1 && matrix[q*n+x] == 1)
                {
                    mCount++;	    
                }
            }
                
        }
        
        output[x]=((mCount)/(nCount*(nCount-1.0)));
        totalC += output[x];
   }
}
double clustCoeff_Serial(AdjacencyMatrix matrix)
{  std::vector<double> total;
        double totalC = 0.0;
        for(int x =0;x<n;x++)
        {
            //Parallelize this hunk
            std::vector<int> temp;
            int nCount = 0;
            int mCount = 0;
            for(int y = 0;y<n;y++)
            {
                if(matrix[x][y])
                {
                    temp.push_back(y);
                    nCount++;
                }

            }
            for(int p =0;p<temp.size();p++ )
            {
                for(int q =0;q<n;q++)
                {
                    if(matrix[temp[p]][q] && matrix[q][x])
                    {
                        mCount++;
                    }
                }
                
            }
            //std::cout<<mCount<<std::endl;
            total.push_back((mCount)/(nCount*(nCount-1.0)));
            totalC += total[x];
        }
        double result = ((1.0/n)*totalC);
        std::cout<<"\nSerial Coeffecient: "<<result<<std::endl;
        return 0.0;//result;
}
long long start_timer() {
	struct timeval tv;
	gettimeofday(&tv, NULL);
	return tv.tv_sec * 1000000 + tv.tv_usec;
}


// Prints the time elapsed since the specified time
long long stop_timer(long long start_time, std::string name) {
	struct timeval tv;
	gettimeofday(&tv, NULL);
	long long end_time = tv.tv_sec * 1000000 + tv.tv_usec;
        std::cout << std::setprecision(5);	
	std::cout << name << ": " << ((float) (end_time - start_time)) / (1000 * 1000) << " sec\n";
	return end_time - start_time;
}
void checkErrors(const char label[])
{
  // we need to synchronise first to catch errors due to
  // asynchroneous operations that would otherwise
  // potentially go unnoticed

  cudaError_t err;

  err = cudaThreadSynchronize();
  if (err != cudaSuccess)
  {
    char *e = (char*) cudaGetErrorString(err);
    fprintf(stderr, "CUDA Error: %s (at %s)", e, label);
  }

  err = cudaGetLastError();
  if (err != cudaSuccess)
  {
    char *e = (char*) cudaGetErrorString(err);
    fprintf(stderr, "CUDA Error: %s (at %s)", e, label);
  }
}
int main()
{
    std::fstream myfile("toyGraph.txt",std::ios_base::in);
    int u,v;
    int maxNode = 0;
    std::vector< std::pair<int,int> > allEdges;
    while(myfile >> u >> v)
    {
        allEdges.push_back(std::make_pair(u,v));
        if(u > maxNode)
          maxNode = u;

        if(v > maxNode)
          maxNode = v;                 
    }

    n = maxNode + 1;  //Since nodes starts with 0
    std::cout << "Graph has " << n << " nodes" << std::endl;

    adjMatrix = AdjacencyMatrix(n,std::vector<int>(n,0));
    //populate the matrix
    for(int i =0; i<allEdges.size() ; i++){
       u = allEdges[i].first;
       v = allEdges[i].second;
       adjMatrix[u][v] = 1;
       adjMatrix[v][u] = 1;
    } 
    //You can also make a list of neighbors for each node if you want.
    //printAdjMatrix(adjMatrix);


    //TODO: Write serial clustering coefficent code; include timing and error checking
   
    long long serial_start = start_timer();
    clustCoeff_Serial(adjMatrix);
    long long serial_end = stop_timer(serial_start,"Serial Run Time");
    
    //TODO: Write parallel clustering cofficient code; include timing and error checking
    int *d_input;
    //int *d_temp = (int*)malloc(n*n*sizeof(int));
    int *d_temp = new int[n*n];
    float *d_output;
    float *h_gpu_result = (float*)malloc(n*sizeof(float));
    cudaMalloc((void **) &d_input, sizeof(int)*n*n);
    cudaMalloc((void **) &d_output, n*sizeof(float));
    //checkErrors("MAlloc");
    for (int i =0;i<n;i++){
	for(int j =0;j<n;j++){
	d_temp[(i*n)+j]=adjMatrix[i][j]; 
	}
    }
    cudaThreadSynchronize();
    cudaMemcpy(d_input, d_temp, (n*n*sizeof(int)), cudaMemcpyHostToDevice);
    //checkErrors("memCopy");

    long long parallel_start = start_timer();
    clustCoeff_Parallel<<<blocks,threads_per_block>>>(d_input,d_output,n);
    cudaMemcpy(h_gpu_result, d_output, n*sizeof(float), cudaMemcpyDeviceToHost);
    float coef=0.0;
    for(int j =0;j<n;j++){
    coef += h_gpu_result[j];
    }
    
    long long parallel_stop = stop_timer(parallel_start,"\nParallel Run Time");
    std::cout<<"Parallel coeffecient is: "<<(coef/n)<<std::endl;
    //checkErrors("Kernal");
    
    cudaThreadSynchronize();
    cudaFree(d_output);
    cudaFree(d_input);
    
    //TODO: Compare serial and parallel results

    return 0;
}


//CSCI415 - Assignment 2
//Original by: Saeed Salem, 2/25/2015
//Updated by: Otto Borchert, 2/20/2017
//To compile: make clean; make
//To run: ./assign2

#include <stdio.h>
#include <iostream>
#include <fstream>
#include <vector>

typedef std::vector< std::vector<int> > AdjacencyMatrix;
AdjacencyMatrix adjMatrix;


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

int main()
{
    std::fstream myfile("toyGraph1.txt",std::ios_base::in);
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

    int n = maxNode + 1;  //Since nodes starts with 0
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
    printAdjMatrix(adjMatrix);


    //TODO: Write serial clustering coefficent code; include timing and error checking

    //TODO: Write parallel clustering cofficient code; include timing and error checking

    //TODO: Compare serial and parallel results

    return 0;
}

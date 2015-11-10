#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>
int main(int argc, char** argv)
{
char name[80];
int namelen;

    MPI_Init(&argc, &argv);
    MPI_Get_processor_name(name, &namelen);
    printf( "Hello world from %s\n", name);
    MPI_Finalize();
}


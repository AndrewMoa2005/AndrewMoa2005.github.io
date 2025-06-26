+++
author = "Andrew Moa"
title = "Matrix multiplication operation (Ⅲ) - using MPI parallel acceleration"
date = "2025-06-25"
description = ""
tags = [
    "c++",
    "fortran",
]
categories = [
    "code",
]
series = [""]
aliases = [""]
image = "/images/code-bg.jpg"
+++

MPI is a parallel computing protocol and is currently the most commonly used interface program for high-performance computing clusters. MPI communicates through inter-process messages and can call multiple cores across nodes to perform parallel computing, which is not available in OpenMP. MPI is implemented on different platforms, such as MS-MPI and Intel MPI under Windows, OpenMPI and MPICH under Linux, etc.

## 1. MPI parallel acceleration loop calculation

### 1.1 C Implementation

MPI needs to initialize the main program interface and establish a message broadcast mechanism; at the same time, the array to be calculated is divided and broadcast to different processes. In the past, these operations were implemented internally by OpenMP or other parallel libraries, and programmers did not need to care about how the underlying implementation was implemented. However, using MPI requires programmers to manually allocate the global and local space of each process and control the broadcast of each message, which undoubtedly increases the additional learning cost.

Here, the `main.c` file is modified as follows.
```C
#include "mpi.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>

#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define MIN(a, b) ((a) < (b) ? (a) : (b))

extern void matrix_multiply_float(int n, int rank, int size, float local_A[], float B[], float local_C[]);
extern void matrix_multiply_double(int n, int rank, int size, double local_A[], double B[], double local_C[]);

// Initialize matrix
void initialize_matrix_float(int n, float matrix[])
{
    srand((unsigned)time(NULL));
    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            matrix[i * n + j] = rand() / (float)(RAND_MAX);
        }
    }
}

void initialize_matrix_double(int n, double matrix[])
{
    srand((unsigned)time(NULL));
    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            matrix[i * n + j] = rand() / (double)(RAND_MAX);
        }
    }
}

// Execute matrix multiply and print results
int mpi_float(int dim, int loop_num, double *ave_gflops, double *max_gflops, double *ave_time, double *min_time)
{
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    // Use volatile to prevent compiler optimizations
    volatile float *a, *b, *local_c;
    struct timespec start_ns, end_ns;
    double cpu_time, total_cpu_time;

    // Count the number of rows processed by each process
    int rows_per_process = dim / size;
    int remainder = dim % size;
    if (rank < remainder)
    {
        rows_per_process++;
    }

    for (int i = 0; i < loop_num; i++)
    {
        int check_indices[2];
        float check_value;

        // The main process allocates memory for the complete matrix
        if (rank == 0)
        {
            a = (float *)malloc(dim * dim * sizeof(float));
            b = (float *)malloc(dim * dim * sizeof(float));
            if (a == NULL || b == NULL)
            {
                fprintf(stderr, "Memory allocation failed\n");
                return 0;
            }
            initialize_matrix_float(dim, a);
            initialize_matrix_float(dim, b);

            // Generate checksum value
            int check_row = rand() % dim;
            int check_col = rand() % dim;
            check_value = 0.0;
            for (int k = 0; k < dim; k++)
            {
                check_value += a[check_row * dim + k] * b[k * dim + check_col];
            }

            check_indices[0] = check_row;
            check_indices[1] = check_col;

            // Broadcast verification row and column index and verification value
            MPI_Bcast(check_indices, 2, MPI_INT, 0, MPI_COMM_WORLD);
            MPI_Bcast(&check_value, 1, MPI_FLOAT, 0, MPI_COMM_WORLD);
        }
        else
        {
            a = NULL;
            b = NULL;
            MPI_Bcast(check_indices, 2, MPI_INT, 0, MPI_COMM_WORLD);
            MPI_Bcast(&check_value, 1, MPI_FLOAT, 0, MPI_COMM_WORLD);
        }

        // Allocate local matrix space for each process
        float *local_A = (float *)malloc(rows_per_process * dim * sizeof(float));
        local_c = (float *)calloc(rows_per_process * dim, sizeof(float));
        if (local_A == NULL || local_c == NULL)
        {
            fprintf(stderr, "Memory allocation failed\n");
            return 0;
        }

        // Distribute the rows of matrix A to each process
        int *sendcounts = (int *)malloc(size * sizeof(int));
        int *displs = (int *)malloc(size * sizeof(int));
        int offset = 0;
        for (int p = 0; p < size; p++)
        {
            sendcounts[p] = (p < remainder) ? (rows_per_process * dim) : ((rows_per_process - 1) * dim);
            displs[p] = offset;
            offset += sendcounts[p];
        }
        MPI_Scatterv(a, sendcounts, displs, MPI_FLOAT, local_A, rows_per_process * dim, MPI_FLOAT, 0, MPI_COMM_WORLD);

        // All processes require the complete matrix B
        float *full_B = (float *)malloc(dim * dim * sizeof(float));
        if (full_B == NULL)
        {
            fprintf(stderr, "Memory allocation failed for full_B\n");
            return 0;
        }
        if (rank == 0)
        {
            memcpy(full_B, b, dim * dim * sizeof(float));
        }
        MPI_Bcast(full_B, dim * dim, MPI_FLOAT, 0, MPI_COMM_WORLD);

        timespec_get(&start_ns, TIME_UTC);
        matrix_multiply_float(dim, rank, size, local_A, full_B, local_c);
        timespec_get(&end_ns, TIME_UTC);
        cpu_time = (end_ns.tv_sec - start_ns.tv_sec) + (end_ns.tv_nsec - start_ns.tv_nsec) / 1e9;

        // Use MPI_Reduce to sum the cpu_time of all processes
        MPI_Reduce(&cpu_time, &total_cpu_time, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

        if (rank == 0)
        {
            // Calculate the average
            cpu_time = total_cpu_time / size;
        }

        // Broadcast the average value to all processes
        MPI_Bcast(&cpu_time, 1, MPI_DOUBLE, 0, MPI_COMM_WORLD);

        double gflops = 1e-9 * dim * dim * dim * 2 / cpu_time;
        if (rank == 0)
        {
            printf("%d\t: %d x %d Matrix multiply wall time : %.6fs(%.3fGflops)\n", i + 1, dim, dim, cpu_time, gflops);
            fflush(stdout); // Force flushing of standard output buffer
        }

        // Collect the local results of all processes to the main process
        float *c = NULL;
        if (rank == 0)
        {
            c = (float *)malloc(dim * dim * sizeof(float));
            if (c == NULL)
            {
                fprintf(stderr, "Memory allocation failed for c matrix\n");
                return 0;
            }
        }
        MPI_Gatherv(local_c, rows_per_process * dim, MPI_FLOAT, c, sendcounts, displs, MPI_FLOAT, 0, MPI_COMM_WORLD);

        // Main process performs verification
        if (rank == 0)
        {
            int check_row = check_indices[0];
            int check_col = check_indices[1];
            float result_value = c[check_row * dim + check_col];
            if (fabs(result_value - check_value) > 0.001)
            {
                fprintf(stderr, "Verification failed at iteration %d: expected %.6f, got %.6f\n", i + 1, check_value, result_value);
            }
            free(c);
        }

        // Free memory
        if (rank == 0)
        {
            free(a);
            free(b);
        }
        free(local_A);
        free(local_c);
        free(sendcounts);
        free(displs);
        free(full_B);
        *ave_gflops += gflops;
        *max_gflops = MAX(*max_gflops, gflops);
        *ave_time += cpu_time;
        *min_time = MIN(*min_time, cpu_time);
    }
    *ave_gflops /= loop_num;
    *ave_time /= loop_num;
    return 1;
}

int mpi_double(int dim, int loop_num, double *ave_gflops, double *max_gflops, double *ave_time, double *min_time)
{
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    // Use volatile to prevent compiler optimizations
    volatile double *a, *b, *local_c;
    struct timespec start_ns, end_ns;
    double cpu_time, total_cpu_time;

    // Count the number of rows processed by each process
    int rows_per_process = dim / size;
    int remainder = dim % size;
    if (rank < remainder)
    {
        rows_per_process++;
    }

    for (int i = 0; i < loop_num; i++)
    {
        int check_indices[2];
        double check_value;

        // The main process allocates memory for the complete matrix
        if (rank == 0)
        {
            a = (double *)malloc(dim * dim * sizeof(double));
            b = (double *)malloc(dim * dim * sizeof(double));
            if (a == NULL || b == NULL)
            {
                fprintf(stderr, "Memory allocation failed\n");
                return 0;
            }
            initialize_matrix_double(dim, a);
            initialize_matrix_double(dim, b);

            // Generate checksum value
            int check_row = rand() % dim;
            int check_col = rand() % dim;
            check_value = 0.0;
            for (int k = 0; k < dim; k++)
            {
                check_value += a[check_row * dim + k] * b[k * dim + check_col];
            }

            check_indices[0] = check_row;
            check_indices[1] = check_col;

            // Broadcast verification row and column index and verification value
            MPI_Bcast(check_indices, 2, MPI_INT, 0, MPI_COMM_WORLD);
            MPI_Bcast(&check_value, 1, MPI_DOUBLE, 0, MPI_COMM_WORLD);
        }
        else
        {
            a = NULL;
            b = NULL;
            MPI_Bcast(check_indices, 2, MPI_INT, 0, MPI_COMM_WORLD);
            MPI_Bcast(&check_value, 1, MPI_DOUBLE, 0, MPI_COMM_WORLD);
        }

        // Allocate local matrix space for each process
        double *local_A = (double *)malloc(rows_per_process * dim * sizeof(double));
        local_c = (double *)calloc(rows_per_process * dim, sizeof(double));
        if (local_A == NULL || local_c == NULL)
        {
            fprintf(stderr, "Memory allocation failed\n");
            return 0;
        }

        // Distribute the rows of matrix A to each process
        int *sendcounts = (int *)malloc(size * sizeof(int));
        int *displs = (int *)malloc(size * sizeof(int));
        int offset = 0;
        for (int p = 0; p < size; p++)
        {
            sendcounts[p] = (p < remainder) ? (rows_per_process * dim) : ((rows_per_process - 1) * dim);
            displs[p] = offset;
            offset += sendcounts[p];
        }
        MPI_Scatterv(a, sendcounts, displs, MPI_DOUBLE, local_A, rows_per_process * dim, MPI_DOUBLE, 0, MPI_COMM_WORLD);

        // All processes require the complete matrix B
        double *full_B = (double *)malloc(dim * dim * sizeof(double));
        if (full_B == NULL)
        {
            fprintf(stderr, "Memory allocation failed for full_B\n");
            return 0;
        }
        if (rank == 0)
        {
            memcpy(full_B, b, dim * dim * sizeof(double));
        }
        MPI_Bcast(full_B, dim * dim, MPI_DOUBLE, 0, MPI_COMM_WORLD);

        timespec_get(&start_ns, TIME_UTC);
        matrix_multiply_double(dim, rank, size, local_A, full_B, local_c);
        timespec_get(&end_ns, TIME_UTC);
        cpu_time = (end_ns.tv_sec - start_ns.tv_sec) + (end_ns.tv_nsec - start_ns.tv_nsec) / 1e9;

        // Use MPI_Reduce to sum the cpu_time of all processes
        MPI_Reduce(&cpu_time, &total_cpu_time, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

        if (rank == 0)
        {
            // Calculate the average
            cpu_time = total_cpu_time / size;
        }

        // Broadcast the average value to all processes
        MPI_Bcast(&cpu_time, 1, MPI_DOUBLE, 0, MPI_COMM_WORLD);

        double gflops = 1e-9 * dim * dim * dim * 2 / cpu_time;
        if (rank == 0)
        {
            printf("%d\t: %d x %d Matrix multiply wall time : %.6fs(%.3fGflops)\n", i + 1, dim, dim, cpu_time, gflops);
            fflush(stdout); // Force flushing of standard output buffer
        }

        // Collect the local results of all processes to the main process
        double *c = NULL;
        if (rank == 0)
        {
            c = (double *)malloc(dim * dim * sizeof(double));
            if (c == NULL)
            {
                fprintf(stderr, "Memory allocation failed for c matrix\n");
                return 0;
            }
        }
        MPI_Gatherv(local_c, rows_per_process * dim, MPI_DOUBLE, c, sendcounts, displs, MPI_DOUBLE, 0, MPI_COMM_WORLD);

        // Main process performs verification
        if (rank == 0)
        {
            int check_row = check_indices[0];
            int check_col = check_indices[1];
            double result_value = c[check_row * dim + check_col];
            if (fabs(result_value - check_value) > 0.000001)
            {
                fprintf(stderr, "Verification failed at iteration %d: expected %.6f, got %.6f\n", i + 1, check_value, result_value);
            }
            free(c);
        }

        // Free memory
        if (rank == 0)
        {
            free(a);
            free(b);
        }
        free(local_A);
        free(local_c);
        free(sendcounts);
        free(displs);
        free(full_B);
        *ave_gflops += gflops;
        *max_gflops = MAX(*max_gflops, gflops);
        *ave_time += cpu_time;
        *min_time = MIN(*min_time, cpu_time);
    }
    *ave_gflops /= loop_num;
    *ave_time /= loop_num;
    return 1;
}

int main(int argc, char *argv[])
{
    int rank;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    int n = 10;                                // Default matrix size exponent
    int loop_num = 5;                          // Number of iterations for averaging
    double ave_gflops = 0.0, max_gflops = 0.0; // Average and maximum Gflops
    double ave_time = 0.0, min_time = 1e9;     // Average and minimum time
    int use_double = 0;                        // Default to float precision

    // Help message
    if (argc == 1 || (argc == 2 && (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0)))
    {
        if (rank == 0)
        {
            printf("Usage: mpiexec/mpirun [-n/-np $NUM_PROCS] %s [-n SIZE] [-l LOOP_NUM] [-float|-double]\n", argv[0]);
            printf("  -n SIZE      Specify matrix size, like 2^SIZE (default: 10)\n");
            printf("  -l LOOP_NUM  Specify number of iterations (default: 5)\n");
            printf("  -float       Use float precision (default)\n");
            printf("  -double      Use double precision\n");
            printf("  -h, --help   Show this help message\n");
        }
        MPI_Finalize();
        return 0;
    }

    // Parse -n, -l, -float, -double options
    int double_flag = 0, float_flag = 0;
    for (int argi = 1; argi < argc; ++argi)
    {
        if (strcmp(argv[argi], "-n") == 0 && argi + 1 < argc)
        {
            n = atoi(argv[argi + 1]);
            argi++;
        }
        else if (strcmp(argv[argi], "-l") == 0 && argi + 1 < argc)
        {
            loop_num = atoi(argv[argi + 1]);
            argi++;
        }
        else if (strcmp(argv[argi], "-double") == 0)
        {
            double_flag = 1;
        }
        else if (strcmp(argv[argi], "-float") == 0)
        {
            float_flag = 1;
        }
    }
    if (double_flag && float_flag)
    {
        if (rank == 0)
        {
            fprintf(stderr, "Error: Cannot specify both -double and -float options.\n");
        }
        MPI_Finalize();
        return 1;
    }
    use_double = double_flag ? 1 : 0;

    int dim = (int)pow(2, n);

    if (use_double)
    {
        if (rank == 0)
        {
            printf("Using double precision for matrix multiplication.\n");
        }
        if (!mpi_double(dim, loop_num, &ave_gflops, &max_gflops, &ave_time, &min_time))
        {
            MPI_Finalize();
            return 1;
        }
    }
    else
    {
        if (rank == 0)
        {
            printf("Using float precision for matrix multiplication.\n");
        }
        if (!mpi_float(dim, loop_num, &ave_gflops, &max_gflops, &ave_time, &min_time))
        {
            MPI_Finalize();
            return 1;
        }
    }

    if (rank == 0)
    {
        printf("Average Gflops: %.3f, Max Gflops: %.3f\n", ave_gflops, max_gflops);
        printf("Average Time: %.6fs, Min Time: %.6fs\n", ave_time, min_time);
    }

    MPI_Finalize();
    return 0;
}
```
In order to ensure that there are no errors in the merged matrix, a random coordinate verification mechanism is added to the main program.

The `mpi.c` file is the specific implementation of the loop nested matrix operation.
```C
void matrix_multiply_float(int n, int rank, int size, float local_A[], float B[], float local_C[])
{
	// Count the number of rows processed by each process
	int rows_per_process = n / size;
	int remainder = n % size;
	if (rank < remainder)
	{
		rows_per_process++;
	}

	// Matrix multiplication operation
	for (int i = 0; i < rows_per_process; i++)
	{
		for (int j = 0; j < n; j++)
		{
			for (int k = 0; k < n; k++)
			{
				local_C[i * n + j] += local_A[i * n + k] * B[k * n + j];
			}
		}
	}
}

// Parallel matrix multiply
void matrix_multiply_double(int n, int rank, int size, double local_A[], double B[], double local_C[])
{
	// Count the number of rows processed by each process
	int rows_per_process = n / size;
	int remainder = n % size;
	if (rank < remainder)
	{
		rows_per_process++;
	}

	// Matrix multiplication operation
	for (int i = 0; i < rows_per_process; i++)
	{
		for (int j = 0; j < n; j++)
		{
			for (int k = 0; k < n; k++)
			{
				local_C[i * n + j] += local_A[i * n + k] * B[k * n + j];
			}
		}
	}
}
```

The `CMakeLists.txt` configuration file sets how to include the mpi header file. The compilation here is done on the Windows platform, and the corresponding mpi library is ms-mpi.
```cmake
cmake_minimum_required(VERSION 3.13)
project(mpi LANGUAGES C CXX)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 20)

set(EXECUTE_FILE_NAME ${PROJECT_NAME}_${CMAKE_C_COMPILER_FRONTEND_VARIANT}_${CMAKE_C_COMPILER_ID}_${CMAKE_C_COMPILER_VERSION})
string(TOLOWER ${EXECUTE_FILE_NAME} EXECUTE_FILE_NAME)

# Enable MPI support
find_package(MPI REQUIRED)

set(SRC_LIST
    src/main.c
    src/mpi.c
)

add_executable(${EXECUTE_FILE_NAME} ${SRC_LIST})

target_include_directories(${EXECUTE_FILE_NAME}
    PRIVATE
    ${MPI_CXX_INCLUDE_DIRS}
)

target_link_libraries(${EXECUTE_FILE_NAME} PRIVATE
    ${MPI_LIBRARIES}
)

```

Compile using MSYS2's ucrt64 on the Windows platform and output the Release program execution effect as follows:
```powershell
PS D:\example\efficiency_v3\c\mpi\build> mpiexec -n 20 D:/example/efficiency_v3/c/mpi/build/mpi_gnu_gnu_15.1.0.exe -l 10 -n 10
Using float precision for matrix multiplication.
1       : 1024 x 1024 Matrix multiply wall time : 0.235279s(9.127Gflops)
2       : 1024 x 1024 Matrix multiply wall time : 0.245679s(8.741Gflops)
3       : 1024 x 1024 Matrix multiply wall time : 0.252880s(8.492Gflops)
4       : 1024 x 1024 Matrix multiply wall time : 0.253803s(8.461Gflops)
5       : 1024 x 1024 Matrix multiply wall time : 0.235253s(9.128Gflops)
6       : 1024 x 1024 Matrix multiply wall time : 0.261678s(8.207Gflops)
7       : 1024 x 1024 Matrix multiply wall time : 0.261258s(8.220Gflops)
8       : 1024 x 1024 Matrix multiply wall time : 0.256560s(8.370Gflops)
9       : 1024 x 1024 Matrix multiply wall time : 0.254379s(8.442Gflops)
10      : 1024 x 1024 Matrix multiply wall time : 0.271509s(7.909Gflops)
Average Gflops: 8.510, Max Gflops: 9.128
Average Time: 0.252828s, Min Time: 0.235253s
PS D:\example\efficiency_v3\c\mpi\build> mpiexec -n 20 D:/example/efficiency_v3/c/mpi/build/mpi_gnu_gnu_15.1.0.exe -l 10 -n 10 -double
Using double precision for matrix multiplication.
1       : 1024 x 1024 Matrix multiply wall time : 0.317128s(6.772Gflops)
2       : 1024 x 1024 Matrix multiply wall time : 0.316111s(6.793Gflops)
3       : 1024 x 1024 Matrix multiply wall time : 0.320794s(6.694Gflops)
4       : 1024 x 1024 Matrix multiply wall time : 0.334887s(6.413Gflops)
5       : 1024 x 1024 Matrix multiply wall time : 0.328439s(6.538Gflops)
6       : 1024 x 1024 Matrix multiply wall time : 0.326553s(6.576Gflops)
7       : 1024 x 1024 Matrix multiply wall time : 0.321168s(6.686Gflops)
8       : 1024 x 1024 Matrix multiply wall time : 0.322008s(6.669Gflops)
9       : 1024 x 1024 Matrix multiply wall time : 0.330364s(6.500Gflops)
10      : 1024 x 1024 Matrix multiply wall time : 0.314038s(6.838Gflops)
Average Gflops: 6.648, Max Gflops: 6.838
Average Time: 0.323149s, Min Time: 0.314038s
```
The CPU of the computing machine is AMD AI 9 365w, with 10 cores and 20 threads. Hyperthreading is used here, and the overall performance is similar to that of OpenMP. The number of computing processes can be controlled through the command line. Since each process needs to allocate local storage space, the more computing processes there are, the greater the memory overhead.

### 1.2 Fortran Implementation

Fortran also provides MPI implementation, and both MS-MPI and OpenMPI provide Fortran interfaces. Due to space limitations, the main program source code here still uses the same `main.c` as in the previous section. The matrix multiplication part is implemented in Fortran, and the program functions are implemented by mixed programming of Fortran and C.

The matrix multiplication calculation related functions are defined in the Fortran source file `mpi2c.f90`:
```fortran
subroutine matrix_multiply_float(n, rank, size, local_A, B, local_C) bind(C, name="matrix_multiply_float")
    use, intrinsic :: iso_c_binding
    implicit none
    integer(c_int), value, intent(in) :: n, rank, size
    real(c_float), intent(in) :: local_A(*)
    real(c_float), intent(in) :: B(*)
    real(c_float), intent(out) :: local_C(*)
    real(c_float), allocatable :: local_A_2d(:, :)
    real(c_float), allocatable :: B_2d(:, :)
    real(c_float), allocatable :: local_C_2d(:, :)
    integer(c_int) :: rows_per_process
    integer(c_int) :: remainder
    integer(c_int) :: i, j, k

    remainder = mod(n, size)
    rows_per_process = n / size
    if (rank < remainder) then
        rows_per_process = rows_per_process + 1
    end if

    allocate(local_A_2d(rows_per_process, n))
    allocate(B_2d(n, n))
    allocate(local_C_2d(rows_per_process, n))

    ! Convert a one-dimensional array to a two-dimensional array
    do i = 1, rows_per_process
        do j = 1, n
            local_A_2d(i, j) = local_A((i - 1) * n + j)
        end do
    end do

    do i = 1, n
        do j = 1, n
            B_2d(i, j) = B((i - 1) * n + j)
        end do
    end do

    ! Initialize the result matrix
    local_C_2d = 0.0_c_float

    ! Matrix multiplication calculation
    do i = 1, rows_per_process
        do j = 1, n
            do k = 1, n
                local_C_2d(i, j) = local_C_2d(i, j) + local_A_2d(i, k) * B_2d(k, j)
            end do
        end do
    end do

    ! Convert a two-dimensional array to a one-dimensional array
    do i = 1, rows_per_process
        do j = 1, n
            local_C((i - 1) * n + j) = local_C_2d(i, j)
        end do
    end do

    deallocate(local_A_2d, B_2d, local_C_2d)
end subroutine matrix_multiply_float

subroutine matrix_multiply_double(n, rank, size, local_A, B, local_C) bind(C, name="matrix_multiply_double")
    use, intrinsic :: iso_c_binding
    implicit none
    integer(c_int), value, intent(in) :: n, rank, size
    real(c_double), intent(in) :: local_A(*)
    real(c_double), intent(in) :: B(*)
    real(c_double), intent(out) :: local_C(*)
    real(c_double), allocatable :: local_A_2d(:, :)
    real(c_double), allocatable :: B_2d(:, :)
    real(c_double), allocatable :: local_C_2d(:, :)
    integer(c_int) :: rows_per_process
    integer(c_int) :: remainder
    integer(c_int) :: i, j, k

    remainder = mod(n, size)
    rows_per_process = n / size
    if (rank < remainder) then
        rows_per_process = rows_per_process + 1
    end if

    allocate(local_A_2d(rows_per_process, n))
    allocate(B_2d(n, n))
    allocate(local_C_2d(rows_per_process, n))

    ! Convert a one-dimensional array to a two-dimensional array
    do i = 1, rows_per_process
        do j = 1, n
            local_A_2d(i, j) = local_A((i - 1) * n + j)
        end do
    end do

    do i = 1, n
        do j = 1, n
            B_2d(i, j) = B((i - 1) * n + j)
        end do
    end do

    ! Initialize the result matrix
    local_C_2d = 0.0_c_double

    ! Matrix multiplication calculation
    do i = 1, rows_per_process
        do j = 1, n
            do k = 1, n
                local_C_2d(i, j) = local_C_2d(i, j) + local_A_2d(i, k) * B_2d(k, j)
            end do
        end do
    end do

    ! Convert a two-dimensional array to a one-dimensional array
    do i = 1, rows_per_process
        do j = 1, n
            local_C((i - 1) * n + j) = local_C_2d(i, j)
        end do
    end do

    deallocate(local_A_2d, B_2d, local_C_2d)
end subroutine matrix_multiply_double
```

Since the C program interface stores the two-dimensional matrix in a one-dimensional array, in order for the Fortran program to read the matrix information stored in the one-dimensional array normally, it is necessary to define the conversion from the one-dimensional array to the two-dimensional array and open up new storage space. In order to facilitate interface reuse, the relevant content of the array conversion is defined in the calculation function, which will bring additional performance overhead.

The `CMakeLists.txt` configuration file itself has not changed much, and still contains the C mpi header file, but the settings for activating the Fortran language support are added.
```cmake
cmake_minimum_required(VERSION 3.13)
project(mpi-fortran LANGUAGES C Fortran)
set(CMAKE_C_STANDARD 11)
set(CMAKE_Fortran_STANDARD 2008)

set(EXECUTE_FILE_NAME ${PROJECT_NAME}_${CMAKE_Fortran_COMPILER_FRONTEND_VARIANT}_${CMAKE_Fortran_COMPILER_ID}_${CMAKE_Fortran_COMPILER_VERSION})
string(TOLOWER ${EXECUTE_FILE_NAME} EXECUTE_FILE_NAME)

# Enable MPI support
find_package(MPI REQUIRED)

set(SRC_LIST
    src/main.c
    src/mpi2c.f90
)
add_executable(${EXECUTE_FILE_NAME} ${SRC_LIST})

target_include_directories(${EXECUTE_FILE_NAME}
    PRIVATE
    ${MPI_CXX_INCLUDE_DIRS}
)

target_link_libraries(${EXECUTE_FILE_NAME} PRIVATE
    ${MPI_LIBRARIES}
)

```

Compiled using MSYS2's ucrt64 toolchain under Windows, the Release program runs as follows:
```powershell
PS D:\example\efficiency_v3\fortran\mpi-fortran\build> mpiexec -n 20 D:/example/efficiency_v3/fortran/mpi-fortran/build/mpi-fortran_gnu_gnu_15.1.0.exe -l 10 -n 10
Using float precision for matrix multiplication.
1       : 1024 x 1024 Matrix multiply wall time : 0.078928s(27.208Gflops)
2       : 1024 x 1024 Matrix multiply wall time : 0.089289s(24.051Gflops)
3       : 1024 x 1024 Matrix multiply wall time : 0.082848s(25.921Gflops)
4       : 1024 x 1024 Matrix multiply wall time : 0.080060s(26.823Gflops)
5       : 1024 x 1024 Matrix multiply wall time : 0.084739s(25.342Gflops)
6       : 1024 x 1024 Matrix multiply wall time : 0.083975s(25.573Gflops)
7       : 1024 x 1024 Matrix multiply wall time : 0.085056s(25.248Gflops)
8       : 1024 x 1024 Matrix multiply wall time : 0.083494s(25.720Gflops)
9       : 1024 x 1024 Matrix multiply wall time : 0.082314s(26.089Gflops)
10      : 1024 x 1024 Matrix multiply wall time : 0.082700s(25.967Gflops)
Average Gflops: 25.794, Max Gflops: 27.208
Average Time: 0.083340s, Min Time: 0.078928s
PS D:\example\efficiency_v3\fortran\mpi-fortran\build> mpiexec -n 20 D:/example/efficiency_v3/fortran/mpi-fortran/build/mpi-fortran_gnu_gnu_15.1.0.exe -l 10 -n 10 -double
Using double precision for matrix multiplication.
1       : 1024 x 1024 Matrix multiply wall time : 0.126719s(16.947Gflops)
2       : 1024 x 1024 Matrix multiply wall time : 0.127700s(16.817Gflops)
3       : 1024 x 1024 Matrix multiply wall time : 0.126309s(17.002Gflops)
4       : 1024 x 1024 Matrix multiply wall time : 0.124125s(17.301Gflops)
5       : 1024 x 1024 Matrix multiply wall time : 0.121543s(17.668Gflops)
6       : 1024 x 1024 Matrix multiply wall time : 0.129106s(16.634Gflops)
7       : 1024 x 1024 Matrix multiply wall time : 0.129957s(16.525Gflops)
8       : 1024 x 1024 Matrix multiply wall time : 0.128702s(16.686Gflops)
9       : 1024 x 1024 Matrix multiply wall time : 0.127478s(16.846Gflops)
10      : 1024 x 1024 Matrix multiply wall time : 0.125188s(17.154Gflops)
Average Gflops: 16.958, Max Gflops: 17.668
Average Time: 0.126683s, Min Time: 0.121543s
```
The above is the result of running on the same processor as 1.1. Fortran arrays use a column-first storage method that is different from C. The cache hit rate is improved, which is beneficial to improving matrix operation performance.

## 2. MPI accelerates matrix block operations

### 2.1 C Implementation

The above results reveal that cache performance has a great impact on matrix operations. In order to improve the cache hit rate, we try to use the matrix block algorithm to see if it can improve the computing performance of the C language program.

The main program `main.c` remains unchanged as before. Only `mpi.c` is changed here to add the block calculation function based on the original loop nested calculation:
```C
#include <math.h>

//Block size, can be adjusted according to cache size
#define BLOCK_SIZE 8

// Parallel matrix multiply
void matrix_multiply_float(int n, int rank, int size, float local_A[], float B[], float local_C[])
{
    // Count the number of rows processed by each process
    int rows_per_process = n / size;
    int remainder = n % size;
    if (rank < remainder)
    {
        rows_per_process++;
    }

    // Initialize local_C to 0
    for (int i = 0; i < rows_per_process; i++) {
        for (int j = 0; j < n; j++) {
            local_C[i * n + j] = 0.0f;
        }
    }

    // Matrix block multiplication
    for (int bi = 0; bi < rows_per_process; bi += BLOCK_SIZE) {
        for (int bj = 0; bj < n; bj += BLOCK_SIZE) {
            for (int bk = 0; bk < n; bk += BLOCK_SIZE) {
                // Calculation within the block
                int end_i = fmin(bi + BLOCK_SIZE, rows_per_process);
                int end_j = fmin(bj + BLOCK_SIZE, n);
                int end_k = fmin(bk + BLOCK_SIZE, n);
                for (int i = bi; i < end_i; i++) {
                    for (int j = bj; j < end_j; j++) {
                        float sum = local_C[i * n + j];
                        for (int k = bk; k < end_k; k++) {
                            sum += local_A[i * n + k] * B[k * n + j];
                        }
                        local_C[i * n + j] = sum;
                    }
                }
            }
        }
    }
}

// Parallel matrix multiply
void matrix_multiply_double(int n, int rank, int size, double local_A[], double B[], double local_C[])
{
    // Count the number of rows processed by each process
    int rows_per_process = n / size;
    int remainder = n % size;
    if (rank < remainder)
    {
        rows_per_process++;
    }

    // Initialize local_C to 0
    for (int i = 0; i < rows_per_process; i++) {
        for (int j = 0; j < n; j++) {
            local_C[i * n + j] = 0.0;
        }
    }

    // Matrix block multiplication
    for (int bi = 0; bi < rows_per_process; bi += BLOCK_SIZE) {
        for (int bj = 0; bj < n; bj += BLOCK_SIZE) {
            for (int bk = 0; bk < n; bk += BLOCK_SIZE) {
                // Calculation within the block
                int end_i = fmin(bi + BLOCK_SIZE, rows_per_process);
                int end_j = fmin(bj + BLOCK_SIZE, n);
                int end_k = fmin(bk + BLOCK_SIZE, n);
                for (int i = bi; i < end_i; i++) {
                    for (int j = bj; j < end_j; j++) {
                        double sum = local_C[i * n + j];
                        for (int k = bk; k < end_k; k++) {
                            sum += local_A[i * n + k] * B[k * n + j];
                        }
                        local_C[i * n + j] = sum;
                    }
                }
            }
        }
    }
}
```

The configuration file `CMakeLists.txt` is the same as in 1.1.

Compiled using MSYS2's ucrt64 toolchain under Windows, the program execution effect is as follows:
```powershell
PS D:\example\efficiency_v3\c\blockmpi\build> mpiexec -n 20 D:/example/efficiency_v3/c/blockmpi/build/blockmpi_gnu_gnu_15.1.0.exe -l 10 -n 10        
Using float precision for matrix multiplication.
1       : 1024 x 1024 Matrix multiply wall time : 0.039390s(54.519Gflops)
2       : 1024 x 1024 Matrix multiply wall time : 0.041973s(51.164Gflops)
3       : 1024 x 1024 Matrix multiply wall time : 0.044693s(48.050Gflops)
4       : 1024 x 1024 Matrix multiply wall time : 0.042822s(50.149Gflops)
5       : 1024 x 1024 Matrix multiply wall time : 0.044406s(48.361Gflops)
6       : 1024 x 1024 Matrix multiply wall time : 0.041931s(51.215Gflops)
7       : 1024 x 1024 Matrix multiply wall time : 0.042498s(50.531Gflops)
8       : 1024 x 1024 Matrix multiply wall time : 0.041639s(51.573Gflops)
9       : 1024 x 1024 Matrix multiply wall time : 0.042505s(50.523Gflops)
10      : 1024 x 1024 Matrix multiply wall time : 0.043471s(49.401Gflops)
Average Gflops: 50.548, Max Gflops: 54.519
Average Time: 0.042533s, Min Time: 0.039390s
PS D:\example\efficiency_v3\c\blockmpi\build> mpiexec -n 20 D:/example/efficiency_v3/c/blockmpi/build/blockmpi_gnu_gnu_15.1.0.exe -l 10 -n 10 -double
Using double precision for matrix multiplication.
1       : 1024 x 1024 Matrix multiply wall time : 0.041856s(51.307Gflops)
2       : 1024 x 1024 Matrix multiply wall time : 0.045559s(47.136Gflops)
3       : 1024 x 1024 Matrix multiply wall time : 0.044370s(48.400Gflops)
4       : 1024 x 1024 Matrix multiply wall time : 0.043212s(49.697Gflops)
5       : 1024 x 1024 Matrix multiply wall time : 0.041711s(51.485Gflops)
6       : 1024 x 1024 Matrix multiply wall time : 0.043633s(49.217Gflops)
7       : 1024 x 1024 Matrix multiply wall time : 0.042332s(50.730Gflops)
8       : 1024 x 1024 Matrix multiply wall time : 0.041305s(51.991Gflops)
9       : 1024 x 1024 Matrix multiply wall time : 0.041940s(51.203Gflops)
10      : 1024 x 1024 Matrix multiply wall time : 0.040975s(52.410Gflops)
Average Gflops: 50.358, Max Gflops: 52.410
Average Time: 0.042689s, Min Time: 0.040975s
```
The block size is set to 8 here, which is the optimal result obtained based on a large number of tests. When implementing on other platforms, it is necessary to test the hardware of the platform to determine the most appropriate block size.

### 2.2 Fortran Implementation

Next, use Fortran to implement the block matrix MPI acceleration function to see if the performance is improved.

`main.c` and `CMakeLists.txt` are basically the same as 1.2, only the `mpi2c.f90` file is changed to add block content:
```fortran
subroutine matrix_multiply_float(n, rank, size, local_A, B, local_C) bind(C, name="matrix_multiply_float")
    use, intrinsic :: iso_c_binding
    implicit none
    integer(c_int), value, intent(in) :: n, rank, size
    real(c_float), intent(in) :: local_A(*)
    real(c_float), intent(in) :: B(*)
    real(c_float), intent(out) :: local_C(*)
    real(c_float), allocatable :: local_A_2d(:, :)
    real(c_float), allocatable :: B_2d(:, :)
    real(c_float), allocatable :: local_C_2d(:, :)
    integer(c_int) :: rows_per_process
    integer(c_int) :: remainder
    integer(c_int) :: i, j, k, ii, jj, kk
    integer(c_int), parameter :: block_size = 8  ! Block size can be adjusted according to actual conditions

    remainder = mod(n, size)
    rows_per_process = n / size
    if (rank < remainder) then
        rows_per_process = rows_per_process + 1
    end if

    allocate(local_A_2d(rows_per_process, n))
    allocate(B_2d(n, n))
    allocate(local_C_2d(rows_per_process, n))

    ! Convert a one-dimensional array to a two-dimensional array
    do i = 1, rows_per_process
        do j = 1, n
            local_A_2d(i, j) = local_A((i - 1) * n + j)
        end do
    end do

    do i = 1, n
        do j = 1, n
            B_2d(i, j) = B((i - 1) * n + j)
        end do
    end do

    ! Initialize the result matrix
    local_C_2d = 0.0_c_float

    ! 分块矩阵乘法计算
    do ii = 1, rows_per_process, block_size
        do kk = 1, n, block_size
            do jj = 1, n, block_size
                do i = ii, min(ii + block_size - 1, rows_per_process)
                    do k = kk, min(kk + block_size - 1, n)
                        do j = jj, min(jj + block_size - 1, n)
                            local_C_2d(i, j) = local_C_2d(i, j) + local_A_2d(i, k) * B_2d(k, j)
                        end do
                    end do
                end do
            end do
        end do
    end do

    ! Convert a two-dimensional array to a one-dimensional array
    do i = 1, rows_per_process
        do j = 1, n
            local_C((i - 1) * n + j) = local_C_2d(i, j)
        end do
    end do

    deallocate(local_A_2d, B_2d, local_C_2d)
end subroutine matrix_multiply_float

subroutine matrix_multiply_double(n, rank, size, local_A, B, local_C) bind(C, name="matrix_multiply_double")
    use, intrinsic :: iso_c_binding
    implicit none
    integer(c_int), value, intent(in) :: n, rank, size
    real(c_double), intent(in) :: local_A(*)
    real(c_double), intent(in) :: B(*)
    real(c_double), intent(out) :: local_C(*)
    real(c_double), allocatable :: local_A_2d(:, :)
    real(c_double), allocatable :: B_2d(:, :)
    real(c_double), allocatable :: local_C_2d(:, :)
    integer(c_int) :: rows_per_process
    integer(c_int) :: remainder
    integer(c_int) :: i, j, k, ii, jj, kk
    integer(c_int), parameter :: block_size = 8  ! Block size can be adjusted according to actual conditions

    remainder = mod(n, size)
    rows_per_process = n / size
    if (rank < remainder) then
        rows_per_process = rows_per_process + 1
    end if

    allocate(local_A_2d(rows_per_process, n))
    allocate(B_2d(n, n))
    allocate(local_C_2d(rows_per_process, n))

    ! Convert a one-dimensional array to a two-dimensional array
    do i = 1, rows_per_process
        do j = 1, n
            local_A_2d(i, j) = local_A((i - 1) * n + j)
        end do
    end do

    do i = 1, n
        do j = 1, n
            B_2d(i, j) = B((i - 1) * n + j)
        end do
    end do

    ! Initialize the result matrix
    local_C_2d = 0.0_c_double

    ! 分块矩阵乘法计算
    do ii = 1, rows_per_process, block_size
        do kk = 1, n, block_size
            do jj = 1, n, block_size
                do i = ii, min(ii + block_size - 1, rows_per_process)
                    do k = kk, min(kk + block_size - 1, n)
                        do j = jj, min(jj + block_size - 1, n)
                            local_C_2d(i, j) = local_C_2d(i, j) + local_A_2d(i, k) * B_2d(k, j)
                        end do
                    end do
                end do
            end do
        end do
    end do

    ! Convert a two-dimensional array to a one-dimensional array
    do i = 1, rows_per_process
        do j = 1, n
            local_C((i - 1) * n + j) = local_C_2d(i, j)
        end do
    end do

    deallocate(local_A_2d, B_2d, local_C_2d)
end subroutine matrix_multiply_double
```

Under Windows, use MSYS2's ucrt64 tool chain to compile and output the Release program. The execution effect is as follows:
```powershell
PS D:\example\efficiency_v3\fortran\blockmpi-fortran\build> mpiexec -n 20 D:/example/efficiency_v3/fortran/blockmpi-fortran/build/blockmpi-fortran_gnu_gnu_15.1.0.exe -l 10 -n 10
Using float precision for matrix multiplication.
1       : 1024 x 1024 Matrix multiply wall time : 0.050200s(42.779Gflops)
2       : 1024 x 1024 Matrix multiply wall time : 0.050326s(42.671Gflops)
3       : 1024 x 1024 Matrix multiply wall time : 0.049548s(43.341Gflops)
4       : 1024 x 1024 Matrix multiply wall time : 0.050283s(42.708Gflops)
5       : 1024 x 1024 Matrix multiply wall time : 0.048627s(44.163Gflops)
6       : 1024 x 1024 Matrix multiply wall time : 0.052763s(40.700Gflops)
7       : 1024 x 1024 Matrix multiply wall time : 0.056050s(38.314Gflops)
8       : 1024 x 1024 Matrix multiply wall time : 0.055364s(38.789Gflops)
9       : 1024 x 1024 Matrix multiply wall time : 0.051921s(41.361Gflops)
10      : 1024 x 1024 Matrix multiply wall time : 0.053460s(40.170Gflops)
Average Gflops: 41.500, Max Gflops: 44.163
Average Time: 0.051854s, Min Time: 0.048627s
PS D:\example\efficiency_v3\fortran\blockmpi-fortran\build> mpiexec -n 20 D:/example/efficiency_v3/fortran/blockmpi-fortran/build/blockmpi-fortran_gnu_gnu_15.1.0.exe -l 10 -n 10 -double
Using double precision for matrix multiplication.
1       : 1024 x 1024 Matrix multiply wall time : 0.078406s(27.389Gflops)
2       : 1024 x 1024 Matrix multiply wall time : 0.066016s(32.530Gflops)
3       : 1024 x 1024 Matrix multiply wall time : 0.067229s(31.943Gflops)
4       : 1024 x 1024 Matrix multiply wall time : 0.067948s(31.605Gflops)
5       : 1024 x 1024 Matrix multiply wall time : 0.063610s(33.760Gflops)
6       : 1024 x 1024 Matrix multiply wall time : 0.063506s(33.816Gflops)
7       : 1024 x 1024 Matrix multiply wall time : 0.063981s(33.564Gflops)
8       : 1024 x 1024 Matrix multiply wall time : 0.063603s(33.764Gflops)
9       : 1024 x 1024 Matrix multiply wall time : 0.068714s(31.252Gflops)
10      : 1024 x 1024 Matrix multiply wall time : 0.063268s(33.943Gflops)
Average Gflops: 32.357, Max Gflops: 33.943
Average Time: 0.066628s, Min Time: 0.063268s
```
It seems a bit slower than the C implementation, but in fact, the Fortran calculation function adds array conversion, storage space allocation and other functions, which increase the extra running time. Excluding this part of the overhead, the actual calculation performance should be better.

## 3. MPI parallelism and underlying optimization acceleration

### 3.1 fortran compiler optimization

Although the previous block matrix has been greatly improved, compared with the compiler's underlying optimization and professional math library mentioned above, this performance is still a bit insufficient. Now try to combine MPI with the underlying optimization of the Fortran compiler to see if the performance can be further improved.

`main.c` and `CMakeLists.txt` are basically the same as 1.2. Here, the `mpi2c.f90` file is modified to use the Fortran built-in function matmul to implement matrix operation functions:
```fortan
subroutine matrix_multiply_float(n, rank, size, local_A, B, local_C) bind(C, name="matrix_multiply_float")
    use, intrinsic :: iso_c_binding
    implicit none
    integer(c_int), value, intent(in) :: n, rank, size
    real(c_float), intent(in) :: local_A(*)
    real(c_float), intent(in) :: B(*)
    real(c_float), intent(out) :: local_C(*)
    real(c_float), allocatable :: local_A_2d(:, :)
    real(c_float), allocatable :: B_2d(:, :)
    real(c_float), allocatable :: local_C_2d(:, :)
    integer(c_int) :: rows_per_process
    integer(c_int) :: remainder
    integer(c_int) :: i, j

    remainder = mod(n, size)
    rows_per_process = n / size
    if (rank < remainder) then
        rows_per_process = rows_per_process + 1
    end if

    allocate(local_A_2d(rows_per_process, n))
    allocate(B_2d(n, n))
    allocate(local_C_2d(rows_per_process, n))

    ! Convert a one-dimensional array to a two-dimensional array
    do i = 1, rows_per_process
        do j = 1, n
            local_A_2d(i, j) = local_A((i - 1) * n + j)
        end do
    end do

    do i = 1, n
        do j = 1, n
            B_2d(i, j) = B((i - 1) * n + j)
        end do
    end do

    ! Use matmul to perform matrix multiplication
    local_C_2d = matmul(local_A_2d, B_2d)

    ! Convert a two-dimensional array to a one-dimensional array
    do i = 1, rows_per_process
        do j = 1, n
            local_C((i - 1) * n + j) = local_C_2d(i, j)
        end do
    end do

    deallocate(local_A_2d, B_2d, local_C_2d)
end subroutine matrix_multiply_float

subroutine matrix_multiply_double(n, rank, size, local_A, B, local_C) bind(C, name="matrix_multiply_double")
    use, intrinsic :: iso_c_binding
    implicit none
    integer(c_int), value, intent(in) :: n, rank, size
    real(c_double), intent(in) :: local_A(*)
    real(c_double), intent(in) :: B(*)
    real(c_double), intent(out) :: local_C(*)
    real(c_double), allocatable :: local_A_2d(:, :)
    real(c_double), allocatable :: B_2d(:, :)
    real(c_double), allocatable :: local_C_2d(:, :)
    integer(c_int) :: rows_per_process
    integer(c_int) :: remainder
    integer(c_int) :: i, j

    remainder = mod(n, size)
    rows_per_process = n / size
    if (rank < remainder) then
        rows_per_process = rows_per_process + 1
    end if

    allocate(local_A_2d(rows_per_process, n))
    allocate(B_2d(n, n))
    allocate(local_C_2d(rows_per_process, n))

    ! Convert a one-dimensional array to a two-dimensional array
    do i = 1, rows_per_process
        do j = 1, n
            local_A_2d(i, j) = local_A((i - 1) * n + j)
        end do
    end do

    do i = 1, n
        do j = 1, n
            B_2d(i, j) = B((i - 1) * n + j)
        end do
    end do

    ! Use matmul to perform matrix multiplication
    local_C_2d = matmul(local_A_2d, B_2d)

    ! Convert a two-dimensional array to a one-dimensional array
    do i = 1, rows_per_process
        do j = 1, n
            local_C((i - 1) * n + j) = local_C_2d(i, j)
        end do
    end do

    deallocate(local_A_2d, B_2d, local_C_2d)
end subroutine matrix_multiply_double
```

Compile using MSYS2's ucrt64 toolchain and execute the Release program under Windows. The results are as follows:
```powershell
PS D:\example\efficiency_v3\fortran\matmul-mpi-fortran\build> mpiexec -n 20 D:/example/efficiency_v3/fortran/matmul-mpi-fortran/build/matmul-mpi-fortran_gnu_gnu_15.1.0.exe -l 10 -n 12        
Using float precision for matrix multiplication.
1       : 4096 x 4096 Matrix multiply wall time : 0.797250s(172.391Gflops)
2       : 4096 x 4096 Matrix multiply wall time : 0.551850s(249.051Gflops)
3       : 4096 x 4096 Matrix multiply wall time : 0.560781s(245.085Gflops)
4       : 4096 x 4096 Matrix multiply wall time : 0.555596s(247.372Gflops)
5       : 4096 x 4096 Matrix multiply wall time : 0.564455s(243.490Gflops)
6       : 4096 x 4096 Matrix multiply wall time : 0.552102s(248.938Gflops)
7       : 4096 x 4096 Matrix multiply wall time : 0.588235s(233.646Gflops)
Verification failed at iteration 7: expected 1032.420410, got 1032.418823
8       : 4096 x 4096 Matrix multiply wall time : 0.582861s(235.801Gflops)
9       : 4096 x 4096 Matrix multiply wall time : 0.604666s(227.297Gflops)
10      : 4096 x 4096 Matrix multiply wall time : 0.615205s(223.404Gflops)
Average Gflops: 232.647, Max Gflops: 249.051
Average Time: 0.597300s, Min Time: 0.551850s
PS D:\example\efficiency_v3\fortran\matmul-mpi-fortran\build> mpiexec -n 20 D:/example/efficiency_v3/fortran/matmul-mpi-fortran/build/matmul-mpi-fortran_gnu_gnu_15.1.0.exe -l 10 -n 12 -double
Using double precision for matrix multiplication.
1       : 4096 x 4096 Matrix multiply wall time : 1.493319s(92.036Gflops)
2       : 4096 x 4096 Matrix multiply wall time : 1.031578s(133.232Gflops)
3       : 4096 x 4096 Matrix multiply wall time : 1.074232s(127.942Gflops)
4       : 4096 x 4096 Matrix multiply wall time : 1.051967s(130.649Gflops)
5       : 4096 x 4096 Matrix multiply wall time : 1.135295s(121.060Gflops)
6       : 4096 x 4096 Matrix multiply wall time : 1.071376s(128.283Gflops)
7       : 4096 x 4096 Matrix multiply wall time : 1.059316s(129.743Gflops)
8       : 4096 x 4096 Matrix multiply wall time : 1.061684s(129.454Gflops)
9       : 4096 x 4096 Matrix multiply wall time : 1.042263s(131.866Gflops)
10      : 4096 x 4096 Matrix multiply wall time : 1.054022s(130.395Gflops)
Average Gflops: 125.466, Max Gflops: 133.232
Average Time: 1.107505s, Min Time: 1.031578s
```
Compared with the previous matrix block algorithm, it is a great improvement. Notice that a check error occurs in single-precision floating-point operations. The single-precision floating-point check error in the main program is 0.001. Here, the numerical error increases to 0.0016, exceeding the error value set previously. As the matrix size increases, the error of floating-point operations will accumulate. A more reasonable solution is to use higher-precision floating-point operations or increase the check error. The former means that the amount of calculation increases and the performance decreases, and the latter may lead to a decrease in the credibility of the calculation results. Which price to accept needs to be determined based on the calculation occasion.

### 3.2 BLAS acceleration

The blas library demonstrated previously uses openmp to achieve parallel acceleration at the bottom layer, but the openmp library is designed to be only suitable for single-node multi-core acceleration, not for multi-node multi-core operating environments on supercomputers. Is there a way to use the blas library with mpi to achieve cross-node multi-core acceleration at the bottom layer? The implementation method is demonstrated below.

First, the main program file `main.c` is directly reused as before, and `mpi.c` is modified to add a call to the openblas function to implement matrix operation functions. Since openblas uses openmp acceleration by default, you need to manually set openblas to run as a single thread.
```C
#include <cblas.h>
#include <openblas_config.h>
#include <mpi.h>

void matrix_multiply_float(int n, int rank, int size, float local_A[], float B[], float local_C[])
{
	// Set OpenBLAS to use single thread
	openblas_set_num_threads(1);

	// Count the number of rows processed by each process
	int rows_per_process = n / size;
	int remainder = n % size;
	if (rank < remainder)
	{
		rows_per_process++;
	}

	// Local matrix multiplication using OpenBLAS
	// C = α * A * B + β * C，which α = 1.0，β = 1.0
	cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
				rows_per_process, n, n,
				1.0, local_A, n,
				B, n,
				1.0, local_C, n);
}

void matrix_multiply_double(int n, int rank, int size, double local_A[], double B[], double local_C[])
{
	// Set OpenBLAS to use single thread
	openblas_set_num_threads(1);

	// Count the number of rows processed by each process
	int rows_per_process = n / size;
	int remainder = n % size;
	if (rank < remainder)
	{
		rows_per_process++;
	}

	// Local matrix multiplication using OpenBLAS
	// C = α * A * B + β * C，which α = 1.0，β = 1.0
	cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
				rows_per_process, n, n,
				1.0, local_A, n,
				B, n,
				1.0, local_C, n);
}

```

The `CMakeLists.txt` configuration file also needs to link to openblas and openmp, otherwise the compilation will report an error.
```cmake
cmake_minimum_required(VERSION 3.13)
project(openblas-mpi LANGUAGES C CXX)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 20)

set(EXECUTE_FILE_NAME ${PROJECT_NAME}_${CMAKE_C_COMPILER_FRONTEND_VARIANT}_${CMAKE_C_COMPILER_ID}_${CMAKE_C_COMPILER_VERSION})
string(TOLOWER ${EXECUTE_FILE_NAME} EXECUTE_FILE_NAME)

# Enable MPI support
find_package(MPI REQUIRED)

# Find OpenBLAS
find_package(OpenMP REQUIRED)
find_package(OpenBLAS CONFIG REQUIRED)

set(SRC_LIST
    src/main.c
    src/mpi.c
)

add_executable(${EXECUTE_FILE_NAME} ${SRC_LIST})

target_include_directories(${EXECUTE_FILE_NAME}
    PRIVATE
    ${MPI_CXX_INCLUDE_DIRS}
)

target_link_libraries(${EXECUTE_FILE_NAME} PRIVATE
    OpenBLAS::OpenBLAS
    OpenMP::OpenMP_C
    ${MPI_LIBRARIES}
)

```

Compile under Windows, use MSYS2's ucrt64 toolchain and its own openblas, compile and output the Release program, the running effect is as follows:
```powershell
PS D:\example\efficiency_v3\c\openblas-mpi\build> mpiexec -n 10 D:/example/efficiency_v3/c/openblas-mpi/build/openblas-mpi_gnu_gnu_15.1.0.exe -l 10 -n 12
Using float precision for matrix multiplication.
1       : 4096 x 4096 Matrix multiply wall time : 0.162794s(844.252Gflops)
2       : 4096 x 4096 Matrix multiply wall time : 0.178354s(770.595Gflops)
3       : 4096 x 4096 Matrix multiply wall time : 0.201812s(681.023Gflops)
4       : 4096 x 4096 Matrix multiply wall time : 0.191400s(718.073Gflops)
5       : 4096 x 4096 Matrix multiply wall time : 0.186770s(735.872Gflops)
6       : 4096 x 4096 Matrix multiply wall time : 0.200100s(686.850Gflops)
7       : 4096 x 4096 Matrix multiply wall time : 0.182761s(752.013Gflops)
8       : 4096 x 4096 Matrix multiply wall time : 0.181107s(758.882Gflops)
9       : 4096 x 4096 Matrix multiply wall time : 0.182459s(753.258Gflops)
10      : 4096 x 4096 Matrix multiply wall time : 0.190692s(720.739Gflops)
Average Gflops: 742.156, Max Gflops: 844.252
Average Time: 0.185825s, Min Time: 0.162794s
PS D:\example\efficiency_v3\c\openblas-mpi\build> mpiexec -n 10 D:/example/efficiency_v3/c/openblas-mpi/build/openblas-mpi_gnu_gnu_15.1.0.exe -l 10 -n 12 -double
Using double precision for matrix multiplication.
1       : 4096 x 4096 Matrix multiply wall time : 0.267384s(514.013Gflops)
2       : 4096 x 4096 Matrix multiply wall time : 0.361675s(380.007Gflops)
3       : 4096 x 4096 Matrix multiply wall time : 0.338016s(406.605Gflops)
4       : 4096 x 4096 Matrix multiply wall time : 0.331837s(414.176Gflops)
5       : 4096 x 4096 Matrix multiply wall time : 0.352789s(389.578Gflops)
6       : 4096 x 4096 Matrix multiply wall time : 0.346735s(396.381Gflops)
7       : 4096 x 4096 Matrix multiply wall time : 0.343613s(399.982Gflops)
8       : 4096 x 4096 Matrix multiply wall time : 0.349749s(392.965Gflops)
9       : 4096 x 4096 Matrix multiply wall time : 0.340508s(403.629Gflops)
10      : 4096 x 4096 Matrix multiply wall time : 0.347642s(395.347Gflops)
Average Gflops: 409.268, Max Gflops: 514.013
Average Time: 0.337995s, Min Time: 0.267384s
```
It can be seen that the calculation speed has been greatly improved compared with the previous method. Hyperthreading is not used here, but the result is very close to the effect of using OpenBLAS alone to accelerate the calculation, and the double-precision floating-point calculation performance is even better. Using hyperthreading during the test did not achieve better results, and there is a high probability that the program will crash, which may be caused by the mixing of OpenMP and MPI.

# 4. Summarize

Running on a single machine, writing an MPI program requires separate control of memory and message broadcasting, which makes coding and debugging more troublesome and brings additional performance overhead. Compared with OpenMP, it has no performance advantage, but OpenMP has more advantages in coding.

The significance of MPI lies in cross-node multi-core calls on machines such as supercomputing clusters. High-performance computing programs developed using MPI are particularly suitable for acceleration through calls on large clusters and multiple nodes in such occasions.

For high-performance computing programs, using MPI alone does not make much sense for loop acceleration. Computing acceleration should be achieved in conjunction with the optimization of compilers and professional mathematical libraries.

------
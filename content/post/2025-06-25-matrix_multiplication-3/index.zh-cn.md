+++
author = "Andrew Moa"
title = "矩阵乘法运算(三)-使用MPI并行加速"
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

MPI是一种并行计算协议，也是目前高性能计算集群最为常用的接口程序。MPI通过进程间消息进行通讯，可以跨节点调用多核心执行并行计算，这是OpenMP所不具备的。不同平台均有mpi实现，比如Windows下的MS-MPI和Intel MPI，Linux下的OpenMPI和MPICH等。

## 1. MPI并行加速循环计算

### 1.1 C实现

mpi需要对主程序接口进行初始化，建立消息广播机制；同时将需要计算的数组进行分割，广播到不同的进程中。以往这些操作都是openmp或其他并行库内部实现的，程序员不需要关心底层如何实现。但使用mpi需要程序员对每个进程的全局和局部空间进行手动分配，需要控制每个消息的广播，无疑增加了额外的学习成本。

这里将`main.c`文件修改如下。
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

    // 计算每个进程处理的行数
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

        // 主进程分配完整矩阵内存
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

            // 生成校验值
            int check_row = rand() % dim;
            int check_col = rand() % dim;
            check_value = 0.0;
            for (int k = 0; k < dim; k++)
            {
                check_value += a[check_row * dim + k] * b[k * dim + check_col];
            }

            check_indices[0] = check_row;
            check_indices[1] = check_col;

            // 广播校验行列索引和校验值
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

        // 为每个进程分配局部矩阵空间
        float *local_A = (float *)malloc(rows_per_process * dim * sizeof(float));
        local_c = (float *)calloc(rows_per_process * dim, sizeof(float));
        if (local_A == NULL || local_c == NULL)
        {
            fprintf(stderr, "Memory allocation failed\n");
            return 0;
        }

        // 分发矩阵 A 的行到各个进程
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

        // 所有进程都需要完整的矩阵 B
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

        // 使用 MPI_Reduce 对所有进程的 cpu_time 求和
        MPI_Reduce(&cpu_time, &total_cpu_time, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

        if (rank == 0)
        {
            // 计算平均值
            cpu_time = total_cpu_time / size;
        }

        // 将平均值广播给所有进程
        MPI_Bcast(&cpu_time, 1, MPI_DOUBLE, 0, MPI_COMM_WORLD);

        double gflops = 1e-9 * dim * dim * dim * 2 / cpu_time;
        if (rank == 0)
        {
            printf("%d\t: %d x %d Matrix multiply wall time : %.6fs(%.3fGflops)\n", i + 1, dim, dim, cpu_time, gflops);
            fflush(stdout); // 强制刷新标准输出缓冲区
        }

        // 收集所有进程的局部结果到主进程
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

        // 主进程进行校验
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

    // 计算每个进程处理的行数
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

        // 主进程分配完整矩阵内存
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

            // 生成校验值
            int check_row = rand() % dim;
            int check_col = rand() % dim;
            check_value = 0.0;
            for (int k = 0; k < dim; k++)
            {
                check_value += a[check_row * dim + k] * b[k * dim + check_col];
            }

            check_indices[0] = check_row;
            check_indices[1] = check_col;

            // 广播校验行列索引和校验值
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

        // 为每个进程分配局部矩阵空间
        double *local_A = (double *)malloc(rows_per_process * dim * sizeof(double));
        local_c = (double *)calloc(rows_per_process * dim, sizeof(double));
        if (local_A == NULL || local_c == NULL)
        {
            fprintf(stderr, "Memory allocation failed\n");
            return 0;
        }

        // 分发矩阵 A 的行到各个进程
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

        // 所有进程都需要完整的矩阵 B
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

        // 使用 MPI_Reduce 对所有进程的 cpu_time 求和
        MPI_Reduce(&cpu_time, &total_cpu_time, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

        if (rank == 0)
        {
            // 计算平均值
            cpu_time = total_cpu_time / size;
        }

        // 将平均值广播给所有进程
        MPI_Bcast(&cpu_time, 1, MPI_DOUBLE, 0, MPI_COMM_WORLD);

        double gflops = 1e-9 * dim * dim * dim * 2 / cpu_time;
        if (rank == 0)
        {
            printf("%d\t: %d x %d Matrix multiply wall time : %.6fs(%.3fGflops)\n", i + 1, dim, dim, cpu_time, gflops);
            fflush(stdout); // 强制刷新标准输出缓冲区
        }

        // 收集所有进程的局部结果到主进程
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

        // 主进程进行校验
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
为了确保合并之后的矩阵没有错误，主程序中增加了随机坐标校验机制。

`mpi.c`是循环嵌套矩阵运算的具体实现。
```C
void matrix_multiply_float(int n, int rank, int size, float local_A[], float B[], float local_C[])
{
	// 计算每个进程处理的行数
	int rows_per_process = n / size;
	int remainder = n % size;
	if (rank < remainder)
	{
		rows_per_process++;
	}

	// 矩阵乘法运算
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
	// 计算每个进程处理的行数
	int rows_per_process = n / size;
	int remainder = n % size;
	if (rank < remainder)
	{
		rows_per_process++;
	}

	// 矩阵乘法运算
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

`CMakeLists.txt`包含mpi头文件，这里编译用的是Windows平台，对应mpi库为ms-mpi。
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

在Windows平台上使用MSYS2的ucrt64编译，输出Release程序执行效果如下：
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
计算机器CPU为AMD AI 9 365w，10核心20线程，这里使用了超线程，整体性能和openmp其实差不多。可以通过命令行控制计算进程数量。由于每个进程都需要分配局部存储空间，计算进程越多内存开销越大。

### 1.2 fortran实现

fortran也提供了mpi实现，ms-mpi和openmpi都提供了fortran的接口。限于篇幅，这里主程序源码还是采用和上一节相同的`main.c`，矩阵乘法部分通过fortran实现，通过fortran和C混合编程的方式实现程序功能。

矩阵乘法计算相关函数在fortran源文件`mpi2c.f90`里定：
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

    ! 将一维数组转换为二维数组
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

    ! 初始化结果矩阵
    local_C_2d = 0.0_c_float

    ! 矩阵乘法计算
    do i = 1, rows_per_process
        do j = 1, n
            do k = 1, n
                local_C_2d(i, j) = local_C_2d(i, j) + local_A_2d(i, k) * B_2d(k, j)
            end do
        end do
    end do

    ! 将二维数组转换为一维数组
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

    ! 将一维数组转换为二维数组
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

    ! 初始化结果矩阵
    local_C_2d = 0.0_c_double

    ! 矩阵乘法计算
    do i = 1, rows_per_process
        do j = 1, n
            do k = 1, n
                local_C_2d(i, j) = local_C_2d(i, j) + local_A_2d(i, k) * B_2d(k, j)
            end do
        end do
    end do

    ! 将二维数组转换为一维数组
    do i = 1, rows_per_process
        do j = 1, n
            local_C((i - 1) * n + j) = local_C_2d(i, j)
        end do
    end do

    deallocate(local_A_2d, B_2d, local_C_2d)
end subroutine matrix_multiply_double
```

由于C程序接口将二维矩阵存储在一维数组里，为了使fortran程序能正常读取存储在一维数组里的矩阵信息，需要定义一维数组到二维数组的转换，开辟新的存储空间。为了方便接口复用，这里把数组转换的相关内容定义到了计算函数中，会带来额外的性能开销。

`CMakeLists.txt`没太大区别，包含C的mpi头文件，激活了fortran语言支持。
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

在Windows下使用MSYS2的ucrt64工具链编译，Release程序运行效果如下：
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
以上是在和1.1相同的处理器上运行的结果，fortran数组采用了和C不同的列优先存储方式，缓存命中率提高，有利于提高矩阵运算性能。

## 2. MPI加速分块矩阵运算

### 2.1 C实现

上面的结果揭示了缓存性能对矩阵运算存在较大的影响，为了提高缓存命中率，这里尝试使用分块矩阵，看是否能提升C语言程序的计算性能。

主程序`main.c`和前面一样保持不变，这里只改动`mpi.c`，在原来的循环嵌套计算的基础上增加分块计算功能：
```C
#include <math.h>

// 分块大小，可根据缓存大小调整
#define BLOCK_SIZE 8

// Parallel matrix multiply
void matrix_multiply_float(int n, int rank, int size, float local_A[], float B[], float local_C[])
{
    // 计算每个进程处理的行数
    int rows_per_process = n / size;
    int remainder = n % size;
    if (rank < remainder)
    {
        rows_per_process++;
    }

    // 初始化 local_C 为 0
    for (int i = 0; i < rows_per_process; i++) {
        for (int j = 0; j < n; j++) {
            local_C[i * n + j] = 0.0f;
        }
    }

    // 分块矩阵乘法
    for (int bi = 0; bi < rows_per_process; bi += BLOCK_SIZE) {
        for (int bj = 0; bj < n; bj += BLOCK_SIZE) {
            for (int bk = 0; bk < n; bk += BLOCK_SIZE) {
                // 块内计算
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
    // 计算每个进程处理的行数
    int rows_per_process = n / size;
    int remainder = n % size;
    if (rank < remainder)
    {
        rows_per_process++;
    }

    // 初始化 local_C 为 0
    for (int i = 0; i < rows_per_process; i++) {
        for (int j = 0; j < n; j++) {
            local_C[i * n + j] = 0.0;
        }
    }

    // 分块矩阵乘法
    for (int bi = 0; bi < rows_per_process; bi += BLOCK_SIZE) {
        for (int bj = 0; bj < n; bj += BLOCK_SIZE) {
            for (int bk = 0; bk < n; bk += BLOCK_SIZE) {
                // 块内计算
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

`CMakeLists.txt`文件和1.1中的相同。

在Windows下使用MSYS2的ucrt64工具链编译，程序执行效果如下：
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
这里分块大小设置为8，是根据大量测试得出的最优结果。在其他平台上实施，需要针对该平台硬件进行测试，才能确定最合适的分块大小。

### 2.2 fortran实现

接下来用fortran实现分块矩阵mpi加速功能，看看性能是否有提升。

`main.c`和`CMakeLists.txt`基本和1.2相同，只改动`mpi2c.f90`文件，增加分块内容：
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
    integer(c_int), parameter :: block_size = 8  ! 分块大小，可根据实际情况调整

    remainder = mod(n, size)
    rows_per_process = n / size
    if (rank < remainder) then
        rows_per_process = rows_per_process + 1
    end if

    allocate(local_A_2d(rows_per_process, n))
    allocate(B_2d(n, n))
    allocate(local_C_2d(rows_per_process, n))

    ! 将一维数组转换为二维数组
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

    ! 初始化结果矩阵
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

    ! 将二维数组转换为一维数组
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
    integer(c_int), parameter :: block_size = 8  ! 分块大小，可根据实际情况调整

    remainder = mod(n, size)
    rows_per_process = n / size
    if (rank < remainder) then
        rows_per_process = rows_per_process + 1
    end if

    allocate(local_A_2d(rows_per_process, n))
    allocate(B_2d(n, n))
    allocate(local_C_2d(rows_per_process, n))

    ! 将一维数组转换为二维数组
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

    ! 初始化结果矩阵
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

    ! 将二维数组转换为一维数组
    do i = 1, rows_per_process
        do j = 1, n
            local_C((i - 1) * n + j) = local_C_2d(i, j)
        end do
    end do

    deallocate(local_A_2d, B_2d, local_C_2d)
end subroutine matrix_multiply_double
```

Windows下使用MSYS2的ucrt64工具链编译输出Release程序，执行效果如下：
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
看上去比C实现的要慢一点，但实际上fortran计算函数内部增加了数组转换、开辟存储空间等功能增加了额外的运行时间。除去这部分开销，实际计算性能应该会更好一点。

## 3. MPI并行配合底层优化加速

### 3.1 fortran编译器优化

虽然前面的分块矩阵已经有了很大的提升，但和之前提到的编译器底层优化和专业数学库比起来，这点性能还是有点不够。现在尝试将mpi配合fortran编译器的底层优化，看能否在性能上进一步提升。

`main.c`和`CMakeLists.txt`基本和1.2相同，这里改动`mpi2c.f90`文件，使用fortran内置函数matmul实现矩阵运算功能：
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

    ! 将一维数组转换为二维数组
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

    ! 使用 matmul 进行矩阵乘法计算
    local_C_2d = matmul(local_A_2d, B_2d)

    ! 将二维数组转换为一维数组
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

    ! 将一维数组转换为二维数组
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

    ! 使用 matmul 进行矩阵乘法计算
    local_C_2d = matmul(local_A_2d, B_2d)

    ! 将二维数组转换为一维数组
    do i = 1, rows_per_process
        do j = 1, n
            local_C((i - 1) * n + j) = local_C_2d(i, j)
        end do
    end do

    deallocate(local_A_2d, B_2d, local_C_2d)
end subroutine matrix_multiply_double
```

使用MSYS2的ucrt64工具编译，在Windows下执行Release程序，效果如下：
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
相比前面的矩阵分块算法有很大的提升。注意到单精度浮点数运算时出现一个校验错误，主程序中单精度浮点数校验误差是0.001，这里数值误差增加到了0.0016，超过了前面设定的误差值。在矩阵规模增大时浮点数运算的误差会累积增加，比较合理的解决办法是采用更高精度的浮点数运算或者加大校验误差，前者意味着计算量增加性能下降时间变长，后者则可能导致计算结果可信度降低，究竟该接受哪种代价需要区分计算场合来决定。

### 3.2 BLAS加速

之前演示的blas库底层都通过openmp实现并行加速，但设计上openmp库只适合单节点多核心加速，不适合超算上的多节点多核心的运行环境。有没有一种办法底层可以利用blas库搭配mpi实现跨节点多核心加速呢？下面演示一下实现方法。

首先主程序文件`main.c`和前面一样直接复用，改动`mpi.c`增加调用openblas函数实现矩阵运算功能。由于openblas默认使用openmp加速，需要手动设置openblas为单线程运行。
```C
#include <cblas.h>
#include <openblas_config.h>
#include <mpi.h>

void matrix_multiply_float(int n, int rank, int size, float local_A[], float B[], float local_C[])
{
	// 设置 OpenBLAS 使用单线程
	openblas_set_num_threads(1);

	// 计算每个进程处理的行数
	int rows_per_process = n / size;
	int remainder = n % size;
	if (rank < remainder)
	{
		rows_per_process++;
	}

	// 使用 OpenBLAS 进行局部矩阵乘法
	// C = α * A * B + β * C，这里 α = 1.0，β = 1.0
	cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
				rows_per_process, n, n,
				1.0, local_A, n,
				B, n,
				1.0, local_C, n);
}

void matrix_multiply_double(int n, int rank, int size, double local_A[], double B[], double local_C[])
{
	// 设置 OpenBLAS 使用单线程
	openblas_set_num_threads(1);

	// 计算每个进程处理的行数
	int rows_per_process = n / size;
	int remainder = n % size;
	if (rank < remainder)
	{
		rows_per_process++;
	}

	// 使用 OpenBLAS 进行局部矩阵乘法
	// C = α * A * B + β * C，这里 α = 1.0，β = 1.0
	cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
				rows_per_process, n, n,
				1.0, local_A, n,
				B, n,
				1.0, local_C, n);
}

```

`CMakeLists.txt`中还需要链接到openblas和openmp，否则无法通过编译。
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

在Windows下编译，使用MSYS2的ucrt64工具链和其自带的openblas，编译输出Release程序，运行效果如下：
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
可以看到计算速度相比于前面的方法已经有了很大的提升。这里没有用到超线程，但是这个结果已经和单独使用openblas加速运算的效果十分接近了，双精度浮点运算性能甚至要更好一些。测试过程中使用超线程没能达成更好的效果，而且有很大几率会导致程序崩溃，可能是openmp和mpi混用所导致的。

# 4. 总结

在单机上运行，编写mpi程序需要单独控制内存和消息广播，编码和调试更加麻烦，而且会带来额外的性能开销，跟openmp相比没有性能上的优势，反而openmp编码上更有优势。

mpi存在的意义在于超算集群等机器上的跨节点多核调用，使用mpi开发的高性能计算程序尤其适合在这种场合下通过大集群多节点的调用进行加速。

对高性能计算程序而言，单独使用mpi对循环加速其实没有多大意义，应配合编译器和专业数学库的优化实现计算加速。

------
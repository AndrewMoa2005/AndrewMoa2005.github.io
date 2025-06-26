+++
author = "Andrew Moa"
title = "Matrix multiplication operation (Ⅱ) - Accelerated operation based on BLAS library"
date = "2025-06-24"
description = ""
tags = [
    "c++",
]
categories = [
    "code",
]
series = [""]
aliases = [""]
image = "/images/code-bg.jpg"
+++

BLAS was originally developed as a linear algebra library using Fortran, and was later ported to C/C++. As a core component of modern high-performance computing, it has formed a set of standards. There are open source implementations such as Netlib BLAS, GotoBLAS and its successor OpenBLAS. Commercially, each manufacturer has corresponding implementations for its own platform, such as Intel's MKL, NVIDIA's CUDA, AMD's AOCL and ROCm. Some of them are optimized for CPU platforms, and some use GPU parallel acceleration. This article uses different BLAS libraries to implement matrix operations and analyzes the performance differences between different implementations.

## 1. CPU parallel accelerated BLAS library

### 1.1 Intel MKL

The `main.c` file is the same as 2.1 in [Matrix multiplication operation (I) - using OpenMP to speed up loop calculation](../2025-06-23-matrix_multiplication-1). `blas.c` imports the BLAS library of mkl and uses the GEMM function to perform matrix multiplication operations.
```C
#include <mkl_cblas.h>

void matrix_multiply_float(int n, float A[], float B[], float C[])
{
    cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
                n, n, n, 1.0, A, n, B, n, 0.0, C, n);
}

void matrix_multiply_double(int n, double A[], double B[], double C[])
{
    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
                n, n, n, 1.0, A, n, B, n, 0.0, C, n);
}
```

The `CMakeLists.txt` configuration file includes the mkl and openmp library files. The mkl underlying layer uses openmp for parallelization by default, so it is necessary to link to the openmp library.
```cmake
cmake_minimum_required(VERSION 3.13)
project(mkl LANGUAGES C)
set(CMAKE_C_STANDARD 11)

set(EXECUTE_FILE_NAME ${PROJECT_NAME}_${CMAKE_C_COMPILER_FRONTEND_VARIANT}_${CMAKE_C_COMPILER_ID}_${CMAKE_C_COMPILER_VERSION})
string(TOLOWER ${EXECUTE_FILE_NAME} EXECUTE_FILE_NAME)

set(MKL_LINK static)

# Enable OpenMP
find_package(OpenMP REQUIRED)

# Enable MKL
find_package(MKL CONFIG REQUIRED)

set(SRC_LIST
    src/main.c
    src/blas.c
)

add_executable(${EXECUTE_FILE_NAME} ${SRC_LIST})

target_compile_options(${EXECUTE_FILE_NAME} PUBLIC
    $<TARGET_PROPERTY:MKL::MKL,INTERFACE_COMPILE_OPTIONS>
)
target_include_directories(${EXECUTE_FILE_NAME} PUBLIC
    $<TARGET_PROPERTY:MKL::MKL,INTERFACE_INCLUDE_DIRECTORIES>
)
target_link_libraries(${EXECUTE_FILE_NAME} PUBLIC
    OpenMP::OpenMP_C
    $<LINK_ONLY:MKL::MKL>
)

```

The compilation machine used here is an AMD laptop with an AI 9 365w processor. It is compiled and run using clang-cl of vs2022 under Windows. The execution effect of the Release program is as follows:
```powershell
PS D:\example\efficiency_v3\c\mkl\build\Release> ."D:/example/efficiency_v3/c/mkl/build/Release/mkl_msvc_clang_19.1.5.exe" -l 10 -n 12
Using float precision for matrix multiplication.
1       : 4096 x 4096 Matrix multiply wall time : 0.218935s(627.761Gflops)
2       : 4096 x 4096 Matrix multiply wall time : 0.211711s(649.183Gflops)
3       : 4096 x 4096 Matrix multiply wall time : 0.215178s(638.722Gflops)
4       : 4096 x 4096 Matrix multiply wall time : 0.223452s(615.072Gflops)
5       : 4096 x 4096 Matrix multiply wall time : 0.202687s(678.085Gflops)
6       : 4096 x 4096 Matrix multiply wall time : 0.203175s(676.455Gflops)
7       : 4096 x 4096 Matrix multiply wall time : 0.225790s(608.702Gflops)
8       : 4096 x 4096 Matrix multiply wall time : 0.204435s(672.287Gflops)
9       : 4096 x 4096 Matrix multiply wall time : 0.217666s(631.421Gflops)
10      : 4096 x 4096 Matrix multiply wall time : 0.217374s(632.270Gflops)
Average Gflops: 642.996, Max Gflops: 678.085
Average Time: 0.214040s, Min Time: 0.202687s
PS D:\example\efficiency_v3\c\mkl\build\Release> ."D:/example/efficiency_v3/c/mkl/build/Release/mkl_msvc_clang_19.1.5.exe" -l 10 -n 12 -double
Using double precision for matrix multiplication.
1       : 4096 x 4096 Matrix multiply wall time : 0.400238s(343.393Gflops)
2       : 4096 x 4096 Matrix multiply wall time : 0.365257s(376.280Gflops)
3       : 4096 x 4096 Matrix multiply wall time : 0.375613s(365.906Gflops)
4       : 4096 x 4096 Matrix multiply wall time : 0.353108s(389.226Gflops)
5       : 4096 x 4096 Matrix multiply wall time : 0.380444s(361.260Gflops)
6       : 4096 x 4096 Matrix multiply wall time : 0.381736s(360.036Gflops)
7       : 4096 x 4096 Matrix multiply wall time : 0.392378s(350.272Gflops)
8       : 4096 x 4096 Matrix multiply wall time : 0.382949s(358.897Gflops)
9       : 4096 x 4096 Matrix multiply wall time : 0.401440s(342.365Gflops)
10      : 4096 x 4096 Matrix multiply wall time : 0.413794s(332.143Gflops)
Average Gflops: 357.978, Max Gflops: 389.226
Average Time: 0.384696s, Min Time: 0.353108s
```
To run Intel mkl programs properly on AMD machines, it is recommended to add `MKL_DEBUG_CPU_TYPE=5` to the environment variables.

The results of running on an Intel workstation (Xeon Gold 6226R) are as follows:
```powershell
PS E:\example\efficiency_v3\run> ./mkl_msvc_clang_19.1.5.exe -l 10 -n 14
Using float precision for matrix multiplication.
1       : 16384 x 16384 Matrix multiply wall time : 4.505398s(1952.345Gflops)
2       : 16384 x 16384 Matrix multiply wall time : 4.513220s(1948.962Gflops)
3       : 16384 x 16384 Matrix multiply wall time : 4.472770s(1966.587Gflops)
4       : 16384 x 16384 Matrix multiply wall time : 4.478043s(1964.272Gflops)
5       : 16384 x 16384 Matrix multiply wall time : 4.487709s(1960.041Gflops)
6       : 16384 x 16384 Matrix multiply wall time : 4.467270s(1969.009Gflops)
7       : 16384 x 16384 Matrix multiply wall time : 4.399587s(1999.299Gflops)
8       : 16384 x 16384 Matrix multiply wall time : 4.511694s(1949.621Gflops)
9       : 16384 x 16384 Matrix multiply wall time : 4.477332s(1964.584Gflops)
10      : 16384 x 16384 Matrix multiply wall time : 4.459314s(1972.521Gflops)
Average Gflops: 1964.724, Max Gflops: 1999.299
Average Time: 4.477234s, Min Time: 4.399587s
PS E:\example\efficiency_v3\run> ./mkl_msvc_clang_19.1.5.exe -l 10 -n 14 -double
Using double precision for matrix multiplication.
1       : 16384 x 16384 Matrix multiply wall time : 10.416302s(844.455Gflops)
2       : 16384 x 16384 Matrix multiply wall time : 10.291459s(854.698Gflops)
3       : 16384 x 16384 Matrix multiply wall time : 10.229627s(859.865Gflops)
4       : 16384 x 16384 Matrix multiply wall time : 10.319844s(852.347Gflops)
5       : 16384 x 16384 Matrix multiply wall time : 10.277702s(855.842Gflops)
6       : 16384 x 16384 Matrix multiply wall time : 10.134144s(867.966Gflops)
7       : 16384 x 16384 Matrix multiply wall time : 10.602970s(829.588Gflops)
8       : 16384 x 16384 Matrix multiply wall time : 10.421812s(844.008Gflops)
9       : 16384 x 16384 Matrix multiply wall time : 10.096355s(871.215Gflops)
10      : 16384 x 16384 Matrix multiply wall time : 10.168106s(865.067Gflops)
Average Gflops: 854.505, Max Gflops: 871.215
Average Time: 10.295832s, Min Time: 10.096355s
```

For BLAS, the smaller the matrix size, the less obvious the acceleration effect. However, the larger the matrix size, the better. There is always an upper limit. The appropriate matrix size depends on the performance of the CPU and cache. Different platforms are suitable for different matrix operation scales.

### 1.2 OpenBLAS

Considering that Intel's library may have a lower execution efficiency on AMD platforms, we will try to replace mkl with openblas. Here we only change the header file referenced by blas.c, and keep the rest unchanged:
```C
#include <cblas.h>

void matrix_multiply_float(int n, float A[], float B[], float C[])
{
    cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
                n, n, n, 1.0, A, n, B, n, 0.0, C, n);
}

void matrix_multiply_double(int n, double A[], double B[], double C[])
{
    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
                n, n, n, 1.0, A, n, B, n, 0.0, C, n);
}
```

The `CMakeLists.txt` configuration file contains openblas and openmp. Yes, the underlying layer of openblas is also parallelized through openmp.
```cmake
cmake_minimum_required(VERSION 3.13)
project(openblas LANGUAGES C)
set(CMAKE_C_STANDARD 11)

set(EXECUTE_FILE_NAME ${PROJECT_NAME}_${CMAKE_C_COMPILER_FRONTEND_VARIANT}_${CMAKE_C_COMPILER_ID}_${CMAKE_C_COMPILER_VERSION})
string(TOLOWER ${EXECUTE_FILE_NAME} EXECUTE_FILE_NAME)

# Enable OpenBLAS and OpenMP
find_package(OpenMP REQUIRED)
find_package(OpenBLAS CONFIG REQUIRED)

set(SRC_LIST
    src/main.c
    src/blas.c
)

add_executable(${EXECUTE_FILE_NAME} ${SRC_LIST})

target_link_libraries(${EXECUTE_FILE_NAME} PRIVATE
    OpenBLAS::OpenBLAS
    OpenMP::OpenMP_C
)
```

Compile and run on an AMD machine, and use MSYS2's ucrt64 toolchain to compile and output the Release program under Windows. The execution effect is as follows:
```powershell
PS D:\example\efficiency_v3\c\openblas\build> ."D:/example/efficiency_v3/c/openblas/build/openblas_gnu_gnu_15.1.0.exe" -l 10 -n 12
Using float precision for matrix multiplication.
1       : 4096 x 4096 Matrix multiply wall time : 0.155257s(885.234Gflops)
2       : 4096 x 4096 Matrix multiply wall time : 0.154143s(891.633Gflops)
3       : 4096 x 4096 Matrix multiply wall time : 0.159396s(862.251Gflops)
4       : 4096 x 4096 Matrix multiply wall time : 0.159194s(863.341Gflops)
5       : 4096 x 4096 Matrix multiply wall time : 0.154769s(888.027Gflops)
6       : 4096 x 4096 Matrix multiply wall time : 0.160298s(857.398Gflops)
7       : 4096 x 4096 Matrix multiply wall time : 0.158431s(867.502Gflops)
8       : 4096 x 4096 Matrix multiply wall time : 0.153623s(894.649Gflops)
9       : 4096 x 4096 Matrix multiply wall time : 0.164457s(835.712Gflops)
10      : 4096 x 4096 Matrix multiply wall time : 0.145844s(942.366Gflops)
Average Gflops: 878.811, Max Gflops: 942.366
Average Time: 0.156541s, Min Time: 0.145844s
PS D:\example\efficiency_v3\c\openblas\build> ."D:/example/efficiency_v3/c/openblas/build/openblas_gnu_gnu_15.1.0.exe" -l 10 -n 12 -double
Using double precision for matrix multiplication.
1       : 4096 x 4096 Matrix multiply wall time : 0.342961s(400.743Gflops)
2       : 4096 x 4096 Matrix multiply wall time : 0.366820s(374.677Gflops)
3       : 4096 x 4096 Matrix multiply wall time : 0.331864s(414.143Gflops)
4       : 4096 x 4096 Matrix multiply wall time : 0.324773s(423.185Gflops)
5       : 4096 x 4096 Matrix multiply wall time : 0.370822s(370.634Gflops)
6       : 4096 x 4096 Matrix multiply wall time : 0.387845s(354.365Gflops)
7       : 4096 x 4096 Matrix multiply wall time : 0.353893s(388.363Gflops)
8       : 4096 x 4096 Matrix multiply wall time : 0.344588s(398.851Gflops)
9       : 4096 x 4096 Matrix multiply wall time : 0.359606s(382.193Gflops)
10      : 4096 x 4096 Matrix multiply wall time : 0.379676s(361.990Gflops)
Average Gflops: 386.914, Max Gflops: 423.185
Average Time: 0.356285s, Min Time: 0.324773s
```
The performance of openblas on the AMD platform is indeed much better than that of Intel mkl.

The results of running on an Intel workstation are as follows:
```powershell
PS E:\example\efficiency_v3\run> ./openblas_gnu_gnu_15.1.0.exe -l 10 -n 14
Using float precision for matrix multiplication.
1       : 16384 x 16384 Matrix multiply wall time : 5.334670s(1648.854Gflops)
2       : 16384 x 16384 Matrix multiply wall time : 5.288424s(1663.273Gflops)
3       : 16384 x 16384 Matrix multiply wall time : 5.288376s(1663.288Gflops)
4       : 16384 x 16384 Matrix multiply wall time : 5.280766s(1665.685Gflops)
5       : 16384 x 16384 Matrix multiply wall time : 5.203108s(1690.546Gflops)
6       : 16384 x 16384 Matrix multiply wall time : 5.283861s(1664.709Gflops)
7       : 16384 x 16384 Matrix multiply wall time : 5.313183s(1655.522Gflops)
8       : 16384 x 16384 Matrix multiply wall time : 5.247752s(1676.164Gflops)
9       : 16384 x 16384 Matrix multiply wall time : 5.229815s(1681.913Gflops)
10      : 16384 x 16384 Matrix multiply wall time : 5.205896s(1689.641Gflops)
Average Gflops: 1669.960, Max Gflops: 1690.546
Average Time: 5.267585s, Min Time: 5.203108s
PS E:\example\efficiency_v3\run> ./openblas_gnu_gnu_15.1.0.exe -l 10 -n 14 -double
Using double precision for matrix multiplication.
1       : 16384 x 16384 Matrix multiply wall time : 12.076276s(728.378Gflops)
2       : 16384 x 16384 Matrix multiply wall time : 12.136422s(724.768Gflops)
3       : 16384 x 16384 Matrix multiply wall time : 12.155159s(723.651Gflops)
4       : 16384 x 16384 Matrix multiply wall time : 12.246918s(718.229Gflops)
5       : 16384 x 16384 Matrix multiply wall time : 12.240157s(718.626Gflops)
6       : 16384 x 16384 Matrix multiply wall time : 12.205895s(720.643Gflops)
7       : 16384 x 16384 Matrix multiply wall time : 12.001869s(732.894Gflops)
8       : 16384 x 16384 Matrix multiply wall time : 12.127655s(725.292Gflops)
9       : 16384 x 16384 Matrix multiply wall time : 12.195832s(721.238Gflops)
10      : 16384 x 16384 Matrix multiply wall time : 12.124491s(725.481Gflops)
Average Gflops: 723.920, Max Gflops: 732.894
Average Time: 12.151067s, Min Time: 12.001869s
```
Openblas performs worse than mkl on Intel platform.

### 1.3 AMD AOCL

Next, let's see how AMD's own blas library performs. AOCL[^1] is a CPU optimization library launched by AMD for its own platform. It contains library files related to mathematical operations such as blas, lapack, and fftw, which are used to accelerate mathematical calculation tasks on AMD CPUs.
As in 1.2, the header file is also `cblas.h`, and this time even `blas.c` does not need to be changed. `CMakeLists.txt` is as follows. When configuring cmake, you need to pass the AOCL installation path `AOCL_DIR` parameter, and the data model `AOCL_BLAS_DATA` uses `LP64` by default. The AOCL used for demonstration is version 5.1 under Windows. Other versions may need to be adjusted according to the installation package file.
```cmake
cmake_minimum_required(VERSION 3.13)
project(aocl LANGUAGES C)
set(CMAKE_C_STANDARD 11)

set(EXECUTE_FILE_NAME ${PROJECT_NAME}_${CMAKE_C_COMPILER_FRONTEND_VARIANT}_${CMAKE_C_COMPILER_ID}_${CMAKE_C_COMPILER_VERSION})
string(TOLOWER ${EXECUTE_FILE_NAME} EXECUTE_FILE_NAME)

# setting aocl directory
if(DEFINED AOCL_DIR)
    message(STATUS "AOCL_DIR is set to: ${AOCL_DIR}")
else()
    message(FATAL_ERROR "AOCL_DIR is not defined. Please set it to the AOCL installation directory.")
endif()

if(NOT DEFINED AOCL_BLAS_DATA)
    set(AOCL_BLAS_DATA LP64)
    message(STATUS "AOCL_BLAS_DATA is not defined. Use default value: ${AOCL_BLAS_DATA}")
else()
    message(STATUS "AOCL_BLAS_DATA is set to: ${AOCL_BLAS_DATA}")
endif()

# Enable AOCL BLAS
set(AOCL_BLIS_INCLUDE_DIRS ${AOCL_DIR}/amd-blis/include/${AOCL_BLAS_DATA})
set(AOCL_BLIS_LINK_DIR ${AOCL_DIR}/amd-blis/lib/${AOCL_BLAS_DATA})
set(AOCL_BLIS_LIBS AOCL-LibBlis-Win-MT.lib)

# find OpenMP
find_package(OpenMP REQUIRED)

set(SRC_LIST
    src/main.c
    src/blas.c
)

add_executable(${EXECUTE_FILE_NAME} ${SRC_LIST})

target_include_directories(${EXECUTE_FILE_NAME} PRIVATE
    ${AOCL_BLIS_INCLUDE_DIRS}
)
target_link_directories(${EXECUTE_FILE_NAME} PRIVATE
    ${AOCL_BLIS_LINK_DIR}
)

target_link_libraries(${EXECUTE_FILE_NAME} PRIVATE
    ${AOCL_BLIS_LIBS}
    OpenMP::OpenMP_C
)
```

Compile using clang-cl of vs2022 on an AMD machine. The parameters passed here are:
```powershell
PS D:\example\efficiency_v3\c\aocl\build\Release> ."D:/example/efficiency_v3/c/aocl/build/Release/aocl_msvc_clang_19.1.5.exe" -l 10 -n 12
Using float precision for matrix multiplication.
1       : 4096 x 4096 Matrix multiply wall time : 0.174192s(789.010Gflops)
2       : 4096 x 4096 Matrix multiply wall time : 0.173520s(792.065Gflops)
3       : 4096 x 4096 Matrix multiply wall time : 0.207043s(663.819Gflops)
4       : 4096 x 4096 Matrix multiply wall time : 0.174526s(787.497Gflops)
5       : 4096 x 4096 Matrix multiply wall time : 0.179918s(763.899Gflops)
6       : 4096 x 4096 Matrix multiply wall time : 0.154489s(889.637Gflops)
7       : 4096 x 4096 Matrix multiply wall time : 0.157877s(870.547Gflops)
8       : 4096 x 4096 Matrix multiply wall time : 0.165565s(830.119Gflops)
9       : 4096 x 4096 Matrix multiply wall time : 0.156284s(879.416Gflops)
10      : 4096 x 4096 Matrix multiply wall time : 0.207975s(660.843Gflops)
Average Gflops: 792.685, Max Gflops: 889.637
Average Time: 0.175139s, Min Time: 0.154489s
PS D:\example\efficiency_v3\c\aocl\build\Release> ."D:/example/efficiency_v3/c/aocl/build/Release/aocl_msvc_clang_19.1.5.exe" -l 10 -n 12 -double
Using double precision for matrix multiplication.
1       : 4096 x 4096 Matrix multiply wall time : 0.307589s(446.827Gflops)
2       : 4096 x 4096 Matrix multiply wall time : 0.348955s(393.859Gflops)
3       : 4096 x 4096 Matrix multiply wall time : 0.292173s(470.403Gflops)
4       : 4096 x 4096 Matrix multiply wall time : 0.296039s(464.259Gflops)
5       : 4096 x 4096 Matrix multiply wall time : 0.291551s(471.407Gflops)
6       : 4096 x 4096 Matrix multiply wall time : 0.316478s(434.277Gflops)
7       : 4096 x 4096 Matrix multiply wall time : 0.306831s(447.931Gflops)
8       : 4096 x 4096 Matrix multiply wall time : 0.302522s(454.311Gflops)
9       : 4096 x 4096 Matrix multiply wall time : 0.291020s(472.266Gflops)
10      : 4096 x 4096 Matrix multiply wall time : 0.301170s(456.351Gflops)
Average Gflops: 451.189, Max Gflops: 472.266
Average Time: 0.305433s, Min Time: 0.291020s
```
On AMD machines, the single-precision floating point performance is slightly inferior to OpenBLAS, the double-precision floating point performance is better than OpenBLAS, and the overall performance is stronger than Intel MKL.

The running results on Intel workstations are as follows:
```powershell
PS E:\example\efficiency_v3\run> ./aocl_msvc_clang_19.1.5.exe -l 10 -n 14
Using float precision for matrix multiplication.
1       : 16384 x 16384 Matrix multiply wall time : 5.475668s(1606.396Gflops)
2       : 16384 x 16384 Matrix multiply wall time : 5.130221s(1714.564Gflops)
3       : 16384 x 16384 Matrix multiply wall time : 5.183950s(1696.794Gflops)
4       : 16384 x 16384 Matrix multiply wall time : 5.265062s(1670.653Gflops)
5       : 16384 x 16384 Matrix multiply wall time : 5.232872s(1680.930Gflops)
6       : 16384 x 16384 Matrix multiply wall time : 4.979762s(1766.368Gflops)
7       : 16384 x 16384 Matrix multiply wall time : 5.069269s(1735.180Gflops)
8       : 16384 x 16384 Matrix multiply wall time : 5.059971s(1738.368Gflops)
9       : 16384 x 16384 Matrix multiply wall time : 5.063930s(1737.009Gflops)
10      : 16384 x 16384 Matrix multiply wall time : 5.029378s(1748.942Gflops)
Average Gflops: 1709.521, Max Gflops: 1766.368
Average Time: 5.149008s, Min Time: 4.979762s
PS E:\example\efficiency_v3\run> ./aocl_msvc_clang_19.1.5.exe -l 10 -n 14 -double
Using double precision for matrix multiplication.
1       : 16384 x 16384 Matrix multiply wall time : 10.912167s(806.081Gflops)
2       : 16384 x 16384 Matrix multiply wall time : 10.452268s(841.549Gflops)
3       : 16384 x 16384 Matrix multiply wall time : 10.402997s(845.535Gflops)
4       : 16384 x 16384 Matrix multiply wall time : 10.937584s(804.208Gflops)
5       : 16384 x 16384 Matrix multiply wall time : 10.529708s(835.360Gflops)
6       : 16384 x 16384 Matrix multiply wall time : 10.834290s(811.875Gflops)
7       : 16384 x 16384 Matrix multiply wall time : 10.291204s(854.720Gflops)
8       : 16384 x 16384 Matrix multiply wall time : 10.675223s(823.973Gflops)
9       : 16384 x 16384 Matrix multiply wall time : 10.651213s(825.830Gflops)
10      : 16384 x 16384 Matrix multiply wall time : 10.510095s(836.918Gflops)
Average Gflops: 828.605, Max Gflops: 854.720
Average Time: 10.619675s, Min Time: 10.291204s
```
The performance of aocl on Intel platform is even better than openblas and second only to mkl.

## 2. GPU parallel accelerated BLAS library

### 2.1 CUDA

cuda is a high-performance computing toolkit developed by Nvidia specifically for its own graphics cards, which includes cublas to implement blas functions.
The `main.c` main program file remains unchanged, and a new `cuda.cu` file is created to implement cuda accelerated matrix multiplication operations.
```C++
#include <cublas_v2.h>
#include <cuda_runtime.h>
#include <stdio.h>

extern "C" void matrix_multiply_float(int n, float A[], float B[], float C[])
{
  cublasStatus_t status;
  cublasHandle_t handle;
  float *d_A = 0;
  float *d_B = 0;
  float *d_C = 0;
  float alpha = 1.0;
  float beta = 0.0;
  cudaMalloc((void **)&d_A, n * n * sizeof(d_A[0]));
  cudaMalloc((void **)&d_B, n * n * sizeof(d_B[0]));
  cudaMalloc((void **)&d_C, n * n * sizeof(d_C[0]));

  cublasSetVector(n * n, sizeof(*A), A, 1, d_A, 1);
  cublasSetVector(n * n, sizeof(*B), B, 1, d_B, 1);
  cublasSetVector(n * n, sizeof(*C), C, 1, d_C, 1);
  status = cublasCreate(&handle);
  if (status != CUBLAS_STATUS_SUCCESS)
  {
    fprintf(stderr, "!!!! CUBLAS initialization error\n");
    return;
  }

  status = cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, n, n, n, &alpha, d_A,
                       n, d_B, n, &beta, d_C, n);
  if (status != CUBLAS_STATUS_SUCCESS)
  {
    fprintf(stderr, "!!!! CUBLAS Sgemm error\n");
    return;
  }

  cudaFree(d_A);
  cudaFree(d_B);
  cudaFree(d_C);
  status = cublasDestroy(handle);
  if (status != CUBLAS_STATUS_SUCCESS)
  {
    fprintf(stderr, "!!!! shutdown error (A)\n");
    return;
  }
}

extern "C" void matrix_multiply_double(int n, double A[], double B[], double C[])
{
  cublasStatus_t status;
  cublasHandle_t handle;
  double *d_A = 0;
  double *d_B = 0;
  double *d_C = 0;
  double alpha = 1.0;
  double beta = 0.0;
  cudaMalloc((void **)&d_A, n * n * sizeof(d_A[0]));
  cudaMalloc((void **)&d_B, n * n * sizeof(d_B[0]));
  cudaMalloc((void **)&d_C, n * n * sizeof(d_C[0]));

  cublasSetVector(n * n, sizeof(*A), A, 1, d_A, 1);
  cublasSetVector(n * n, sizeof(*B), B, 1, d_B, 1);
  cublasSetVector(n * n, sizeof(*C), C, 1, d_C, 1);
  status = cublasCreate(&handle);
  if (status != CUBLAS_STATUS_SUCCESS)
  {
    fprintf(stderr, "!!!! CUBLAS initialization error\n");
    return;
  }

  status = cublasDgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, n, n, n, &alpha, d_A,
                       n, d_B, n, &beta, d_C, n);
  if (status != CUBLAS_STATUS_SUCCESS)
  {
    fprintf(stderr, "!!!! CUBLAS Dgemm error\n");
    return;
  }

  cudaFree(d_A);
  cudaFree(d_B);
  cudaFree(d_C);
  status = cublasDestroy(handle);
  if (status != CUBLAS_STATUS_SUCCESS)
  {
    fprintf(stderr, "!!!! shutdown error (A)\n");
    return;
  }
}
```

The `CMakeLists.txt` file is as follows. CMake will automatically call `nvcc` to compile the cuda source file, which needs to be linked to the cublas library and the cuda runtime.
```cmake
cmake_minimum_required(VERSION 3.13)
project(cuda LANGUAGES C)
set(CMAKE_C_STANDARD 11)
enable_language(CUDA)
set(CMAKE_CUDA_ARCHITECTURES OFF)

set(EXECUTE_FILE_NAME ${PROJECT_NAME}_${CMAKE_C_COMPILER_FRONTEND_VARIANT}_${CMAKE_C_COMPILER_ID}_${CMAKE_C_COMPILER_VERSION})
string(TOLOWER ${EXECUTE_FILE_NAME} EXECUTE_FILE_NAME)

set(SRC_LIST
    src/main.c
    src/cuda.cu
)

add_executable(${EXECUTE_FILE_NAME}
    ${SRC_LIST}
)

target_link_libraries(${EXECUTE_FILE_NAME} PRIVATE
    cublas
    cudart
)
```

The cuda toolkit version 12.9 is used for compilation here, and the compiler is msvc of vs2022. The running effect on the NVIDIA RTX A4000 single-card workstation is as follows:
```powershell
PS E:\example\efficiency_v3\run> ./cuda_msvc_msvc_19.44.35209.0.exe -l 10 -n 14
Using float precision for matrix multiplication.
1       : 16384 x 16384 Matrix multiply wall time : 2.473336s(3556.369Gflops)
2       : 16384 x 16384 Matrix multiply wall time : 2.124057s(4141.175Gflops)
3       : 16384 x 16384 Matrix multiply wall time : 2.141353s(4107.727Gflops)
4       : 16384 x 16384 Matrix multiply wall time : 2.164315s(4064.146Gflops)
5       : 16384 x 16384 Matrix multiply wall time : 2.146332s(4098.198Gflops)
6       : 16384 x 16384 Matrix multiply wall time : 2.083143s(4222.510Gflops)
7       : 16384 x 16384 Matrix multiply wall time : 2.092037s(4204.559Gflops)
8       : 16384 x 16384 Matrix multiply wall time : 2.200659s(3997.026Gflops)
9       : 16384 x 16384 Matrix multiply wall time : 2.104675s(4179.311Gflops)
10      : 16384 x 16384 Matrix multiply wall time : 2.177780s(4039.018Gflops)
Average Gflops: 4061.004, Max Gflops: 4222.510
Average Time: 2.170769s, Min Time: 2.083143s
PS E:\example\efficiency_v3\run> ./cuda_msvc_msvc_19.44.35209.0.exe -l 10 -n 14 -double
Using double precision for matrix multiplication.
1       : 16384 x 16384 Matrix multiply wall time : 31.435958s(279.810Gflops)
2       : 16384 x 16384 Matrix multiply wall time : 32.104813s(273.981Gflops)
3       : 16384 x 16384 Matrix multiply wall time : 33.338183s(263.844Gflops)
4       : 16384 x 16384 Matrix multiply wall time : 33.624088s(261.601Gflops)
5       : 16384 x 16384 Matrix multiply wall time : 33.429806s(263.121Gflops)
6       : 16384 x 16384 Matrix multiply wall time : 33.508910s(262.500Gflops)
7       : 16384 x 16384 Matrix multiply wall time : 33.479590s(262.730Gflops)
8       : 16384 x 16384 Matrix multiply wall time : 33.880561s(259.621Gflops)
9       : 16384 x 16384 Matrix multiply wall time : 33.770107s(260.470Gflops)
10      : 16384 x 16384 Matrix multiply wall time : 33.821256s(260.076Gflops)
Average Gflops: 264.775, Max Gflops: 279.810
Average Time: 33.239327s, Min Time: 31.435958s
```
It can only be said that the single-precision floating-point computing performance is indeed very powerful, and the double-precision floating-point computing performance is not as good as CPU acceleration.

In order to ensure the universality of the `main.c` file, `cuda.cu` writes the video memory allocation program inside the calculation function. In fact, after deducting this part of the overhead, the actual computing performance should be higher. However, this is also in line with programming habits. Generally, high-performance computing programs package different mathematical libraries into separate modules, separate from the main program, and switch the appropriate module according to the runtime. Therefore, the running time mainly counts the computing time of the main program calling different modules. The main program writer does not need to care about how each module is executed, but only needs to care about the output results and performance.

### 2.2 OpenCL

Opencl not only supports Nvidia, but also AMD and Intel products. Although graphics card manufacturers all claim to support opencl, Nvidia has cuda as a moat. Before the release of rocm, AMD lacked a suite with the same functions for a long time and could only rely on opencl to achieve a similar ecosystem. And at this stage, rocm only supports a few high-end graphics cards from AMD, unlike cuda which has relatively wide support.

There are two main blas libraries implemented using opencl: one is clblas, which has been stopped for a long time; the other is clblast, which can be used as a substitute for clblas at this stage.

As before, `main.c` is universal, and a new `clblast.c` file is created to call clblast to implement matrix multiplication operations.
```C
// Reference : https://github.com/CNugteren/CLBlast/blob/master/samples/sgemm.c
#include <stdio.h>
#include <clblast_c.h>

#define CL_TARGET_OPENCL_VERSION 120
#define CL_USE_DEPRECATED_OPENCL_1_2_APIS 

void matrix_multiply_float(int n, float A[], float B[], float C[])
{
	const size_t platform_id = 0;
	const size_t device_id = 0;
	const float alpha = 0.7f;
	const float beta = 1.0f;

	cl_uint num_platforms;
	clGetPlatformIDs(0, NULL, &num_platforms);
	cl_platform_id *platforms = (cl_platform_id *)malloc(num_platforms * sizeof(cl_platform_id));
	clGetPlatformIDs(num_platforms, platforms, NULL);
	cl_platform_id platform = platforms[platform_id];

	cl_uint num_devices;
	clGetDeviceIDs(platform, CL_DEVICE_TYPE_ALL, 0, NULL, &num_devices);
	cl_device_id *devices = (cl_device_id *)malloc(num_devices * sizeof(cl_device_id));
	clGetDeviceIDs(platform, CL_DEVICE_TYPE_ALL, num_devices, devices, NULL);
	cl_device_id device = devices[device_id];

	cl_context context = clCreateContext(NULL, 1, &device, NULL, NULL, NULL);
	cl_command_queue queue = clCreateCommandQueue(context, device, 0, NULL);
	cl_event event = NULL;

	cl_mem device_a = clCreateBuffer(context, CL_MEM_READ_WRITE, n * n * sizeof(float), NULL, NULL);
	cl_mem device_b = clCreateBuffer(context, CL_MEM_READ_WRITE, n * n * sizeof(float), NULL, NULL);
	cl_mem device_c = clCreateBuffer(context, CL_MEM_READ_WRITE, n * n * sizeof(float), NULL, NULL);
	clEnqueueWriteBuffer(queue, device_a, CL_TRUE, 0, n * n * sizeof(float), A, 0, NULL, NULL);
	clEnqueueWriteBuffer(queue, device_b, CL_TRUE, 0, n * n * sizeof(float), B, 0, NULL, NULL);
	clEnqueueWriteBuffer(queue, device_c, CL_TRUE, 0, n * n * sizeof(float), C, 0, NULL, NULL);

	CLBlastStatusCode status = CLBlastSgemm(CLBlastLayoutRowMajor,
											CLBlastTransposeNo, CLBlastTransposeNo,
											n, n, n,
											alpha,
											device_a, 0, n,
											device_b, 0, n,
											beta,
											device_c, 0, n,
											&queue, &event);
	if (status == CLBlastSuccess)
	{
		clWaitForEvents(1, &event);
		clReleaseEvent(event);
	}
	else
	{
		fprintf(stderr, "Error! CLBlast failed with status %d\n", status);
	}

	free(platforms);
	free(devices);
	clReleaseMemObject(device_a);
	clReleaseMemObject(device_b);
	clReleaseMemObject(device_c);
	clReleaseCommandQueue(queue);
	clReleaseContext(context);
}

void matrix_multiply_double(int n, double A[], double B[], double C[])
{
	const size_t platform_id = 0;
	const size_t device_id = 0;
	const double alpha = 0.7f;
	const double beta = 1.0f;

	cl_uint num_platforms;
	clGetPlatformIDs(0, NULL, &num_platforms);
	cl_platform_id *platforms = (cl_platform_id *)malloc(num_platforms * sizeof(cl_platform_id));
	clGetPlatformIDs(num_platforms, platforms, NULL);
	cl_platform_id platform = platforms[platform_id];

	cl_uint num_devices;
	clGetDeviceIDs(platform, CL_DEVICE_TYPE_ALL, 0, NULL, &num_devices);
	cl_device_id *devices = (cl_device_id *)malloc(num_devices * sizeof(cl_device_id));
	clGetDeviceIDs(platform, CL_DEVICE_TYPE_ALL, num_devices, devices, NULL);
	cl_device_id device = devices[device_id];

	cl_context context = clCreateContext(NULL, 1, &device, NULL, NULL, NULL);
	cl_command_queue queue = clCreateCommandQueue(context, device, 0, NULL);
	cl_event event = NULL;

	cl_mem device_a = clCreateBuffer(context, CL_MEM_READ_WRITE, n * n * sizeof(double), NULL, NULL);
	cl_mem device_b = clCreateBuffer(context, CL_MEM_READ_WRITE, n * n * sizeof(double), NULL, NULL);
	cl_mem device_c = clCreateBuffer(context, CL_MEM_READ_WRITE, n * n * sizeof(double), NULL, NULL);
	clEnqueueWriteBuffer(queue, device_a, CL_TRUE, 0, n * n * sizeof(double), A, 0, NULL, NULL);
	clEnqueueWriteBuffer(queue, device_b, CL_TRUE, 0, n * n * sizeof(double), B, 0, NULL, NULL);
	clEnqueueWriteBuffer(queue, device_c, CL_TRUE, 0, n * n * sizeof(double), C, 0, NULL, NULL);

	CLBlastStatusCode status = CLBlastDgemm(CLBlastLayoutRowMajor,
											CLBlastTransposeNo, CLBlastTransposeNo,
											n, n, n,
											alpha,
											device_a, 0, n,
											device_b, 0, n,
											beta,
											device_c, 0, n,
											&queue, &event);

	if (status == CLBlastSuccess)
	{
		clWaitForEvents(1, &event);
		clReleaseEvent(event);
	}
	else
	{
		fprintf(stderr, "Error! CLBlast failed with status %d\n", status);
	}

	free(platforms);
	free(devices);
	clReleaseMemObject(device_a);
	clReleaseMemObject(device_b);
	clReleaseMemObject(device_c);
	clReleaseCommandQueue(queue);
	clReleaseContext(context);
}
```
Just like cuda, minus the overhead of video memory allocation and preheating, the actual computing time will only be shorter.

The contents of the `CMakeLists.txt` file are as follows, and need to be linked to opencl:
```cmake
cmake_minimum_required(VERSION 3.13)
project(opencl LANGUAGES C)
set(CMAKE_C_STANDARD 11)

set(EXECUTE_FILE_NAME ${PROJECT_NAME}_${CMAKE_C_COMPILER_FRONTEND_VARIANT}_${CMAKE_C_COMPILER_ID}_${CMAKE_C_COMPILER_VERSION})
string(TOLOWER ${EXECUTE_FILE_NAME} EXECUTE_FILE_NAME)

# Enable clBlast
find_package(clBlast REQUIRED)

set(SRC_LIST
    src/main.c
    src/clblast.c
)

add_executable(${EXECUTE_FILE_NAME} ${SRC_LIST})

target_link_libraries(${EXECUTE_FILE_NAME} PRIVATE
    clBlast
    opencl
)
```

The compilation toolchain uses MSYS2's ucrt64, and the compilation machine is configured with AMD Radeon 880M core graphics. The running results on the compilation machine are as follows:
```powershell
PS D:\example\efficiency_v3\run> ./opencl_gnu_gnu_15.1.0.exe -l 10 -n 12
Using float precision for matrix multiplication.
1       : 4096 x 4096 Matrix multiply wall time : 1.117597s(122.977Gflops)
2       : 4096 x 4096 Matrix multiply wall time : 0.186813s(735.703Gflops)
3       : 4096 x 4096 Matrix multiply wall time : 0.162170s(847.499Gflops)
4       : 4096 x 4096 Matrix multiply wall time : 0.168798s(814.219Gflops)
5       : 4096 x 4096 Matrix multiply wall time : 0.159344s(862.531Gflops)
6       : 4096 x 4096 Matrix multiply wall time : 0.162423s(846.179Gflops)
7       : 4096 x 4096 Matrix multiply wall time : 0.180195s(762.723Gflops)
8       : 4096 x 4096 Matrix multiply wall time : 0.156903s(875.949Gflops)
9       : 4096 x 4096 Matrix multiply wall time : 0.170804s(804.659Gflops)
10      : 4096 x 4096 Matrix multiply wall time : 0.150039s(916.018Gflops)
Average Gflops: 758.846, Max Gflops: 916.018
Average Time: 0.261509s, Min Time: 0.150039s
PS D:\example\efficiency_v3\run> ./opencl_gnu_gnu_15.1.0.exe -l 10 -n 12 -double
Using double precision for matrix multiplication.
1       : 4096 x 4096 Matrix multiply wall time : 2.102548s(65.368Gflops)
2       : 4096 x 4096 Matrix multiply wall time : 1.159928s(118.489Gflops)
3       : 4096 x 4096 Matrix multiply wall time : 1.173824s(117.087Gflops)
4       : 4096 x 4096 Matrix multiply wall time : 1.161465s(118.332Gflops)
5       : 4096 x 4096 Matrix multiply wall time : 1.159717s(118.511Gflops)
6       : 4096 x 4096 Matrix multiply wall time : 1.172199s(117.249Gflops)
7       : 4096 x 4096 Matrix multiply wall time : 1.157075s(118.781Gflops)
8       : 4096 x 4096 Matrix multiply wall time : 1.178716s(116.601Gflops)
9       : 4096 x 4096 Matrix multiply wall time : 1.162563s(118.221Gflops)
10      : 4096 x 4096 Matrix multiply wall time : 1.175523s(116.917Gflops)
Average Gflops: 112.556, Max Gflops: 118.781
Average Time: 1.260356s, Min Time: 1.157075s
```
The single-precision floating-point computing performance is equivalent to the CPU acceleration performance, and the double-precision floating-point computing performance is only about 1/4 of the CPU acceleration performance.

The running results on the NVIDIA RTX A4000 single-card workstation are as follows:
```powershell
PS E:\example\efficiency_v3\run> ./opencl_gnu_gnu_15.1.0.exe -l 10 -n 14
Using float precision for matrix multiplication.
1       : 16384 x 16384 Matrix multiply wall time : 6.913470s(1272.312Gflops)
2       : 16384 x 16384 Matrix multiply wall time : 6.030729s(1458.545Gflops)
3       : 16384 x 16384 Matrix multiply wall time : 6.100249s(1441.924Gflops)
4       : 16384 x 16384 Matrix multiply wall time : 6.059375s(1451.650Gflops)
5       : 16384 x 16384 Matrix multiply wall time : 6.045835s(1454.901Gflops)
6       : 16384 x 16384 Matrix multiply wall time : 6.013252s(1462.785Gflops)
7       : 16384 x 16384 Matrix multiply wall time : 6.010330s(1463.496Gflops)
8       : 16384 x 16384 Matrix multiply wall time : 6.043099s(1455.560Gflops)
9       : 16384 x 16384 Matrix multiply wall time : 6.087911s(1444.846Gflops)
10      : 16384 x 16384 Matrix multiply wall time : 6.010101s(1463.552Gflops)
Average Gflops: 1436.957, Max Gflops: 1463.552
Average Time: 6.131435s, Min Time: 6.010101s
PS E:\example\efficiency_v3\run> ./opencl_gnu_gnu_15.1.0.exe -l 10 -n 14 -double
Using double precision for matrix multiplication.
1       : 16384 x 16384 Matrix multiply wall time : 30.209699s(291.168Gflops)
2       : 16384 x 16384 Matrix multiply wall time : 32.432424s(271.213Gflops)
3       : 16384 x 16384 Matrix multiply wall time : 32.288050s(272.426Gflops)
4       : 16384 x 16384 Matrix multiply wall time : 32.304304s(272.289Gflops)
5       : 16384 x 16384 Matrix multiply wall time : 32.392134s(271.550Gflops)
6       : 16384 x 16384 Matrix multiply wall time : 32.370801s(271.729Gflops)
7       : 16384 x 16384 Matrix multiply wall time : 32.440887s(271.142Gflops)
8       : 16384 x 16384 Matrix multiply wall time : 32.515872s(270.517Gflops)
9       : 16384 x 16384 Matrix multiply wall time : 32.635461s(269.526Gflops)
10      : 16384 x 16384 Matrix multiply wall time : 32.786553s(268.284Gflops)
Average Gflops: 272.984, Max Gflops: 291.168
Average Time: 32.237619s, Min Time: 30.209699s
```
The single-precision floating-point operation is much worse than that of CUDA, only about 1/3 of CUDA, and even worse than MKL; the double-precision is slightly better than CUDA.

## 3. Summarize

The main advantage of GPU acceleration lies in large-scale single-precision floating-point calculations. Due to the long preheating time of the video memory, the advantage of GPU acceleration is not obvious for small-scale calculations. For ultra-large-scale calculations, it is necessary to consider the limitations of video memory size and memory exchange capacity. For double-precision floating-point calculations, the GPU acceleration effect is not obvious, and is not even as significant as the CPU acceleration performance improvement.

If you only consider the CPU acceleration library, it is best to choose the math library of the corresponding manufacturer according to the CPU platform. For example, Intel platform is suitable for mkl, AMD platform AOCL is the first choice, and of course openblas can also be used as a cross-platform alternative for general devices. A more reasonable approach is to develop specific computing modules for different platforms, and then flexibly schedule them at runtime to ensure optimal performance on each platform.

[^1]: [AMD Optimizing CPU Libraries (AOCL)](https://www.amd.com/zh-cn/developer/aocl.html)
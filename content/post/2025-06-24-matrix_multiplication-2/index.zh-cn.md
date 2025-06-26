+++
author = "Andrew Moa"
title = "矩阵乘法运算(二)-基于BLAS库的加速运算"
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

BLAS最初是采用fortran开发的线性代数库，后来移植到C/C++上，作为现代高性能计算的核心组件，已经形成了一套标准。有开源的实现如Netlib BLAS、GotoBLAS及其后继者OpenBLAS，商业上各个厂商针对自家平台都有相应的实现，比如Intel的MKL、NVIDIA的CUDA、AMD的AOCL和ROCm。其中有针对CPU平台进行优化的，也有采用GPU并行加速的。本文通过使用不同BLAS库实现矩阵运算，分析不同实现间的性能差异。

## 1. CPU并行加速BLAS库

### 1.1 Intel MKL

`main.c`文件同[矩阵乘法运算(一)-使用OpenMP加速循环计算](../2025-06-23-matrix_multiplication-1)中的2.1，`blas.c`引入mkl的blas库，并使用gemm函数执行矩阵乘法运算。
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

`CMakeLists.txt`包含了mkl和openmp库文件，mkl底层默认使用openmp进行并行化，因此要链接到openmp库。
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

编译机器是AMD笔记本，处理器是AI 9 365w，在Windows下使用vs2022的clang-cl编译并运行，Release程序执行效果如下：
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
想要在AMD机器上正常运行Intel mkl程序，建议在环境变量中加入`MKL_DEBUG_CPU_TYPE=5`。

在Intel工作站(Xeon Gold 6226R)上运行效果如下：
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

对于blas来说，矩阵规模越小加速效果越不明显，但矩阵规模也不是越大越好，总有一个上限值。矩阵规模多少合适，取决于CPU和缓存的性能，不同平台适合的矩阵运算规模不一样。

### 1.2 OpenBLAS

考虑到Intel的库在AMD平台上执行效率可能会差一点，这里用openblas替换mkl试试。这里只改动`blas.c`所引用的头文件，其余保持不变：
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

`CMakeLists.txt`包含openblas和openmp，没错，openblas底层也是通过openmp实现并行化的。
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

在AMD的机器上编译运行，Windows下使用MSYS2的ucrt64工具链编译输出Release程序，执行效果如下：
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
在AMD平台上openblas运行性能确实比Intel mkl提升了不少。

在Intel工作站上运行效果如下：
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
Intel平台上openblas表现不如mkl。

### 1.3 AMD AOCL

接下来看看AMD自家的blas库表现如何。AOCL[^1]是AMD针对自家平台推出的CPU优化库，包含了blas、lapack、fftw等数学运算相关的库文件，用于在AMD CPU上加速数学计算任务。
和1.2中的一样，头文件同样都是`cblas.h`，这回连`blas.c`都不用更改。`CMakeLists.txt`如下所示，配置cmake时需要传递AOCL的安装路径`AOCL_DIR`参数，数据模型`AOCL_BLAS_DATA`默认采用`LP64`。演示用的AOCL是Windows下的5.1版本，其他版本可能需要根据安装包文件自行调整。
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

在AMD机器上使用vs2022的clang-cl编译，这里传递的是参数是，Release程序执行效果如下：
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
在AMD的机器上单精度浮点数表现稍逊于openblas，双精度浮点数性能优于openblas，整体性能强于Intel mkl。

在Intel工作站上运行效果如下：
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
aocl在Intel平台上的表现甚至要优于openblas，仅次于mkl。

## 2. GPU并行加速BLAS库

### 2.1 CUDA

cuda是Nvidia专门为自家显卡开发的高性能计算工具包，其中包含了cublas用于实现blas的功能。
`main.c`主程序文件不变，新建`cuda.cu`文件用于实现cuda加速矩阵乘法运算。
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

`CMakeLists.txt`文件如下，cmake会自动调用`nvcc`对cuda源文件进行编译，需要链接到cublas库和cuda的运行时。
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

这里编译用的cuda工具包版本12.9，编译器是vs2022的msvc，在NVIDIA RTX A4000单卡工作站上运行效果如下：
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
只能说单精度浮点运算性能确实很强大，双精度浮点运算性能不如CPU加速。

为了确保`main.c`文件通用，`cuda.cu`将显存分配程序写到了计算函数内部，实际上扣除掉这一部分的开销，真实的计算性能应该会更高。不过这也符合的编程习惯，一般高性能计算程序都是将不同的数学库包装到单独的模块当中，和主程序分开，根据运行时切换合适的模块。因此运行时间主要统计主程序调用不同模块的计算时间。主程序编写者不需要关心每个模块到底如何执行，只需要关心输出结果和性能表现。

### 2.2 OpenCL

opencl不光支持Nvidia，还支持AMD和Intel的产品。虽然显卡厂商都宣称支持opencl，但是Nvidia有cuda作为护城河。AMD在rocm发布之前长期缺乏同样功能的套件，只能依靠opencl实现类似的生态。并且现阶段rocm只支持AMD少数高端显卡，不像cuda支持相对广泛。

使用opencl实现的blas库主要有两个：一个是clblas，已经停止开发很久了；另一个是clblast，现阶段可作为clblas的替代品。

和前面一样`main.c`通用，新建`clblast.c`文件调用clblast实现矩阵乘法运算。
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
和cuda一样，扣掉显存分配和预热的开销，真正的计算时间只会更短。

`CMakeLists.txt`文件如下，需要链接到opencl：
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

编译工具链用的是MSYS2的ucrt64，编译机器配置是AMD Radeon 880M核显，在编译机器上运行效果如下：
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
单精度浮点运算性能与CPU加速性能相当，双精度浮点运算性能只有CPU加速性能的1/4左右。

在NVIDIA RTX A4000单卡工作站上运行效果如下：
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
单精度浮点数运算跟cuda相比差太多了，只有cuda的1/3左右，还不如mkl；双精度反而比cuda好一点。

## 3. 总结

GPU加速主要优势在于大规模单精度浮点数计算，由于显存预热时间长，对于小规模计算GPU加速优势不明显。超大规模计算就需要考虑显存大小和内存交换能力的限制。对于双精度浮点数计算，GPU加速效果并不明显，甚至不如CPU加速性能提升来得显著。

如果只考虑CPU加速库，最好根据cpu平台选择对应厂商的数学库，比如Intel平台适合mkl，AMD平台AOCL是首选，当然openblas也可以作为通用设备跨平台备选项。比较合理的办法是针对不同平台开发特定的计算模块，再通过运行时灵活调度，确保在各个平台上都能达到最优性能。

[^1]: [AMD Optimizing CPU Libraries (AOCL)](https://www.amd.com/zh-cn/developer/aocl.html)
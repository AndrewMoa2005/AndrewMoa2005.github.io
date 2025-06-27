+++
author = "Andrew Moa"
title = "Compile rocblas-rocm-6.2.4 under Windows"
date = "2025-06-27"
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

When I was demonstrating matrix operation acceleration before, I wanted to try AMD's own ROCm. After compiling and running the program, I encountered an error:
```txt
rocBLAS error: Cannot read D:\example\efficiency_v3\rocm\build\Release\/rocblas/library/TensileLibrary.dat: No such file or directory for GPU arch : gfx1150
 List of available TensileLibrary Files : 
```

According to the official website, ROCm does not support Radeon 880M integrated graphics (AI H 365w processor)[^1]. Unless you compile rocblas yourself, it will not work.

I checked the tutorial articles online[^2][^3][^4], but there is no one that is compatible with this integrated graphics, so I have to do it myself.

## 1. Download tools and source

The tools you need are shown in the table below. If you don’t have them, go to the official website to download and install them.

| No. | Software/Toolkit | Version |
| --- | --- | --- |
| 1 | Visual Studio Community | 2022 |
| 2 | AMD HIP SDK for Windows[^5] | 6.2.4 |
| 3 | Python | 3.13 |
| 4 | Git for Windows | 2.7.4 |
| 5 | Strawberry Perl | 5.40.0.1 |
| 6 | CMake | 3.30.1 |

I have vcpkg installed on my machine. Except for the first two which are downloaded and installed from the official website, the rest are extracted from the `downloads\tools` directory of vcpkg. Just add the path to the environment variable.
```powershell
# Configure toolkit path
$Env:HIP_PATH="C:\Program Files\AMD\ROCm\6.2"
$Env:GIT_BIN_PATH = "D:\vcpkg\downloads\tools\git-2.7.4-windows\bin"
$Env:PERL_PATH = "D:\vcpkg\downloads\tools\perl\5.40.0.1"
$Env:CMAKE_BIN_PATH = "D:\vcpkg\downloads\tools\cmake-3.30.1-windows\cmake-3.30.1-windows-i386\bin"

# Configure system environment variables
$Env:PATH += ";$Env:HIP_PATH\bin;$Env:GIT_BIN_PATH;$Env:PERL_PATH\perl\site\bin;$Env:PERL_PATH\perl\bin;$Env:PERL_PATH\c\bin;$Env:CMAKE_BIN_PATH"
```

Download the source code of **rocBLAS** and **Tensile** from Github, and make sure the version is consistent with the **AMD HIP SDK** version installed on your computer. You also need to download the patch file **Tensile-fix-fallback-arch-build.patch** to ensure that you can compile content for unsupported graphics cards.
```powershell
# Create a working directory
New-Item -Path D:\rocblas_build -ItemType Directory
# Download rocBLAS
git clone -b rocm-6.2.4 https://github.com/ROCm/rocBLAS
# Download Tensile
git clone -b rocm-6.2.4 https://github.com/ROCm/Tensile
# Download Tensile patch
Invoke-WebRequest -Uri https://raw.githubusercontent.com/ulyssesrr/docker-rocm-xtra/f25f12835c1d0a5efa80763b5381accf175b200e/rocm-xtra-rocblas-builder/patches/Tensile-fix-fallback-arch-build.patch -OutFile Tensile-fix-fallback-arch-build.patch
```
It is best to package and back up the downloaded source code first to ensure that the changes can be rolled back if an error occurs.

## 2. Modify source code

Enter the `Tensile` folder and apply the patch:
```powershell
# Copy the patch file to the git folder
Copy-Item -Path Tensile-fix-fallback-arch-build.patch -Destination $PWD/Tensile
# Enter the Tensile directory
cd Tensile
# Apply the patch file
git apply Tensile-fix-fallback-arch-build.patch
```

The patch application here fails. It seems that the patch version is too old and needs to be modified manually. Below is the modified `Tensile-fix-fallback-arch-build.patch` file. Save it as and refer to the above command to re-patch.
```patch
diff --git a/Tensile/TensileCreateLibrary.py b/Tensile/TensileCreateLibrary.py
index ac0486d8..d069949c 100644
--- a/Tensile/TensileCreateLibrary.py
+++ b/Tensile/TensileCreateLibrary.py
@@ -949,12 +949,11 @@ def generateLogicDataAndSolutions(logicFiles, args):
       for key, value in masterLibraries.items():
         if key != "fallback":
           value.insert(deepcopy(masterLibraries["fallback"]))
-      for archName in archs:
-        archName = archName.split('-', 1)[0]
-        if archName not in masterLibraries:
-          print1("Using fallback for arch: " + archName)
-          masterLibraries[archName] = deepcopy(masterLibraries["fallback"])
-          masterLibraries[archName].version = args.version
+      for architectureName in parseArchitecturesFromArgs(args.Architecture, True):
+        if architectureName not in masterLibraries:
+          print("Using fallback for arch: "+architectureName)
+          masterLibraries[architectureName] = deepcopy(masterLibraries["fallback"])
+          masterLibraries[architectureName].version = args.version
 
       masterLibraries.pop("fallback")
 
@@ -1027,6 +1027,17 @@ def WriteClientLibraryFromSolutions(solutionList, libraryWorkingPath, tensileSou
 
   return (codeObjectFiles, newLibrary)
 
+def parseArchitecturesFromArgs(architectureArgValue, handleLiteralAllAsList):
+  if architectureArgValue == 'all' and handleLiteralAllAsList:
+    archs = [gfxName(arch) for arch in globalParameters['SupportedISA']]
+  else:
+    if ";" in architectureArgValue:
+      archs = architectureArgValue.split(";") # user arg list format
+    else:
+      archs = architectureArgValue.split("_") # workaround for cmake list in list issue
+
+  return archs
+
 ################################################################################
 # Write Master Solution Index CSV
 ################################################################################
@@ -1167,10 +1178,7 @@ def TensileCreateLibrary():
   if not os.path.exists(logicPath):
     printExit("LogicPath %s doesn't exist" % logicPath)
 
-  if ";" in arguments["Architecture"]:
-    archs = arguments["Architecture"].split(";") # user arg list format
-  else:
-    archs = arguments["Architecture"].split("_") # workaround for cmake list in list issue
+  archs = parseArchitecturesFromArgs(arguments["Architecture"], False)
   logicArchs = set()
   for arch in archs:
     if arch in architectureMap:

```

Next, we need to add the AMD Radeon 880M architecture to the Tensile source code. Use the hipinfo command to view the local graphics architecture. The gfx1150 corresponding to the gcnArchName: below is the architecture name of the graphics card.
```powershell
--------------------------------------------------------------------------------
device#                           0
Name:                             AMD Radeon(TM) 880M Graphics
...
gcnArchName:                      gfx1150
...

```

Then add the graphics card architecture name and parameters to the three files `Tensile\Tensile\Source\CMakeLists.txt`, `Tensile\AsmCaps.py` and `Tensile\Common.py`, or apply the following patch:
```patch
diff --git a/Tensile/AsmCaps.py b/Tensile/AsmCaps.py
index 783f9af8..27f29f5a 100644
--- a/Tensile/AsmCaps.py
+++ b/Tensile/AsmCaps.py
@@ -771,6 +771,50 @@ CACHED_ASM_CAPS = \
               'v_mov_b64': False,
               'v_pk_fma_f16': True,
               'v_pk_fmac_f16': False},
+ (11, 5, 0): {'HasAddLshl': True,
+              'HasAtomicAdd': True,
+              'HasDirectToLdsDest': False,
+              'HasDirectToLdsNoDest': False,
+              'HasExplicitCO': True,
+              'HasExplicitNC': True,
+              'HasGLCModifier': True,
+              'HasNTModifier': False,
+              'HasLshlOr': True,
+              'HasMFMA': False,
+              'HasMFMA_b8': False,
+              'HasMFMA_bf16_1k': False,
+              'HasMFMA_bf16_original': False,
+              'HasMFMA_constSrc': False,
+              'HasMFMA_f64': False,
+              'HasMFMA_f8': False,
+              'HasMFMA_i8_908': False,
+              'HasMFMA_i8_940': False,
+              'HasMFMA_vgpr': False,
+              'HasMFMA_xf32': False,
+              'HasSMulHi': True,
+              'HasWMMA': True,
+              'KernargPreloading': False,
+              'MaxLgkmcnt': 15,
+              'MaxVmcnt': 63,
+              'SupportedISA': True,
+              'SupportedSource': True,
+              'VOP3v_dot4_i32_i8': False,
+              'v_dot2_f32_f16': True,
+              'v_dot2c_f32_f16': True,
+              'v_dot4_i32_i8': False,
+              'v_dot4c_i32_i8': False,
+              'v_fma_f16': True,
+              'v_fma_f32': True,
+              'v_fma_f64': True,
+              'v_fma_mix_f32': True,
+              'v_fmac_f16': False,
+              'v_fmac_f32': True,
+              'v_mac_f16': False,
+              'v_mac_f32': False,
+              'v_mad_mix_f32': False,
+              'v_mov_b64': False,
+              'v_pk_fma_f16': True,
+              'v_pk_fmac_f16': False},
  (11, 5, 1): {'HasAddLshl': True,
               'HasAtomicAdd': True,
               'HasDirectToLdsDest': False,
diff --git a/Tensile/Common.py b/Tensile/Common.py
index e440e942..57813169 100644
--- a/Tensile/Common.py
+++ b/Tensile/Common.py
@@ -229,7 +229,7 @@ globalParameters["SupportedISA"] = [(8,0,3),
                                     (9,4,0), (9,4,1), (9,4,2),
                                     (10,1,0), (10,1,1), (10,1,2), (10,3,0), (10,3,1),
                                     (11,0,0), (11,0,1), (11,0,2),
-                                    (11,5,1)] # assembly kernels writer supports these architectures
+                                    (11,5,0), (11,5,1)] # assembly kernels writer supports these architectures
 
 globalParameters["CleanupBuildFiles"] = False                     # cleanup build files (e.g. kernel assembly) once no longer needed
 globalParameters["GenerateManifestAndExit"] = False               # Output manifest file with list of expected library objects and exit
@@ -308,7 +308,7 @@ architectureMap = {
   'gfx1010':'navi10', 'gfx1011':'navi12', 'gfx1012':'navi14',
   'gfx1030':'navi21', 'gfx1031':'navi22', 'gfx1032':'navi23', 'gfx1034':'navi24', 'gfx1035':'rembrandt',
   'gfx1100':'navi31', 'gfx1101':'navi32', 'gfx1102':'navi33',
-  'gfx1151':'gfx1151'
+  'gfx1150':'gfx1150', 'gfx1151':'gfx1151'
 }
 
 def getArchitectureName(gfxName):
diff --git a/Tensile/Source/CMakeLists.txt b/Tensile/Source/CMakeLists.txt
index e973a9ed..8904f4a7 100644
--- a/Tensile/Source/CMakeLists.txt
+++ b/Tensile/Source/CMakeLists.txt
@@ -51,9 +51,9 @@ if(NOT DEFINED CXX_VERSION_STRING)
 endif()
 
 if(CMAKE_CXX_COMPILER STREQUAL "hipcc")
-  set(TENSILE_GPU_ARCHS gfx803 gfx900 gfx906:xnack- gfx908:xnack- gfx90a:xnack- gfx1010 gfx1011 gfx1012 gfx1030 gfx1031 gfx1032 gfx1034 gfx1035 gfx1100 gfx1101 gfx1102 CACHE STRING "GPU architectures")
+  set(TENSILE_GPU_ARCHS gfx803 gfx900 gfx906:xnack- gfx908:xnack- gfx90a:xnack- gfx1010 gfx1011 gfx1012 gfx1030 gfx1031 gfx1032 gfx1034 gfx1035 gfx1100 gfx1101 gfx1102 gfx1150 CACHE STRING "GPU architectures")
 else()
-  set(TENSILE_GPU_ARCHS gfx803 gfx900 gfx906 gfx908 gfx90a gfx1010 gfx1011 gfx1012 gfx1030 gfx1031 gfx1032 gfx1034 gfx1035 gfx1100 gfx1101 gfx1102 CACHE STRING "GPU architectures")
+  set(TENSILE_GPU_ARCHS gfx803 gfx900 gfx906 gfx908 gfx90a gfx1010 gfx1011 gfx1012 gfx1030 gfx1031 gfx1032 gfx1034 gfx1035 gfx1100 gfx1101 gfx1102 gfx1150 CACHE STRING "GPU architectures")
 endif()
 
 include(CMakeDependentOption)
```

Then add the graphics card architecture name to the source code `rocBLAS\CMakeLists.txt` file of **rocBLAS**. You can apply the following patch:
```patch 
diff --git a/CMakeLists.txt b/CMakeLists.txt                                                       
index dd521358..9c074139 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -111,7 +111,7 @@ list( APPEND CMAKE_PREFIX_PATH ${ROCM_PATH}/llvm ${ROCM_PATH} ${ROCM_PATH}/hip /
 set( TARGET_LIST_ROCM_5.6 "gfx803;gfx900;gfx906:xnack-;gfx908:xnack-;gfx90a:xnack+;gfx90a:xnack-;gfx1010;gfx1012;gfx1030;gfx1100;gfx1101;gfx1102")
 set( TARGET_LIST_ROCM_5.7 "gfx803;gfx900;gfx906:xnack-;gfx908:xnack-;gfx90a:xnack+;gfx90a:xnack-;gfx940;gfx941;gfx942;gfx1010;gfx1012;gfx1030;gfx1100;gfx1101;gfx1102")
 set( TARGET_LIST_ROCM_6.0 "gfx900;gfx906:xnack-;gfx908:xnack-;gfx90a:xnack+;gfx90a:xnack-;gfx940;gfx941;gfx942;gfx1010;gfx1012;gfx1030;gfx1100;gfx1101;gfx1102")
-set( TARGET_LIST_ROCM_6.2.4 "gfx900;gfx906:xnack-;gfx908:xnack-;gfx90a:xnack+;gfx90a:xnack-;gfx940;gfx941;gfx942;gfx1010;gfx1012;gfx1030;gfx1100;gfx1101;gfx1102;gfx1151")
+set( TARGET_LIST_ROCM_6.2.4 "gfx900;gfx906:xnack-;gfx908:xnack-;gfx90a:xnack+;gfx90a:xnack-;gfx940;gfx941;gfx942;gfx1010;gfx1012;gfx1030;gfx1100;gfx1101;gfx1102;gfx1150;gfx1151")
 
 if(ROCM_PLATFORM_VERSION)
   if(${ROCM_PLATFORM_VERSION} VERSION_LESS 5.7.0)

```

## 3. Compile and install

The following command initializes the **x64 Native Tools Command Prompt for VS** command line tool and enters the **rocBLAS** source directory, and executes the python command to download the vcpkg installation dependencies. Compile while downloading. For laptops, it is best to plug in the power supply and turn on the performance mode.
```powershell
# Load vc2022 compilation environment
cmd /c "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
# Enter the rocBLAS source directory
cd rocBLAS
# Execute the following command to download a bunch of dependencies
python rdeps.py
```
Some of the dependent files will be stored in the temporary folder `C:\github` and deleted after the compilation is successful.

Next, execute the command to generate the library file, which takes a long time:
```powershell
python rmake.py -a gfx1150 --no-lazy-library-loading --no-merge-architectures -t $PWD\..\Tensile --cmake-arg="-DROCM_PLATFORM_VERSION=6.2.4"
```
After execution, the `rocblas.dll` file will be generated under the `build\release\staging` path of the **rocBLAS** source code directory.

Finally, execute the following command to copy the generated library file and **Tensile** architecture file to a new folder:
```powershell
# Create a folder
New-Item -Path $PWD\..\rocblas_dll -ItemType Directory
# Copy the rocblas.dll file to the new folder
Copy-Item -Path $PWD\build\release\staging\rocblas.dll -Destination  $PWD\..\rocblas_dll
# Copy the Tensile architecture file
Copy-Item -Path $PWD\build\release\Tensile\library -Destination $PWD\..\rocblas_dll\rocblas\library -Recurse
```
The generated dll file is much smaller than the dll that comes with the HIP SDK. There are two ways to use the newly generated rocblas:

 1. Release the dll file and architecture file packaged in the `rocblas_dll` folder together with the compiled program. It is relatively simple and does not require the modification of the HIP SDK installation file;

 2. Add the `bin` of the HIP SDK installation path to PATH, back up the original rocblas.dll and copy the newly generated rocblas.dll to the path, copy the newly generated gfx1150's `TensileLibrary_gfx1150.dat` file and `Kernels.so-000-gfx1150.hsaco` to the `bin\rocblas\library` path of the HIP SDK installation path, and copy the generated `TensileManifest.txt` to the original `TensileManifest.txt`.

Finally, don't forget to delete the temporary folder: `C:\github`

## 4. Compile test

Next, write a matrix multiplication program to test the performance of ROCm acceleration. The main program `main.c` is the same as 2.1 in [Matrix multiplication operation (I) - using OpenMP to speed up loop calculation](../2025-06-23-matrix_multiplication-1), and the `blas.c` file is as follows:
```C
// References: https://github.com/ROCm/rocBLAS-Examples/blob/develop/Languages/C/main.c

#include <assert.h>
#include <hip/hip_runtime_api.h>
#include <math.h>
#include <rocblas/rocblas.h>
#include <stdlib.h>
#include <stdio.h>

#ifndef CHECK_HIP_ERROR
#define CHECK_HIP_ERROR(error)                    \
    if (error != hipSuccess)                      \
    {                                             \
        fprintf(stderr,                           \
                "hip error: '%s'(%d) at %s:%d\n", \
                hipGetErrorString(error),         \
                error,                            \
                __FILE__,                         \
                __LINE__);                        \
    }
#endif

#ifndef CHECK_ROCBLAS_STATUS
#define CHECK_ROCBLAS_STATUS(status)                  \
    if (status != rocblas_status_success)             \
    {                                                 \
        fprintf(stderr, "rocBLAS error: ");           \
        fprintf(stderr,                               \
                "rocBLAS error: '%s'(%d) at %s:%d\n", \
                rocblas_status_to_string(status),     \
                status,                               \
                __FILE__,                             \
                __LINE__);                            \
    }
#endif

void matrix_multiply_float(int n, float A[], float B[], float C[])
{
    size_t rows, cols;
    rows = cols = n;

    typedef float data_type;

    rocblas_handle handle;
    rocblas_status rstatus = rocblas_create_handle(&handle);
    CHECK_ROCBLAS_STATUS(rstatus);

    hipStream_t test_stream;
    rstatus = rocblas_get_stream(handle, &test_stream);
    CHECK_ROCBLAS_STATUS(rstatus);

    data_type *da = 0;
    data_type *db = 0;
    data_type *dc = 0;
    CHECK_HIP_ERROR(hipMalloc((void **)&da, n * cols * sizeof(data_type)));
    CHECK_HIP_ERROR(hipMalloc((void **)&db, n * cols * sizeof(data_type)));
    CHECK_HIP_ERROR(hipMalloc((void **)&dc, n * cols * sizeof(data_type)));

    // upload asynchronously from pinned memory
    rstatus = rocblas_set_matrix_async(rows, cols, sizeof(data_type), A, n, da, n, test_stream);
    rstatus = rocblas_set_matrix_async(rows, cols, sizeof(data_type), B, n, db, n, test_stream);

    // scalar arguments will be from host memory
    rstatus = rocblas_set_pointer_mode(handle, rocblas_pointer_mode_host);
    CHECK_ROCBLAS_STATUS(rstatus);

    data_type alpha = 1.0;
    data_type beta = 2.0;

    // invoke asynchronous computation
    rstatus = rocblas_sgemm(handle,
                            rocblas_operation_none,
                            rocblas_operation_none,
                            rows,
                            cols,
                            n,
                            &alpha,
                            da,
                            n,
                            db,
                            n,
                            &beta,
                            dc,
                            n);
    CHECK_ROCBLAS_STATUS(rstatus);

    // fetch results asynchronously to pinned memory
    rstatus = rocblas_get_matrix_async(rows, cols, sizeof(data_type), dc, n, C, n, test_stream);
    CHECK_ROCBLAS_STATUS(rstatus);

    // wait on transfer to be finished
    CHECK_HIP_ERROR(hipStreamSynchronize(test_stream));

    CHECK_HIP_ERROR(hipFree(da));
    CHECK_HIP_ERROR(hipFree(db));
    CHECK_HIP_ERROR(hipFree(dc));

    rstatus = rocblas_destroy_handle(handle);
    CHECK_ROCBLAS_STATUS(rstatus);
}

void matrix_multiply_double(int n, double A[], double B[], double C[])
{
    size_t rows, cols;
    rows = cols = n;

    typedef double data_type;

    rocblas_handle handle;
    rocblas_status rstatus = rocblas_create_handle(&handle);
    CHECK_ROCBLAS_STATUS(rstatus);

    hipStream_t test_stream;
    rstatus = rocblas_get_stream(handle, &test_stream);
    CHECK_ROCBLAS_STATUS(rstatus);

    data_type *da = 0;
    data_type *db = 0;
    data_type *dc = 0;
    CHECK_HIP_ERROR(hipMalloc((void **)&da, n * cols * sizeof(data_type)));
    CHECK_HIP_ERROR(hipMalloc((void **)&db, n * cols * sizeof(data_type)));
    CHECK_HIP_ERROR(hipMalloc((void **)&dc, n * cols * sizeof(data_type)));

    // upload asynchronously from pinned memory
    rstatus = rocblas_set_matrix_async(rows, cols, sizeof(data_type), A, n, da, n, test_stream);
    rstatus = rocblas_set_matrix_async(rows, cols, sizeof(data_type), B, n, db, n, test_stream);

    // scalar arguments will be from host memory
    rstatus = rocblas_set_pointer_mode(handle, rocblas_pointer_mode_host);
    CHECK_ROCBLAS_STATUS(rstatus);

    data_type alpha = 1.0;
    data_type beta = 2.0;

    // invoke asynchronous computation
    rstatus = rocblas_dgemm(handle,
                            rocblas_operation_none,
                            rocblas_operation_none,
                            rows,
                            cols,
                            n,
                            &alpha,
                            da,
                            n,
                            db,
                            n,
                            &beta,
                            dc,
                            n);
    CHECK_ROCBLAS_STATUS(rstatus);

    // fetch results asynchronously to pinned memory
    rstatus = rocblas_get_matrix_async(rows, cols, sizeof(data_type), dc, n, C, n, test_stream);
    CHECK_ROCBLAS_STATUS(rstatus);

    // wait on transfer to be finished
    CHECK_HIP_ERROR(hipStreamSynchronize(test_stream));

    CHECK_HIP_ERROR(hipFree(da));
    CHECK_HIP_ERROR(hipFree(db));
    CHECK_HIP_ERROR(hipFree(dc));

    rstatus = rocblas_destroy_handle(handle);
    CHECK_ROCBLAS_STATUS(rstatus);
}
```

The cmake configuration file `CMakeLists.txt` is as follows. The HIP installation path is passed through the variable `ROCM_DIR`. The compilation here uses `-DROCM_DIR=C:/Program Files/AMD/ROCm/6.2`.
```cmake
cmake_minimum_required(VERSION 3.13)
string(REGEX MATCHALL "[a-zA-Z]+\ |[a-zA-Z]+$" DIRNAME "${CMAKE_CURRENT_SOURCE_DIR}")
project(${DIRNAME} LANGUAGES C)
message(STATUS "PROJECT_NAME: ${PROJECT_NAME}")
set(CMAKE_C_STANDARD 11)

set(EXECUTE_FILE_NAME ${PROJECT_NAME}_${CMAKE_C_COMPILER_FRONTEND_VARIANT}_${CMAKE_C_COMPILER_ID}_${CMAKE_C_COMPILER_VERSION})
string(TOLOWER ${EXECUTE_FILE_NAME} EXECUTE_FILE_NAME)
message(STATUS "EXECUTE_FILE_NAME: ${EXECUTE_FILE_NAME}")

# setting aocl directory
if(DEFINED ROCM_DIR)
    message(STATUS "ROCM_DIR is set to: ${ROCM_DIR}")
else()
    message(FATAL_ERROR "ROCM_DIR is not defined. Please set it to the AOCL installation directory.")
endif()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D__HIP_PLATFORM_AMD__")

# Enable AOCL BLAS
set(ROCM_INCLUDE_DIRS ${ROCM_DIR}/include)
set(ROCM_LINK_DIR ${ROCM_DIR}/lib)
set(ROCM_LIBS "rocblas;amdhip64")

set(SRC_LIST
    src/main.c
    src/blas.c
)

add_executable(${EXECUTE_FILE_NAME} ${SRC_LIST})

target_include_directories(${EXECUTE_FILE_NAME} PRIVATE
    ${ROCM_INCLUDE_DIRS}
)
target_link_directories(${EXECUTE_FILE_NAME} PRIVATE
    ${ROCM_LINK_DIR}
)

target_link_libraries(${EXECUTE_FILE_NAME} PRIVATE
    ${ROCM_LIBS}
)

```

Compile using clang-cl of vs2022 on Windows platform, the running effect is as follows:
```powershell
PS D:\example\efficiency_v3\rocm\build\Release> ."D:/example/efficiency_v3/rocm/build/Release/rocm_msvc_clang_19.1.5.exe" -l 10 -n 12
Using float precision for matrix multiplication.
1       : 4096 x 4096 Matrix multiply wall time : 0.595000s(230.990Gflops)
2       : 4096 x 4096 Matrix multiply wall time : 0.146214s(939.986Gflops)
3       : 4096 x 4096 Matrix multiply wall time : 0.147548s(931.486Gflops)
4       : 4096 x 4096 Matrix multiply wall time : 0.146811s(936.165Gflops)
5       : 4096 x 4096 Matrix multiply wall time : 0.152827s(899.311Gflops)
6       : 4096 x 4096 Matrix multiply wall time : 0.143523s(957.610Gflops)
7       : 4096 x 4096 Matrix multiply wall time : 0.147841s(929.642Gflops)
8       : 4096 x 4096 Matrix multiply wall time : 0.152921s(898.757Gflops)
9       : 4096 x 4096 Matrix multiply wall time : 0.173812s(790.734Gflops)
10      : 4096 x 4096 Matrix multiply wall time : 0.172323s(797.565Gflops)
Average Gflops: 831.225, Max Gflops: 957.610
Average Time: 0.197882s, Min Time: 0.143523s
PS D:\example\efficiency_v3\rocm\build\Release> ."D:/example/efficiency_v3/rocm/build/Release/rocm_msvc_clang_19.1.5.exe" -l 10 -n 12 -double
Using double precision for matrix multiplication.
1       : 4096 x 4096 Matrix multiply wall time : 1.694739s(81.097Gflops)
2       : 4096 x 4096 Matrix multiply wall time : 1.185994s(115.885Gflops)
3       : 4096 x 4096 Matrix multiply wall time : 1.262083s(108.898Gflops)
4       : 4096 x 4096 Matrix multiply wall time : 1.232974s(111.469Gflops)
5       : 4096 x 4096 Matrix multiply wall time : 1.156926s(118.797Gflops)
6       : 4096 x 4096 Matrix multiply wall time : 1.220483s(112.610Gflops)
7       : 4096 x 4096 Matrix multiply wall time : 1.270335s(108.191Gflops)
8       : 4096 x 4096 Matrix multiply wall time : 1.209922s(113.593Gflops)
9       : 4096 x 4096 Matrix multiply wall time : 1.226809s(112.030Gflops)
10      : 4096 x 4096 Matrix multiply wall time : 1.335011s(102.950Gflops)
Average Gflops: 108.552, Max Gflops: 118.797
Average Time: 1.279528s, Min Time: 1.156926s
```
The performance is similar to opencl, and we look forward to developing more features.

[^1]: [System requirements (Windows)](https://rocm.docs.amd.com/projects/install-on-windows/en/latest/reference/system-requirements.html)

[^2]: [AMD 680M显卡编译rocBLAS使用SD](https://www.bilibili.com/opus/950640016858546201)

[^3]: [Windows编译AMD ROCm rocblas教程](https://www.bilibili.com/opus/930119242935697447)

[^4]: [Windows下编译rocBLAS](https://zhuanlan.zhihu.com/p/680642344)

[^5]: [AMD HIP SDK for Windows](https://www.amd.com/en/developer/resources/rocm-hub/hip-sdk.html)
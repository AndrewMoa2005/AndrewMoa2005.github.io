+++
author = "Andrew Moa"
title = "OpenFOAM compiles and installs cfmesh and ccm tools"
date = "2025-03-27"
description = ""
tags = [
    "linux",
    "openfoam",
]
categories = [
    "cfd",
]
series = [""]
aliases = [""]
image = "/images/vortex-bg.jpg"
+++

## 1. Compile cfmesh

The early compiled and installed OpenFOAM version of com, with the version number v2412, and there is no source code with cfmesh.
According to the official documentation, you need to manually download the source code file of cfmesh:
```Bash
cd $WM_PROJECT_DIR
git submodule update --init --recursive plugins/cfmesh
```

The following error occurs:
```Bash
fatal: fatal: not a git repository (or any of the parent directories): .git
```

Okay, let's try another approach. Download the source code directly through git to the specified folder, folder and URL path to view it `.gitmodules` document:
```Bash
cd $WM_PROJECT_DIR
git clone https://develop.openfoam.com/Community/integration-cfmesh.git plugins/cfmesh
```

Enter the cfmesh folder and start compiling:
```Bash
cd plugins/cfmesh
./Allwmake -jN # Replace N with the number of CPU cores
```

Run pMesh to verify that the installation is successful:
```Bash
pMesh -help
```

## 2. Compile the ccm tool

OpenFOAM's ccm tool includes ccmToFoam and foamToCcm, the former is used to convert the ccm format grid output by STAR-CCM+ into the grid of OpenFOAM, and the latter is the opposite.
You need to compile and install the third-party library libccmio first:
```bash
cd $WM_THIRD_PARTY_DIR
# Download libccmio
wget http://portal.nersc.gov/project/visit/third_party/libccmio-2.6.1.tar.gz
# Alternative links
# wget https://sourceforge.net/projects/foam-extend/files/ThirdParty/libccmio-2.6.1.tar.gz
tar xvzf libccmio-2.6.1.tar.gz  # Decompress the downloaded compressed file
./makeCCMIO # Run the libccmio compiler
```

Next compile ccmToFoam:
```Bash
# Compile libccm first
cd $WM_PROJECT_DIR/src/conversion/ccm
./Allwmake
# Then compile ccmToFoam and foamToCcm
cd $WM_PROJECT_DIR/applications/utilities/mesh/conversion/ccm
./Allwmake
```

Run ccmToFoam to verify that the installation is successful:
```Bash
ccmToFoam -help
```


---
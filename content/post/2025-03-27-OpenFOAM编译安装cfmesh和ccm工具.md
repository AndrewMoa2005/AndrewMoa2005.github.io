---
layout:     post
title:      "OpenFOAM编译安装cfmesh和ccm工具"
description: ""
excerpt: ""
date:    2025-03-27
author:  "Andrew Moa"
image: ""
publishDate: 2025-03-27
tags:
    - linux 
    - openfoam
URL: "/2025/03/27/openfoam-compile-cfmesh-and-ccm/"
categories: [ "CFD" ]    
---

## 1. 编译cfmesh

前期编译安装的是com版的OpenFOAM，版本号是v2412，没有附带cfmesh的源码。
根据官方文档的提示，需要手动下载cfmesh的源码文件：
```Bash
cd $WM_PROJECT_DIR
git submodule update --init --recursive plugins/cfmesh
```

出现以下错误：
```Bash
fatal: 不是 git 仓库（或者任何父目录）：.git
```

无语了，直接通过git下载源码到指定文件夹，文件夹和URL路径可以查看`.gitmodules`文件：
```Bash
cd $WM_PROJECT_DIR
git clone https://develop.openfoam.com/Community/integration-cfmesh.git plugins/cfmesh
```

进入cfmesh文件夹，开始编译：
```Bash
cd plugins/cfmesh
./Allwmake -jN # N替换成CPU核心数
```

运行pMesh，验证是否安装成功：
```Bash
pMesh -help
```

## 2. 编译ccm工具

OpenFOAM的ccm工具包含ccmToFoam和foamToCcm，前者用于将STAR-CCM+输出的ccm格式网格转换成OpenFOAM的网格，后者相反。
需要先编译安装第三方库libccmio：
```bash
cd $WM_THIRD_PARTY_DIR
# 下载libccmio
wget http://portal.nersc.gov/project/visit/third_party/libccmio-2.6.1.tar.gz
# 备选链接
# wget https://sourceforge.net/projects/foam-extend/files/ThirdParty/libccmio-2.6.1.tar.gz
tar xvzf libccmio-2.6.1.tar.gz	# 解压下载的压缩包
./makeCCMIO	# 运行libccmio的编译程序
```

接下来编译ccmToFoam：
```Bash
# 先编译libccm
cd $WM_PROJECT_DIR/src/conversion/ccm
./Allwmake
# 然后编译ccmToFoam和foamToCcm
cd $WM_PROJECT_DIR/applications/utilities/mesh/conversion/ccm
./Allwmake
```

运行ccmToFoam，验证是否安装成功：
```Bash
ccmToFoam -help
```

---
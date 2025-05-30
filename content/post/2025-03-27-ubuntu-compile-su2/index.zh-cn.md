+++
author = "Andrew Moa"
title = "Ubuntu编译安装SU2"
date = "2025-03-27"
description = ""
tags = [
    "slurm",
    "su2",
    "ubuntu",
]
categories = [
    "linux",
]
series = [""]
aliases = [""]
image = "/images/ubuntu-bg.jpg"
+++

[SU2](https://su2code.github.io/)是一款由斯坦福大学航空航天学院开发的开源CFD求解器，基于C++和Python开发，定位类似于OpenFOAM，但不支持多面体网格。相比OpenFOAM，SU2在高速可压缩流方面的求解更有优势。

下载SU2源代码：
```Bash
mkdir $HOME/su2code && cd $HOME/su2code
# 只clone最近commit版本，加快下载速度
git clone https://github.com/su2code/SU2.git --depth=1
```

定义环境变量，新建配置文件`su2.env`：
```Bash
touch $HOME/su2code/su2.env
chmod +x $HOME/su2code/su2.env
vim $HOME/su2code/su2.env
```

在`su2.env`文件中加入以下内容，保存退出：
```Bash
#!/bin/sh

# 定义SU2环境变量
export SU2_RUN=$HOME/su2code/bin	# 编译完成后su2的安装路径
export SU2_HOME=$HOME/su2code/SU2	# 下载su2的源码的文件夹路径
export PATH=$PATH:$SU2_RUN
export PYTHONPATH=$SU2_RUN:$PYTHONPATH
```

编译程序的配置文件`meson_options.txt`位于SU2源代码文件夹下，根据自己的需求调整其中的编译选项：
```Bash
vim $HOME/su2code/SU2/meson_options.txt
```

这里打开mpi和blas支持，修改以下两行的value：
```Python
option('with-mpi',   type : 'feature', value : 'enabled', description: 'enable MPI support')
option('enable-openblas', type : 'boolean', value : true, description: 'enable BLAS and LAPACK support via OpenBLAS')
```
如果是Intel的机器，建议打开mkl支持。

默认支持的blas库是openblas，要先下载openblas库：
```Bash
sudo apt install libopenblas-dev -y
```

进入下载的源码目录，运行编译程序
```Bash
# 载入环境变量
source $HOME/su2code/su2.env
# 进入源码文件夹
cd $SU2_HOME
# 配置编译器，生成ninja构建文件
# 配置过程中会自动从git上下载外部依赖
# 非常花时间……
./meson.py build --prefix=$SU2_RUN/..
# 开始编译并安装
./ninja -C build install
```

验证是否安装成功：
```Bash
SU2_CFD --help
```
安装成功会输出软件版本号和帮助信息。

编写SU2的slurm计算脚本：
```Bash
#!/bin/bash 

#SBATCH --job-name=su2_test
#SBATCH --partition=debug 
#SBATCH --output=%j.out 
#SBATCH --error=%j.err 
#SBATCH -N 1 
#SBATCH --ntasks-per-node=32 

cd $SLURM_SUBMIT_DIR

source ${HOME}/su2code/su2.env # 应填写绝对路径
export CFG_FILE=`find . -name "*.cfg"`
export MACHINEFILE=$SLURM_JOBID.nodes 
scontrol show hostnames $SLURM_JOB_NODELIST > $MACHINEFILE 

mpiexec -np $SLURM_NPROCS --machinefile $MACHINEFILE SU2_CFD $CFG_FILE

```
将脚本文件和SU2的cfg文件及网格放到同一文件夹，通过`sbatch`命令提交计算任务。

---

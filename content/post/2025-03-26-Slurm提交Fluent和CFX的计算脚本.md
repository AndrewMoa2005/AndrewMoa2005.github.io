---
layout:     post
title:      "Slurm提交Fluent和CFX的计算脚本"
description: ""
excerpt: ""
date:    2025-03-26
author:  "Andrew Moa"
image: ""
publishDate: 2025-03-26
tags:
    - cfx 
    - fluent
    - slurm
URL: "/2025/03/26/slurm-script-for-fluent-and-cfx/"
categories: [ "CFD" ]    
---

## 1. Fluent

首先要编写Fluent的jou脚本：
```text
/file/read-case "small_fan.cas.h5" 
/solve/initialize/hyb-initialization 
/solve/iterate 100 
/file/write-case "small_fan_results.cas.h5" ok 
/file/write-data "small_fan_results.dat.h5" ok 
/exit ok 
```
这个jou文件很简单，就是告诉Fluent读取哪个文件、怎么初始化、迭代多少步、如何保存直至最后退出。
如果计算比较复杂的，比如涉及到UDF加载或特殊条件初始化设置的，还需要增加相应的命令行。
不熟悉怎么编写TUI命令的话，可以通过Fluent图形界面下面的命令行窗口录制脚本。

编写Slurm脚本：
```Bash
#!/bin/bash 

#SBATCH --job-name=fluent_test	# 任务名称
#SBATCH --partition=debug 
#SBATCH --output=%j.out 
#SBATCH --error=%j.err 
#SBATCH -N 1	# 计算节点数
#SBATCH --ntasks-per-node=32	# 每节点计算进程数

cd $SLURM_SUBMIT_DIR

source ${HOME}/opt/ansys2025r1.env	# 载入许可证设置环境变量，这里应该使用绝对路径
export FLUENT=/ansys_inc/v251/fluent/bin/fluent	# fluent可执行文件路径
export MPI_TYPE=intel # intel or openmpi 
export JOU_FILE=`find . -name "*.jou"`
export MACHINEFILE=$SLURM_JOBID.node 
scontrol show hostnames $SLURM_JOB_NODELIST > $MACHINEFILE 

#注意fluent根据2维3维单双精度的不同有4钟计算模式：2d、3d、2ddp、3ddp，根据自己的需求选择对应的计算模式
$FLUENT 3ddp -g -t$SLURM_NPROCS -cnf=$MACHINEFILE -mpi=$MPI_TYPE -ssh -i $JOU_FILE

```
保存以上脚本，将待提交的cas文件和jou文件放到脚本所在文件夹，通过`sbatch`命令提交脚本即可。计算完成后将输出的结果文件下载到本地机器上处理。

## 2. CFX

相比fluent，cfx计算脚本简单很多：
```Bash
#!/bin/bash 

#SBATCH --job-name=cfx_test	# 任务名称
#SBATCH --partition=debug 
#SBATCH --output=%j.out 
#SBATCH --error=%j.err 
#SBATCH -N 1	# 计算节点数
#SBATCH --ntasks-per-node=32	# 每节点计算进程数

cd $SLURM_SUBMIT_DIR

source ${HOME}/opt/ansys2025r1.env	# 载入许可证设置环境变量，这里应该使用绝对路径
export CFX=/ansys_inc/v251/CFX/bin/cfx5solve	# cfx求解器可执行文件路径
export DEF_FILE=`find . -name "*.def"`
hostnames=`scontrol show hostnames $SLURM_JOB_NODELIST`
hostnames=`echo $hostnames | sed -e 's/ /,/g'`

$CFX -def $DEF_FILE -double -part $SLURM_NPROCS -par-dist $hostnames -start-method 'Intel MPI Distributed Parallel' -name $SLURM_JOB_NAME

```
将脚本文件和def文件放到同一文件夹并提交即可。

参考资料：
 - [Journal 脚本编写指南](https://static.fastonetech.com/Fluent%20jou%E8%84%9A%E6%9C%AC%E7%BC%96%E5%86%99%E6%8C%87%E5%8D%97.pdf)
 - [Fluent 极客 —— 强大的自定义功能（UDF，jou，参数化，expression，ACT ）](https://zhuanlan.zhihu.com/p/389105686)
 - [ANSYS - CFX, Fluent, Mechanical](https://www.ichec.ie/academic-services/national-hpc-service/software/ansys)
 - [CFX本地多核批处理文件编写方法](https://blog.csdn.net/wing_of_lyre/article/details/90080239)

---
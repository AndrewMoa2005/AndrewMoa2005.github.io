+++
author = "Andrew Moa"
title = "Slurm submits Fluent and CFX calculation scripts"
date = "2025-03-26"
description = ""
tags = [
    "cfx",
    "fluent",
    "slurm",
]
categories = [
    "cfd",
]
series = [""]
aliases = [""]
image = "/images/vortex-bg.jpg"
+++

## 1. Fluent

First, write the Fluent jou script:
```text
/file/read-case "small_fan.cas.h5" 
/solve/initialize/hyb-initialization 
/solve/iterate 100 
/file/write-case "small_fan_results.cas.h5" ok 
/file/write-data "small_fan_results.dat.h5" ok 
/exit ok 
```
This jou file is very simple. It tells Fluent which file to read, how to initialize, how many steps to iterate, and how to save until the final exit.
If the calculation is more complicated, such as involving UDF loading or special condition initialization settings, you need to add corresponding command lines.
If you are not familiar with how to write TUI commands, you can record scripts through the command line window under the Fluent graphical interface.

Writing Slurm scripts:
```Bash
#!/bin/bash 

#SBATCH --job-name=fluent_test	# Job Name
#SBATCH --partition=debug 
#SBATCH --output=%j.out 
#SBATCH --error=%j.err 
#SBATCH -N 1	# Number of computing nodes
#SBATCH --ntasks-per-node=32	# Number of computing processes per node

cd $SLURM_SUBMIT_DIR

source ${HOME}/opt/ansys2025r1.env	# Load the license setting environment variable. An absolute path should be used here.
export FLUENT=/ansys_inc/v251/fluent/bin/fluent	# Fluent executable file path
export MPI_TYPE=intel # intel or openmpi 
export JOU_FILE=`find . -name "*.jou"`
export MACHINEFILE=$SLURM_JOBID.node 
scontrol show hostnames $SLURM_JOB_NODELIST > $MACHINEFILE 

#Note that Fluent has four calculation modes according to 2D, 3D, single and double precision: 2d, 3d, 2ddp, 3ddp. Choose the corresponding calculation mode according to your needs.
$FLUENT 3ddp -g -t$SLURM_NPROCS -cnf=$MACHINEFILE -mpi=$MPI_TYPE -ssh -i $JOU_FILE

```
Save the above script, put the cas file and jou file to be submitted into the folder where the script is located, and submit the script through the `sbatch` command. After the calculation is completed, download the output result file to the local machine for processing.

## 2. CFX

Compared with Fluent, CFX calculation scripts are much simpler:
```Bash
#!/bin/bash 

#SBATCH --job-name=cfx_test	# Job Name
#SBATCH --partition=debug 
#SBATCH --output=%j.out 
#SBATCH --error=%j.err 
#SBATCH -N 1	# Number of computing nodes
#SBATCH --ntasks-per-node=32	# Number of computing processes per node

cd $SLURM_SUBMIT_DIR

source ${HOME}/opt/ansys2025r1.env	# Load the license setting environment variable. An absolute path should be used here.
export CFX=/ansys_inc/v251/CFX/bin/cfx5solve	# CFX executable file path
export DEF_FILE=`find . -name "*.def"`
hostnames=`scontrol show hostnames $SLURM_JOB_NODELIST`
hostnames=`echo $hostnames | sed -e 's/ /,/g'`

$CFX -def $DEF_FILE -double -part $SLURM_NPROCS -par-dist $hostnames -start-method 'Intel MPI Distributed Parallel' -name $SLURM_JOB_NAME

```
Put the script file and def file into the same folder and submit it.

References:
 - [Journal 脚本编写指南](https://static.fastonetech.com/Fluent%20jou%E8%84%9A%E6%9C%AC%E7%BC%96%E5%86%99%E6%8C%87%E5%8D%97.pdf)
 - [Fluent 极客 —— 强大的自定义功能（UDF，jou，参数化，expression，ACT ）](https://zhuanlan.zhihu.com/p/389105686)
 - [ANSYS - CFX, Fluent, Mechanical](https://www.ichec.ie/academic-services/national-hpc-service/software/ansys)
 - [CFX本地多核批处理文件编写方法](https://blog.csdn.net/wing_of_lyre/article/details/90080239)

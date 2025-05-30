+++
author = "Andrew Moa"
title = "超算平台部署STAR-CCM+"
date = "2022-04-08"
description = ""
tags = [
    "cfd",
    "slurm",
    "star-ccm+",
]
categories = [
    "zhihu",
]
series = [""]
aliases = [""]
image = "/images/post-bg-tech.jpg"
+++

最近提供超算试用的平台挺多的，很多平台都有免费试用的申请。因工作需要申请了某超算平台的账号并进行了相关的试用，就超算平台部署STAR-CCM+软件及应用的过程做一个简单的记录，也为后续相关应用提供参考。

## 1. 超算平台信息

远程登陆超算可以通过SSH连接，某些平台还提供的webSSH、webVNC连接，支持通过浏览器连接命令行或图形界面。具体登陆方式请参考平台提供的相关文档。

首次登陆安装部署软件之前应当先了解超算平台的配置，确定平台是否支持需要安装的软件。通过以下命令了解超算平台的发行版信息。

```bash
lsb_release -a
```

可以了解到该平台发行版为CentOS，版本7.9.2009。

![01-发行版信息.png](./images/01-发行版信息.png)

该超算平台所用并行作业调度系统为开源的Slurm，可以通过以下命令查看可供调用的计算资源。

```bash
sinfo -a
```

输出比较长，这里只截了一部分。下图中`amd_256`表示计算节点所在分区，记住它，后面编写脚本会用到。

![02-计算节点信息.png](./images/02-计算节点信息.png)

## 2. 软件安装

软件上传及存储请参考平台提供的相关文档。

本文安装的是16.06.010双精度Linux版本。通过以下命令解压`tar.gz`安装包。

```bash
tar xvzf [file-name].tar.gz
```

安装文件被解压到`starccm+_16.06.010`目录中，进入该目录运行`.sh`文件开始安装。注意，此处不需要root用户权限（多数情况下平台是不会提供root账号的，但不影响软件安装）。

```bash
./STAR-CCM+16.06.010_01_linux-x86_64-2.17_gnu9.2-r8.sh
```

用VNC连接的可以通过图形界面安装，不想通过图形界面安装可以用以下命令强制通过控制台安装。

```bash
./STAR-CCM+16.06.010_01_linux-x86_64-2.17_gnu9.2-r8.sh -i console
```

本文采用控制台方式进行安装。首先提示LICENSE，如下图所示，按`ENTER`继续。

![03-LICENSE提示.png](./images/03-LICENSE提示.png)

是否接受用户协议，输入`Y`，`ENTER`确认继续。

![04-LICENSE确认.png](./images/04-LICENSE确认.png)

用户体验计划，根据自己需要选择是否接受(Y/N)，不影响后续使用。

![05-用户体验计划.png](./images/05-用户体验计划.png)

安装位置，本文选择安装在`${HOME}/opt/Siemens`目录下，按提示输入绝对路径，`Y`确认。

![06-输入安装位置.png](./images/06-输入安装位置.png)

安装信息，`ENTER`确认，开始复制文件。

![07-安装信息.png](./images/07-安装信息.png)

安装完成，`ENTER`确认退出。记住安装路径：

`${HOME}/opt/Siemens/16.06.010-R8/STAR-CCM+16.06.010-R8`

![08-安装完成确认.png](./images/08-安装完成确认.png)

和谐过程就免了，自行参考文档吧。支持正版，打击盗版。

## 3. 编制SLURM脚本

下面编写SLURM脚本，提交算例简单测试一下。

```bash
#!/bin/bash 

#SBATCH --job-name=carbin_tcm 
#SBATCH --partition=amd_256 
#SBATCH --output=%j.out 
#SBATCH --error=%j.err 
#SBATCH -N 2 
#SBATCH --ntasks-per-node=64 

export MPI_TYPE=openmpi # intel platform openmpi 
export DIR=/***/home/***/opt/Siemens/16.06.010-R8/STAR-CCM+16.06.010-R8/star/bin 
export CDLMD_LICENSE_FILE=/***/home/***/opt/Siemens/license.dat 
export SIM_FILE=carbin_tcm.sim 
#export JAVA_FILE=carbin_tcm.java 
export MACHINEFILE=$SLURM_JOBID.node 
scontrol show hostnames $SLURM_JOB_NODELIST > $MACHINEFILE 
$DIR/starccm+ $SIM_FILE -batch $JAVA_FILE -np $SLURM_NPROCS -machinefile $MACHINEFILE -mpi $MPI_TYPE -rsh ssh -power 
```

`--job-name`指定的的是案例的名称，可以在`squeue`命令中显示的名称。

`--partition`指定的是计算节点所在分区，这里调用的是`amd_256`分区中的计算节点。

`--output`指定输出文件名称，`%j`或`$SLURM_JOBID`表示当前作业ID，由平台自行指定。

`--error`指定输出错误文件名称。

`-N`指定该案例调用的节点数，这里调用2个计算节点。

`--ntasks-per-node`指定每节点进程数，这里指定每节点调用64线程。

变量`$SLURM_NPROCS`表示总的计算进程数，可以根据以上两个参数自动计算，总的计算进程为128。

参数`MPI_TYPE`指定调用mpi类型，推荐用`intel`或`openmpi`，`platform`高版本不再支持。

参数`DIR`指定STAR-CCM+安装路径，就是`starccm`+文件所在的路径。

参数`CDLMD_LICENSE_FILE`指定LICENSE的访问路径，可以是**文件路径**也可以是**端口号@主机地址**。

参数`SIM_FILE`指定测试案例文件名。

参数`JAVA_FILE`指定宏文件名。如果使用了宏，可以把这一行的注释去掉，把文件名改成调用的宏文件名即可。

参数`MACHINEFILE`指定节点文件。

命令`scontrol show hostnames SLURM_JOB_NODELIST > MACHINEFILE`用于输出主机名到节点文件。

保存算例脚本文件为`carbin_tcm.slurm`，测试案例文件为`carbin_tcm.sim`，一共2个文件，上传。计算时间步长、迭代次数等要在`.sim`文件中先定义好，生成网格、配置好边界条件再行上传计算。

如果算例文件比较大，可以压缩上传再解压。也可以清除掉网格再上传，通过调用宏重新生成网格、定义边界条件、计算。

## 4. 提交计算任务

通过`sbatch`命令提交计算任务。

```bash
sbatch carbin_tcm.slurm
```

提交后自动生成ID、排队，本算例ID号为899634。

![09-提交计算.png](./images/09-提交计算.png)

通过`squeue`命令查看计算任务队列。

![10-计算任务队列.png](./images/10-计算任务队列.png)

计算完成后，打包下载输出文件即可。

![11-输出文件.png](./images/11-输出文件.png)


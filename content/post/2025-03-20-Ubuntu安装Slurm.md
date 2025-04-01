---
layout:     post
title:      "Ubuntu安装Slurm"
description: ""
excerpt: ""
date:    2025-03-20
author:  "Andrew Moa"
image: ""
publishDate: 2025-03-20
tags:
    - linux
    - slurm
    - ubuntu
URL: "/2025/03/20/ubuntu-install-slurm/"
categories: [ "Linux" ]    
---

Slurm，和PBS、LSF一样，超算上常用的任务管理系统。Slurm优点是开源免费、活跃度很高，近几年国内新兴的超算平台几乎都提供了Slurm作为主要的任务管理系统。PBS开源后活跃度低得可怜，更新到最新系统后安装一直出问题，提了issue也不见答复。LSF有版权风险，国内应用也不多，属于很少见的类型。至于命令和脚本，这三家都大差不差，学会了其中一家另外的也是手到擒来。

Ubuntu安装Slurm还是十分简单的，重要的工具基本都编译好了，直接apt安装即可，其他依赖项会自动安装：
```Bash
sudo apt install slurmd	# 安装计算节点守护进程
sudo apt install slurmctld # 安装管理节点守护进程
```

Slurm需要有一个专门的用户用于通信等操作，这个用户的默认用户名是`slurm`，上面的命令其实已经自动在Ubuntu中生成了`slurm`用户，可以通过下面的命令验证：
```Bash
lastlog | grep slurm
```

如果Ubuntu没有生成`slurm`用户，可以用以下命令生成：
```Bash
sudo useradd slurm
```

Slurm配置文件主要在 `/etc/slurm/` 目录下，主配置文件：`/etc/slurm/slurm.conf`，我们需要生成配置文件。官方提供了辅助生成配置文件的工具：[Slurm Configuration Tool](https://slurm.schedmd.com/configurator.html) 。

根据网页内容提示，填写配置文件其中一些关键部分：
```Bash
ClusterName=Cluster # 集群命名，任意英文和数字组合

SlurmctldHost=dell-vm # 管理节点，这里填本机名称

NodeName=dell-vm # 计算节点，同样填本机名称
PartitionName=debug # 计算节点所在分区，默认为debug
CPUs=32 # 计算节点CPU核心数，根据实际情况填写
Sockets=1 # CPU插槽数，根据实际情况填写
CoresPerSocket＝32 # 每插槽核心数，根据实际情况填写
ThreadsPerCore=1 # 每核心线程数，建议为1，不建议打开超线程

SlurmUser=slurm # 默认为slurm用户，不建议改成root用户

StateSaveLocation=/var/spool/slurmctld # 管理节点守护进程的存储文件夹，默认即可
SlurmdSpoolDir=/var/spool/slurmd # 计算点守护进程的存储文件夹，默认即可
```
更多解释可以参考中科大网站上的信息。<sup>(1)

网页内容填写完成后点击最下面的`Submit`，把显示的配置文件模板拷贝下来，存到`/etc/slurm/slurm.conf`文件中：
```Bash
sudo vim /etc/slurm/slurm.conf	# 复制粘贴到这个文件里
```

生成守护进程的读写文件夹：
```Bash
sudo mkdir /var/spool/slurmd # Ubuntu下提示文件夹已存在，无视它
sudo mkdir /var/spool/slurmctld
```

启动Slurm的服务：
```Bash
sudo systemctl enable slurmd
sudo systemctl enable slurmctld
sudo systemctl start slurmd
sudo systemctl start slurmctld
```

查看Slurm守护进程的启动状态：
```Bash
sudo systemctl status slurmd
sudo systemctl status slurmctld
```

`slurmd`守护进程启动成功，但`slurmctld`守护进程启动报错，查看报错信息如下：
```text
(null): _log_init: Unable to open logfile `/var/log/slurmctld.log': Permission denied
slurmctld: fatal: Incorrect permissions on state save loc: /var/spool/slurmctld
```

为解决这个问题，最简单办法是将`SlurmUser`改为`root`。这里采用另外一种方法：
```Bash
sudo touch /var/log/slurmctld.log # 创建slurmctld守护进程的日志文件
sudo chown slurm /var/log/slurmctld.log # 将日志文件所有者改为slurm用户
sudo chown -R slurm /var/spool/slurmctld # 将slurmctld守护进程读写文件夹的所有者改为slurm用户
```

重新启动`slurmctld`服务即可：
```Bash
sudo systemctl restart slurmctld
```

Slurm脚本和命令行，国内的用户可以参考交大编写的用户手册，比较全面，这里就不一一列举了。<sup>(2) 

以下是一些常用Slurm命令：

- 当前节点的配置可以通过以下命令获取：
  ```Bash
  slurmd -C
  ```

- 查看当前集群的节点状态：
  ```Bash
  sinfo -N
  ```

- 查看指定节点信息：
  ```Bash
  scontrol show node dell-vm # dell-vm是计算节点的名称
  ```

- 查看当前用户提交的任务信息，通常只显示正在排队和运行中的任务：
  ```Bash
  squeue
  ```

- 提交计算任务：
  ```Bash
  sbatch jobscript.slurm # jobscript.slurm为用户编写的计算脚本，可不带后缀名
  ```

- 查看和修改任务状态：
  ```Bash
  scontrol show job ${JOB_ID} # 查看指定任务的信息，${JOB_ID}对应squeue显示的第一列的任务编号
  scontrol hold ${JOB_ID} # 暂停${JOB_ID}
  scontrol release ${JOB_ID} # 恢复${JOB_ID}
  ```

- 取消计算任务：
  ```Bash
  scancel ${JOB_ID} # 取消${JOB_ID}
  ```

<sup>(1) [Slurm资源管理与作业调度系统安装配置](https://scc.ustc.edu.cn/hmli/doc/linux/slurm-install/slurm-install.html#id17)

<sup>(2) [Slurm 作业调度系统](https://docs.hpc.sjtu.edu.cn/job/slurm.html)

---
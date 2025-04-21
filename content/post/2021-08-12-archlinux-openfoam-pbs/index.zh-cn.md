+++
author = "Andrew Moa"
title = "ArchLinux下OpenFOAM编译安装与PBS并行化"
date = "2021-08-12"
description = ""
tags = [
    "linux",
    "pbs",
]
categories = [
    "zhihu",
]
series = [""]
aliases = [""]
image = "/images/post-bg-tech.jpg"
+++

## 1. 源代码下载 

### 1.1 下载OpenFOAM源代码

在`${HOME}`目录下新建OpenFOAM目录：

```bash
cd ${HOME}
mkdir OpenFOAM && cd OpenFOAM
```

从github下载OpenFOAM和ThirdParty的源代码，放到`${HOME}/OpenFOAM`目录中：

```bash
git clone https://github.com/OpenFOAM/OpenFOAM-dev --depth=1
git clone https://github.com/OpenFOAM/ThirdParty-dev --depth=1
```

### 1.2 下载Torque(PBS)源码包

本文用的是AUR中的Torque，CentOS、Debian和SUSE系的操作系统可以从Github上的OpenPBS下载现成的二进制包。采用OpenPBS或PBS Pro请跳过本文第3节，参照其他文档进行PBS配置。

从AUR上下载Torque(PBS)源文件：

```bash
git clone https://aur.archlinux.org/torque.git
cd torque
wget http://wpfilebase.s3.amazonaws.com/torque/torque-6.1.1.1.tar.gz
```

## 2. 编译安装OpenFOAM

### 2.1 设置环境变量

编辑`${HOME}/.bashrc`文件，添加以下两行：

```bash
#OpenFOAM
source ${HOME}/OpenFOAM/OpenFOAM-dev/etc/bashrc WM_MPLIB=OPENMPI
```

末尾的`WM_MPLIB=OPENMPI`表示使用重新编译的OpenMPI库。

更新环境变量：

```bash
source ${HOME}/.bashrc
```

验证环境变量是否正确：

```bash
echo $WM_PROJECT_DIR
echo $WM_THIRD_PARTY_DIR
```

可以正确输出OpenFOAM编译目录，则表示环境变量设置正确。

### 2.2 编译第三方库

进入`ThirdParty-dev`目录，编译第三方库：

```bash
cd $WM_THIRD_PARTY_DIR
wget https://download.open-mpi.org/release/open-mpi/v2.1/openmpi-2.1.1.tar.gz
tar -xvzf openmpi-2.1.1.tar.gz
./Allwmake
```

由于前面指定了`WM_MPLIB=OPENMPI`，此处需要手动下载OpenMPI源码文件，使用`wget`下载OpenMPI源码包并解压。`Allwmake`后面可以增加`-jN`选项开启多核并行编译，这里的`N`应替换成并行数，`Allwmake`会自动编译OpenMPI。

```bash
which mpirun
>${WM_THIRD_PARTY_DIR}/platforms/linux64Gcc/openmpi-2.1.1/bin/mpirun
which mpicc
>${WM_THIRD_PARTY_DIR}/platforms/linux64Gcc/openmpi-2.1.1/bin/mpicc
```

### 2.3 编译ParaView

继续在`ThirdParty-dev`目录里编译ParaView：

```bash
cd $WM_THIRD_PARTY_DIR
./makeParaView -mpi
wmRefresh
```

编译完成后运行`wmRefresh`刷新环境变量。

### 2.4 编译OpenFOAM

切换到`OpenFOAM-dev`目录编译OpenFOAM：

```bash
cd $WM_PROJECT_DIR
./Allwmake -jN
```

OpenFOAM编译时间较长，建议开启多核心并行编译，这里的`N`应替换成核心数。

### 2.5 测试

执行以下命令从OpenFOAM自带的实例文件中拷贝cavity文件夹到当前路径下：

```bash
mkdir $FOAM_RUN && cd $FOAM_RUN
cp -r $FOAM_TUTORIALS/incompressible/simpleFoam/pitzDaily .
cd pitzDaily
```

生成网格：

```bash
blockMesh
```

执行计算：

```bash
simpleFoam | tee simpleFoam.log
```

启动ParaView进行后处理：

```bash
paraFoam
```

### 2.6 更新

使用`git`命令更新`OpenFOAM-dev`及`ThirdParty-dev`目录中的源代码文件，然后重新编译安装：

```bash
git pull
wcleanPlatform
./Allwmake -jN
```

## 3. 编译安装Torque(PBS)

### 3.1 安装Torque

进入`torque`目录：

```bash
cd ${HOME}/OpenFOAM/torque
```

编译Torque：

```bash
makepkg
```

安装Torque：

```bash
sudo pacman -U torque-6.1.1.1-2-x86_64.pkg.tar.zst
```

启动服务（`pbs_mom.service`和`pbs_sched.service`在源代码的`src/torque-6.1.1.1/contrib/systemd`目录中，需要手动复制过来）：

```bash
sudo systemctl enable pbs_server
sudo systemctl enable trqauthd
sudo systemctl start pbs_server
sudo systemctl start trqauthd
sudo cp pbs_mom.service /usr/lib/systemd/system
sudo systemctl enable pbs_mom
sudo systemctl start pbs_mom
sudo cp pbs_sched.service /usr/lib/systemd/system
sudo systemctl enable pbs_sched
sudo systemctl start pbs_sched
```

### 3.2 服务器配置

参考[archlinux wiki](https://wiki.archlinux.org/index.php/TORQUE)，完成Torque配置。

编辑`/etc/hosts`文件（示例），添加服务器节点和计算节点IP地址：

```bash
192.168.100.101    master
#192.168.100.102    cluster01
#192.168.100.103    cluster02
```

更改`/var/spool/torque/server_name`文件中的主机名为服务器节点主机名：

```bash
master
```

执行以下命令，选择Y新建服务器端配置文件（只运行一次，提示会覆盖现有配置文件）：

```bash
sudo pbs_server -t create
```

执行以下命令，运行服务器端守护进程：

```bash
sudo trqauthd
```

初始化默认设置：

```bash
sudo qmgr -c "set server acl_hosts = master"
sudo qmgr -c "set server scheduling=true"
sudo qmgr -c "create queue batch queue_type=execution"
sudo qmgr -c "set queue batch started=true"
sudo qmgr -c "set queue batch enabled=true"
sudo qmgr -c "set queue batch resources_default.nodes=1"
sudo qmgr -c "set queue batch resources_default.walltime=3600"
sudo qmgr -c "set server default_queue=batch"
sudo qmgr -c "set server keep_completed = 60"
```

验证设置：

```bash
qmgr -c 'p s'
```

编辑`/var/spool/torque/server_priv/nodes`文件，添加计算节点（服务器也可以是计算节点）。格式为`HOSTNAME np=x gpus=y`：

```bash
master np=8 gpus=1
```

### 3.3 计算节点设置

编辑`/var/spool/torque/mom_priv/config`文件，添加以下信息：

```bash
pbsserver    master    # 服务器主机名，与nodes一致
logevent    255    # 日志记录事件数
```

生成并注册密钥文件，确保主机间ssh访问通畅：

```bash
cd $HOME/.ssh
ssh-keygen -t rsa
cp id_rsa.pub authorized_keys
```

### 3.4 重启服务端进程

在服务器端执行以下命令，重启服务端进程。

```bash
sudo killall -s 9 pbs_server
sudo pbs_server
```

### 3.5 启动计算节点进程

执行以下命令，启动计算节点进程

```bash
sudo pbs_mom
```

执行以下命令，显示计算节点状态：

```bash
pbsnodes -a
```

输出以下信息（示例），表示配置成功：

```bash
master
     state = free
     power_state = Running
     np = 4
     ntype = cluster
     mom_service_port = 15002
     mom_manager_port = 15003
     gpus = 1
```

若节点state显示为down，表示该节点不可用。可以用以下命令强制使节点释放：

```bash
sudo qmgr -a -c 'set node master state=free'
```

我们可以编写systemd服务脚本，自动释放节点。脚本内容如下，另存为`/usr/lib/systemd/system/pbs_autofree.service`文件：

```bash
[Unit]
Description=Auto free pbs_server
Requires=network.target
After=network.target trqauthd.service pbs_server.service pbs_mom.service
StartLimitIntervalSec=0
 
[Service]
Type=simple
Restart=always
RestartSec=30
User=root
ExecStart=qmgr -a -c 'set node master state=free'
 
[Install]
WantedBy=multi-user.target
```

启动服务：

```bash
sudo systemctl enable pbs_autofree
sudo systemctl start pbs_autofree
```

关闭服务以节省资源：

```bash
sudo systemctl disable pbs_autofree
sudo systemctl stop pbs_autofree
```

## 4. OpenFOAM并行化提交作业

### 4.1 准备算例

执行以下命令从OpenFOAM自带的实例文件中拷贝cavity文件夹到当前路径下：

```bash
cd $FOAM_RUN
mkdir cluster && cd cluster
cp -r $FOAM_TUTORIALS/incompressible/simpleFoam/pitzDaily .
cd pitzDaily
```

在`system`目录下新建`decomposeParDict`文件，用于网格分区，为并行化作准备。文件内容如下，网格分区数为2：

```bash
FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    note        "mesh decomposition control dictionary";
    object      decomposeParDict;
}
numberOfSubdomains  2;
method          scotch;
```

### 4.2 提交作业

新建脚本文件，命名为`pitzDaily.pbs`，用于提交并行作业。文件内容如下，使用1个节点、每节点2个CPU核心进行计算（`nodes=1:ppn=2`），线程数2（`mpirun -np 2`），这些与`decomposeParDict`文件中网格分区数目要保持一致：

```bash
#!/bin/bash
#PBS -l nodes=1:ppn=2
#
#PBS -N pitzDaily
#PBS -A OpenFOAM
#PBS -o pitzDaily.out
#PBS -e pitzDaily.err
#
source ${HOME}/OpenFOAM/OpenFOAM-dev/etc/bashrc WM_MPLIB=OPENMPI
export RUN_DIR=${FOAM_RUN}/cluster/pitzDaily
cd ${RUN_DIR}
blockMesh
decomposePar
mpirun -np 2 simpleFoam -parallel | tee simpleFoam.log
reconstructPar
tar -Jcvf pitzDaily_results.tar.xz *
```

使用qsub提交作业：

```bash
chmod 755 pitzDaily.pbs
qsub pitzDaily.pbs
```

使用qstat检查作业状态：

```bash
qstat -a
```

计算结束后，下载`pitzDaily_results.tar.xz`文件并解压缩，启动ParaView进行后处理：

```bash
paraFoam
```


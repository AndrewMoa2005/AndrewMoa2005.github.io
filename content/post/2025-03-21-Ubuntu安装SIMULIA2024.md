---
layout:     post
title:      "Ubuntu安装SIMULIA2024"
description: ""
excerpt: ""
date:    2025-03-21
author:  "Andrew Moa"
image: ""
publishDate: 2025-03-21
tags:
    - abaqus
    - cae
    - linux
    - slurm
    - ubuntu
URL: "/2025/03/21/ubuntu-install-simulia/"
categories: [ "Linux" ]    
---

为什么选择SIMULIA？首先是Abaqus功能强大，绝大多数结构问题都能求解。其次流固耦合方便，STAR-CCM+自带案例就手把手你怎么和Abaqus双向耦合。再次是过往经历的惯性，毕竟主机厂Abaqus用得可不少，不缺案例和资源。

## 1. 准备工作

首先安装开发环境和一些必要的软件：
```Bash
sudo apt update # 更新软件源
sudo apt upgrade # 更新本地安装的软件
sudo apt install build-essential # 安装开发环境
sudo apt install csh tcsh ksh gcc g++ gfortran libstdc++5 build-essential make libjpeg62 libmotif-dev
```

解压安装包：
```Bash
mkdir iso # 新建一个iso文件夹，用于存放解压出来的文件
tar xvzf DS.SIMULIA.SUITE.2024.LINX64.tar.gz -C ./iso # 解压到iso文件夹中
```

## 2. 安装过程

### 2.1 启动安装程序

首先定义环境变量，不然无法启动安装程序：
```Bash
# 可以把下面的内容加到${HOME}/.bashrc里，然后重新启动终端
export DSYAuthOS_`lsb_release -si`=1
export DSY_Force_OS=linux_a64
export NOLICENSECHECK=true
```

进入`/iso/1`文件夹，运行安装程序。启动图形化界面在终端运行`./StartGUI.sh`，类似Windows下的安装方式，跟着向导一步步安装即可。

这里选择文本界面：
```Bash
./StartTUI.sh # 启动文本界面安装向导
```

![7222cbf4b6f8545b9766ce654edf28ba.png](/resources/7222cbf4b6f8545b9766ce654edf28ba.png)
`Enter`下一步。

![32a37d1807765cbc529f11c58e35ea12.png](/resources/32a37d1807765cbc529f11c58e35ea12.png)
记得一定要选`4`，也就是`FLEXnet License Server`。输入`4`，然后`Enter`继续。

![e29968284f99250e82746af3a935d704.png](/resources/e29968284f99250e82746af3a935d704.png)
确认安装内容，`Enter`开始启动相关安装程序。

### 2.2 安装许可证服务器

![2b46aa33180c36f27a537a1ab8418f3a.png](/resources/2b46aa33180c36f27a537a1ab8418f3a.png)
选择`P`，然后输入`/iso/4`文件夹的绝对路径。

![98b4844bd00955f5d423ca362fe2b553.png](/resources/98b4844bd00955f5d423ca362fe2b553.png)
选择许可证服务器的安装路径，这里选择安装在`${HOME}/opt/SIMULIA/License/2024`路径下，要输入绝对路径。

![da9c6aa1f933df48fe6027e382c878d5.png](/resources/da9c6aa1f933df48fe6027e382c878d5.png)
这里选择默认，安装后启动许可证服务器。

![842cf6835291e50d2a108b92c793ae29.png](/resources/842cf6835291e50d2a108b92c793ae29.png)
选择许可证文件路径，输入绝对路径。

![0a7fcef173dc84dbae5cd0fd3561f1d0.png](/resources/0a7fcef173dc84dbae5cd0fd3561f1d0.png)
输入许可证文件后提示检索主机ID失败，忽略它，输入`2`继续。

![3cdf57da3ac4f813368bc21959fd50cc.png](/resources/3cdf57da3ac4f813368bc21959fd50cc.png)
继续选`2`。

![37278e435bdf4ce57cc8753974ed4262.png](/resources/37278e435bdf4ce57cc8753974ed4262.png)
确认安装信息。

![d98331d9aec49934746e4780dc8a570f.png](/resources/d98331d9aec49934746e4780dc8a570f.png)
安装完成，`Enter`继续下一个程序安装。

### 2.3 安装求解器

![e63e9f0c584011800a215af5d2c128a7.png](/resources/e63e9f0c584011800a215af5d2c128a7.png)
选择`P`，然后输入`/iso/5`文件夹的绝对路径。

![9da9338bf17ca917eee54135eac4bd13.png](/resources/9da9338bf17ca917eee54135eac4bd13.png)
选择安装路径，这里选择安装在`${HOME}/opt/SIMULIA/EstProducts/2024`路径下。

![150907cf29102dc5b4bcda22e3f2af44.png](/resources/150907cf29102dc5b4bcda22e3f2af44.png)
选择要安装的内容，全选输入`-1`。

![618fa052254d576c29637eb792b63f5b.png](/resources/618fa052254d576c29637eb792b63f5b.png)
选择许可证类型，默认选第`1`个。

![2525f16acab485199fb0107493718334.png](/resources/2525f16acab485199fb0107493718334.png)
输入许可证服务器的访问地址和端口，输入`29100@localhost`定义`License Server 1`，其余`Enter`跳过。

![5e3f75d3e4eb45d0651f815415cec836.png](/resources/5e3f75d3e4eb45d0651f815415cec836.png)
选择命令行程序的路径，这里选择安装到`${HOME}/opt/SIMULIA/var/DassaultSystemes/SIMULIA/Commands`。

![2dbc679c28801c1edcf17410e0541414.png](/resources/2dbc679c28801c1edcf17410e0541414.png)
选择外部插件的路径，这里选择安装到`${HOME}/opt/SIMULIA/var/DassaultSystemes/SIMULIA/CAE/plugins/2024`。

![0ab546bf5c53e748044cb596a40aac68.png](/resources/0ab546bf5c53e748044cb596a40aac68.png)
选择`Tosca`的接口，根据实际需要来。

![575d8708a07ed1bc9781af02aa739e58.png](/resources/575d8708a07ed1bc9781af02aa739e58.png)
选择`Tosca Fluid`工作目录，这里指派到`${HOME}/temp`下。

![f9de5443a5f54c198a15d433cbcc459d.png](/resources/f9de5443a5f54c198a15d433cbcc459d.png)
选择STAR-CCM+安装路径，根据实际情况设置，默认留空。

![bfade401e6f700848f6166f118eb2204.png](/resources/bfade401e6f700848f6166f118eb2204.png)
选择STAR-CCM+许可证，根据实际情况设置，默认留空。

![817069e8e89653272d962e4a6553940e.png](/resources/817069e8e89653272d962e4a6553940e.png)
选择Fluent安装路径，根据实际情况设置，默认留空。

![4b87a12aa92cdc9ef67cb2596b331bc1.png](/resources/4b87a12aa92cdc9ef67cb2596b331bc1.png)
确认安装信息，`Enter`开始复制文件。

![a48dc4111041562afdd9c43a3f853613.png](/resources/a48dc4111041562afdd9c43a3f853613.png)
安装过程中会启动验算程序，可以查看验算结果。`Enter`继续。

![192460b7772483522ff8ff97c5f47f61.png](/resources/192460b7772483522ff8ff97c5f47f61.png)
求解器安装完成，`Enter`退出，进入下一个安装程序。

### 2.4 安装CAA API

![a1105475937fa8f0c85abdf177501160.png](/resources/a1105475937fa8f0c85abdf177501160.png)
选择`P`，然后输入`/iso/6`文件夹的绝对路径。

![fbe21029d223f693d9cdfd727ec588c4.png](/resources/fbe21029d223f693d9cdfd727ec588c4.png)
选择安装路径，这里选择安装到`${HOME}/opt/SIMULIA/EstProducts/2024`。

![098367e7a54310e3ceefee9c52659171.png](/resources/098367e7a54310e3ceefee9c52659171.png)
确认要安装的内容，`Enter`继续。

![2e23fd22aea12099636c0c53efb9b011.png](/resources/2e23fd22aea12099636c0c53efb9b011.png)
完成安装，`Enter`退出。

### 2.5 安装Isight

![58015ba8b4b0068cfcb447f20857939f.png](/resources/58015ba8b4b0068cfcb447f20857939f.png)
选择安装路径，这里选择安装到`${HOME}/opt/SIMULIA/Isight/2024`。

![48a30d42cac1ed6b1b91f2ce39040cce.png](/resources/48a30d42cac1ed6b1b91f2ce39040cce.png)
选择要安装的内容，`-1`全选。

![741fd85d5d3f278d9bb7f9bf6530c60a.png](/resources/741fd85d5d3f278d9bb7f9bf6530c60a.png)
是否启动`TomEE`配置工具，默认跳过。

![bcda28276dc83f5ae970fcfa37300078.png](/resources/bcda28276dc83f5ae970fcfa37300078.png)
这一步也默认跳过吧。

![b6652ff01997c5fa5e1375d92be835f3.png](/resources/b6652ff01997c5fa5e1375d92be835f3.png)
没有安装文档，选择跳过吧。

![952737d22e78e4dd5cbb2fddf27e9bc4.png](/resources/952737d22e78e4dd5cbb2fddf27e9bc4.png)
确认安装内容，`Enter`开始复制文件。

![f27fe27fbc46bb915c1fe167d235753f.png](/resources/f27fe27fbc46bb915c1fe167d235753f.png)
安装完成，`Enter`退出。

### 2.6 安装完成

![2f4f47eb05fb870bb885b5ccfb13a9aa.png](/resources/2f4f47eb05fb870bb885b5ccfb13a9aa.png)
确认安装结果，`Enter`退出SIMULIA安装程序。

## 3. 安装后配置

### 3.1 启动配置

启动之前要修改配置文件：
```Bash
vim ${HOME}/opt/SIMULIA/EstProducts/2024/linux_a64/SMA/site/custom_v6.env
```

在最末尾增加两行内容，保存退出：
```Bash
license_server_type=FLEXNET
abaquslm_license_file="29100@localhost"
```

新建环境变量配置文件：
```Bash
touch ${HOME}/opt/SIMULIA/simulia24.env
chmod +x ${HOME}/opt/SIMULIA/simulia24.env
vim ${HOME}/opt/SIMULIA/simulia24.env
```

编辑内容如下，最好都用绝对路径，保存退出：
```Bash
export LICENSE_PREFIX_DIR=${HOME}/opt/SIMULIA/License/2024/linux_a64/code/bin
export SIMULIA_COMMAND_DIR=${HOME}/opt/SIMULIA/var/DassaultSystemes/SIMULIA/Commands
export PATH=$SIMULIA_COMMAND_DIR:$LICENSE_PREFIX_DIR:$PATH
export LM_LICENSE_FILE=29100@localhost
```

运行以下命令载入环境变量：
```Bash
source ${HOME}/opt/SIMULIA/simulia24.env
```

通过以下命令启动Abaqus图形界面[^1]：
```Bash
abaqus cae -mesa
abaqus view -mesa
```

### 3.2 许可证安装问题

如果[3.1](#31-启动配置)中Abaqus能正常启动，那么这一步骤可以跳过了。

验证许可证服务器是否在运行：
```Bash
ps -eaf | grep ABAQUSLM
```

发现许可证服务器没有运行，通过以下命令启动许可证服务器：
```Bash
${HOME}/opt/SIMULIA/License/2024/linux_a64/code/bin/licenseStartup.sh
```

启动未成功，报错信息如下：
```Bash
/home/***/opt/SIMULIA/License/2024/linux_a64/code/bin/licenseStartup.sh: 2: /home/***/opt/SIMULIA/License/2024/linux_a64/code/bin/lmgrd: not found
```

无解了，这要么是安装包有问题，要么是这个发行版缺少了某些运行库，等大佬出手吧。

不过好在Windows版许可证可以正常安装，只需要将许可证路径指派到Windows机器上即可。首先在Windows防火墙中打开29100端口，新建防火墙入站规则：
![33aec1f9e7b7132dc0d6143a9d9d25fe.png](/resources/33aec1f9e7b7132dc0d6143a9d9d25fe.png)

然后将[3.1](#31-启动配置)中`custom_v6.env`文件的许可证地址修改如下：
```Bash
license_server_type=FLEXNET
# abaquslm_license_file="29100@localhost"
abaquslm_license_file="29100@172.25.64.1" # 172.25.64.1为Windows主机IP地址
```

修改环境变量文件`${HOME}/opt/SIMULIA/simulia24.env`：
```Bash
# export LM_LICENSE_FILE=29100@localhost
export LM_LICENSE_FILE=29100@172.25.64.1
```

载入环境变量后，通过`abaqus cae`命令可以正常启动，不会再提示许可证问题。
![截图 2025-03-21 15-16-50.png](/resources/截图%202025-03-21%2015-16-50.png)

不得不承认，Linux的图形界面确实不好用，但是谁关心呢？反正又不会在Linux下画图、处理网格，能提交计算就行了。

### 3.3 提交集群计算

Abaqus的Slurm脚本[^2]参考如下：
```Bash
#!/bin/bash 

#SBATCH --job-name=abaqus_test
#SBATCH --partition=debug 
#SBATCH --output=%j.out 
#SBATCH --error=%j.err 
#SBATCH -N 1 
#SBATCH --ntasks-per-node=32 

cd $SLURM_SUBMIT_DIR

source /home/***/opt/SIMULIA/simulia24.env # 填写绝对路径
export INPFILE=`find . -name "*.inp"`
export ENVFILE=/home/***/opt/SIMULIA/EstProducts/2024/linux_a64/SMA/site/abaqus_v6.env # 填写绝对路径

# 生成abaqus_6.env文件，指定hosts
rm -rf $PWD/abaqus_v6.env
cp $ENVFILE $PWD/abaqus_v6.env
node_list=$(scontrol show hostname ${SLURM_NODELIST} | sort -u)
mp_host_list="["
for host in ${node_list}; do
    mp_host_list="${mp_host_list}['$host', ${SLURM_NTASKS_PER_NODE}],"
done
mp_host_list=$(echo ${mp_host_list} | sed -e "s/,$/]/")
echo "mp_host_list=${mp_host_list}"  >> $PWD/abaqus_v6.env

# 创建Scratch目录
mkdir scratch.$SLURM_JOB_ID

abaqus job=$SLURM_JOB_NAME input=$INPFILE cpus=$SLURM_NPROCS scratch=scratch.$SLURM_JOB_ID mp_mode=mpi double=both output_precision=full resultsformat=odb int ask=off > $SLURM_JOB_NAME.log
rm -rf $PWD/abaqus_v6.env scratch.$SLURM_JOB_ID

```

将`inp`文件和脚本放到同一文件夹，使用`sbatch`命令提交脚本。计算完成后下载结果到本机，用`Abaqus Viewer`或`Meta`查看结果。

[^1]: [franaudo/abaqus-ubuntu ](https://github.com/franaudo/abaqus-ubuntu)

[^2]: [abhpc/ABHPC-Guide ](https://github.com/abhpc/ABHPC-Guide/tree/master)

---

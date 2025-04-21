+++
author = "Andrew Moa"
title = "Ubuntu Install SIMULIA2024"
date = "2025-03-21"
description = ""
tags = [
    "abaqus",
    "cae",
    "linux",
    "slurm",
    "ubuntu",
]
categories = [
    "linux",
]
series = [""]
aliases = [""]
image = "/images/ubuntu-bg.jpg"
+++

Why did you choose SIMULIA? First, Abaqus is powerful and can solve most structural problems. Second, fluid-structure coupling is convenient. STAR-CCM+ comes with a case that shows you how to couple with Abaqus bidirectionally. Third, it is the inertia of past experience. After all, automobile companies use Abaqus a lot, and there are a lot of cases and resources.

## 1. Preparation

First install the development environment and some necessary software:
```Bash
sudo apt update # Update software sources
sudo apt upgrade # Update locally installed software
sudo apt install build-essential # Installing the Development Environment
sudo apt install csh tcsh ksh gcc g++ gfortran libstdc++5 build-essential make libjpeg62 libmotif-dev
```

解压安装包：
```Bash
mkdir iso # Create a new iso folder to store the decompressed files
tar xvzf DS.SIMULIA.SUITE.2024.LINX64.tar.gz -C ./iso # Unzip to the iso folder
```

## 2. Installation process

### 2.1 Start the installation program

First, define the environment variables, otherwise the installation program cannot be started:
```Bash
# You can add the following content to ${HOME}/.bashrc and restart the terminal
export DSYAuthOS_`lsb_release -si`=1
export DSY_Force_OS=linux_a64
export NOLICENSECHECK=true
```

Enter the `/iso/1` folder and run the installer. Start the graphical interface and run `./StartGUI.sh` in the terminal. It is similar to the installation method under Windows. Just follow the wizard step by step.

Select the text interface here:
```Bash
./StartTUI.sh # Start the text interface installation wizard
```

![7222cbf4b6f8545b9766ce654edf28ba.png](./images/7222cbf4b6f8545b9766ce654edf28ba.png)
`Enter` to next step.

![32a37d1807765cbc529f11c58e35ea12.png](./images/32a37d1807765cbc529f11c58e35ea12.png)
Remember to select `4`, which means `FLEXnet License Server`. Type `4` and then `Enter` to continue.

![e29968284f99250e82746af3a935d704.png](./images/e29968284f99250e82746af3a935d704.png)
Confirm the installation content and press `Enter` to start the relevant installation program.

### 2.2 Installing the License Server

![2b46aa33180c36f27a537a1ab8418f3a.png](./images/2b46aa33180c36f27a537a1ab8418f3a.png)
Select `P` and enter the absolute path to the `/iso/4` folder.

![98b4844bd00955f5d423ca362fe2b553.png](./images/98b4844bd00955f5d423ca362fe2b553.png)
Select the installation path of the license server. Here, choose to install it in the path `${HOME}/opt/SIMULIA/License/2024`. Enter the absolute path.

![da9c6aa1f933df48fe6027e382c878d5.png](./images/da9c6aa1f933df48fe6027e382c878d5.png)
Select the default here and start the license server after installation.

![842cf6835291e50d2a108b92c793ae29.png](./images/842cf6835291e50d2a108b92c793ae29.png)
Select License File Path and enter the absolute path.

![0a7fcef173dc84dbae5cd0fd3561f1d0.png](./images/0a7fcef173dc84dbae5cd0fd3561f1d0.png)
After entering the license file, a message appears stating that retrieval of the host ID failed. Ignore it and enter `2` to continue.

![3cdf57da3ac4f813368bc21959fd50cc.png](./images/3cdf57da3ac4f813368bc21959fd50cc.png)
Continue to select `2`.

![37278e435bdf4ce57cc8753974ed4262.png](./images/37278e435bdf4ce57cc8753974ed4262.png)
Confirm the installation information.

![d98331d9aec49934746e4780dc8a570f.png](./images/d98331d9aec49934746e4780dc8a570f.png)
The installation is complete, press `Enter` to continue the next program installation.

### 2.3 Install the solver

![e63e9f0c584011800a215af5d2c128a7.png](./images/e63e9f0c584011800a215af5d2c128a7.png)
Select `P` and enter the absolute path to the `/iso/5` folder.

![9da9338bf17ca917eee54135eac4bd13.png](./images/9da9338bf17ca917eee54135eac4bd13.png)
Select the installation path. Here, choose to install it in the path `${HOME}/opt/SIMULIA/EstProducts/2024`.

![150907cf29102dc5b4bcda22e3f2af44.png](./images/150907cf29102dc5b4bcda22e3f2af44.png)
Select the content to be installed, select all and enter `-1`.

![618fa052254d576c29637eb792b63f5b.png](./images/618fa052254d576c29637eb792b63f5b.png)
Select the license type, the default is `1`.

![2525f16acab485199fb0107493718334.png](./images/2525f16acab485199fb0107493718334.png)
Enter the access address and port of the license server, enter `29100@localhost` to define `License Server 1`, and skip the rest by pressing `Enter`.

![5e3f75d3e4eb45d0651f815415cec836.png](./images/5e3f75d3e4eb45d0651f815415cec836.png)
Select the path of the command line program. Here, choose to install it to `${HOME}/opt/SIMULIA/var/DassaultSystemes/SIMULIA/Commands`.

![2dbc679c28801c1edcf17410e0541414.png](./images/2dbc679c28801c1edcf17410e0541414.png)
Select the path of the external plug-in. Here, choose to install it to `${HOME}/opt/SIMULIA/var/DassaultSystemes/SIMULIA/CAE/plugins/2024`.

![0ab546bf5c53e748044cb596a40aac68.png](./images/0ab546bf5c53e748044cb596a40aac68.png)
Select the `Tosca` interface according to actual needs.

![575d8708a07ed1bc9781af02aa739e58.png](./images/575d8708a07ed1bc9781af02aa739e58.png)
Select the `Tosca Fluid` working directory, which is assigned to `${HOME}/temp`.

![f9de5443a5f54c198a15d433cbcc459d.png](./images/f9de5443a5f54c198a15d433cbcc459d.png)
Select the STAR-CCM+ installation path, set it according to actual needs, and leave it blank by default.

![bfade401e6f700848f6166f118eb2204.png](./images/bfade401e6f700848f6166f118eb2204.png)
Select STAR-CCM+ license, set according to actual situation, leave blank by default.

![817069e8e89653272d962e4a6553940e.png](./images/817069e8e89653272d962e4a6553940e.png)
Select Fluent installation path, set according to actual situation, leave blank by default.

![4b87a12aa92cdc9ef67cb2596b331bc1.png](./images/4b87a12aa92cdc9ef67cb2596b331bc1.png)
Confirm the installation information and press `Enter` to start copying files.

![a48dc4111041562afdd9c43a3f853613.png](./images/a48dc4111041562afdd9c43a3f853613.png)
The verification program will be started during the installation process, and the verification results can be viewed. `Enter` to continue.

![192460b7772483522ff8ff97c5f47f61.png](./images/192460b7772483522ff8ff97c5f47f61.png)
The solver installation is complete, `Enter` to exit and enter the next installation program.

### 2.4 Install CAA API

![a1105475937fa8f0c85abdf177501160.png](./images/a1105475937fa8f0c85abdf177501160.png)
Select `P` and enter the absolute path of the `/iso/6` folder.

![fbe21029d223f693d9cdfd727ec588c4.png](./images/fbe21029d223f693d9cdfd727ec588c4.png)
Select the installation path. Here, choose to install to `${HOME}/opt/SIMULIA/EstProducts/2024`.

![098367e7a54310e3ceefee9c52659171.png](./images/098367e7a54310e3ceefee9c52659171.png)
Confirm the content to be installed, and press `Enter` to continue.

![2e23fd22aea12099636c0c53efb9b011.png](./images/2e23fd22aea12099636c0c53efb9b011.png)
The installation is complete, and press `Enter` to exit.

### 2.5 Install Isight

![58015ba8b4b0068cfcb447f20857939f.png](./images/58015ba8b4b0068cfcb447f20857939f.png)
Select the installation path. Here, choose to install to `${HOME}/opt/SIMULIA/Isight/2024`.

![48a30d42cac1ed6b1b91f2ce39040cce.png](./images/48a30d42cac1ed6b1b91f2ce39040cce.png)
Select the content to be installed. `-1` selects all.

![741fd85d5d3f278d9bb7f9bf6530c60a.png](./images/741fd85d5d3f278d9bb7f9bf6530c60a.png)
Whether to start the `TomEE` configuration tool, skip by default.

![bcda28276dc83f5ae970fcfa37300078.png](./images/bcda28276dc83f5ae970fcfa37300078.png)
This step is also skipped by default.

![b6652ff01997c5fa5e1375d92be835f3.png](./images/b6652ff01997c5fa5e1375d92be835f3.png)
There is no installation document, choose to skip it.

![952737d22e78e4dd5cbb2fddf27e9bc4.png](./images/952737d22e78e4dd5cbb2fddf27e9bc4.png)
Confirm the installation content and press `Enter` to start copying files.

![f27fe27fbc46bb915c1fe167d235753f.png](./images/f27fe27fbc46bb915c1fe167d235753f.png)
The installation is complete. Press `Enter` to exit.

### 2.6 Installation completed

![2f4f47eb05fb870bb885b5ccfb13a9aa.png](./images/2f4f47eb05fb870bb885b5ccfb13a9aa.png)
Confirm the installation result and press `Enter` to exit the SIMULIA installation program.

## 3. Post-installation configuration

### 3.1 Startup configuration

Before starting, modify the configuration file:
```Bash
vim ${HOME}/opt/SIMULIA/EstProducts/2024/linux_a64/SMA/site/custom_v6.env
```

Add two lines at the end, save and exit:
```Bash
license_server_type=FLEXNET
abaquslm_license_file="29100@localhost"
```

Create a new environment variable configuration file:
```Bash
touch ${HOME}/opt/SIMULIA/simulia24.env
chmod +x ${HOME}/opt/SIMULIA/simulia24.env
vim ${HOME}/opt/SIMULIA/simulia24.env
```

Edit the content as follows. It is best to use absolute paths, save and exit:
```Bash
export LICENSE_PREFIX_DIR=${HOME}/opt/SIMULIA/License/2024/linux_a64/code/bin
export SIMULIA_COMMAND_DIR=${HOME}/opt/SIMULIA/var/DassaultSystemes/SIMULIA/Commands
export PATH=$SIMULIA_COMMAND_DIR:$LICENSE_PREFIX_DIR:$PATH
export LM_LICENSE_FILE=29100@localhost
```

Run the following command to load the environment variables:
```Bash
source ${HOME}/opt/SIMULIA/simulia24.env
```

Start the Abaqus graphical interface by using the following command[^1]:
```Bash
abaqus cae -mesa
abaqus view -mesa
```

### 3.2 License installation problem

If Abaqus can be started normally in [3.1](#31-Startup configuration), then this step can be skipped.

Verify whether the license server is running:
```Bash
ps -eaf | grep ABAQUSLM
```

If the license server is not running, start the license server with the following command:
```Bash
${HOME}/opt/SIMULIA/License/2024/linux_a64/code/bin/licenseStartup.sh
```

The startup failed, and the error message is as follows:
```Bash
/home/***/opt/SIMULIA/License/2024/linux_a64/code/bin/licenseStartup.sh: 2: /home/***/opt/SIMULIA/License/2024/linux_a64/code/bin/lmgrd: not found
```

There is no solution. Either there is a problem with the installation package or this distribution lacks some runtime libraries. Let's wait for the experts to help.

Fortunately, the Windows version license can be installed normally. You only need to assign the license path to the Windows machine. First, open port 29100 in Windows Firewall and create a new firewall inbound rule:
![33aec1f9e7b7132dc0d6143a9d9d25fe.png](./images/33aec1f9e7b7132dc0d6143a9d9d25fe.png)

Then modify the license address of the `custom_v6.env` file in [3.1](#31-Startup Configuration) as follows:
```Bash
license_server_type=FLEXNET
# abaquslm_license_file="29100@localhost"
abaquslm_license_file="29100@172.25.64.1" # 172.25.64.1 is the IP address of the Windows host
```

Modify the environment variable file `${HOME}/opt/SIMULIA/simulia24.env`:
```Bash
# export LM_LICENSE_FILE=29100@localhost
export LM_LICENSE_FILE=29100@172.25.64.1
```

After loading the environment variables, the `abaqus cae` command can be started normally, and the license issue will no longer be prompted.
![Screenshot 2025-03-21 15-16-50.png](./images/2025-03-21-15-16-50.png)

I have to admit that the Linux graphical interface is really not easy to use, but who cares? Anyway, I don't need to process models or grids under Linux, and I just submit calculations.

### 3.3 Submit cluster calculation

The Slurm script of Abaqus[^2] is as follows:
```Bash
#!/bin/bash 

#SBATCH --job-name=abaqus_test
#SBATCH --partition=debug 
#SBATCH --output=%j.out 
#SBATCH --error=%j.err 
#SBATCH -N 1 
#SBATCH --ntasks-per-node=32 

cd $SLURM_SUBMIT_DIR

source /home/***/opt/SIMULIA/simulia24.env # Fill in the absolute path
export INPFILE=`find . -name "*.inp"`
export ENVFILE=/home/***/opt/SIMULIA/EstProducts/2024/linux_a64/SMA/site/abaqus_v6.env # Fill in the absolute path

# Generate abaqus_6.env file and specify hosts
rm -rf $PWD/abaqus_v6.env
cp $ENVFILE $PWD/abaqus_v6.env
node_list=$(scontrol show hostname ${SLURM_NODELIST} | sort -u)
mp_host_list="["
for host in ${node_list}; do
    mp_host_list="${mp_host_list}['$host', ${SLURM_NTASKS_PER_NODE}],"
done
mp_host_list=$(echo ${mp_host_list} | sed -e "s/,$/]/")
echo "mp_host_list=${mp_host_list}"  >> $PWD/abaqus_v6.env

# Create a Scratch Directory
mkdir scratch.$SLURM_JOB_ID

abaqus job=$SLURM_JOB_NAME input=$INPFILE cpus=$SLURM_NPROCS scratch=scratch.$SLURM_JOB_ID mp_mode=mpi double=both output_precision=full resultsformat=odb int ask=off > $SLURM_JOB_NAME.log
rm -rf $PWD/abaqus_v6.env scratch.$SLURM_JOB_ID

```

Put the `inp` file and the script in the same folder and submit the script using the `sbatch` command. After the calculation is completed, download the results to your local computer and view the results using `Abaqus Viewer` or `Meta`.

[^1]: [franaudo/abaqus-ubuntu ](https://github.com/franaudo/abaqus-ubuntu)

[^2]: [abhpc/ABHPC-Guide ](https://github.com/abhpc/ABHPC-Guide/tree/master)


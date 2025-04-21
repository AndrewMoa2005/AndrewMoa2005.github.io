+++
author = "Andrew Moa"
title = "Compile and install OpenFOAM and parallelize PBS under ArchLinux"
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

## 1. Download source 

### 1.1 Download OpenFOAM source

Create a new OpenFOAM directory under the `${HOME}`:

```bash
cd ${HOME}
mkdir OpenFOAM && cd OpenFOAM
```

Download the source of OpenFOAM and ThirdParty from GitHub and put it in the `${HOME}/OpenFOAM`:

```bash
git clone https://github.com/OpenFOAM/OpenFOAM-dev --depth=1
git clone https://github.com/OpenFOAM/ThirdParty-dev --depth=1
```

### 1.2 Download Torque (PBS) source

Here we use Torque from AUR. CentOS, Debian and SUSE operating systems can download ready-made binary packages from OpenPBS on Github. If you use OpenPBS or PBS Pro, please skip Section 3 of this article and refer to other documents to configure PBS.

Download Torque(PBS) source from AUR:

```bash
git clone https://aur.archlinux.org/torque.git
cd torque
wget http://wpfilebase.s3.amazonaws.com/torque/torque-6.1.1.1.tar.gz
```

## 2. Compile and install OpenFOAM

### 2.1 Setting Environment Variables

Edit the `${HOME}/.bashrc` file and add the following two lines:

```bash
#OpenFOAM
source ${HOME}/OpenFOAM/OpenFOAM-dev/etc/bashrc WM_MPLIB=OPENMPI
```

The `WM_MPLIB=OPENMPI` at the end means to use the recompiled OpenMPI library.

Update the environment variables:

```bash
source ${HOME}/.bashrc
```

Verify that the environment variables are correct:

```bash
echo $WM_PROJECT_DIR
echo $WM_THIRD_PARTY_DIR
```

If the OpenFOAM compilation directory can be output correctly, it means that the environment variables are set correctly.

### 2.2 Compile third-party libraries

Enter the `ThirdParty-dev` directory and compile the third-party library:

```bash
cd $WM_THIRD_PARTY_DIR
wget https://download.open-mpi.org/release/open-mpi/v2.1/openmpi-2.1.1.tar.gz
tar -xvzf openmpi-2.1.1.tar.gz
./Allwmake
```

Since `WM_MPLIB=OPENMPI` is specified above, you need to manually download the OpenMPI source code file here. Use `wget` to download the OpenMPI source code package and decompress it. You can add the `-jN` option after `Allwmake` to enable multi-core parallel compilation. Here, `N` should be replaced with the number of cores. `Allwmake` will automatically compile OpenMPI.

```bash
which mpirun
>${WM_THIRD_PARTY_DIR}/platforms/linux64Gcc/openmpi-2.1.1/bin/mpirun
which mpicc
>${WM_THIRD_PARTY_DIR}/platforms/linux64Gcc/openmpi-2.1.1/bin/mpicc
```

### 2.3 Compiling ParaView

Continue compiling ParaView in the `ThirdParty-dev` directory:

```bash
cd $WM_THIRD_PARTY_DIR
./makeParaView -mpi
wmRefresh
```

After compiling, run `wmRefresh` to refresh the environment variables.

### 2.4 Compiling OpenFOAM

Change to the `OpenFOAM-dev` directory and compile OpenFOAM:

```bash
cd $WM_PROJECT_DIR
./Allwmake -jN
```

OpenFOAM takes a long time to compile, so it is recommended to enable multi-core parallel compilation. Here `N` should be replaced with the number of cores.

### 2.5 Test

Execute the following command to copy the `cavity` folder from the instance file that comes with OpenFOAM to the current path:

```bash
mkdir $FOAM_RUN && cd $FOAM_RUN
cp -r $FOAM_TUTORIALS/incompressible/simpleFoam/pitzDaily .
cd pitzDaily
```

Generate mesh:

```bash
blockMesh
```

Calculation:

```bash
simpleFoam | tee simpleFoam.log
```

Launch ParaView for post-processing:

```bash
paraFoam
```

### 2.6 Update

Use the `git` command to update the source code files in the `OpenFOAM-dev` and `ThirdParty-dev` directories, and then recompile and install:

```bash
git pull
wcleanPlatform
./Allwmake -jN
```

## 3. Compile and install Torque (PBS)

### 3.1 Install Torque

Enter the `torque` directory:

```bash
cd ${HOME}/OpenFOAM/torque
```

Compile Torque:

```bash
makepkg
```

Install Torque：

```bash
sudo pacman -U torque-6.1.1.1-2-x86_64.pkg.tar.zst
```

Start the service (`pbs_mom.service` and `pbs_sched.service` are in the `src/torque-6.1.1.1/contrib/systemd` directory of the source code and need to be copied manually):

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

### 3.2 Server Configuration

Refer to [archlinux wiki](https://wiki.archlinux.org/index.php/TORQUE) to complete Torque configuration.

Edit the `/etc/hosts` file (example) and add the server node and compute node IP addresses:

```bash
192.168.100.101    master
#192.168.100.102    cluster01
#192.168.100.103    cluster02
```

Change the hostname in the `/var/spool/torque/server_name` file to the server node hostname:

```bash
master
```

Execute the following command and select Y to create a new server-side configuration file (only run once, the prompt will overwrite the existing configuration file):


```bash
sudo pbs_server -t create
```

Execute the following command to run the server daemon process:

```bash
sudo trqauthd
```

Initialize default settings:

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

Verify setting:

```bash
qmgr -c 'p s'
```

Edit the file /var/spool/torque/server_priv/nodes and add a compute node (a server can also be a compute node). The format is HOSTNAME np=x gpus=y:

```bash
master np=8 gpus=1
```

### 3.3 Computional node settings

Edit the `/var/spool/torque/mom_priv/config` file and add the following information:

```bash
pbsserver    master    # Server host name, consistent with nodes
logevent    255    # Number of logging events
```

Generate and register the key file to ensure smooth SSH access between hosts:

```bash
cd $HOME/.ssh
ssh-keygen -t rsa
cp id_rsa.pub authorized_keys
```

### 3.4 Restart the server process

Run the following command on the server to restart the server process.

```bash
sudo killall -s 9 pbs_server
sudo pbs_server
```

### 3.5 Start the computional node process

Execute the following command to start the compute node process:

```bash
sudo pbs_mom
```

Execute the following command to display the status of the compute node:

```bash
pbsnodes -a
```

The following information (example) is output, indicating that the configuration is successful:

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

If the node `state` is displayed as `down`, it means that the node is unavailable. You can use the following command to force the node to be released:

```bash
sudo qmgr -a -c 'set node master state=free'
```

We can write a systemd service script to automatically release the node. The script content is as follows, save it as `/usr/lib/systemd/system/pbs_autofree.service` file:

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

Start the service:

```bash
sudo systemctl enable pbs_autofree
sudo systemctl start pbs_autofree
```

Turn off services to save resources:

```bash
sudo systemctl disable pbs_autofree
sudo systemctl stop pbs_autofree
```

## 4. Parallelization of OpenFOAM job submission

### 4.1 Preparing the case

Execute the following command to copy the `cavity` folder from the instance file that comes with OpenFOAM to the current path:

```bash
cd $FOAM_RUN
mkdir cluster && cd cluster
cp -r $FOAM_TUTORIALS/incompressible/simpleFoam/pitzDaily .
cd pitzDaily
```

Create a new file called decomposeParDict in the system directory to partition the grid and prepare for parallelization. The file content is as follows, and the number of grid partitions is 2:

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

### 4.2 Submitting jobs

Create a new script file named `pitzDaily.pbs` to submit parallel jobs. The file content is as follows, using 1 node, 2 CPU cores per node for calculation (`nodes=1:ppn=2`), 2 threads (`mpirun -np 2`), which should be consistent with the number of grid partitions in the `decomposeParDict` file:

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

Submitting a job using qsub:

```bash
chmod 755 pitzDaily.pbs
qsub pitzDaily.pbs
```

Check the job status using qstat:

```bash
qstat -a
```

After the calculation is completed, download the `pitzDaily_results.tar.xz` file and unzip it, and start ParaView for post-processing:

```bash
paraFoam
```


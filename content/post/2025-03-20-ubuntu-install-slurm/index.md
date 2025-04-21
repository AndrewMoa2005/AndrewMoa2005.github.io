+++
author = "Andrew Moa"
title = "Ubuntu Install Slurm"
date = "2025-03-20"
description = ""
tags = [
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

Slurm, like PBS and LSF, is a commonly used task management system for supercomputers. The advantages of Slurm are that it is open source, free, and highly active. In recent years, almost all emerging supercomputer platforms in China have provided Slurm as the main task management system. After PBS was open sourced, its activity was pitifully low. After updating to the latest system, there were always problems with installation, and no response was received for the issues raised. LSF has copyright risks and is not widely used in China. It is a very rare type. As for commands and scripts, these three are similar. Once you learn one, you can easily learn the other.

It is still very simple to install Slurm on Ubuntu. The important tools are basically compiled. You can directly install it with apt, and other dependencies will be automatically installed:
```Bash
sudo apt install slurmd	# Install the compute node daemon
sudo apt install slurmctld # Install the management node daemon
```

Slurm requires a dedicated user for communication and other operations. The default username of this user is `slurm`. The above command has actually automatically generated the `slurm` user in Ubuntu, which can be verified by the following command:
```Bash
lastlog | grep slurm
```

If Ubuntu does not generate the `slurm` user, you can generate it with the following command:
```Bash
sudo useradd slurm
```

Slurm configuration files are mainly in the `/etc/slurm/` directory, the main configuration file is: `/etc/slurm/slurm.conf`, we need to generate the configuration file. The official tool to assist in generating the configuration file is provided: [Slurm Configuration Tool](https://slurm.schedmd.com/configurator.html) .

According to the web page content prompts, fill in some key parts of the configuration file:
```Bash
ClusterName=Cluster # Cluster name, any combination of English and numbers

SlurmctldHost=dell-vm # Management node, fill in the name of the machine here

NodeName=dell-vm # Compute node, also fill in the name of the machine
PartitionName=debug # The partition where the compute node is located. The default value is debug.
CPUs=32 # The number of CPU cores of the computing node should be filled in according to the actual situation.
Sockets=1 # Number of CPU slots, fill in according to actual situation
CoresPerSocket＝32 # The number of cores per socket should be filled in according to the actual situation.
ThreadsPerCore=1 # The recommended number of threads per core is 1. It is not recommended to enable hyperthreading.

SlurmUser=slurm # The default user is slurm. It is not recommended to change to root user.

StateSaveLocation=/var/spool/slurmctld # The storage folder of the management node daemon process, the default is OK
SlurmdSpoolDir=/var/spool/slurmd # The storage folder of the computing point daemon process, the default is OK
```
For more explanation, please refer to the information on the USTC website. <sup>(1)

After completing the web page content, click `Submit` at the bottom, copy the displayed configuration file template, and save it to the `/etc/slurm/slurm.conf` file:
```Bash
sudo vim /etc/slurm/slurm.conf	# Copy and paste into this file
```

Create a read-write folder for the daemon:
```Bash
sudo mkdir /var/spool/slurmd # Ubuntu prompts that the folder already exists, ignore it
sudo mkdir /var/spool/slurmctld
```

Start the Slurm service:
```Bash
sudo systemctl enable slurmd
sudo systemctl enable slurmctld
sudo systemctl start slurmd
sudo systemctl start slurmctld
```

Check the startup status of the Slurm daemon:
```Bash
sudo systemctl status slurmd
sudo systemctl status slurmctld
```

The `slurmd` daemon process started successfully, but the `slurmctld` daemon process started with an error. The error information is as follows:
```text
(null): _log_init: Unable to open logfile `/var/log/slurmctld.log': Permission denied
slurmctld: fatal: Incorrect permissions on state save loc: /var/spool/slurmctld
```

To solve this problem, the easiest way is to change `SlurmUser` to `root`. Here is another method:
```Bash
sudo touch /var/log/slurmctld.log # Create a log file for the slurmctld daemon
sudo chown slurm /var/log/slurmctld.log # Change the log file owner to the slurm user
sudo chown -R slurm /var/spool/slurmctld # Change the owner of the slurmctld daemon read-write folder to the slurm user
```

Just restart the `slurmctld` service:
```Bash
sudo systemctl restart slurmctld
```

For Slurm scripts and command lines, domestic users can refer to the user manual written by Jiaotong University, which is quite comprehensive and will not be listed here. <sup>(2)

The following are some commonly used Slurm commands:

- The configuration of the current node can be obtained by the following command:
  ```Bash
  slurmd -C
  ```

- View the node status of the current cluster:
  ```Bash
  sinfo -N
  ```

- View the specified node information:
  ```Bash
  scontrol show node dell-vm # dell-vm is the name of the compute node
  ```

- View the job information submitted by the current user, usually only the queued and running jobs are displayed:
  ```Bash
  squeue
  ```

- Submit a job:
  ```Bash
  sbatch jobscript.slurm # jobscript.slurm is a calculation script written by the user, and the suffix can be omitted
  ```

- To view and modify job status:
  ```Bash
  scontrol show job ${JOB_ID} # View the information of the specified job. ${JOB_ID} corresponds to the job number in the first column displayed by squeue.
  scontrol hold ${JOB_ID} # Pause ${JOB_ID}
  scontrol release ${JOB_ID} # Resume ${JOB_ID}
  ```

- Cancel a specific job:
  ```Bash
  scancel ${JOB_ID} # 取消${JOB_ID}
  ```

---

<sup>(1) [Slurm资源管理与作业调度系统安装配置](https://scc.ustc.edu.cn/hmli/doc/linux/slurm-install/slurm-install.html#id17)

<sup>(2) [Slurm 作业调度系统](https://docs.hpc.sjtu.edu.cn/job/slurm.html)

+++
author = "Andrew Moa"
title = "Ubuntu compile and install SU2"
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

[SU2](https://su2code.github.io/) is an open source CFD solver developed by the School of Aeronautics and Astronautics at Stanford University. It is based on C++ and Python and is similar to OpenFOAM, but does not support polyhedral meshes. Compared with OpenFOAM, SU2 has more advantages in solving high-speed compressible flows.

Download SU2 source code:
```Bash
mkdir $HOME/su2code && cd $HOME/su2code
# Only clone the latest commit version to speed up downloading
git clone https://github.com/su2code/SU2.git --depth=1
```

Define environment variables and create a new configuration file `su2.env`:
```Bash
touch $HOME/su2code/su2.env
chmod +x $HOME/su2code/su2.env
vim $HOME/su2code/su2.env
```

Add the following content to the `su2.env` file, save and exit:
```Bash
#!/bin/sh

# Define SU2 environment variables
export SU2_RUN=$HOME/su2code/bin # su2 installation path after compilation
export SU2_HOME=$HOME/su2code/SU2 # su2 source code folder path
export PATH=$PATH:$SU2_RUN
export PYTHONPATH=$SU2_RUN:$PYTHONPATH
```

The compiler configuration file `meson_options.txt` is located in the SU2 source code folder. Adjust the compilation options according to your needs:
```Bash
vim $HOME/su2code/SU2/meson_options.txt
```

Here, enable mpi and blas support and modify the values ​​of the following two lines:
```Python
option('with-mpi',   type : 'feature', value : 'enabled', description: 'enable MPI support')
option('enable-openblas', type : 'boolean', value : true, description: 'enable BLAS and LAPACK support via OpenBLAS')
```
If it is an Intel machine, it is recommended to enable mkl support.

The default supported blas library is openblas. You need to download the openblas library first:
```Bash
sudo apt install libopenblas-dev -y
```

Enter the downloaded source code directory and run the compiler
```Bash
# Load environment variables
source $HOME/su2code/su2.env
# Enter the source code folder
cd $SU2_HOME
# Configure the compiler and generate ninja build files
# The configuration process will automatically download external dependencies from git
# It takes a lot of time...
./meson.py build --prefix=$SU2_RUN/..
# Start compiling and installing
./ninja -C build install
```

Verify that the installation was successful:
```Bash
SU2_CFD --help
```
If the installation is successful, the software version number and help information will be output.

Write the slurm calculation script for SU2:
```Bash
#!/bin/bash 

#SBATCH --job-name=su2_test
#SBATCH --partition=debug 
#SBATCH --output=%j.out 
#SBATCH --error=%j.err 
#SBATCH -N 1 
#SBATCH --ntasks-per-node=32 

cd $SLURM_SUBMIT_DIR

source ${HOME}/su2code/su2.env # The absolute path should be filled in
export CFG_FILE=`find . -name "*.cfg"`
export MACHINEFILE=$SLURM_JOBID.nodes 
scontrol show hostnames $SLURM_JOB_NODELIST > $MACHINEFILE 

mpiexec -np $SLURM_NPROCS --machinefile $MACHINEFILE SU2_CFD $CFG_FILE

```
Put the script file, SU2's cfg file and mesh into the same folder, and submit the calculation task through the `sbatch` command.

---

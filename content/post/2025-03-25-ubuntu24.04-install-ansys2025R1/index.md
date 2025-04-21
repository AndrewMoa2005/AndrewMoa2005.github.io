+++
author = "Andrew Moa"
title = "Install Ansys2025R1 on Ubuntu24.04"
date = "2025-03-25"
description = ""
tags = [
    "ansys",
    "cae",
    "linux",
    "ubuntu",
]
categories = [
    "linux",
]
series = [""]
aliases = [""]
image = "/images/ubuntu-bg.jpg"
+++

## 1. Preparation

161GB of disk space is required for the full installation. Please ensure that the remaining available disk space meets the requirements. You can choose the installation content according to your needs.
![e8b6a55779447694ef28a8a9560f2bab.png](./images/e8b6a55779447694ef28a8a9560f2bab.png)
![3f912a7795844465627dc878eb409e95.png](./images/3f912a7795844465627dc878eb409e95.png)
At least 8GB of memory is required during the installation process, and 16~32GB of memory is recommended.

Dependent tools during the installation process:
```Bash
sudo apt install libnsl2 libpcre3 lsb-* ldap-utils libunistring5 xfonts-100dpi xfonts-75dpi
```

For installation of other runtime dependent tools, please refer to the official documentation.

The Ansys2025R1 installation file contains 9 `.iso` installation files. Use the following command to mount the `.iso` file to the specified path:
```Bash
mkdir ${HOME}/ISO/1
sudo mount ${HOME}/Share/Ansys/ANSYS2025R1_LINX64_DISK1.iso ${HOME}/ISO/1 -o loop
```
In the same way, mount the remaining installation packages to other folders.

## 2. Install the license server

### 2.1 Install Ansys License Manager

Since Ansys installation requires a graphical interface, you need to first access the Ubuntu desktop system through a remote connection.

Enter the mount point of the first installation package and run the installer:
```Bash
cd ${HOME}/ISO/1
sudo ./INSTALL # Since it needs to be run as a service, it is recommended to run the installer with administrator user privileges
```

![598ba0142449e130e1d6680aef25e2db.png](./images/598ba0142449e130e1d6680aef25e2db.png)

License installation path selection: `/opt/ansys_inc`:
![5a06611a2b8026902f761f7ff6953b86.png](./images/5a06611a2b8026902f761f7ff6953b86.png)
After the installation is complete, exit the installer.

Verify that the Ansys License Server daemon is running:
```Bash
ps -eaf | grep ansyslmd
```

If the ansyslmd process is running, kill it:
```Bash
kill -s 9 [PID] # [PID] Fill in the PID of the ansyslmd process
```

### 2.2 Configure the license server

We need to unzip the files in the `/shared_files` folder in the `ansys.2025r1.linx64-ssq.tar.gz` compressed package to the installation directory and overwrite:
```Bash
tar xvzf ansys.2025r1.linx64-ssq.tar.gz
sudo cp -r shared_files /opt/ansys_inc/
```

Next, configure the license service. The following command runs the license configuration program:
```Bash
sudo /opt/ansys_inc/shared_files/licensing/init_ansyslm_tomcat start
```

Then use the browser to open the address: `http://localhost:1084/ANSYSLMCenter.html`, locate the `Get System Hostid information` column, find `HOSTID`, copy it and use it later:
![a52950f2db9ae12884303cbf17f8bdc2.png](./images/a52950f2db9ae12884303cbf17f8bdc2.png)

Open the `license_2024.12.15.txt` file, replace `XXXXXXXXXXXX` with the `HOSTID` copied above in the line `SERVER localhost XXXXXXXXXXXX 1055` at the beginning, and save the file.
![98784654bd0673c67c268b30c410841d.png](./images/98784654bd0673c67c268b30c410841d.png)

Locate the `Add a License File` column and load the `license_2024.12.15.txt` file that you just edited.
![8b20a3edf84fd2d7ed3014bb482ebaa3.png](./images/8b20a3edf84fd2d7ed3014bb482ebaa3.png)

There is a problem here, prompting that `lmgrd` cannot be found and the server daemon cannot be started. Run the following command:
```Bash
sudo cp /opt/ansys_inc/shared_files/licensing/linx64/update/lmgrd /opt/ansys_inc/shared_files/licensing/linx64/lmgrd
```

Just load the file again:
![3d393bbce991d531ef2829ec57b3f0d2.png](./images/3d393bbce991d531ef2829ec57b3f0d2.png)

Locate the `View Status/Start/Stop License Manager` column and confirm the server running status:
![fc01fe3a22a3f809c25540c512c61df0.png](./images/fc01fe3a22a3f809c25540c512c61df0.png)

Exit the browser and close the license configuration program, and confirm whether the daemon is running:
```Bash
sudo /opt/ansys_inc/shared_files/licensing/init_ansyslm_tomcat stop
ps -eaf | grep ansyslmd
```
![edac3b8a6905bbabd6bbe9ab46101f0f.png](./images/edac3b8a6905bbabd6bbe9ab46101f0f.png)

If the license server and the main program are installed on different machines, you need to open port 1055 of the license server in the firewall:
```Bash
sudo ufw allow from any to any port 1055 proto tcp
```

### 2.3 Add custom service

After completing the above settings, when the server is restarted, the system will not automatically start the daemon process. You need to start ansyslmd with the following command:
```Bash
sudo /opt/ansys_inc/shared_files/licensing/start_ansyslmd
```

In order to prevent the server from being unable to calculate due to license issues after power failure and restart, the following custom service is added through systemd to realize the automatic start of the daemon process at startup. The following command creates a new ansyslmd service:
```Bash
sudo touch /usr/lib/systemd/system/ansyslmd.service
sudo vim /usr/lib/systemd/system/ansyslmd.service
sudo chmod 754 /usr/lib/systemd/system/ansyslmd.service
```

Add the following content and save and exit:
```systemd
[Unit]
Description=Ansys License Deamon
After=ansyslmd.service
  
[Service]
Type=forking
User=root
Group=root
ExecStart=/opt/ansys_inc/shared_files/licensing/start_ansyslmd
ExecReload=
ExecStop=/opt/ansys_inc/shared_files/licensing/stop_ansyslmd
  
[Install]
WantedBy=multi-user.target
```

Start the service with the following command:
```Bash
sudo systemctl enable ansyslmd
sudo systemctl start ansyslmd
```

Check the service status:
```Bash
sudo systemctl status ansyslmd
```

![936bafa551b8e5f366e60560bc7a3cb1.png](./images/936bafa551b8e5f366e60560bc7a3cb1.png)
The service is started successfully. After the installation is complete, you can restart it to verify.

## 3. Install the main program

You also need to enter the Ubuntu desktop system to install the main program.

Enter the mount point of the first installation package and run the installation program:
```Bash
cd ${HOME}/ISO/1
sudo ./INSTALL # Install with root privileges
```

![6933ca38adf2f53214ee6da37be02675.png](./images/6933ca38adf2f53214ee6da37be02675.png)

Solve the same choice to install in: `/opt/ansys_inc`
![93a9af6a6829b4c21c211ed56a9089a2.png](./images/93a9af6a6829b4c21c211ed56a9089a2.png)

Choose what to install according to your needs:
![921717f 7b3c0f69710ca2d0de4f8a702.png](./images/921717f7b3c0f69710ca2d0de4f8a702.png)

Configure CAD geometry interface. CAD software is not installed on this machine. Select Skip:
![3905fc228e5b13ede8a3389f6997b76f.png](./images/3905fc228e5b13ede8a3389f6997b76f.png)

Depending on the installation content selected earlier, a bunch of configuration file paths will be asked later. Set them according to your needs. If there is no such a thing, just click Next.
![1ae7bc0a6a670019f24a6b43a6a45e7b.png](./images/1ae7bc0a6a670019f24a6b43a6a45e7b.png)

Choose whether to create a desktop shortcut. Select it. It may be useful.
![40ec3516e05c8562ad9e52ed6703e3ef.png](./images/40ec3516e05c8562ad9e52ed6703e3ef.png)

Confirm the installation content and click Next to start copying files:
![bdaa34603562269aeb94f1634682c3e5.png](./images/bdaa34603562269aeb94f1634682c3e5.png)

You can check the installation progress. During the installation, you will be asked to load other `.iso` file mount paths.
![6e6129bc46d805ef3d32b5269fdddbf0.png](./images/6e6129bc46d805ef3d32b5269fdddbf0.png)

The installation is complete, and there are some errors. Ignore it and exit.
![8329e891f49681100884f8cd734a3685.png](./images/8329e891f49681100884f8cd734a3685.png)

Next, unzip the files in the `v251` folder in the `ansys.2025r1.linx64-ssq.tar.gz` compressed package to the installation directory and overwrite:
```Bash
tar xvzf ansys.2025r1.linx64-ssq.tar.gz
sudo cp -r v251 /opt/ansys_inc/
```

After the main program is installed, unmount the mount point of the `.iso` file:
```Bash
sudo umount ${HOME}/ISO/1
```
Unmount the remaining mount points in the same way.

## 4. Configure the main program license

After installing the main program, you need to configure the license for the main program. There are two ways.

### 4.1 Method 1 → Configure environment variables

Create and edit the environment variable file in `${HOME}/opt/`:
```Bash
touch ${HOME}/opt/ansys2025r1.env
chmod +x ${HOME}/opt/ansys2025r1.env
vim ${HOME}/opt/ansys2025r1.env
```

Add the following content, save and exit:
```Bash
export ANSYSLMD_LICENSE_FILE=1055@localhost
```

You can load the environment variables with the following command later.
```Bash
source ${HOME}/opt/ansys2025r1.env
```
You can add the above command line to the `${HOME}/.bashrc` file, so that the environment variables will be automatically loaded every time you log in.

### 4.2 Method 2→Ansys Licensing Settings

Run the following command to start the `Licensing Settings` program:
```Bash
/ansys_inc/v251/licensingclient/linx64/LicensingSettings
```

Follow the steps to set the following:
 1. Change the configuration file level from Installion to User
 2. Set the status to Enable
 3. Fill in 1055 for the port number
 4. Fill in localhost for the Server1 address
 5. Click the Test button to test
 6. Click Save to save the configuration

![4a20e58eeea7df3348c81b7cd2b1dd5c.png](./images/4a20e58eeea7df3348c81b7cd2b1dd5c.png)
Save and exit to complete the license configuration.

## 5. Start the main program

After configuring the license, start `Workbench` with the following command:
```Bash
/ansys_inc/v251/Framework/bin/Linux64/runwb2
```

![3294556c73209acc5799dc0203469459.png](./images/3294556c73209acc5799dc0203469459.png)

Similarly, the entry points of some key main programs are as follows:
| Application | How to Launch |
| ----- | ----- |
| ACP | /ansys_inc/v251/ACP/ACP.sh |
| CFD-Post | /ansys_inc/v251/cfdpost |
| CFX | /ansys_inc/v251/CFX/bin/cfx5<sup>(Note)  |
| FLUENT | /ansys_inc/v251/fluent/bin/fluent |
| ICEM CFD | /ansys_inc/v251/icemcfd/icemcfd |
| ICEPAK | /ansys_inc/v251/icepak/icepak |
| Motion | /ansys_inc/v251/Motion/solver/rundfs.sh |
| Polyflow Classic | /ansys_inc/v251/polyflow/bin/polyflow |
| TurboGrid | /ansys_inc/v251/TurboGrid/bin/cfxtg |
| Sherlock | /ansys_inc/v251/sherlock/runSherlock |
| Workbench | /ansys_inc/v251/Framework/bin/Linux64/runwb2 |
| Electronics | /ansys_inc/v251/AnsysEM/ansysedt |

<sup>(Note): cfx5 can be replaced by cfx5launch, cfx5pre, cfx5solve or cfx5post. They correspond to different functional modules.

At this point, Ansys is installed.

---

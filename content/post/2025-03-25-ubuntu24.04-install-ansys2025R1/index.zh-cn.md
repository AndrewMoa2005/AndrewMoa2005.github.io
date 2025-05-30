+++
author = "Andrew Moa"
title = "Ubuntu24.04安装Ansys2025R1"
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

## 1. 准备工作

全部安装需要161GB磁盘空间，请确保磁盘剩余可用空间满足需求，可以根据自己需求选择安装内容。
![e8b6a55779447694ef28a8a9560f2bab.png](./images/e8b6a55779447694ef28a8a9560f2bab.png)
![3f912a7795844465627dc878eb409e95.png](./images/3f912a7795844465627dc878eb409e95.png)
安装过程中至少需要8GB内存，推荐内存16~32GB。

安装过程中的依赖工具：
```Bash
sudo apt install libnsl2 libpcre3 lsb-* ldap-utils libunistring5 xfonts-100dpi xfonts-75dpi
```

其他运行时的依赖工具安装，请查询官方文档。

Ansys2025R1安装文件中包含9个`.iso`安装文件，用以下命令挂载`.iso`文件到指定路径：
```Bash
mkdir ${HOME}/ISO/1
sudo mount ${HOME}/Share/Ansys/ANSYS2025R1_LINX64_DISK1.iso ${HOME}/ISO/1 -o loop
```
同样的办法，将剩下的安装包分别挂载至其他文件夹。

## 2. 安装许可证服务器

### 2.1 安装Ansys License Manager

由于Ansys安装需要用到图形界面，因此需要先通过远程连接进入Ubuntu桌面系统。

进入第一个安装包的挂载点，运行安装程序：
```Bash
cd ${HOME}/ISO/1
sudo ./INSTALL # 由于需要以服务形式运行，建议以管理员用户权限运行安装程序
```

![598ba0142449e130e1d6680aef25e2db.png](./images/598ba0142449e130e1d6680aef25e2db.png)

许可证安装路径选择：`/opt/ansys_inc`：
![5a06611a2b8026902f761f7ff6953b86.png](./images/5a06611a2b8026902f761f7ff6953b86.png)
安装完成后退出安装程序。

确认Ansys许可证服务器的守护进程是否在运行：
```Bash
ps -eaf | grep ansyslmd
```

如果ansyslmd进程在运行，kill掉它：
```Bash
kill -s 9 [PID] # [PID]填写ansyslmd进程的PID
```

### 2.2 配置许可证服务器

我们需要将`ansys.2025r1.linx64-ssq.tar.gz`压缩包中的`/shared_files`文件夹下的文件解压到安装目录下并覆盖：
```Bash
tar xvzf ansys.2025r1.linx64-ssq.tar.gz
sudo cp -r shared_files /opt/ansys_inc/
```

接下来配置许可证服务，以下命令运行许可证配置程序：
```Bash
sudo /opt/ansys_inc/shared_files/licensing/init_ansyslm_tomcat start
```

然后用浏览器打开该地址：`http://localhost:1084/ANSYSLMCenter.html`，定位到`Get System Hostid information`栏目，找到`HOSTID`，把它复制下来后面会用到：
![a52950f2db9ae12884303cbf17f8bdc2.png](./images/a52950f2db9ae12884303cbf17f8bdc2.png)

打开`license_2024.12.15.txt`文件，在开头的`SERVER localhost XXXXXXXXXXXX 1055`这一行中将`XXXXXXXXXXXX`替换为上面复制下来的`HOSTID`，保存文件。
![98784654bd0673c67c268b30c410841d.png](./images/98784654bd0673c67c268b30c410841d.png)

定位到`Add a License File`栏目，载入刚刚编辑过的`license_2024.12.15.txt`文件。
![8b20a3edf84fd2d7ed3014bb482ebaa3.png](./images/8b20a3edf84fd2d7ed3014bb482ebaa3.png)

这里出现了一个问题，提示`lmgrd`找不到，无法启动服务器守护进程，运行以下命令：
```Bash
sudo cp /opt/ansys_inc/shared_files/licensing/linx64/update/lmgrd /opt/ansys_inc/shared_files/licensing/linx64/lmgrd
```

再次载入文件即可：
![3d393bbce991d531ef2829ec57b3f0d2.png](./images/3d393bbce991d531ef2829ec57b3f0d2.png)

定位到`View Status/Start/Stop License Manager`栏目，确认服务器运行状态：
![fc01fe3a22a3f809c25540c512c61df0.png](./images/fc01fe3a22a3f809c25540c512c61df0.png)

退出浏览器并关闭许可证配置程序，确认守护进程是否在运行：
```Bash
sudo /opt/ansys_inc/shared_files/licensing/init_ansyslm_tomcat stop
ps -eaf | grep ansyslmd
```
![edac3b8a6905bbabd6bbe9ab46101f0f.png](./images/edac3b8a6905bbabd6bbe9ab46101f0f.png)

如果许可证服务器和主程序分别安装在不同机器上，需要在防火墙中开启许可证服务器的1055端口：
```Bash
sudo ufw allow from any to any port 1055 proto tcp
```

### 2.3 添加自定义服务

完成以上设置，当重启服务器之后，系统不会自动启动守护进程，需要通过以下命令启动ansyslmd：
```Bash
sudo /opt/ansys_inc/shared_files/licensing/start_ansyslmd
```

为了防止服务器断电重启之后因许可证问题导致无法计算，下面通过systemd添加自定义服务，实现开机自动启动守护进程。以下命令新建ansyslmd服务：
```Bash
sudo touch /usr/lib/systemd/system/ansyslmd.service
sudo vim /usr/lib/systemd/system/ansyslmd.service
sudo chmod 754 /usr/lib/systemd/system/ansyslmd.service
```

添加如下内容并保存退出：
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

通过以下命令启动服务：
```Bash
sudo systemctl enable ansyslmd
sudo systemctl start ansyslmd
```

查看服务状态：
```Bash
sudo systemctl status ansyslmd
```

![936bafa551b8e5f366e60560bc7a3cb1.png](./images/936bafa551b8e5f366e60560bc7a3cb1.png)
服务启动成功，安装完毕后可以重启验证下。

## 3. 安装主程序

安装主程序同样需要进入Ubuntu桌面系统。

进入第一个安装包的挂载点，运行安装程序：
```Bash
cd ${HOME}/ISO/1
sudo ./INSTALL # 用root权限安装
```

![6933ca38adf2f53214ee6da37be02675.png](./images/6933ca38adf2f53214ee6da37be02675.png)

求解同样选择安装在：`/opt/ansys_inc`
![93a9af6a6829b4c21c211ed56a9089a2.png](./images/93a9af6a6829b4c21c211ed56a9089a2.png)

根据自己需要选择安装哪些内容：
![921717f7b3c0f69710ca2d0de4f8a702.png](./images/921717f7b3c0f69710ca2d0de4f8a702.png)

配置CAD几何图形接口，本机没安装CAD软件，选择跳过：
![3905fc228e5b13ede8a3389f6997b76f.png](./images/3905fc228e5b13ede8a3389f6997b76f.png)

根据前面选择安装内容的不同，后面会询问一堆配置文件路径，根据自己需要设置吧，没有就无脑Next。
![1ae7bc0a6a670019f24a6b43a6a45e7b.png](./images/1ae7bc0a6a670019f24a6b43a6a45e7b.png)

选择是否创建桌面快捷方式，选上吧，兴许有用呢。
![40ec3516e05c8562ad9e52ed6703e3ef.png](./images/40ec3516e05c8562ad9e52ed6703e3ef.png)

确认安装内容，点击Next开始复制文件：
![bdaa34603562269aeb94f1634682c3e5.png](./images/bdaa34603562269aeb94f1634682c3e5.png)

可以查看安装进度，安装过程中会询问载入其他`.iso`文件挂载路径。
![6e6129bc46d805ef3d32b5269fdddbf0.png](./images/6e6129bc46d805ef3d32b5269fdddbf0.png)

安装完成，提示有一些报错，不管它，退出。
![8329e891f49681100884f8cd734a3685.png](./images/8329e891f49681100884f8cd734a3685.png)

接下来将`ansys.2025r1.linx64-ssq.tar.gz`压缩包中的`v251`文件夹下的文件解压到安装目录下并覆盖：
```Bash
tar xvzf ansys.2025r1.linx64-ssq.tar.gz
sudo cp -r v251 /opt/ansys_inc/
```

主程序安装完成，卸载`.iso`文件的挂载点：
```Bash
sudo umount ${HOME}/ISO/1
```
剩余挂载点按相同方式卸载。

## 4. 配置主程序许可证

安装完主程序之后，需要给主程序配置许可证，有两种方法。

### 4.1 方法1→配置环境变量

在`${HOME}/opt/`中创建并编辑环境变量文件：
```Bash
touch ${HOME}/opt/ansys2025r1.env
chmod +x ${HOME}/opt/ansys2025r1.env
vim ${HOME}/opt/ansys2025r1.env
```

加入以下内容，保存退出：
```Bash
export ANSYSLMD_LICENSE_FILE=1055@localhost
```

后续可以通过以下命令载入环境变量。
```Bash
source ${HOME}/opt/ansys2025r1.env
```
可以把上面的命令行加入到`${HOME}/.bashrc`文件当中，这样每次登录都会自动载入环境变量。

### 4.2 方法2→Ansys Licensing Settings

运行以下命令启动`Licensing Settings`程序：
```Bash
/ansys_inc/v251/licensingclient/linx64/LicensingSettings
```

按步骤进行以下设置：
 1. 将配置文件等级从Installion改为User
 2. 将状态设置为Enable
 3. 端口号填写1055
 4. Server1地址填写localhost
 5. 点击Test按钮测试
 6. 点击Save保存配置

![4a20e58eeea7df3348c81b7cd2b1dd5c.png](./images/4a20e58eeea7df3348c81b7cd2b1dd5c.png)
保存退出，完成许可证配置。

## 5. 启动主程序

配置完许可证之后，通过以下命令启动`Workbench`：
```Bash
/ansys_inc/v251/Framework/bin/Linux64/runwb2
```

![3294556c73209acc5799dc0203469459.png](./images/3294556c73209acc5799dc0203469459.png)

类似的，一些关键主程序的入口参考如下：
| 应用 | 启动命令 |
| ----- | ----- |
| ACP | /ansys_inc/v251/ACP/ACP.sh |
| CFD-Post | /ansys_inc/v251/cfdpost |
| CFX | /ansys_inc/v251/CFX/bin/cfx5<sup>(注)  |
| FLUENT | /ansys_inc/v251/fluent/bin/fluent |
| ICEM CFD | /ansys_inc/v251/icemcfd/icemcfd |
| ICEPAK | /ansys_inc/v251/icepak/icepak |
| Motion | /ansys_inc/v251/Motion/solver/rundfs.sh |
| Polyflow Classic | /ansys_inc/v251/polyflow/bin/polyflow |
| TurboGrid | /ansys_inc/v251/TurboGrid/bin/cfxtg |
| Sherlock | /ansys_inc/v251/sherlock/runSherlock |
| Workbench | /ansys_inc/v251/Framework/bin/Linux64/runwb2 |
| Electronics | /ansys_inc/v251/AnsysEM/ansysedt |

<sup>(注): cfx5可以替换成 cfx5launch、cfx5pre、cfx5solve或cfx5post.，分别对应不同的功能模块。

至此，Ansys安装完毕。

---

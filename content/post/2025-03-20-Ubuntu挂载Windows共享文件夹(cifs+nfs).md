---
layout:     post
title:      "Ubuntu挂载Windows共享文件夹(cifs+nfs)"
description: ""
excerpt: ""
date:    2025-03-20
author:  "Andrew Moa"
image: ""
publishDate: 2025-03-20
tags:
    - linux
    - ubuntu
URL: "/2025/03/20/ubuntu-mount-windows-share-folder/"
categories: [ "Linux" ]    
---

在虚拟机中运行计算文件，会导致虚拟磁盘膨胀，占用太多磁盘空间。这个时候可以通过挂载宿主机文件夹的形式，把计算文件转移到宿主机磁盘上，避免了虚拟磁盘膨胀的问题。
在Windows中建立共享文件夹，这里省略了，只需要确保虚拟机能通过IP地址访问宿主机即可。

## 1. 查看资源路径

以下命令查看服务器共享出来的资源路径，确认挂载点：
```Bash
smbclient -L 172.25.64.1 -U ${username}
```

![915cf6282a8325b667b52d37dea315f0.png](/docs/img/_resources/915cf6282a8325b667b52d37dea315f0.png)
挂载点访问路径：`//172.25.64.1/Share`

## 2. 挂载方法

想要在Ubuntu中访问Windows共享文件夹，首先得安装cifs工具：
```Bash
sudo apt install cifs-utils
```

然后通过`mount`命令挂载共享文件夹：
```Bash
sudo mount -t cifs //172.25.64.1/Share /mnt -o username=${username},password=${password}
```
这里的IP地址`172.25.64.1`是虚拟机中访问的宿主机的网关地址，`Share`是宿主机共享的文件夹，`/mnt`是要挂载到的虚拟机本地访问路径，把命令后面的`${username}`和`${password}`替换成访问用户名和密码即可。
需要注意的是，Windows本地用户的用户名需要写成`${计算机名}\${用户名}`的形式，用反斜杠连接，例如：`xxx-desktop\administrator`。如果是在线账户的话就需要填写完整的邮件账户名称。
如果密码中包含逗号等特殊转义字符的话，命令行就不要包含`,password=`及后面的内容，后续根据提示输入密码登录。

如果出现无读写权限的问题，挂载命令中增加`dir_mode=0777,file_mode=0777`：
```Bash
sudo mount -t cifs //172.25.64.1/Share /mnt -o dir_mode=0777,file_mode=0777,username=${username},password=${password}
```

如果想只添加某些特定用户的读写权限，通过`uid`和`gid`指定用户和组：
```Bash
sudo mount -t cifs //172.25.64.1/Share /mnt -o uid=user,gid=group,username=${username},password=${password}
```

通过`mount`命令可以查看挂载情况：
```Bash
mount | grep cifs
```
![b9e4cda2700bd92ba7d89159f79cc007.png](/docs/img/_resources/b9e4cda2700bd92ba7d89159f79cc007.png)

取消挂载通过`umount`命令：
```Bash
sudo umount /mnt
```

如果想开机自动挂载的话，就需要编辑`/etc/fstab`，内容如下:
```text
//172.25.64.1/Share /mnt cifs auto,dir_mode=0777,file_mode=0777,username=${username},password=${password} 0 0
```

## 3. 特殊字符密码

对于密码含有特殊转义字符的情况，要在Linux开机时实现自动挂载Windows共享文件夹，可以采取以下方法[^1]：

1. 创建凭证文件：为保持密码的安全性，最好将Windows共享的用户名和密码保存在一个只有root权限能访问的文件中，例如：`/etc/cifs-credentials`，并确保它的权限设置为仅root可读。
   ```Bash
   sudo touch /etc/cifs-credentials
   sudo chmod 600 /etc/cifs-credentials
   ```

2. 使用文本编辑器编辑该文件， 如果密码中包含特殊字符，直接在文件中输入即可(无需转义)，写入用户名（xxx-desktop\administrator）和密码（123456,abcde）:

   ```text
   username=xxx-desktop\administrator
   password=123456,abcde
   ```
3. 编辑 `/etc/fstab` 文件：打开 `/etc/fstab` 文件，在文件末尾添加如下内容，以包含挂载信息：
    ```text
   //172.25.64.1/Share /mnt cifs credentials=/etc/cifs-credentials,iocharset=utf8,file_mode=0777,dir_mode=0777 0 0
   ```
	注意`/etc/cifs-credentials`文件的编码需要是UTF-8。

以上便完成了开机自动挂载设置，重启后可以通过`df -h`验证。
![8bcbb069683deec77050415a12e0edc1.png](/docs/img/_resources/8bcbb069683deec77050415a12e0edc1.png)

## 4. 权限问题

使用cifs挂载Windows的共享文件夹，chmod和chown等命令失效，无法调整被挂载的文件和文件夹权限。这里采用NFS(网络文件系统)挂载共享文件夹以解决此问题。

默认情况下，NFS并不提供任何验证机制，因此不需要验证用户名密码，存在一定的安全风险。NFSv3根据客户端IP地址完成验证[^2]，可以通过指定客户端IP地址的方式提高安全性。

Windows10可以通过第三方工具haneWIN[^3]创建NFS共享文件夹，下载安装并通过图形界面配置即可，这里不详细介绍，可以参考其他相关文章[^4]。注意配置完成后要在防火墙中开放相关端口。
![4581ebf45d084151983b8c35aa9a88ac.png](/docs/img/_resources/4581ebf45d084151983b8c35aa9a88ac.png)

在Ubuntu上安装NFS相关工具，开启相关服务：
```Bash
sudo apt install nfs-common rpcbind
sudo systemctl start rpcbind
sudo systemctl enable rpcbind
```

使用`mount`命令挂载共享目录。注意后面的`-t nfs`：
```Bash
sudo mount -t nfs 172.25.64.1:/Share /mnt 
```

取消挂载命令和cifs是一样的，当网络状态突然中断时可以增加`-lf`开关：
```Bash
sudo umount -lf /mnt
```

编辑`/etc/fstab`，添加开机自动挂载：
```text
172.25.64.1:/Share	/mnt	nfs	defaults,_netdev 0 0
```

[^1]: [Linux开机自动挂载window密码有转义字符的共享文件夹](https://blog.csdn.net/qq_37959253/article/details/135715798)

[^2]: [NFS身份验证](https://developer.aliyun.com/article/1629577)

[^3]: [haneWIN](https://www.hanewin.net/nfs-e.htm)

[^4]: [Windows服务器使用haneWIN NFS Server快速搭建NFS服务并挂载到Linux服务器](https://cloud.tencent.com/developer/article/2404222)

---
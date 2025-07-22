+++
author = "Andrew Moa"
title = "Ubuntu搭建软路由"
date = "2025-07-18"
description = ""
tags = [
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

把原先工作用的工作站改成了Ubuntu 24.04，需要通过Windows办公笔记本直连工作站进行操作。一开始在无线网下连接，上传下载数据太慢。后来通过有线网卡桥接，但有时候数据却不通过有线网卡传输反而走无线网卡。禁用笔记本无线网卡无法上网办公，也不是一个好办法。

## 1. 临时方案
工作站作为主机A，笔记本作为主机B，主机B通过有线共享主机A的无线网络[^1]。

### 1.1 查询当前设备网卡
查询两台机子的网卡信息
```bash
iwconfig
```

### 1.2 配置主机A的静态IP并作为软路由
可以通过GUI配置，主机A只需要设置IP地址和子网掩码信息。
```bash
sudo ifconfig eno1 192.168.68.1/24 # enol 为A主机内接的有线网卡名称
ifconfig # 查询效果
```

### 1.3 配置主机B的静态IP、网关和DNS
这一步也可以通过GUI配置，主机B需要配置IP地址、子网掩码，网关设置成主机A的IP地址，另外还需要设置DNS地址。
```bash
sudo ifconfig enp0s31f6 192.168.68.2/24 # enp0s31f6 为A主机有线网卡名称
sudo route add -net 0.0.0.0/0 gw 192.168.68.1 # 添加网关
sudo chmod +666 /etc/resolv.conf 
sudo echo "nameserver 114.114.114.114" > /etc/resolv.conf # 添加DNS
```

### 1.4 打开IP转发功能
Linux默认是禁止IP转发的，需要手动打开该功能。
```bash
sudo bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'   # 打开ip转发
```

### 1.5 配置NAT
通过`iptables`设置路由转发。
```bash
sudo iptables -F
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -t nat -A POSTROUTING -o wlp0s20f3 -j MASQUERADE     # wlp0s20f3为A主机接外网的无线网卡
```

这个方案每次主机A重启都要重新按1.4、1.5设置一遍，非常不方便。

## 2. 持久方案
两个选择，一是将1.4、1.5中的命令行编写成脚本并在每次开机时自动执行，二是使用` iptables-persistent `进行持久化配置[^2]。本文采用第二种方法。

### 2.1 安装`iptables-persistent`
执行以下命令安装`iptables-persistent`。
```bash
sudo apt install iptables-persistent
```

### 2.2 检查规则
查看己设置的`iptables`规则[^3]。
```bash
sudo iptables -L -t nat
```

### 2.3 永久开启IP转发
管理员权限编辑`/etc/sysctl.conf`文件[^4]。
```bash
sudo vi /etc/sysctl.conf
```
找到这一行，将前面的注释符号`#`删除掉，等号的`0`后面改为`1`，保存并退出。
```config
#net.ipv4.ip_forward=1
```

### 2.4 保存`iptables`设置
执行完1.5中的命令行后，管理员身份运行`netfilter-persistent save`命令，永久保持当前`iptables`设置。
```bash
sudo netfilter-persistent save
```

重启验证，问题解决。

[^1]: [两台ubuntu18.04通过有线网络共享无线网络](https://blog.csdn.net/weixin_41281151/article/details/116057867)

[^2]: [基于Ubuntu的软路由搭建记录](https://zahui.fan/posts/cfedbd03/)

[^3]: [linux系统中查看己设置iptables规则](https://blog.csdn.net/chengxuyuanyonghu/article/details/51897666)

[^4]: [如何使用Debian/Ubuntu等Linux做软路由（物理机版本，非虚拟机容器版）](https://zhuanlan.zhihu.com/p/587068225)


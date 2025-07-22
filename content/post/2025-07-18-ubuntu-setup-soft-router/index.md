+++
author = "Andrew Moa"
title = "Building a soft router on Ubuntu"
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

The original workstation was changed to Ubuntu 24.04, and I usually need to connect to the workstation directly through my Windows office laptop. At first, I connected to the wireless network, but the upload and download data was too slow. Later, I used a wired network card to bridge, but sometimes the data was not transmitted through the wired network card but through the wireless network card. Disabling the laptop's wireless network card and being unable to go online for work is not a good solution.

## 1. Temporary solution
The workstation is used as host A, the laptop is used as host B, and host B shares the wireless network of host A through a wired connection[^1].

### 1.1 Query the current device network card
Query the network card hardware information of the two machines.
```bash
iwconfig
```

### 1.2 Configure a static IP for host A and use it as a soft router
It can be configured through the GUI, and host A only needs to set the IP address and subnet mask information.
```bash
sudo ifconfig eno1 192.168.68.1/24 # enol is the name of the wired network card connected to host A
ifconfig # 查询效果
```

### 1.3 Configure static IP, gateway and DNS for host B
This step can also be configured through the GUI. Host B needs to be configured with an IP address, subnet mask, and the gateway is set to the IP address of Host A. In addition, the DNS address needs to be set.
```bash
sudo ifconfig enp0s31f6 192.168.68.2/24 # enp0s31f6 is the name of the wired network card of host A
sudo route add -net 0.0.0.0/0 gw 192.168.68.1 # Add a Gateway
sudo chmod +666 /etc/resolv.conf 
sudo echo "nameserver 114.114.114.114" > /etc/resolv.conf # Add DNS
```

### 1.4 Enable IP forwarding
IP forwarding is disabled by default in Linux and needs to be enabled manually.
```bash
sudo bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'   # enable ip forwarding
```

### 1.5 Configuring NAT
Set up routing forwarding through `iptables`.
```bash
sudo iptables -F
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -t nat -A POSTROUTING -o wlp0s20f3 -j MASQUERADE     # wlp0s20f3 is the wireless network card that connects host A to the external network
```

This solution requires resetting 1.4 and 1.5 every time host A is restarted, which is very inconvenient.

## 2. Permanent solution
There are two options here. One is to write the command lines in 1.4 and 1.5 into a script and execute it automatically every time the computer is turned on. The other is to use `iptables-persistent` for persistent configuration[^2]. This article adopts the second method.

### 2.1 Install `iptables-persistent`
Execute the following command to install iptables-persistent.
```bash
sudo apt install iptables-persistent
```

### 2.2 Check the rules
Check the `iptables` rules that have been set[^3].
```bash
sudo iptables -L -t nat
```

### 2.3 Permanently enable IP forwarding
Edit the /etc/sysctl.conf file with administrator privileges[^4].
```bash
sudo vi /etc/sysctl.conf
```
Find this line, delete the comment symbol `#` in front of it, change the `0` after the equal sign to `1`, save and exit.
```config
#net.ipv4.ip_forward=1
```

### 2.4 Save `iptables` settings
After executing the command line in 1.5, run the `netfilter-persistent save` command as an administrator to permanently save the current `iptables` settings.
```bash
sudo netfilter-persistent save
```

Restart verification and the problem is solved.

[^1]: [两台ubuntu18.04通过有线网络共享无线网络](https://blog.csdn.net/weixin_41281151/article/details/116057867)

[^2]: [基于Ubuntu的软路由搭建记录](https://zahui.fan/posts/cfedbd03/)

[^3]: [linux系统中查看己设置iptables规则](https://blog.csdn.net/chengxuyuanyonghu/article/details/51897666)

[^4]: [如何使用Debian/Ubuntu等Linux做软路由（物理机版本，非虚拟机容器版）](https://zhuanlan.zhihu.com/p/587068225)


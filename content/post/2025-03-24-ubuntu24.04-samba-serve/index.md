+++
author = "Andrew Moa"
title = "Ubuntu24.04 builds Samba server"
date = "2025-03-24"
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

Since Ubuntu runs in a virtual machine, when you mount a Windows shared folder through Ubuntu, some CAE software will report a calculation error when running it in the mount point. Consider sharing the Ubuntu folder with Windows, so you need to build a Samba server on the Ubuntu system.

First, install the samba package on Ubuntu:
```Bash
sudo apt install samba -y
```

Create a shared folder:
```Bash
mkdir ${HOME}/LinuxShare
```

Edit the Samba configuration file `/etc/samba/smb.conf`:
```Bash
sudo vim /etc/samba/smb.conf
```

Add the following content to the end of the file, save and exit:
```Text
[Ubuntu_Share] # The name of the shared folder displayed on the client
    comment = Samba # Comment, displayed to the user
    path = /home/***/LinuxShare # The local path of the shared folder, fill in the absolute path
    public = yes # Whether anonymous users are allowed to access
    writable = yes # Whether users are allowed to edit
    available = yes # Whether it is available
    browseable = yes # Whether it can be browsed on the network
    valid users = user # Fill in the Ubuntu login user name
```

Set a password for the Samba user:
```Bash
sudo smbpasswd -a user
```

Start the Samba service daemon:
```Bash
sudo systemctl enable smbd
sudo systemctl start smbd
```

Query the Samba service status:
```Bash
sudo systemctl status smbd
```

![43d6c0a3f978558be05ab8832d33eff8.png](./images/43d6c0a3f978558be05ab8832d33eff8.png)
Service status: `Active: active (running)`, running normally.

Update the Samba configuration file `/etc/samba/smb.conf` and refresh it with the following command:
```Bash
sudo service smbd restart 
```

Add firewall rules:
```Bash
sudo ufw allow samba
```

After the configuration is complete, you can access the shared folder on the Windows side. For more information, please refer to other documents.

---

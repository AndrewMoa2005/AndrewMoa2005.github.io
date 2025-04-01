---
layout:     post
title:      "PowerShell编写STAR-CCM+自动排队计算脚本"
description: ""
excerpt: ""
date:    2025-03-25
author:  "Andrew Moa"
image: ""
publishDate: 2025-03-25
tags:
    - powershell 
    - star-ccm+
URL: "/2025/03/25/powershell-starccm-script/"
categories: [ "CFD" ]    
---

以前用STAR-CCM+在Windows工作站做计算的时候（没钱，公司舍不得上超算……），有时候一晚上要提交十几二十个计算任务（瞎卷ㄟ( ▔, ▔ )ㄏ），当然不可能十几个任务全都一起跑（机器遭不住），也不可能全程盯着它跑一个个手动提交（人遭不住）。几年前用PowerShell编写了这个简易的排队计算的模板，在这里分享给大家。

```PowerShell
$title = "STAR-CCM+ 19.06.009-r8"	# 窗口标题，怎么填随你喜欢
$host.ui.RawUI.WindowTitle = $title

$STARCCM_PATH = "D:\XXX\Siemens\19.06.009-R8\STAR-CCM+19.06.009-R8\star\lib\win64\clang17.0vc14.2-r8\lib"	# 填写本机STAR-CCM+的安装绝对路径
$env:path += ";$STARCCM_PATH"
$run_dir = $pwd
$thread_number = 32	# 填写本机的CPU核心数

$Array = Get-ChildItem -Path $run_dir -Name "*.sim"
$n = 0

foreach($item in $Array)
{
    $n += 1
    $sub_dir = $n.ToString() + "_" + $item.Substring(0,$item.Length-4)
    mkdir $sub_dir
    mv $item $sub_dir
    cd $sub_dir
    $host.ui.RawUI.WindowTitle = $title + " - " + $item + " - " + $n + "/" + $Array.Count
    $log = $item + ".log"
    starccm+ $item -batch run -np $thread_number -mpi ms | tee $log
    cd $run_dir
}
```

把以上命令行以文本格式保存为`.ps1`脚本文件，和要提交计算的`.sim`文件放到同一个文件夹，然后通过终端运行这个脚本。会自动统计排队任务数，将计算的.sim文件转移至新建子文件夹，同时生成`.log`日志文件，也可以在输出窗口中监控运行情况。计算完成后关闭终端即可。

美中不足的是，不支持宏文件，也不支持临时增加或插入算例。

各位可以针对自己的情况，做一些针对性的调整。

如果碰到输出窗口和日志文件中有乱码的情况，多半是你的PowerShell不支持UTF-8所导致。参考以下方法[^1]，在PowerShell窗口中输入：
```PowerShell
# 配置文件一般位于：C:\Users\用户名\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
# 如果没有就新建一个
notepad $PROFILE # 编辑配置文件
```

在配置文件中增加以下内容，保存退出：
```PowerShell
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
```

[^1]: [WindowsPowerShell中文乱码问题解决](https://www.azfum.com/archives/ki3syg5b/)

---
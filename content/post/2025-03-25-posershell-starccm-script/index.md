+++
author = "Andrew Moa"
title = "PowerShell编写STAR-CCM+自动排队计算脚本"
date = "2025-03-25"
description = ""
tags = [
    "powershell",
    "star-ccm+",
]
categories = [
    "cfd",
]
series = [""]
aliases = [""]
image = "/images/vortex-bg.jpg"
+++

When I used STAR-CCM+ to do calculations on a Windows workstation, sometimes I had to submit more than ten or twenty computing tasks in one night. Of course, it was impossible to run more than ten tasks at the same time, and it was impossible to watch it run and submit them manually one by one. A few years ago, I wrote this simple queue calculation template using PowerShell, and I share it with you here.

```PowerShell
$title = "STAR-CCM+ 19.06.009-r8"	# Window title, fill it in as you like
$host.ui.RawUI.WindowTitle = $title

$STARCCM_PATH = "D:\XXX\Siemens\19.06.009-R8\STAR-CCM+19.06.009-R8\star\lib\win64\clang17.0vc14.2-r8\lib"	# Fill in the absolute installation path of STAR-CCM+ on this machine
$env:path += ";$STARCCM_PATH"
$run_dir = $pwd
$thread_number = 32	# Fill in the number of CPU cores of this machine

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

Save the above command line in text format as a `.ps1` script file, put it in the same folder as the `.sim` file to be submitted for calculation, and then run this script through the terminal. It will automatically count the number of queued tasks, transfer the calculated .sim file to a new subfolder, and generate a `.log` log file. You can also monitor the operation status in the output window. Close the terminal after the calculation is completed.

The only drawback is that it does not support macro files, nor does it support temporary addition or insertion of calculation examples.

You can make some targeted adjustments according to your own situation.

If you encounter garbled characters in the output window and log file, it is mostly caused by your PowerShell not supporting UTF-8. Refer to the following method [^1] and enter in the PowerShell window:
```PowerShell
# Configuration files are usually located at: C:\Users\用户名\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
# If not, create a new one
notepad $PROFILE # Editing the Configuration File
```

Add the following content to the configuration file, save and exit:
```PowerShell
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
```

[^1]: [WindowsPowerShell中文乱码问题解决](https://www.azfum.com/archives/ki3syg5b/)

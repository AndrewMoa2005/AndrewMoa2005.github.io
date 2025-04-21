+++
author = "Andrew Moa"
title = "Ansa单位制"
date = "2025-03-05"
description = ""
tags = [
    "ansa",
    "cae",
]
categories = [
    "ansa",
]
series = [""]
aliases = [""]
image = "/images/grid-bg.jpg"
+++

Ansa导入step模型默认长度单位是mm，重量是ton。但我们常用的SI单位制长度是m，重量是kg。
关于两种单位的转换如下表所示。

| 长度 | 质量 | 时间 | 力 | 应力 | 能量 | 密度 | 杨氏模量 | 速度 (56.3KPH) | 重力 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | 
| m | kg | s | N | Pa | Joule | 7.83E+03 | 2.07E+11 | 15.64 | 9.81 |
| mm | ton | s | N | MPa | N-mm| 7.83E-09 | 2.07E+05 | 1.564E+04| 9.81E+03 |

在定义模型参数时，应注意根据长度选择对应的单位制。

---
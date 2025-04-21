+++
author = "Andrew Moa"
title = "Ansa system of units"
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

The default length unit for Ansa imported step model is mm, and the weight is ton. However, the SI unit we commonly use is m for length and kg for weight.
The conversion between the two units is shown in the following table.

| LENGTH | MASS | TIME | FORCE | STRESS | ENERGY | DENSITY | YOUNG’s MUDULUS | Velocity (56.3KPH) | GRAVITY |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | 
| m | kg | s | N | Pa | Joule | 7.83E+03 | 2.07E+11 | 15.64 | 9.81 |
| mm | ton | s | N | MPa | N-mm| 7.83E-09 | 2.07E+05 | 1.564E+04| 9.81E+03 |

When defining model parameters, care should be taken to select the corresponding unit system based on the length.

---
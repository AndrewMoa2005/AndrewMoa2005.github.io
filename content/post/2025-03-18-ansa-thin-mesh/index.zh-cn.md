+++
author = "Andrew Moa"
title = "Ansa薄板网格建模"
date = "2025-03-18"
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

由于近期经常做一些冷板结构分析，涉及到薄板建模的。虽然尝试过用Shell单元进行分析，但相比于Solid单元，Shell单元做出来的结果应力、位移均有所偏大，而且涉及到接触问题更容易出现计算不收敛的情况。
所幸Ansa提供了通过Shell单元拉伸生成体网格的方式，可以快速通过Shell单元生成Solid网格，极大地节省了建模时间。

建模步骤如下：
1. 薄板实体简化为Shell并划分网格，可以参考[Ansa抽中面功能](../2025-02-27-ansa-midsurf/)。
![5c6da744441c0b43367e9d1ff0296ec1.png](./images/5c6da744441c0b43367e9d1ff0296ec1.png)

2. `Volume Mesh`→`Extrude`调出`Extrude`窗口，选中要拉伸的Shell单元。
![02fe91f7f3a74047ccd442f4eaa42505.png](./images/02fe91f7f3a74047ccd442f4eaa42505.png)

3. 目标面选择`None`。
![5818d8ffc832684765e7312eafe76ea9.png](./images/5818d8ffc832684765e7312eafe76ea9.png)

4. 拉伸方式选择`Offse`，方向选择`Both sides (middle)`。
![d464570c23719e82fcd4d152a9278f8d.png](./images/d464570c23719e82fcd4d152a9278f8d.png)

5. `Steps`选择层数，`Distance`输入薄板厚度，`Biasing`建议选择`Smooth`，`Finish`完成。
![e3b90aaa49545a963c3f998a86a3a036.png](./images/e3b90aaa49545a963c3f998a86a3a036.png)

6. 检查生成的网格质量，修复差网格。
![242f974310b6eff9061c0c8ce2230673.png](./images/242f974310b6eff9061c0c8ce2230673.png)

总结：这种方式比较适合厚度均匀的薄板生成体网格。但是当薄板厚度不均匀，或者存在T型连接（例如注塑件筋条等，如下图）的时候，就不适用了。
![0ad79055f8a7a324c278b023ee79be6f.png](./images/0ad79055f8a7a324c278b023ee79be6f.png)

---



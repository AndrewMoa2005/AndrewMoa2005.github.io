+++
author = "Andrew Moa"
title = "Ansa螺钉孔washer网格"
date = "2025-02-28"
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

使用Ansa建面网格的时候我们都希望螺钉孔能处理成washer网格的形式，方便后面加约束。
![ff86c5fd4ac5cc0624c9013d21a1dab5.png](./images/ff86c5fd4ac5cc0624c9013d21a1dab5.png)

但默认设置生成的网格螺钉孔貌似都没有按washer处理。
![6ea45853b136275e0c8325e7b4a47341.png](./images/6ea45853b136275e0c8325e7b4a47341.png)

有几种方法，其一是通过几何处理手动添加`Zone Cut`的方式，这种方法手工处理工作量太大，不推荐

另一种方法需要手动`Reconstruct`网格，首先在网格参数设置里设置孔的特征参数。
![363c5b51b1b6eab2ba3b44bd907c10dd.png](./images/363c5b51b1b6eab2ba3b44bd907c10dd.png)
![6db3f7dddb8aaa1cea878f831db1abc0.png](./images/6db3f7dddb8aaa1cea878f831db1abc0.png)

返回`Mesh`里，`Reconstrust`就有了。
![5489ac8734b83c3b95fbac196237c402.png](./images/5489ac8734b83c3b95fbac196237c402.png)

---



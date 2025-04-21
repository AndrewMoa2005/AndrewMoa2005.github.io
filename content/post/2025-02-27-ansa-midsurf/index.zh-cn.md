+++
author = "Andrew Moa"
title = "Ansa抽中面功能"
date = "2025-02-27"
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

ANSA针对钣金件抽中面有几种不同处理方式。

## 1. `Skin`方法

`TOPO`→`Mid.Surfa.`→`Skin`，选中整个几何体然后无脑按鼠标中键就可以自动抽中面。
![0f525cbbea14aa2904b78e9e80f86f98.png](./images/0f525cbbea14aa2904b78e9e80f86f98.png)

适合一些厚度比较均匀的钣金结构件，没有筋条、凸台、凹坑等特征。
![86e9dc3696bc04b9a2811e5e191d2ae8.png](./images/86e9dc3696bc04b9a2811e5e191d2ae8.png)

抽出来的中面是几何不带网格，需要手动画网格，会自动删除原来的几何并添加厚度。
![65641a61f8dc0512e7817886b49376ac.png](./images/65641a61f8dc0512e7817886b49376ac.png)

对一些挤压件像挤压铝型材也支持，但是有圆角的话要先处理掉，不然抽出来的中面圆角会保留并放大。
![943f3baab965a035e5eb414649bfc120.png](./images/943f3baab965a035e5eb414649bfc120.png)
![68c5c4d9c15d8b0aa5963fcc69b65e0a.png](./images/68c5c4d9c15d8b0aa5963fcc69b65e0a.png)

## 2. `Casting/Extrusion`方法

还有一种针对铸造和挤压件的抽中面方法，`TOPO`→`Mid.Surfa.`→`Casting/Extrusion`
![ca523b08317e499e8d5b541abc272c63.png](./images/ca523b08317e499e8d5b541abc272c63.png)

首先要确保几何是封闭的，没有错误面和边。
![04aff45feacbd435a025c1fa4d939939.png](./images/04aff45feacbd435a025c1fa4d939939.png)

在弹出选项卡选好要抽中面的零部件是铸造件还是挤压件，定义好最小厚度和面网格尺寸。抽中面之前最好先在网格参数中定义好特征孔参数，用于生成washer网格，因为抽完面之后就直接是面网格。
![41aca4cbf0e00ad69276c8e89041a513.png](./images/41aca4cbf0e00ad69276c8e89041a513.png)

最后生成的网格，厚度根据几何形状自动计算，不需要在PID里再设置厚度。
![bd6e4eb9c3a4f72253bdd1c10eb452ad.png](./images/bd6e4eb9c3a4f72253bdd1c10eb452ad.png)

## 3. `Middle Multi.`手工处理

很麻烦，不推荐。但是对于一些复杂结构件，比如注塑件等，只能用这种办法。
![410117bbbf085e19ff33ed0193e0f28f.png](./images/410117bbbf085e19ff33ed0193e0f28f.png)

首先要把一些和筋条等特征共面的曲面按拓扑分割，方便后面处理。
![33a2206ca7f19d97f0358ba9472d2cbd.png](./images/33a2206ca7f19d97f0358ba9472d2cbd.png)

用红色和绿色标注中面的正反面，蓝色是侧面。
![7469baf9dcb520788aa5d1389b4f0f99.png](./images/7469baf9dcb520788aa5d1389b4f0f99.png)

抽完的中面会自动隐藏，方便处理剩下的模型。
![652f8d7c29cef890403edda839b163f1.png](./images/652f8d7c29cef890403edda839b163f1.png)

## 4. 总结

- `Skin`方法：简单，适合钣金件，生成几何数据，精度好
- `Casting/Extrusion`方法：简单，适合铸造和挤压件，生成网格数据，精度稍差
- `Middle Multi.`手工处理：繁琐，但适合复杂结构件如注塑件等，生成几何数据，精度因人而异

---


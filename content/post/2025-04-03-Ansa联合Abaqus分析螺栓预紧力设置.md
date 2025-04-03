---
layout:     post
title:      "Ansa联合Abaqus分析螺栓预紧力设置"
description: ""
excerpt: ""
date:    2025-04-03
author:  "Andrew Moa"
image: ""
publishDate: 2025-04-03
tags:
    - 前处理
    - ansa
    - cae
    - abaqus
URL: "/2025/04/03/ansa-abaqus-deck-bolt-pretension/"
categories: [ "Ansa" ]    
---

Ansa联合Abaqus分析经常遇到螺栓施加预紧力问题，除了设置复杂外还容易踩坑，一不小心就会遇到各种各样的问题。下面记录一下Ansa螺栓预紧力设置过程和一些坑，为后面相关分析作参考。

## 1. Solid+Assistant 

实体螺栓和法兰面之间要先建立连接，具体可以参考[Abaqus接触设置](https://andrewmoa2005.github.io/2025/03/10/abaqus-connect-setup/)。
![1a56cfc8f6f5583e360bf9bd9ae4de48.png](/resources/1a56cfc8f6f5583e360bf9bd9ae4de48.png)

 1. 单个螺栓可以通过`AUXILIARIES`→`PRTENS`→`Assistant`向导进行设置。
 ![0529d3a74d53af475e0c91c8f355cb58.png](/resources/0529d3a74d53af475e0c91c8f355cb58.png)

 2. 在弹出向导中选择`Surface - Solid Elements`或者`Surface - Solid Property`，然后选择螺栓实体。 勾选下面的`Detect and create all possible pretensions.`，会尝试自动搜索类似实体并创建相同的预紧力。
 ![9d13058ea827e23ce047e9f1b52fde1d.png](/resources/9d13058ea827e23ce047e9f1b52fde1d.png)

 3. 下一步，在螺栓实体上选择第一个参考点。
 ![5086d6cd6a8c37ddea9506db6731656b.png](/resources/5086d6cd6a8c37ddea9506db6731656b.png)

4. 下一步，选择第二个参考点定义螺栓预紧力方向，此时会在第一个参考点生成参考平面。注意预紧力方向要与螺栓轴线平行。
 ![74336c606e1112ff70556e8a1b845a23.png](/resources/74336c606e1112ff70556e8a1b845a23.png)

5. 下一步，输入预紧力大小50kN，注意勾选后面的`Fixed`。这里会自动生成两个`STEP`。第一个`STEP`用于加载预紧力，第二个`STEP`用于固定预紧力状态。其他的载荷可以施加到第二个`STEP`里面。
 ![62ad85d4eb3da3ebeaf9d6bd74784a32.png](/resources/62ad85d4eb3da3ebeaf9d6bd74784a32.png)

6. 最后，定义参考平面的法向，确认应用螺栓预紧力。
 ![64fd2a39cb6d08089a8f3dcb35de2854.png](/resources/64fd2a39cb6d08089a8f3dcb35de2854.png)

以上步骤完成后就可以提交计算了。

**容易踩坑的地方**：
   
 - 涉及到接触问题导致的不收敛，可以加上接触控制`Contact Control`→`Stabilize`，提高求解的稳定性。
   ![0044bbf908b9542e60878b21e06b0940.png](/resources/0044bbf908b9542e60878b21e06b0940.png)

 - 如果加上接触控制还是不收敛，建议将实体螺栓和法兰面之间的接触改用Coupling约束替代之。
   ![fa55849b34b2665b973afb52d8cd2e27.png](/resources/fa55849b34b2665b973afb52d8cd2e27.png)

 - 如果计算结果出现螺钉变长的情况，多半是第6步参考平面的法向定义反了，更改参考面法线方向即可。
   ![7f6ca35973bffa52ccc6c0f6515c03bf.png](/resources/7f6ca35973bffa52ccc6c0f6515c03bf.png)

计算完成后通过`Meta`打开，可以查看实体螺栓内部的应力分布状态。
![3701316cf8a485c6a40358827e2b6e72.png](/resources/3701316cf8a485c6a40358827e2b6e72.png)

## 2. Beam+Assistant

当要研究的问题不涉及螺栓本体强度时，可采用梁单元替代螺栓实体，减少计算量提高计算效率的同时还能避免出现计算不收敛的问题。

 1. 梁单元需要先新建梁的PID，先定义螺栓的截面和材料。截面形式选圆形，定义螺栓半径。
![aa224c8a201f2492d1a62954df43c008.png](/resources/aa224c8a201f2492d1a62954df43c008.png)

 2. 需要通过Beam新建梁单元（建议先通过螺栓孔新建两个Coupling约束，再通过Coupling约束的中心新建Beam单元），再指派到上面的PID里，此时Beam单元只有一段。
![fa2bd5582a7602facfab1a070c3fe110.png](/resources/fa2bd5582a7602facfab1a070c3fe110.png)
	 
 3. 然后转到`Mesh`，通过`Insert`插入点的方式，将Beam单元分割为多段。
![b13884f8e33ae2d9fa054c9d7de1381e.png](/resources/b13884f8e33ae2d9fa054c9d7de1381e.png)

 4. 接下来启动向导，选择`Beam Elements`，选择中间的一段Beam单元。如果上一步没有分割Beam单元，这里可以选择下面的`Split Beams`，会自动将Beam单元分割为3段并选中中间的一段。
![b99d2690fa392cb288ae45836ec32635.png](/resources/b99d2690fa392cb288ae45836ec32635.png)

 5. 同样，输入预紧力50kN，选择固定预紧力状态。
![ddf9dd2eac9916853e5878d58293b01a.png](/resources/ddf9dd2eac9916853e5878d58293b01a.png)

 6. 确认创建预紧力。
![b48b617fe706fbcd3ab8ab80b3928615.png](/resources/b48b617fe706fbcd3ab8ab80b3928615.png)

以上步骤完成后可以提交计算。

**常见问题**：

 - `Meta`不支持显示Beam单元应力分布。如果要查看Beam单元应力分布状态，需要通过`Abaqus Viewer`来渲染结果文件。

 - 需要在`View`→`ODB Display Options`里打开`Render beam profiles`才能显示梁单元的状态。
![04efaf98e00ea3de3cba47e7ae6ffe9a.png](/resources/04efaf98e00ea3de3cba47e7ae6ffe9a.png)

 - 梁单元的应力显示要选择`BEAM_STRESS`。
![119d81cf131d6238901f36b8090bd44f.png](/resources/119d81cf131d6238901f36b8090bd44f.png)

 - 想在结果中查看梁的应力分布状态，建议在`*OUTPUT`关键字选择输出所有变量，这样用`Abaqus Viewer`渲染的时候才能查看`BEAM_STRESS`。
![7858de766a8079b575e43008a3ebb326.png](/resources/7858de766a8079b575e43008a3ebb326.png)

## 3. Beam+Connection

Connection设置可以参考[Ansa快速设置连接](https://andrewmoa2005.github.io/2025/03/05/ansa-connector/)。通过Connection也可以设置螺栓预紧力，尤其适合多个螺栓连接、需要经常替换模型或调整参数的场合。这里螺栓本体选择梁单元。

建立PID的步骤同上一章节中的第2步。`Body Type`选择`CBEAM`，激活`Create Pretension`并输入预紧力大小。
![b3ad8f55b683acf6abd709917322dede.png](/resources/b3ad8f55b683acf6abd709917322dede.png)

多个螺栓应力显示：
![04a3aa65c393ae2df076591add66570d.png](/resources/04a3aa65c393ae2df076591add66570d.png)

## 4. 总结

- `Solid+Assistant `： 螺栓本体应力结果相对更准确，但计算量较大，容易出现不收敛情况。
- `Beam+Assistant `：计算量少，更容易收敛，但只能用在不考察螺栓本体强度的场合。
- `Beam+Connection` ：计算量少、容易收敛，更改、替换操作更方便，同样不能直接考察螺栓本体强度。







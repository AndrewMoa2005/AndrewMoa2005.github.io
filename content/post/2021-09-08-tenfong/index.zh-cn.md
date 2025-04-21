+++
author = "Andrew Moa"
title = "扒一扒十沣科技国产CFD软件——QFlux及QMesh"
date = "2021-09-08"
description = ""
tags = [
    "cfd",
]
categories = [
    "zhihu",
]
series = [""]
aliases = [""]
image = "/images/post-bg-tea.jpg"
+++

先说结论：十沣科技产品QFlux和QMesh与自身宣传不符。QMesh并不是什么“自主开发的先进计算流体力学核心软件”；而QFlux功能根本就尚未完善，至少没有包含其宣传所拥有的功能，而且笔者有理由怀疑其求解器根本就是“借鉴”自OpenFOAM。

## 1. 软件介绍及下载

废话不多说，关于十沣科技的宣传可以从其官网（http://www.tenfong.cn/、http://www.qfx-tech.com/）上窥知一二。

![20210808-01-企业概况.png](./images/20210808-01-企业概况.png)

该公司官网上的两个产品：QFlux和QMesh，前一个是CFD求解器、后一个是网格前处理器。感兴趣的同学可以在官网上注册然后登录下载。

![20210808-02-QFlux.png](./images/20210808-02-QFlux.png)

![20210808-03-QMesh.png](./images/20210808-03-QMesh.png)

不知是不是浏览器的问题，点击下载按钮后并不会弹出下载信息确认窗口，而是直接在浏览器后台下载，用户需要等到下载完成后到临时文件夹（Windows：C:\Users\\[用户名]]\AppData\Local\Temp）里才能找到下载的程序安装文件。不仔细找找还真找不到，也不知道是官方是不是故意的呢。

![20210808-04-下载文件.png](./images/20210808-04-下载文件.png)

解压之后会得到`QFlux_x64.exe`及`QMesh_x64.exe`两个安装文件，分别安装之。安装过程没什么复杂的，这里就不细讲了。

## 2. 前处理软件QMesh

按照惯例，先扒一扒前处理软件QMesh。

![20210808-05-QMesh程序文件.png](./images/20210808-05-QMesh程序文件.png)

可以看到QMesh网格显示方面是通过vtk库来实现的，界面则是通过Qt来实现。也不知道该公司有没有购买Qt的商业授权，要知道Qt的三种授权模式分别是GPL、LGPL和商业授权，笔者反正是没看到安装文件有声明引用Qt及其相关类库。

![20210808-06-QMesh网格生成程序.png](./images/20210808-06-QMesh网格生成程序.png)

QMesh网格生成器的核心是`snappyHexMesh`，熟悉OpenFOAM的朋友应该都知道，这是OpenFOAM自带的网格生成器。

![20210808-07-QMesh帮助文件概述.png](./images/20210808-07-QMesh帮助文件概述.png)

QMesh软件的帮助文件倒是很大方地承认了这一点。但是官网上宣传的不是“QMESH 是深圳十沣科技有限公司自主开发的先进计算流体力学核心软件”吗？核心的网格生成器引用别人的工具，这算哪门子的自主开发？合着就“自主”开发了一个GUI界面？然后还用了别人的类库？

![20210808-08-QMesh软件界面.png](./images/20210808-08-QMesh软件界面.png)

首次进入会提示试用期180天，软件界面中归中距。帮助文件关于里显示软件版本是2.1.3，版权方为“深圳清沣溪有限公司”。

![20210808-09-elbow面网格文件-stl格式.png](./images/20210808-09-elbow面网格文件-stl格式.png)

接下来用Fluent官方的算例elbow来试着进行建模及计算。上图是用ANSA导出的STL格式文件（ASCII格式），已经分好面。

![20210808-10-QMesh导入STL文件.png](./images/20210808-10-QMesh导入STL文件.png)

QMesh只支持导入STL格式曲面，但导入STL文件后无法识别已经分好的面，也无法对实体进行重新分区等操作。

![20210808-11-QMesh设置网格区域.png](./images/20210808-11-QMesh设置网格区域.png)

QMesh通过“区域”选项设置背景网格的区域，这点与OpenFOAM中的blockMesh类似，但不足的是不能调整背景网格的大小。需要指定材料点，也就是OpenFOAM中snappyHexMeshDict文件的`locationInMesh`关键字，熟悉OpenFOAM的同学应该都清楚。

![20210808-12-QMesh设置网格控制参数.png](./images/20210808-12-QMesh设置网格控制参数.png)

QMesh通过“控制”选项设置贴体网格及边界层的控制参数，基本对应OpenFOAM中snappyHexMeshDict文件的`castellatedMeshControls`、`snapControls`及`addLayersControls`等所包含的内容。

![20210808-13-QMesh剖分网格.png](./images/20210808-13-QMesh剖分网格.png)

点击“剖分网格”，在弹出会话框可以选择并行设置相关参数以及选择剖分体网格及边界层。

![20210808-14-QMesh调用snappyHexMesh生成网格.png](./images/20210808-14-QMesh调用snappyHexMesh生成网格.png)

通过任务管理器可以看到，QMesh实际上是通过调用snappyHexMesh进行网格生成操作的。

![20210808-15-QMesh生成网格.png](./images/20210808-15-QMesh生成网格.png)

由于是调用用snappyHexMesh进行网格生成操作的，因此不可避免地将snappyHexMesh的一些固有缺陷也带入其中。可以看到局部网格出现畸形，这其实是snappyHexMesh的缺陷所导致的，至今依然没有很好的解决办法。由于不能调整背景网格大小，因此当局部网格与背景网格相互重合时，有可能生成新的边界区域，就像上图中的`y-minus`区域一样。

![20210808-16-QMesh导出网格.png](./images/20210808-16-QMesh导出网格.png)

将QMesh生成的网格导出elbow.msh（Fluent Mesh格式）及elbow.cgns（CGNS通用格式），QMesh工程文件保存格式为.qmh。可以看到elbow.cgns大小只有4kB，明显CGNS格式保存得不成功。唉~，软件能做成这样，估计都没经过测试就直接发出来了。

## 3. CFD求解器QFlux

![20210808-17-QFlux程序文件.png](./images/20210808-17-QFlux程序文件.png)

QFlux的程序文件和QMesh类似，底层是通过Qt和vtk来实现得，笔者依然没有看到相关引用类库的声明。

![20210808-18-QFlux核心求解器文件.png](./images/20210808-18-QFlux核心求解器文件.png)

QFlux核心求解器文件是qcore，这个留到后面再讲。

![20210808-19-QFlux软件界面.png](./images/20210808-19-QFlux软件界面.png)

QFlux软件界面，版本号显示是2.7.152.0，版权方变成了“深圳十沣科技有限公司”。

![20210809-20-QFlux导入msh文件.png](./images/20210809-20-QFlux导入msh文件.png)

试着导入前面QMesh生成的elbow.msh，结果导入失败，识别不了。真是大水冲了龙王庙——一家人不认一家人(～￣▽￣)～。至于QMesh生成的elbow.cgns，很明显保存失败，不用费劲巴拉去试了。

![20210809-21-QFlux导入ANSA生成的cgns文件.png](./images/20210809-21-QFlux导入ANSA生成的cgns文件.png)

导入ANSA生成的cgns文件，已经分好边界。

![20210809-22-QFlux导入cgns网格.png](./images/20210809-22-QFlux导入cgns网格.png)

QFlux导入CGNS网格之后依然没有识别出边界信息，边界条件里面只有一个边界，不能作边界分割的操作。（PS：依然是半成品呀~，这么草率就发出来吗？）

安装包提供了`OFoamToQFlux`程序用于转换OpenFOAM网格，好在笔者用OpenFOAM计算过相关案例。打开CMD命令行窗口，执行以下命令转换OpenFOAM网格。

```cmd
cd /d D:\opt\tenfong\QFlux #[QFlux安装路径]
set path=%cd%;%path%
cd /d F:\tenfong\solve #[OpenFOAM文件所在目录]
OFoamToQFlux %cd%\[OpenFOAM文件的Case目录]\constant\polyMesh out.qfx
```

这样即生成了QFlux的网格文件，并保存城QFlux格式(.qfx)。直接打开out.qfx文件即可。

![20210809-23-QFlux打开qfx文件.png](./images/20210809-23-QFlux打开qfx文件.png)

![20210809-24-QFlux显示边界信息.png](./images/20210809-24-QFlux显示边界信息.png)

可以看到这回显示了边界信息，边界条件后面再慢慢改。

![20210809-25-案例说明.png](./images/20210809-25-案例说明.png)

计算案例取自Ansys Fluent的经典案例elbow，流体及边界参数设置如上图所示。

![20210809-26-QFlux基本方程信息.png](./images/20210809-26-QFlux基本方程信息.png)

QFlux的基本方程，貌似只能选不可压缩流求解器Incompressible（喂喂喂，宣传中的可压缩流求解器呢？），激活能量方程。

![20210809-27-QFlux物理模型选择.png](./images/20210809-27-QFlux物理模型选择.png)

湍流模型，没什么需要特别说明的。右边的湍流参数也都是可以在OpenFOAM的turbulenceProperties文件里修改的。唯一的亮点可能是湍流模型的近壁处理方面，总比OpenFOAM里一个一个地在k文件、nut文件里调试壁面函数要好。（PS：仅仅是加了一个GUI而已，同样的功能我用Qt包装一下也能实现。）

![20210809-28-QFlux离散格式选择.png](./images/20210809-28-QFlux离散格式选择.png)

数值方法，就是求解器、离散格式和松弛因子的选择，基本相当于OpenFOAM的controlDict、fvSchemes和fvSolution文件，只不过不用你一个个去调试了而已。貌似求解器还只能选择SIMPLE算法。

![20210809-29-QFlux材料设置.png](./images/20210809-29-QFlux材料设置.png)

材料库里面只有空气、水和结构钢三种材料。

![20210809-30-QFlux设置边界条件.png](./images/20210809-30-QFlux设置边界条件.png)

进出口边界条件，流动方向不能指定为表面法向，只能手动输入流动方向坐标。不过它的湍流参数定义方式与其他商业CFD软件比较接近，总比OpenFOAM中一个个去计算然后手动定义k文件、epsilon文件还有nut文件方便地多。貌似速度和温度的单位不能更改，所以如果用户用的是℃单位的话，那么还要自己转换温标。

![20210809-31-QFlux设置收敛条件.png](./images/20210809-31-QFlux设置收敛条件.png)

设置收敛条件，动量方程、能量方程、连续性方程及湍流粘度方程收敛判断公差均设置为`1.0e-6`。

![20210809-32-QFlux设置计算条件.png](./images/20210809-32-QFlux设置计算条件.png)

设置计算条件，计算最大步数1000步，可以设置并行核数，可以看到QFlux的Windows版下MPI库用的是Microsoft MPI库，这点和OpenFOAM的Windows版出奇地一致。计算调用的是qcore.exe程序。

![20210809-33-QFlux计算收敛曲线.png](./images/20210809-33-QFlux计算收敛曲线.png)

可以看到计算385步左右收敛，但当鼠标停留在收敛曲线上时，标签数字只能显示到小数点后面四位数，而且还不能用科学记数法显示标签数字。

![20210809-34-QFlux温度云图显示.png](./images/20210809-34-QFlux温度云图显示.png)

上图是QFlux计算结果输出的温度云图。

![20210809-35-OpenFOAM计算的温度云图.png](./images/20210809-35-OpenFOAM计算的温度云图.png)

上图是相同案例OpenFOAM计算结果输出的温度云图，相同的案例可以通过`simpleFoam`+`scalarTransportFoam`或者`buoyantSimpleFoam`实现。可以看到两者计算结果较为相似。

## 4. QFlux求解器与OpenFOAM的对比

![20210809-36-QFlux与OpenFOAM文件对比.png](./images/20210809-36-QFlux与OpenFOAM文件对比.png)

对比QFlux与OpenFOAM(v2012)的动态链接库文件，不难发现，两者在主要文件结构和命名方式上有不少相似之处。

![20210809-37-QFlux与OpenFOAM的dll对比.png](./images/20210809-37-QFlux与OpenFOAM的dll对比.png)

用"Dependency Walker"查看两者引用动态链接库文件的函数命名，可以发现在一些关键的链接库中，内部函数命名方式不敢说一模一样，只能说高度相似。

由于OpenFOAM是开源软件，源代码网上都可以下载得到，很难说QFlux没有“借鉴”OpenFOAM源代码。至于“借鉴”了多少内容，则又很难说得清了。

鉴于国内CFD等工业软件无比孱弱的现状，相比于自主开发，在开源平台上快速包装出易用的软件平台似乎更容易受到软件开发者和投资者的欢迎。对比OpenFOAM和QFlux两者功能实现、开发程度以及代码量的不同，OpenFOAM程序大小、代码量还有成熟度是要远远高于QFlux的。其实在OpenFOAM平台上开发相关界面、引入流程控制一直是业界研究的重点，国内外有不少公司都是围绕着OpenFOAM进行相关应用及二次开发。但是一边“借鉴”开源程序，一边宣称完全”自主开发“的，可能除了国内的互联网公司外都做不出来了，当然这其中”十沣科技“算是一个。

其实对于OpenFOAM等开源平台来说，交流和创新是最重要的，新方法的实现远比工业化的包装以及简单易用重要的多，这也是OpenFOAM这么多年来坚持文本和命令行参数控制的原因之一。比”借鉴“本身更可怕的是麻木和惰性，当我们用惯了开源平台，只知道一味索取而不知道反哺，只知道重构别人家的代码而不知道从底层进行构建和完善，知其然而不知其所以然……当有一天失去了开源平台之后，我们还有没有办法坚持所谓的”自主开发“呢？

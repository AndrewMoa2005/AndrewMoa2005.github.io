---
layout:     post
title:      "使用VSCode调试STAR-CCM+宏"
description: ""
excerpt: ""
date:    2025-04-18
author:  "Andrew Moa"
image: ""
publishDate: 2025-04-18
tags:
    - java 
    - star-ccm+
URL: "/2025/04/18/vscode-debug-starccm-java-marco/"
categories: [ "CFD" ]    
---

前面讲过STAR-CCM+宏文件的录制和编写，宏文件的本质就是java文件，因此可以用java编程的方法来对它进行开发和调试。如果涉及到复杂的业务场景，需要增加额外的功能，程序本身比较复杂，很难等到整个程序编写完成后再对它进行测试，免不了要在开发过程中进行调试。官方文档采用的开发工具是古早版本的**NetBeans**，很多功能已经发生变化，加之官方文档描述过于简略，大多数人阅读完后对于STAR-CCM+的调试过程还是一头雾水。[**VSCode**](https://code.visualstudio.com/)作为新兴IDE的佼佼者，不仅可以通过拓展支持java编程，还可以通过[**copilot**](https://copilot.microsoft.com/chats/Uz4t8yZbNmpyo1CVtqKWP)拓展集成强大的AI编程能力，本文便采用**VSCode**演示一下STAR-CCM+宏文件的调试过程。

## 1. VSCode配置

首先要在VSCode中安装支持java的拓展，至少要安装下面几个：
 1. [Language Support for Java(TM) by Red Hat](https://marketplace.visualstudio.com/items?itemName=redhat.java)
 2. [Debugger for Java](https://marketplace.visualstudio.com/items?itemName=vscjava.vscode-java-debug)
 3. [Project Manager for Java](https://marketplace.visualstudio.com/items/?itemName=vscjava.vscode-java-dependency)

也可以直接安装这个拓展包，一次性把所有需要用到的java拓展都装齐了：
[Extension Pack for Java](https://marketplace.visualstudio.com/items/?itemName=vscjava.vscode-java-pack)

下载一个JDK并安装，如果不想下载JDK的话，也可以在STAR-CCM+安装路径中找到安装包附带的JDK，把它添加到环境变量中。
![53d9d7c07aca055269657c5ccf18a81f.png](/resources/53d9d7c07aca055269657c5ccf18a81f.png)

## 2. 建立java项目

在VSCode命令面板(Ctrl+Shift+P)中输入`Java: Create Java Project`，创建一个新的java项目。
![56a3e9ec89aa1f165d0bbf43818f8843.png](/resources/56a3e9ec89aa1f165d0bbf43818f8843.png)

项目类型选择`No build tools`。
![e3fe06a5c9f45db8e2bb95dd2229afb3.png](/resources/e3fe06a5c9f45db8e2bb95dd2229afb3.png)

在弹出对话框选择项目文件夹位置，然后输入项目名称(例如：starccm)，新建项目完成，可以看到java项目的结构。
![4f796690032a038647929f935871897e.png](/resources/4f796690032a038647929f935871897e.png)

将`[STAR-CCM+_Installation]/star/lib/java/platform/modules/ext`文件夹复制到新建项目的lib文件夹中[^1]。
![6ee3b58e9ea5f952aef77f34dccd5a18.png](/resources/6ee3b58e9ea5f952aef77f34dccd5a18.png)

将之前录制或编写的java宏复制到项目生成的java文件中，可以看到语法检查和代码高亮提示已经生效了，这时候修改代码就能通过自动完成补充代码片段，也可以通过“Ctrl+I”调用copilot自动填写和纠正代码错误。
![de9b21474ee4bb138a6ada6e449eefb9.png](/resources/de9b21474ee4bb138a6ada6e449eefb9.png)

## 3. 配置调试

在项目文件夹的`.vscode`目录下修改`launch.json`文件，编辑代码如下。
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "type": "java",
            "name": "Debug (Attach)",
            "projectName": "starccm",
            "request": "attach",
            "hostName": "localhost",
            "port": 8765
        }
    ]
}
```

如果`.vscode`下面没有`launch.json`这个文件，可以点击VSCode左侧的`运行与调试`按钮，根据提示生成该文件，然后按照上面的内容进行编辑。
![fe42c7df2354ce038014d8fab7610fd6.png](/resources/fe42c7df2354ce038014d8fab7610fd6.png)

通过命令行方式启动STAR-CCM+主程序，注意要在`starccm+`后面附加启动参数，`address`后面的端口号要与上面`launch.json`文件中填写的端口号一致。
```bash
<InstallationDirectory>/star/bin/starccm+ -jvmargs '-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8765'
```
![9d3195c2a43a1987c82be84179648cd9.png](/resources/9d3195c2a43a1987c82be84179648cd9.png)

上面配置完成之后，接下来就可以在STAR-CCM+中正常打开或者新建sim文件，用于测试我们编写的java程序。

接着点击VSCode左侧的`运行与调试`按钮，进入调试模式。成功进入调试模式后，会在调式页面中显示调用的堆栈和断点信息。
![77e492c6e2f6b2b11616ee8b5074332d.png](/resources/77e492c6e2f6b2b11616ee8b5074332d.png)

如果进入调试模式失败，会弹出对话框提醒。需要确认STAR-CCM+有没有正常启动、有没有附加启动参数，以及`launch.json`文件编写有没有错误。
![d917ee07dd6acd9fb56eaa4168bed927.png](/resources/d917ee07dd6acd9fb56eaa4168bed927.png)

## 4. 调试过程

下面编写一个简单的java文件，用于演示调试过程。
```java
// 下面这一行是录制时自动生成的，没什么作用，可以注释掉。
// package macro;

import star.common.*;

public class testCCMDebug extends StarMacro {

  // 宏操作入口
  public void execute() {
    pringMsg();
  }

  // 演示打印消息的函数
  private void pringMsg() {
    Simulation simulation_0 = getActiveSimulation();
    simulation_0.println("Hello, starccm+!");
    simulation_0.println("This is a macro example.");
    simulation_0.println("This macro is used to test STAR-CCM+ debug mode.");
    String fileName = simulation_0.getPresentationName() + ".sim";
    simulation_0.println("The simulation file name is: " + fileName);
  }

}

```

然后在其中加入断点。
![41ef0c76c1932fe320359a8e84dad63f.png](/resources/41ef0c76c1932fe320359a8e84dad63f.png)
![c4a225cbb85bb7496366d8687c44f7ee.png](/resources/c4a225cbb85bb7496366d8687c44f7ee.png)

关键的地方来了[^2]，**一定要在STAR-CCM+中使用“播放宏”加载java文件**。等执行到断点时，会在VSCode中提示中断，这样就可以通过VSCode控制调试的执行进程。
![5aac9b5a398c7733e445025ae69624da.png](/resources/5aac9b5a398c7733e445025ae69624da.png)

最终执行效果：
![9b5db179b2483fe30352d7bb840cfe77.png](/resources/9b5db179b2483fe30352d7bb840cfe77.png)

调试执行到断点，过程中STAR-CCM+会进入暂停状态，这时候点击取消按钮（进度条旁边红色的X）是没有用的。
![ed8fa3bd5401c2c409ca23368d142cc2.png](/resources/ed8fa3bd5401c2c409ca23368d142cc2.png)

VSCode调试执行完成之后，想要再次进入调试，需要在STAR-CCM+中使用"播放宏"重新加载java文件。

---

[^1]: [使用 IDE 调试宏](https://www.topcfd.cn/Ebook/STARCCMP/GUID-C9B469BA-DE86-4824-9094-9207D72099D1.html)

[^2]: [学习STAR-CCM+编程语言：在Eclipse中进行二次开发调试](https://www.jishulink.com/post/1893585)


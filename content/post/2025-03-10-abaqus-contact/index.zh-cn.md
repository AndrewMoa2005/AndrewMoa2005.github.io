+++
author = "Andrew Moa"
title = "Abaqus接触设置"
date = "2025-03-10"
description = ""
tags = [
    "abaqus",
    "ansa",
    "cae",
]
categories = [
    "ansa",
]
series = [""]
aliases = [""]
image = "/images/abaqus-bg.jpg"
+++

## 1. 相关命令
Ansa中，给Abaqus设置接触一般常用以下命令：
![cb35dcf11a636abacef3aabe97112e62.png](./images/cb35dcf11a636abacef3aabe97112e62.png)

## 2. 接触对
最常用的接触对，一般通过`AUXILIARIES`→ `CONTACT`→`CONTACT`调出创建对话框。
![038dffae1f80e68c064572e228df00c6.png](./images/038dffae1f80e68c064572e228df00c6.png)
常用设置一般为以下几个：
1. 定义接触名称，方便检索
2. 定义接触类型为`接触对`(`CONTACT PAIR`)或者`通用接触`(`CONTACT INCLUSIONS`或`CONTACT EXCLUSIONS`)
3. 接触从面，需要预先在`SET`里设置好单元集合
4. 接触主面，需要预先在`SET`里设置好单元集合
5. 接触行为，定义摩擦系数等
6. 接触面调整行为，选择`YES`可以在后面的`POS_TOLER`定义容差数值
7. 接触面是否产生小滑移，默认`NO`
8. 接触类型，默认`surface-to-surface`，或者`node-to-surface`
9. 接触间隙，定义接触的过盈或间隙值

## 3. 通用接触
跟创建接触对共用同一个命令和对话框，只需要把接触类型改为`接触包含面`(`CONTACT INCLUSIONS`)或`接触排除面`(`CONTACT EXCLUSIONS`)即可。
![5ce0bee8d0eaf02a8ec041bb8aa5d791.png](./images/5ce0bee8d0eaf02a8ec041bb8aa5d791.png)

1. 定义接触类型
2. 接触从面，选择`SET`里设置好的单元集合
3. 接触主面，选择`SET`里设置好的单元集合（一般不需要，可以留空）
4. 接触行为

## 4. 绑定接触
通过`AUXILIARIES`→ `CONTACT`→`TIE`调出对话框。
![e354721ca85e003b8683798b2a78cde3.png](./images/e354721ca85e003b8683798b2a78cde3.png)

1. 接触从面，选择`SET`里设置好的单元集合
2. 接触主面，选择`SET`里设置好的单元集合
3. 当两个接触面存在不重合时，可以在这里设置接触容差

## 5.接触向导
Ansa内置的功能，可以通过引导建立接触。通过`AUXILIARIES`→ `CONTACT`→`Assistant`命令调出。
![305cb5999a3ca4c8cffc347b22e893d9.png](./images/305cb5999a3ca4c8cffc347b22e893d9.png)

## 6. 自动创建接触对
通过`AUXILIARIES`→ `CONTACT`→`Flanges`调出。
![7d0af046869e917327ec96591dfd5c6a.png](./images/7d0af046869e917327ec96591dfd5c6a.png)

1. 选择要搜索的对象
2. 定义搜索距离容差

在弹出对话框里面检查、定义接触参数。
![7727dd9b9786726aa43e70e2e4891cee.png](./images/7727dd9b9786726aa43e70e2e4891cee.png)

## 7. 与接触有关的输出设置
一般在`STEP`的`OUTPUT`选项卡里面定义，没有特殊要求的话输出参数选择`PRESELECT`就行了。
![6ce6c753db7bf01666dfe10178b59a0b.png](./images/6ce6c753db7bf01666dfe10178b59a0b.png)

---


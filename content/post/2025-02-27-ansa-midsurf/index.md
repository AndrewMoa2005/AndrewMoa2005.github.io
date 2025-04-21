+++
author = "Andrew Moa"
title = "Extracting mid-face using Ansa"
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

ANSA has several different treatment methods for the extraction of sheet metal parts.

## 1. `Skin` method

`TOPO` → `Mid.Surfa.` → `Skin` , select the entire geometry and then press the middle mouse button without brain to automatically draw the middle face.
![0f525cbbea14aa2904b78e9e80f86f98.png](./images/0f525cbbea14aa2904b78e9e80f86f98.png)

It is suitable for some sheet metal structural parts with relatively uniform thickness, without characteristics such as ribs, bosses, and pits.
![86e9dc3696bc04b9a2811e5e191d2ae8.png](./images/86e9dc3696bc04b9a2811e5e191d2ae8.png)

The extracted middle surface is a geometry without a grid. It requires manual animation of the grid, which will automatically delete the original geometry and add thickness.
![65641a61f8dc0512e7817886b49376ac.png](./images/65641a61f8dc0512e7817886b49376ac.png)

Some extruded parts such as extruded aluminum profiles are also supported, but if there are rounded corners, you must first deal with them, otherwise the mid-side rounded corners will be retained and enlarged.
![943f3baab965a035e5eb414649bfc120.png](./images/943f3baab965a035e5eb414649bfc120.png)
![68c5c4d9c15d8b0aa5963fcc69b65e0a.png](./images/68c5c4d9c15d8b0aa5963fcc69b65e0a.png)

## 2. `Casting/Extrusion` method

There is also a method for pulling the surface for casting and extrusions, `TOPO` → `Mid.Surfa.` → `Casting/Extrusion` 
![ca523b08317e499e8d5b541abc272c63.png](./images/ca523b08317e499e8d5b541abc272c63.png)

First, make sure that the geometry is closed and there are no wrong faces and edges.
![04aff45feacbd435a025c1fa4d939939.png](./images/04aff45feacbd435a025c1fa4d939939.png)

On the pop-up tab, select whether the parts to be drawn on the center surface are cast or extruded, and define the minimum thickness and surface grid size. It is best to define feature hole parameters in the grid parameters before drawing the surface, which is used to generate a washer grid, because after drawing the surface, it is directly a surface grid.
![41aca4cbf0e00ad69276c8e89041a513.png](./images/41aca4cbf0e00ad69276c8e89041a513.png)

The thickness of the final generated mesh is automatically calculated based on the geometry, and there is no need to set the thickness in the PID.
![bd6e4eb9c3a4f72253bdd1c10eb452ad.png](./images/bd6e4eb9c3a4f72253bdd1c10eb452ad.png)

## 3. `Middle Multi.` Hand-processed

Very troublesome, not recommended. However, this method can only be used for some complex structural parts, such as injection molded parts.
![410117bbbf085e19ff33ed0193e0f28f.png](./images/410117bbbf085e19ff33ed0193e0f28f.png)

First, some surfaces coplanar with features such as ribs should be divided according to topology to facilitate subsequent processing.
![33a2206ca7f19d97f0358ba9472d2cbd.png](./images/33a2206ca7f19d97f0358ba9472d2cbd.png)

Mark the front and back of the middle face with red and green, and the blue face is the side.
![7469baf9dcb520788aa5d1389b4f0f99.png](./images/7469baf9dcb520788aa5d1389b4f0f99.png)

The mid-side drawn will be automatically hidden to facilitate processing of the remaining models.
![652f8d7c29cef890403edda839b163f1.png](./images/652f8d7c29cef890403edda839b163f1.png)

## 4. Summary

- `Skin` Method: Simple, suitable for sheet metal parts, generate geometric data, good accuracy
- `Casting/Extrusion` Method: Simple, suitable for casting and extrusion parts, generate grid data, slightly poor accuracy
- `Middle Multi.` Manual processing: cumbersome, but suitable for complex structural parts such as injection molded parts, etc., to generate geometric data, the accuracy varies from person to person

---


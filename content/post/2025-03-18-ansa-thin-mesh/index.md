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

Recently, I often do some cold plate structural analysis, involving thin plate modeling. Although I have tried to use Shell units for analysis, the stress and displacement results of Shell units are larger than those of Solid units, and it is more likely that the calculation will not converge when it comes to contact problems. Fortunately, Ansa provides a way to generate a body mesh by stretching Shell units, which can quickly generate a Solid mesh through Shell units, greatly saving modeling time.

The modeling steps are as follows:
1. Simplify the thin plate entity into a shell and divide the mesh. You can refer to [Extracting mid-face using Ansa](../2025-02-27-ansa-midsurf/).
![5c6da744441c0b43367e9d1ff0296ec1.png](./images/5c6da744441c0b43367e9d1ff0296ec1.png)

2. `Volume Mesh` → `Extrude` to bring up the `Extrude` window and select the Shell unit to be stretched.
![02fe91f7f3a74047ccd442f4eaa42505.png](./images/02fe91f7f3a74047ccd442f4eaa42505.png)

3. Select `None` for the target surface.
![5818d8ffc832684765e7312eafe76ea9.png](./images/5818d8ffc832684765e7312eafe76ea9.png)

4. Select `Offset` for the stretch method and `Both sides (middle)` for the direction.
![d464570c23719e82fcd4d152a9278f8d.png](./images/d464570c23719e82fcd4d152a9278f8d.png)

5. Select the number of layers in `Steps`, input the thickness of the thin plate in `Distance`, it is recommended to select `Smooth` in `Biasing`, and complete it in `Finish`.
![e3b90aaa49545a963c3f998a86a3a036.png](./images/e3b90aaa49545a963c3f998a86a3a036.png)

6. Check the quality of the generated mesh and repair poor mesh.
![242f974310b6eff9061c0c8ce2230673.png](./images/242f974310b6eff9061c0c8ce2230673.png)

Summary: This method is more suitable for generating volume meshes for thin plates with uniform thickness. However, it is not applicable when the thickness of the thin plate is uneven or there are T-type connections (such as plastic parts, ribs, etc., as shown in the figure below).
![0ad79055f8a7a324c278b023ee79be6f.png](./images/0ad79055f8a7a324c278b023ee79be6f.png)

---



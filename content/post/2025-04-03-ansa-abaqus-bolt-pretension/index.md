+++
author = "Andrew Moa"
title = "Ansa combined with Abaqus to analyze bolt preload setting"
date = "2025-04-03"
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

Ansa combined with Abaqus analysis often encounters the problem of applying bolt preload. In addition to the complex settings, it is also easy to make mistakes, and various problems may occur if you are not careful. The following records the Ansa bolt preload setting process and some pitfalls for reference for related analysis later.

## 1. Solid+Assistant 

The connection between the solid bolt and the flange surface must be established first. For details, please refer to [Abaqus contact settings](../2025-03-10-abaqus-contact/)。
![1a56cfc8f6f5583e360bf9bd9ae4de48.png](./images/1a56cfc8f6f5583e360bf9bd9ae4de48.png)

 1. Individual bolts can be set up via the `AUXILIARIES` → `PRTENS` → `Assistant` Assistant.
 ![0529d3a74d53af475e0c91c8f355cb58.png](./images/0529d3a74d53af475e0c91c8f355cb58.png)

 2. In the pop-up wizard, select `Surface - Solid Elements` or `Surface - Solid Property`, then select the bolt entity. Check the `Detect and create all possible pretensions.` below to automatically search for similar entities and create the same pretension.
 ![9d13058ea827e23ce047e9f1b52fde1d.png](./images/9d13058ea827e23ce047e9f1b52fde1d.png)

 3. Next, select the first reference point on the bolt body.
 ![5086d6cd6a8c37ddea9506db6731656b.png](./images/5086d6cd6a8c37ddea9506db6731656b.png)

4. Next, select the second reference point to define the bolt preload direction. A reference plane will be generated at the first reference point. Note that the preload direction must be parallel to the bolt axis.
 ![74336c606e1112ff70556e8a1b845a23.png](./images/74336c606e1112ff70556e8a1b845a23.png)

5. Next, enter the preload force of 50kN and check the box labeled "Fixed". Two "STEP"s will be automatically generated. The first "STEP" is used to load the preload, and the second "STEP" is used to fix the preload. Other loads can be applied to the second "STEP".
 ![62ad85d4eb3da3ebeaf9d6bd74784a32.png](./images/62ad85d4eb3da3ebeaf9d6bd74784a32.png)

6. Finally, define the normal direction of the reference plane to confirm the application of the bolt preload.
 ![64fd2a39cb6d08089a8f3dcb35de2854.png](./images/64fd2a39cb6d08089a8f3dcb35de2854.png)

After completing the above steps, you can submit the calculation.

**Where things can go wrong**：
   
 - If the non-convergence is caused by contact problems, you can add contact control `Contact Control`→`Stabilize` to improve the stability of the solution.
   ![0044bbf908b9542e60878b21e06b0940.png](./images/0044bbf908b9542e60878b21e06b0940.png)

 - If the system still does not converge after adding contact control, it is recommended to replace the contact between the solid bolt and the flange surface with a Coupling constraint.
   ![fa55849b34b2665b973afb52d8cd2e27.png](./images/fa55849b34b2665b973afb52d8cd2e27.png)

 - If the calculation results show that the bolt becomes longer, it is most likely that the normal definition of the reference plane in step 6 is reversed. Simply change the normal direction of the reference plane.
   ![7f6ca35973bffa52ccc6c0f6515c03bf.png](./images/7f6ca35973bffa52ccc6c0f6515c03bf.png)

After the calculation is completed, open it through `Meta` to view the stress distribution state inside the solid bolt.
![3701316cf8a485c6a40358827e2b6e72.png](./images/3701316cf8a485c6a40358827e2b6e72.png)

## 2. Beam+Assistant

When the problem to be studied does not involve the strength of the bolt body, beam elements can be used to replace the bolt entity, which can reduce the amount of calculation, improve calculation efficiency, and avoid the problem of non-convergence of calculation.

 1. For beam elements, you need to create a new beam PID first, define the cross section and material of the bolts, select circular as the cross section, and define the bolt radius.
![aa224c8a201f2492d1a62954df43c008.png](./images/aa224c8a201f2492d1a62954df43c008.png)

 2. It is necessary to create a new beam unit through Beam (it is recommended to first create two coupling constraints through the bolt holes, and then create a new Beam unit through the center of the coupling constraints), and then assign it to the PID above. At this time, the Beam unit has only one section.
![fa2bd5582a7602facfab1a070c3fe110.png](./images/fa2bd5582a7602facfab1a070c3fe110.png)
	 
 3. Then go to `Mesh` and split the Beam unit into multiple segments by inserting points through `Insert`.
![b13884f8e33ae2d9fa054c9d7de1381e.png](./images/b13884f8e33ae2d9fa054c9d7de1381e.png)

 4. Next, start the wizard, select `Beam Elements`, and select the middle section of the beam unit. If the beam unit was not split in the previous step, you can select the following `Split Beams`, which will automatically split the beam unit into 3 sections and select the middle section.
![b99d2690fa392cb288ae45836ec32635.png](./images/b99d2690fa392cb288ae45836ec32635.png)

 5. Similarly, enter the preload force of 50kN and select the fixed preload state.
![ddf9dd2eac9916853e5878d58293b01a.png](./images/ddf9dd2eac9916853e5878d58293b01a.png)

 6. Confirm creation of preload.
![b48b617fe706fbcd3ab8ab80b3928615.png](./images/b48b617fe706fbcd3ab8ab80b3928615.png)

After completing the above steps, you can submit the calculation.

**Common Mistakes**：

 - `Meta` does not support displaying the stress distribution of beam elements. If you want to view the stress distribution of beam elements, you need to use `Abaqus Viewer` to render the result file.

 - You need to turn on `Render beam profiles` in `View` → `ODB Display Options` to display the status of the beam elements.
![04efaf98e00ea3de3cba47e7ae6ffe9a.png](./images/04efaf98e00ea3de3cba47e7ae6ffe9a.png)

 - To display stresses for beam elements, select `BEAM_STRESS`.
![119d81cf131d6238901f36b8090bd44f.png](./images/119d81cf131d6238901f36b8090bd44f.png)

 - If you want to view the stress distribution state of the beam in the results, it is recommended to select the output of all variables in the `*OUTPUT` keyword, so that `BEAM_STRESS` can be viewed when rendering with `Abaqus Viewer`.
![7858de766a8079b575e43008a3ebb326.png](./images/7858de766a8079b575e43008a3ebb326.png)

## 3. Beam+Connection

For connection settings, please refer to [Ansa Quick Connection](../2025-03-05-ansa-connector/). Bolt preload can also be set through Connection, which is especially suitable for multiple bolt connections, where models need to be replaced frequently or parameters need to be adjusted. Here, the beam element is selected for the bolt body.

The steps to create PID are the same as step 2 in the previous chapter. Select `CBEAM` for `Body Type`, activate `Create Pretension` and enter the pretension value.
![b3ad8f55b683acf6abd709917322dede.png](./images/b3ad8f55b683acf6abd709917322dede.png)

Multiple bolt stress display:
![04a3aa65c393ae2df076591add66570d.png](./images/04a3aa65c393ae2df076591add66570d.png)

## 4. Summary

- `Solid+Assistant `: The bolt body stress result is relatively more accurate, but the calculation is large and it is easy to fail to converge.
- `Beam+Assistant `: The calculation is small and it is easier to converge, but it can only be used when the bolt body strength is not examined.
- `Beam+Connection` : The calculation is small, it is easy to converge, and the change and replacement operations are more convenient. It also cannot directly examine the bolt body strength.

---

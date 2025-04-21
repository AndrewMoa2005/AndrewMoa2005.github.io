+++
author = "Andrew Moa"
title = "Tabby configuration MSYS2"
date = "2025-03-26"
description = ""
categories = [
    "tech",
]
series = [""]
aliases = [""]
image = "/images/code-bg.jpg"
+++


[Tabby](https://tabby.sh/) is a very good-looking terminal tool. I first used it to replace the local terminal, and then I found more and more advantages.
First of all, it has built-in support for SSH connection and SFTP file transfer. The setting operation is simple, avoiding the tedious settings in the Windows terminal. Secondly, it can be used to replace the original Mintty interface of MSYS2 and Cygwin to achieve seamless switching between different terminals.
Regarding how to call MSYS2 in the Tabby terminal, the following is a record of the configuration method:

1. First clone a CMD configuration in Tabby settings:
	![d3078fcb85ac34f312416cd671b2cb58.png](./images/d3078fcb85ac34f312416cd671b2cb58.png)

2. Fill in the name of the MSYS2 toolchain you want to call:
	![462779a7512334158043be9cbd1a265c.png](./images/462779a7512334158043be9cbd1a265c.png)
	Note that you cannot directly assign an ico file to the icon here, as Tabby cannot recognize it. You must convert the ico icon to svg format.
	There are many online ico2svg conversion resources, and you can find a lot of them by searching online:
	 - [ACCONVERT - ICO to SVG](https://www.aconvert.com/cn/image/ico-to-svg/)
	 - [CDKM - ICO to SVG](https://cdkm.com/cn/ico-to-svg)
	 - [FreeConvert - ICO to SVG](https://www.freeconvert.com/zh/ico-to-svg)
	   
	After the conversion is complete, download the svg file, open it with a text tool, copy and paste the svg source code into the icon bar above, and Tabby will be able to display the icon normally.

	```svg
	<?xml version="1.0" encoding="UTF-8" standalone="no"?>
	<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
	<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="16px" height="16px" viewBox="0 0 16 16" enable-background="new 0 0 16 16" xml:space="preserve">  <image id="image0" width="16" height="16" x="0" y="0"
	    xlink:href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAIGNIUk0AAHomAACAhAAA+gAAAIDo
	AAB1MAAA6mAAADqYAAAXcJy6UTwAAADPUExURb5kPsBpRdWbgtSZgL9lQMBoQ8+McMyEZsJuS/36
	+P///9uplL5lP+3UyevOws2HafDc1NCPdOjHuejIur9mQO3TyeXCs8NxTv37+vv18sh7W8h8XP/+
	/uS+rt2umtOXfuXBsvfs6Pjv6+bDtMFqRvny7vHf1/36+dyrlvXn4e/a0dadhMBpRP79/f7+/fz4
	9sJuSvHe1vnw7PPi2+O9rNqmkN2tmeC2pP78+8Z3Vfft6L9mQfz59+fFt8JtSdKVe79nQsuDZcV0
	UtGSd8NvTFLhcR8AAAABYktHRApo0PRWAAAAB3RJTUUH6QMaAysVnHCKGgAAAJpJREFUGNONj1cS
	ggAUA2NBIdi7WAErYEFFBRXr/c8k7QC8n8zuRyYPSHWZbC4fhFAoJkKUKAOlMiuJqJI1oE42EtEk
	pRbaZCfmbq9PKoMhOYrFmDI5maoa9Yhn84VC6svVmkYkZJrWhtvd3qYkBmwdNAFH8hR2O4FweAYu
	vLowSc/CzbMtwL0/gqUGVR/+8xUWvT/h9u8vxaN/UKUNLao7WagAAAAldEVYdGRhdGU6Y3JlYXRl
	ADIwMjUtMDMtMjZUMDM6NDM6MjArMDA6MDDH702KAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTAz
	LTI2VDAzOjQzOjIwKzAwOjAwtrL1NgAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNS0wMy0yNlQw
	Mzo0MzoyMSswMDowMEfQ310AAAAASUVORK5CYII=" />
	</svg>
	```
	isable dynamic tab title: Set according to your needs, it is recommended to select it.
	Group: You need to create a new profile group first, and then select it here.

3. The execution commands, parameters, and environment variables are shown in the figure.
	![3d0df91731d21b5ff1106c8dcdb927ff.png](./images/3d0df91731d21b5ff1106c8dcdb927ff.png)
	Fill in the HOME directory of MSYS2 in the working directory and HOME directory, and fill in the tool chain to be called in MSYSTEM.

4. After saving in step 3 above, you can quickly call the Clang64 terminal of MSYS2 through the icon in the Tabby title bar. Other tool chains are configured in the same way.
	![1b2105682c9dbbeb3e58d7bc9fb5d6ca.png](./images/1b2105682c9dbbeb3e58d7bc9fb5d6ca.png)

---
   

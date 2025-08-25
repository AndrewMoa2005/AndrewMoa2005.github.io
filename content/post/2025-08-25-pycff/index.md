+++
author = "Andrew Moa"
title = "PyCFF - a Python-based curve fitting tool"
date = "2025-08-25"
description = ""
tags = [
    "python",
    "qt",

]
categories = [
    "code",
]
series = [""]
aliases = [""]
image = "/images/code-bg.jpg"
+++

Lately, I've frequently encountered situations in my work where I need to fit function curves to scattered data. Typical examples include fitting porous media parameters using the pressure drop of a heat exchanger and fitting polynomial density to a fluid medium. While these tasks can be performed using Excel, Origin, and other tools, they are cumbersome and support limited function types. Here, I've developed a simple toolkit in Python that implements function fitting using numpy and scipy. The user interface is written in PySide, allowing for the entire process from input data to output fitting function parameters. The tool also supports data prediction and custom functions.

## 1. Introduction

Repository：[PyCFF](https://github.com/AndrewMoa2005/PyCFF/)

### 1.1 User Interface

Below is the software's startup interface. The software interface is implemented using PySide (Qt). It supports function drawing, allowing users to customize drawing content and save output images.
![c6219195050ac1b0866829f371239172.png](./images/c6219195050ac1b0866829f371239172.png)

The image below shows the software's input interface. Input data is presented in a table format, and users select the independent variable (x) and dependent variable (y) to be fitted by specifying columns. Users can enter data manually in the table, paste data from spreadsheet software like Excel, and quickly enter large amounts of data using the **Paste Replace Columns** feature.
![1dbefea8b95c2677587b4f885c9df838.png](./images/1dbefea8b95c2677587b4f885c9df838.png)

The image below shows the software's output interface. The software pre-defines some common functions. Clicking an operation displays the function parameters in the table on the left and the complete function expression in the text box. Users can customize the precision of the output parameters and whether to use scientific notation. The default setting is scientific notation with six decimal places, which meets the needs of most engineering calculations.
![98ecd6a60f59bed8a70596750a11fd4d.png](./images/98ecd6a60f59bed8a70596750a11fd4d.png)

### 1.2 Custom Functions

The software includes predefined functions such as polynomials, exponentials, logarithms, and power functions. In addition to these predefined functions, the software also supports user-defined functions. Custom functions such as `a+b*x**1+c*x**2` and `-omega-alpha * exp(x)` automatically extract their parameters and fit them to the input data. Custom functions support not only the four arithmetic operations (+, -, *, /) and power operations (** or ^), but also common functions. See the table below for specific functions and their descriptions.
![cc51005d3b909b23abebc855fbc2e641.png](./images/cc51005d3b909b23abebc855fbc2e641.png)


| Function | Usage | Description |
|---|---|---|
| exp | exp(a) | Calculates the exponential value of a |
| pow | pow(a, b) | Calculates a raised to the power of b |
| abs | abs(a) | Calculates the absolute value of a |
| sqrt | sqrt(a) | Calculates the square root of a |
| cbrt | cbrt(a) | Calculates the cube root of a |
| log | log(a) | Calculates the base e logarithm of a |
| log10 | log10(a) | Calculates the base 10 logarithm of a |
| log2 | log2(a) | Calculates the base 2 logarithm of a |
| min | min(a) | Calculates the minimum value of a |
| max | max(a) | Calculates the maximum value of a |
| sin | sin(a) | Calculates the sine of a |
| cos | cos(a) | Find the cosine of a |
| tan | tan(a) | Find the tangent of a |
| asin | asin(a) | Find the inverse sine of a |
| acos | acos(a) | Find the inverse cosine of a |
| atan | atan(a) | Find the inverse tangent of a |
| sinh | sinh(a) | Find the hyperbolic sine of a |
| cosh | cosh(a) | Find the hyperbolic cosine of a |
| tanh | tanh(a) | Find the hyperbolic tangent of a |
| asinh | asinh(a) | Find the inverse hyperbolic sine of a |
| acosh | acosh(a) | Find the inverse hyperbolic cosine of a |
| atanh | atanh(a) | Find the inverse hyperbolic tangent of a |
| pi | pi() | Pi |
| e | e() | base of natural logarithms |

## 2. Build

### 2.1 Build Environment

The source code provides a `build.py` script for quick and easy building. Users should create a virtual environment before building:
```bash
python -m venv myvenv # myvenv is the name of the virtual environment, which can be defined as needed
```

On Windows, use the following command to activate the virtual environment:
```powershell
./myvenv/Scripts/activate # in windows, it is recommended to run under posershell
```

On Linux, use the following command to activate the virtual environment:
```bash
source ./myvenv/bin/activate # in posix
```

After activating the virtual environment, the `(myvenv)` character will be displayed at the beginning of the command line, indicating that Python under the command line is running in the virtual environment `myvenv`. Install the dependencies using the following command:
```bash
pip install -r requirements.txt
```

After the build is complete, exit the virtual environment by deactivating it:
```bash
deactivate # The same command is used under windows and posix
```

### 2.2 Build Script

Run the following command to display help information for the build script:
```
python build.py -h
```
![c526195ad4f9c0928665d83df792851b.png](./images/c526195ad4f9c0928665d83df792851b.png)

 - The `-h`/`--help` switch displays command-line help.
 - The `-c`/`--copy` switch copies the source code to a specified directory for debugging purposes.
 - The `-b`/`--build` switch runs `pyinstaller` to package the source code into an executable file. `dir` packages the source code into a directory (the default), and `one` packages the source code into a single executable file.
 - The `-u`/`--update` switch compiles `.ui` and `.qrc` files in the source code into `.py` files for debugging purposes.
 - The `-t`/`--translate` switch allows for multi-language translation. `up` updates `.ts` files in the source code, `gui` launches the `linguistgui` interface and opens `.ts` files, and `gen` compiles `.ts` files into `.qm` files. This switch is typically used for debugging purposes only.
 - The `-p`/`--pyd` switch compiles the `.py` file into `.pyd`/`.so`, then runs `pyinstaller` to package it into an executable file. `dir` packages the file into a directory (the default), and `one` packages the file into a single executable file.
 - The `-g`/`--genwhl` switch generates a whl distribution package.

In general, you can quickly build an executable program using the following command:
```bash
python build.py -p
```
The generated executable file/folder is located in the `[source_dir]/build/pycff/dist` directory.

You can quickly build the whl distribution package using the following command:
```bash
python build.py -g
```
The generated whl file is in the `[source_dir]/build/dist` path. You can install the release package through `pip install pycff-{version}-py3-none-{platform}.whl`. After the release package is installed, you can start the main program through `pycff` or `python -m pycff`.

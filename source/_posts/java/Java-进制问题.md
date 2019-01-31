---
title: 十进制-十六进制转换问题
tags: Radix
categories: Java
date: 2019/01/08
---

​	最近在做 `Netty `解析`TCP`协议的时候，遇到了`hexstring`和`string`的转换问题。

# HexString

​	Hex是由对应机器语言码和/或常量数据的十六进制编码数字组成。

# 进制转换

## 十进制转十六进制

```java
String hex = Integer.toHexString(48); // 30
```

## 十六进制转十进制

```java
String num = Integer.valueOf("fafa", 16); //64250
String num = Integer.parseInt("fafa", 16); //64250
```

# 注意事项

​	若十进制数为负数，转换将出现问题。

如`Integer.toHexString(-6)`将输出`fffffa`，此时若进行十六进制转十进制将报`NumberFormatException`，因此此处在转为`Hex`的时候需做如下操作

```
Integer.toHexString(-6 & 0xff);
```


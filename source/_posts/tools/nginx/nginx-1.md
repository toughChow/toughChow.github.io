---
title: nginx入门
tags: nginx
categories: ['工具']
date: 2019/03/14
---
# 简述

​	nginx是一个开源且高性能 可靠的HTTP中间件 代理服务

## 常见的HTTP服务

HTTPD - Apache基金会

IIS - 微软

GWS - Google

# 优点

## IO多路复用

​	多个描述符的I/O操作都能在一个线程内并发交替地顺序完成。这就叫I/O多路复用，这里的`复用`指的是复用同一个线程。

​	IO多路复用的实现方式select poll epoll

### select

- 内核断发送Read请求，在应用端采用select一直遍历列表。select采用线性遍历。

缺点

1. 能够监视文件描述符的数量存在最大限制
2. 线性扫描效率低下

### epoll

- 每当FD就绪，采用系统的回调函数之间将fd放入，效率更高。

- 最大连接无限制
- nginx使用epoll模式

## 轻量级

功能模块少

代码模块化

## cpu亲和(affinity)

### 什么是CPU亲和

​	是一种把CPU核心和Nginx工作进程绑定方式，把每个worker进程固定在一个cpu上执行，减少切换cpu的cache miss，获得更好的性能。

## sendfile

​	传统sendfile中文件将通过内核空间到用户空间传输，而nginx中sendfile文件只需从内核空间传输即可。

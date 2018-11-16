---
title: Hexo-Next小记
tags: hexo
categories: 建站
---
# Hexo简易安装

## 前置条件

`npm install -g hexo-cli`

## 安装hexo

`npm install -g hexo-cli`

# 插件

## 评论系统-Valine

​	Valine是基于[LearnCloud](https://leancloud.cn/)的无后端评论系统,创建一个开发版的应用,点击应用->设置->应用Key

![1542360255995](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\1542360255995.png)

复制App ID 和 App Key到 _config.yml,搜索Valine，将appid和appkey替换，enable设置为true

![1542360529278](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\1542360529278.png)

最后在LearnCloud的设置->安全中心,添加你的网址进去
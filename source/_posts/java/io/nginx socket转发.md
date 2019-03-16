---
title: nginx socket短链接转发
tags: nginx
categories: Java
date: 2019/03/13
---

# 简介

​	在实现物联网过程中，起初设备所有都是往一台服务器发起请求进行直连。随着设备的增多，一台服务器肯定吃不消。于是想着通过nginx做分发。

# 配置

​	nginx配置文件添加如下配置

```nginx
stream {
    # 添加socket转发的代理
    upstream socket_proxy {
        #hash $remote_addr consistent;
        # 转发的目的地址和端口
        
		server 192.168.1.48:9998 weight=5 max_fails=3 fail_timeout=30s;		
		server 192.168.1.214:9998 weight=5 max_fails=3 fail_timeout=30s;
    }

    # 提供转发的服务，即访问localhost:9001，会跳转至代理socket_proxy指定的转发地址
    server {
       listen 9001;
       proxy_connect_timeout 1s;
       proxy_timeout 3s;
       proxy_pass socket_proxy;
    }
}  
```


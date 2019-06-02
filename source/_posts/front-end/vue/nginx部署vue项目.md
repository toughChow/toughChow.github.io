---
title: nginx部署vue
date: 2019/02/21
categories: ['前端']
tags: ['vue','nginx']
comments: true
img:
---
# vue打包

​	使用命令

```node.js
npm run build
```

生成打包文件，生成文件包含一个static文件夹以及一个index.html文件，位于项目的/dist目录下。

# 上传文件

​	此处我将文件上传至 `/data/wwwroot/mobile_school_h5/campus_micro/dm200` 路径下。

# nginx配置

## nginx.conf配置

​	在nginx.conf配置文件中添加

```nginx
include vhost/*.conf;
```

## api.conf文件编写

​	在当前目录下创建 `vhost`文件夹，并在 `vhost`文件夹下创建 `api.conf` 配置文件

```nginx
server
{
	listen 8081;
	server_name 139.196.109.5;
	index index.html index.htm index.php;
	root /data/wwwroot/mobile_school_h5/campus_micro/dm200;
	location / {
		try_files $uri $uri/ @router;
		index index.html;
	}

	location @router {
		rewrite ^.*$ /index.html last;
	}
}
```

​	此处可配置多个端口号，`server_name` 可以设置为IP，`root`为文件的存放路径，一般都在html下新建要给文件夹，存放当前目录。`location`是为了防止404找不到。

## 启动nginx

重新加载`nginx`命令如下：

`/etc/init.d/nginx reload`

启动nginx命令：

`/etc/init.d/nginx restart`

查看nginx启动状态命令:

`/etc/init.d/nginx status`
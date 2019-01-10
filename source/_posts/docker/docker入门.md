---
title: Hello World
tags: docker
categories: skill
date: 2019/01/10
---
# 基础命令

## 获取、创建

```dockerfile
docker pull
docker build
```

## 运行docker容器

```dockerfile
docker run ubuntu echo hello docker
```

其中，`ubuntu`为`image`名字。

```dockerfile
docker run -p 8080:80 -d nginx
```

其中，`-p`端口映射，将nginx的`80`端口映射到本地的`8080`端口；`-d`允许程序直接返回，将`container`作为守护进程来运行。

## 查看本地所有`image`

```dockerfile
docker images
```

## 查看`container`

### 查看正在运行的容器

```dockerfile
docker ps
```

### 查看所有的container

```dockerfile
docker ps -a
```

## 拷贝文件到docker的`container`

```dockerfile
docker cp file 17add7bbc58c:/usr/share/nginx/html
```

其中，`file`要拷贝的文件的，`17add7bbc58c`为`container`的id，`//usr/share/nginx/html`为目标路径。`cp`为host和image之间拷贝文件命令。

## 停止docker

```dockerfile
docker stop 17add7bbc58c
```

其中，`17add7bbc58c`为container的id。

停止docker后，再次启动该容器，将被初始化，因此需要对所做修改进行保存。

### 保存docker更改

```dockerfile
docker commit -m "commit message" 17add7bbc58c
```

其中`commit message`为提交信息，`17add7bbc58c`为容器id。

这样保存，没有image名字和tag。

```dockerfile
docker commit -m "commit message" 17add7bbc58c nginx-fun
```

其中，`nginx-fun`为该images名字。

## 删除

### 删除image

```
docker rmi 17add7bbc58c
```

### 删除container

``` do
 docker rm 17add7bbc58c 17add7bbc58b
```

以上命令为删除id为`17add7bbc58c`和`17add7bbc58c`的container。


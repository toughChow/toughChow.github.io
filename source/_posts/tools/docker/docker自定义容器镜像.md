---
title: Docker 自定义容器镜像
tags: docker
categories: ['工具']
date: 2019/03/08
---
# 将容器变成镜像

## 法一 docker commit

```
docker commit <container> [repo:tag]
```

当我们在制作自己的镜像的时候，会在container中安装一些工具，修改配置，如果不做commit保存起来，那么container停止后再启动，这些更改就消失了。

### 验证例子

1. `docker create --name myjava -it java /bin/bash`
2. `docker start myjava`
3. `docker ps`
4. `docker exec -it d5c89f21f0d3 /bin/bash`
5. 创建一个自己的文件夹
6. `docker commit d5c89f21f0d3 myjava`
7. `docker images`
8. `docker run -it myjava ls`

### 优点

- 最方便 最快速

### 缺点

- 不规范 无法自动化

## 法二 Buildfile

### 语法

```
FROM nimmis/ubuntu:14.04
MAINTAINER nimmis<kjell.havneskold@gmail.com>
ENV DEBIAN_FRONTEND noninteractive
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
RUN apt-get install -y software-properties-common && \
add-apt-repository ppa:openjdk-r/ppa -y && \
apt-get update && \
apt-get install -y --no-intstall-recommends openjdk-8-jre && \
rm -rf /var/lib/apt/lists/*
```

### 创建镜像

```
docker build -t leader/java .
```

其中`leader/java`为命名的名称，`.`为在当前文件夹寻找该文件

### tip

BuildFile中执行的环境并非本系统环境，而是docker环境。

如在文件中添加

```
RUN ./hello.sh #hello.sh 为本系统当前文件夹下一个输出`hello world`的文件
```

这样执行是不会成功的。

需要在文件中添加

```
ADD hello.shh /bin/hello.sh
RUN /bin/hello.sh
```

才可以执行。

### 案例分析

Build过程中

```
RUN curl http://baidu.com
```

无法成功，此时需要在文件中添加

```
ENV http_proxy=http:///xxx
RUN curl http://baidu.com
```

代理后，才可以成功。

# 实战

制作ubuntu+java+tomcat+ssh server镜像

```
FROM ubunntu
MAINTAINER tough<toughchow@gmail.com>
#更新源，安装ssh server
RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe">/etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y openssh-server
RUN mkdir -p /var/run/sshd
#设置root ssh远程登录密码为123456
RUN echo "root:123456"|chpasswd
#添加oracle java7源，一次性安装vim wget curl java7 tomcat7等必备软件
RUN apt-get install python-software-properties
RUN add-apt-repository ppa:webupd8team/java
RUN apt-get update
RUN apt-get install -y vim wget curl oracle-java7-installer tomcat7
#设置JAVA_HOME环境变量
RUN update-alternatives --display java
RUN echo "JAVA_HOME=/usr/lib/jvm/java-7-oracle">>/etc/enviroment
RUN echo "JAVA_HOME=/usr/lib/jvm/java-7-oracle">>/etc/default/tomcat7

#容器需要开放ssh22端口
EXPOSE 22

#容器需要开放Tomcat 8080端口
EXPOSE 8080

#设置Tomcat7初始化运行，SSH终端放服务器作为后台运行
ENTRYPOINT service tomcat7 start && /usr/sbin/sshd -D
```

其中`-y`为自动安装，不需要一直输入yes

---
title: netty入门
tags: netty
categories: http
date: 2019/03/16
---

# 简介

​	在使用Netty开发TimeServer之前，先回顾一下使用NIO进行服务端开发的步骤。

1. 创建`ServerSocketChannel`,配置它为非阻塞模式；
2. 绑定监听，配置TCP参数，例如backlog大小；
3. 创建一个独立的I/O线程，用于轮询多路复用器Selector；
4. 创建Selector，将之前创建的ServerSocketChannel注册到Selector，监听SelectionKey.ACCEPT;
5. 启动I/O线程，在循环体重执行Selector.select()方法，轮询就绪的Channel；
6. 当轮询到了处于就绪状态的Channel时，对其进行判断，如果是OP_ACCEPT状态，说明是新的客户端接入，则调用ServerSocketChannel.accept()方法接受新的客户端；
7. 设置新接入的客户端链路SocketChannel为非阻塞模式，配置其他的一些TCP参数；
8. 将SocketChannel注册到Selector，监听OP_READ操作位；
9. 如果轮询的Channel为OP_READ,则说明SocketChannel中有新的就绪的数据包需要读取，则构建ByteBuffer对象，读取数据包；
10. 如果轮询的Channel为OP_WRITE，说明还有数据没有发送完成，需要继续发送。

# Netty时间服务器服务端

## TimeServer

### 步骤

- 创建线程组

  ```java
  EventLoopGroup bossGroup = new NioEventLoopGroup();
  EventLoopGroup workerGroup = new NioEventLoopGroup();
  ```

  ​	创建两个NioEventLoopGroup实例。`NioEventLoopGroup`是个线程组，它包含了一组NIO线程，专门用于网络时间的处理，实际上他们就是`Reactor`线程组。

  ​	这里创建两个的原因是一个用于服务端接收客户端的连接，另一个用于进行SocketChannel的网络读写。

- ServerBootstraop对象

  ```java
  ServerBootstrap b = new ServerBootstrap();
  ```

  ​	ServerBootstrap对象，是Netty用于启动NIO服务端的辅助启动类，目的是降低服务端的开发复杂度。

  ```java
  b.group(bossGroup, workerGroup)
      .channel(NioServerSocketChannel.class)
  	.option(ChannelOption.SO_BACKLOG, 1024)
      .childHandler(new ChildChannelHandler());
  ```

  ​	这里讲NIO线程组当作入参传递到ServerBootstrap中；

  ​	接着设置创建的Channel为NioServerSocketChannel，它的功能对应于JDK NIO类库中的ServerSocketChannel类;

  ​	然后配置NioServerScoketChannel中的TCP参数；

  ​	最后绑定I/O事件的处理类ChildChannelHandler，它的作用类似于Reactor模式中的Handler类，主要用于处理网络I/O事件，如记录日志、对消息进行编解码等。

- 调用bind方法

  ​	服务端启动辅助类配置完成后，调用它的bind方法绑定监听端口， 随后，调用它的同步阻塞方法sync等待绑定操作完成。完成之后，Netty会返回一个ChannelFuture。它的功能类似于JDK的java.util.concurrent.Future，主要用于异步操作的通知回调。

```java
package com.toughchow.io.netty;

import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelOption;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;

/**
 * Created by toughChow
 * 2019-03-14 11:03
 */
public class TimeServer {

    public void bind(int port) throws Exception {
        /*  配置服务端的NIO线程组
            NioEventLoopGroup是个线程组，它包含了一组NIO线程，专门用于网络时间的处理，实际上就是Reactor线程组
            这里创建两个是一个用于服务端接收客户端的连接，一个用于SocketChannel的网络读写
         */
        EventLoopGroup bossGroup = new NioEventLoopGroup();
        EventLoopGroup workerGroup = new NioEventLoopGroup();
        try {
            // ServerBootstrap是Netty用于启动NIO服务端的辅助启动类，目的是降低服务端的开发复杂度
            ServerBootstrap b = new ServerBootstrap();
            // 将两个NIO线程组当作入参传递到ServerBootstrap中
            b.group(bossGroup, workerGroup)
                    .channel(NioServerSocketChannel.class)// 设置创建的Channel为NioServerChannel（功能对应JDK NIO的ServerSocketChannel）
                    .option(ChannelOption.SO_BACKLOG, 1024) // 配置NioServerSocketChannel的TCP参数
                    .childHandler(new ChildChannelHandler()); // 绑定IO时间的处理类ChildChannelHandler 用于处理网络I/O事件
            // 绑定端口 同步等待成功
            ChannelFuture f = b.bind(port).sync();

            // 等待服务端监听端口关闭
            f.channel().closeFuture().sync();
        } finally {
            // 退出 释放线程池资源
            bossGroup.shutdownGracefully();
            workerGroup.shutdownGracefully();
        }
    }

    private class ChildChannelHandler extends ChannelInitializer<SocketChannel> {

        @Override
        protected void initChannel(SocketChannel arg0) throws Exception {
            arg0.pipeline().addLast(new WithOutConsiderTCPStickyTimeServerHandler());
        }
    }

    public static void main(String[] args) throws Exception {
        int port = 8081;
        new TimeServer().bind(port);
    }
}

```

## TimerServerHandler

​	TimeServerHandler继承自ChannelHandlerAdapter，它用于对网络事件进行读写操作。

​	ChannelHandlerContext的write方法可异步发送应答消息给客户端。

```java
package com.toughchow.io.netty;

import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelHandlerAdapter;
import io.netty.channel.ChannelHandlerContext;

import java.util.Date;

/**
 * Created by toughChow
 * 2019-03-14 13:53
 */
public class TimeServerHandler extends ChannelHandlerAdapter{

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        ByteBuf buf = (ByteBuf) msg; // 将msg转换成Netty的ByteBuf对象
        byte[] req = new byte[buf.readableBytes()];
        buf.readBytes(req);
        String body = new String(req, "UTF-8");
        System.out.println("Time server receive order : " + body);
        String currentTime = "QUERY TIME ORDER".equalsIgnoreCase(body) ? new Date(
                System.currentTimeMillis()).toString() : "BAD ORDER";
        ByteBuf resp = Unpooled.copiedBuffer(currentTime.getBytes());
        ctx.write(resp);
    }

    @Override
    public void channelReadComplete(ChannelHandlerContext ctx) throws Exception {
        ctx.flush(); //将消息发送队列中的消息写入到SocketChannel中发送给对方
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        ctx.close();
    }
}

```

# Netty时间服务器客户端

## TimeClient

​	与服务端不同的是，它的Channel为`NioSocketChannel`，而服务端为`NioServerSocketChannel`,然后为其添加Handler。此处为了简单直接创建匿名内部类，实现initChannel方法，其作用是当创建NioSocketChannel成功后，在进行初始化之时，将它的ChannelHandler设置到ChannelPipeline中，用于处理网络I/O事件。

​	客户端启动辅助类设置完成之后，调用connect方法发起异步连接，然后调用同步方法等待连接成功。

```java
package com.toughchow.io.netty;

import io.netty.bootstrap.Bootstrap;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelOption;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioSocketChannel;

/**
 * Created by toughChow
 * 2019-03-14 14:51
 */
public class TimeClient {

    public void connect(int port, String host) throws Exception {
        //配置客户端NIO线程组
        EventLoopGroup group = new NioEventLoopGroup();
        try {
            Bootstrap b = new Bootstrap();
            b.group(group).channel(NioSocketChannel.class)
                    .option(ChannelOption.TCP_NODELAY, true)
                    .handler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel ch) throws Exception {
                            ch.pipeline().addLast(new WithOutConsiderTCPStickyTimeClientHandler());
                        }
                    });

            // 发起异步连接操作
            ChannelFuture f = b.connect(host, port).sync();

            // 等待客户端链路关闭
            f.channel().closeFuture().sync();
        } finally {
            group.shutdownGracefully();
        }
    }

    public static void main(String[] args) throws Exception {
        int port = 8081;
        new TimeClient().connect(port, "127.0.0.1");
    }
}

```

## TimeClientHandler

​	这里主要方法有channelActive、channelRead和exceptionCaught。

​	当客户端和服务端TCP链路建立成功之后，Netty的NIO线程会调用channelActive方法，发送查询时间的指令给服务端，调用ChannelHandlerCnotect的writeAndFlush方法将请求消息发送给服务端。

​	当服务端返回应答消息时，channelRead方法被调用，从Netty的ByteBuf中读取并打印消息。

```java
package com.toughchow.io.netty;

import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelHandlerAdapter;
import io.netty.channel.ChannelHandlerContext;

import java.util.logging.Logger;

/**
 * Created by toughChow
 * 2019-03-14 14:56
 */
public class TimeClientHandler extends ChannelHandlerAdapter{

    private static final Logger logger =Logger.getLogger(TimeClientHandler.class.getName());

    private final ByteBuf firstMessage;

    public TimeClientHandler() {
        byte[] req = "QUERY TIME ORDER".getBytes();
        firstMessage = Unpooled.buffer(req.length);
        firstMessage.writeBytes(req);
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        logger.warning("Unexpected exception : " + cause.getMessage());
        ctx.close();
    }

    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        ctx.writeAndFlush(firstMessage);
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        ByteBuf buf = (ByteBuf) msg;
        byte[] req = new byte[buf.readableBytes()];
        buf.readBytes(req);
        String body = new String(req, "UTF-8");
        System.out.println("Now is : " + body);
    }
}

```


---
title: TCP粘包和拆包
tags: netty
categories: http
date: 2019/03/16
---

# 简介

​	TCP是个`流`协议，在TCP底层并不了解上层业务数据的具体含义，它会根据TCP缓存区的实际情况进行包的划分。所以在业务上，一个完整的包可能会被TCP拆分成多个包进行发送，也有可能把多个小的包封装成一个大的数据包发送。这就是TCP的粘包`Sticky`和拆包`unpacking in `。

## TCP粘包 拆包发生的原因

1. 应用程序write写入的字节大小大于套接口发送缓冲区大小
2. 进行MSS大小的TCP分段
3. 以太网帧的payload大于MTU进行IP分片

## 异常案例

### 	我们将TimerServerHandler进行改装一下

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
public class WithOutConsiderTCPStickyTimeServerHandler extends ChannelHandlerAdapter{

    private int counter;

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        ByteBuf buf = (ByteBuf) msg; // 将msg转换成Netty的ByteBuf对象
        byte[] req = new byte[buf.readableBytes()];
        buf.readBytes(req);
        String body = new String(req, "UTF-8").substring(0, req.length
            - System.getProperty("line.separator").length());
        System.out.println("Time server receive order : " + body
            + "; the counter is : " + ++counter);
        String currentTime = "QUERY TIME ORDER".equalsIgnoreCase(body) ? new Date(
                System.currentTimeMillis()).toString() : "BAD ORDER";
        currentTime = currentTime + System.getProperty("line.separator");
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

​	按照设计，服务端收到的消息总数应该和客户端发送的消息总数相同，而且请求消息删除回车换行符后应该为“QUERY TIME ORDER”

### 	接下来对客户端Handler改造一下

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
public class WithOutConsiderTCPStickyTimeClientHandler extends ChannelHandlerAdapter {

    private static final Logger logger = Logger
            .getLogger(WithOutConsiderTCPStickyTimeClientHandler.class.getName());

    private int counter;

    private byte[] req;

    public WithOutConsiderTCPStickyTimeClientHandler() {
        req = ("QUERY TIME ORDER" + System.getProperty("line.separator"))
                .getBytes();
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        logger.warning("Unexpected exception : " + cause.getMessage());
        ctx.close();
    }

    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        ByteBuf message = null;
        for (int i = 0; i < 100; i++) {
            message = Unpooled.buffer(req.length);
            message.writeBytes(req);
            ctx.writeAndFlush(message);
        }
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        ByteBuf buf = (ByteBuf) msg;
        byte[] req = new byte[buf.readableBytes()];
        buf.readBytes(req);
        String body = new String(req, "UTF-8");
        System.out.println("Now is : " + body + " ; the counter is : " + ++counter);
    }
}

```

​	这里将循环发送100条消息，每发送一条就刷新一次，保证每条都会被写入Channel中，并每次收到服务端的应答消息之后，就打印一次计数器。

### 	运行结果：

​	客户端和服务端的counter并非想象中的100，此处发生了粘包。

# 利用LineBasedFrameDecoder解决TCP粘包问题

## Server端

### TimeServer

​	在原来的TimeServerHandler之前新增两个解码器`LineBasedFrameDecoder`和`StringDecoder`

```java
arg0.pipeline().addLast(new LineBasedFrameDecoder(1024));
arg0.pipeline().addLast(new StringDecoder());
```

​	源代码如下：

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
import io.netty.handler.codec.LineBasedFrameDecoder;
import io.netty.handler.codec.string.StringDecoder;

/**
 * Created by toughChow
 * 2019-03-14 11:03
 */
public class LineBasedFrameDecoderTimeServer {

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
            arg0.pipeline().addLast(new LineBasedFrameDecoder(1024));
            arg0.pipeline().addLast(new StringDecoder());
            arg0.pipeline().addLast(new LineBaseFrameDecoderTimeServerHandler());
        }
    }

    public static void main(String[] args) throws Exception {
        int port = 8081;
        new LineBasedFrameDecoderTimeServer().bind(port);
    }
}

```

### TimeServerHandler

​	在此handler中，对接收到的msg就是删除回车换行符后的请求消息，不需要额外考虑处理读半包问题，也不需要对请求消息进行编码。

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
public class LineBaseFrameDecoderTimeServerHandler extends ChannelHandlerAdapter{

    private int counter;

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        String body = (String) msg; // 接收到的msg就是删除回车换行符后的请求消息，不需要额外考虑处理读半包问题，也不需要对请求消息进行编码
        System.out.println("Time server receive order : " + body
            + "; the counter is : " + ++counter);
        String currentTime = "QUERY TIME ORDER".equalsIgnoreCase(body) ? new Date(
                System.currentTimeMillis()).toString() : "BAD ORDER";
        currentTime = currentTime + System.getProperty("line.separator");
        ByteBuf resp = Unpooled.copiedBuffer(currentTime.getBytes());
        ctx.writeAndFlush(resp);
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        ctx.close();
    }
}

```

## Client端

客户端更改与Server端一样。

### TimeClient

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
import io.netty.handler.codec.LineBasedFrameDecoder;
import io.netty.handler.codec.string.StringDecoder;

/**
 * Created by toughChow
 * 2019-03-14 14:51
 */
public class LineBasedFrameDecoderTimeClient {

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
                            new LineBasedFrameDecoder(1024);
                            ch.pipeline().addLast(new StringDecoder());
                            ch.pipeline().addLast(new LineBaseFrameDecoderTimeClientHandler());
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
        new LineBasedFrameDecoderTimeClient().connect(port, "127.0.0.1");
    }
}

```

### TimeClientHandler

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
public class LineBaseFrameDecoderTimeClientHandler extends ChannelHandlerAdapter {

    private static final Logger logger = Logger
            .getLogger(LineBaseFrameDecoderTimeClientHandler.class.getName());

    private int counter;

    private byte[] req;

    public LineBaseFrameDecoderTimeClientHandler() {
        req = ("QUERY TIME ORDER" + System.getProperty("line.separator"))
                .getBytes();
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        logger.warning("Unexpected exception : " + cause.getMessage());
        ctx.close();
    }

    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        ByteBuf message = null;
        for (int i = 0; i < 100; i++) {
            message = Unpooled.buffer(req.length);
            message.writeBytes(req);
            ctx.writeAndFlush(message);
        }
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        String body = (String) msg;
        System.out.println("Now is : " + body + " ; the counter is : " + ++counter);
    }
}

```

# 原理分析

​	LineBasedFrameDecoder的工作原理是它依次便利ByteBuf中的可读字节，判断是否有`\n`或者`\r\n`。如果有 就以此位置为结束位置，从可读索引到结束位置区间的字节就组成了一行。它是以换行符为结束标志的解码器，支持携带结束符或者不携带结束符两种解码方式，同时支持配置当行的最大长度。如果连续读取到最大长度后仍然没有发现换行符，就会抛出异常，同时忽略之前读到的异常码流。

​	StringDecoder的功能就是将接收到的对象转换成字符串，然后继续调用后面的handler。LineBasedFrameDecoder+StringDecoder组合就是按行切换的文本解码器，它被设计用来支持TCP的粘包和拆包。
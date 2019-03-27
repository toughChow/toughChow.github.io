---
title: TCP分隔符和定长解码器
tags: netty
categories: http
date: 2019/03/19
---

# 简介

​	TCP上层的协议通过四种方式对消息进行区分

1. 消息长度固定，累计读取到长度总和为定长LEN的报文后，就认为读取到了一个完整的消息；将计数器置位，重新开始读取下一个数据报；
2. 将回车换行符作为消息结束符，如FTP协议，这种方式在文本协议中应用比较广泛；
3. 将特殊的分隔符作为消息的结束标志，回车换行符就是一种特殊的结束分隔符；
4. 通过在消息头中定义长度字段来标识消息的总长度。

# DelimiterBasedFrameDecoder

​	`DelimiterBasedFrameDecoder`可以自动完成以分隔符作为码流结束标识的消息的解码。

## 示例

### `DelimiterBasedFrameDecoderEchoServer`

```java
package com.toughchow.io.netty.echoserver;

import io.netty.bootstrap.ServerBootstrap;
import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelOption;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.handler.codec.DelimiterBasedFrameDecoder;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.logging.LogLevel;
import io.netty.handler.logging.LoggingHandler;

/**
 * Created by toughChow
 * 2019-03-19 19:22
 */
public class DelimiterBasedFrameDecoderEchoServer {
    public void bind(int port) throws Exception {
        EventLoopGroup bossGroup = new NioEventLoopGroup();
        EventLoopGroup workerGroup = new NioEventLoopGroup();
        try {
            ServerBootstrap b = new ServerBootstrap();
            b.group(bossGroup, workerGroup)
                    .channel(NioServerSocketChannel.class)
                    .option(ChannelOption.SO_BACKLOG, 100)
                    .handler(new LoggingHandler(LogLevel.INFO))
                    .childHandler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel ch) throws Exception {
                            ByteBuf delimiter = Unpooled.copiedBuffer("$_".getBytes());
                            ch.pipeline().addLast(new DelimiterBasedFrameDecoder(1024, delimiter));
                            ch.pipeline().addLast(new StringDecoder());
                            ch.pipeline().addLast(new DelimiterBasedFrameDecoderEchoServerHandler());
                        }
                    });

            ChannelFuture f = b.bind(port).sync(); //绑定端口 同步等待成功

            f.channel().closeFuture().sync(); // 等待服务端监听端口关闭
        } finally {
            bossGroup.shutdownGracefully();
            workerGroup.shutdownGracefully();
        }
    }

    public static void main(String[] args) throws Exception {
        int port = 8081;
        new DelimiterBasedFrameDecoderEchoServer().bind(port);
    }
}

```

此处使用`$_`作为分隔符，并创建`DelimiterBasedFrameDecoder`对象，将其加入到`ChannelPipline`，`DelimiterBasedFrameDecoder`有多个构造方法，这里我们传递两个参数：第一个1024表示单条消息的最大长度，当达到该长度仍未找到分隔符，则报`TooLongFrameException`。第二个对象就是分隔符缓冲对象。

```java
ByteBuf delimiter = Unpooled.copiedBuffer("$_".getBytes())；
ch.pipeline().addLast(new DelimiterBasedFrameDecoder(1024, delimiter));
```

### `DelimiterBasedFrameDecoderEchoServerHandler`

```java
package com.toughchow.io.netty.echoserver;

import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelHandlerAdapter;
import io.netty.channel.ChannelHandlerContext;

/**
 * Created by toughChow
 * 2019-03-19 19:54
 */
public class DelimiterBasedFrameDecoderEchoServerHandler extends ChannelHandlerAdapter{

    int counter = 0;

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        cause.printStackTrace();
        ctx.close();
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        String body = (String) msg;
        System.out.println("This is " + ++counter + " times receive client : [" + body + " ]");
        body += "$_";
        ByteBuf echo = Unpooled.copiedBuffer(body.getBytes());
        ctx.writeAndFlush(echo);
    }
}

```

​	由于我们设置`DelimiterBasedFrameDecoder`过滤掉了`$_`，所以在回复客户端的时候，需要加上`$_`，最后创建`ByteBuf`，将原始消息重新返回给客户端。

### `DelimiterBasedFrameDecoderEchoClient`

```java
package com.toughchow.io.netty.echoserver;

import io.netty.bootstrap.Bootstrap;
import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelOption;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioSocketChannel;
import io.netty.handler.codec.DelimiterBasedFrameDecoder;
import io.netty.handler.codec.string.StringDecoder;

/**
 * Created by toughChow
 * 2019-03-19 19:22
 */
public class DelimiterBasedFrameDecoderEchoClient {
    public void connect(String host, int port) throws Exception {
        EventLoopGroup group = new NioEventLoopGroup();
        try {
            Bootstrap b = new Bootstrap();
            b.group(group)
                    .channel(NioSocketChannel.class)
                    .option(ChannelOption.TCP_NODELAY, true)
                    .handler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel ch) throws Exception {
                            ByteBuf delimiter = Unpooled.copiedBuffer("$_".getBytes());
                            ch.pipeline().addLast(new DelimiterBasedFrameDecoder(1024, delimiter));
                            ch.pipeline().addLast(new StringDecoder());
                            ch.pipeline().addLast(new DelimiterBasedFrameDecoderEchoClientHandler());
                        }
                    });

            ChannelFuture f = b.connect(host,port).sync(); //绑定端口 同步等待成功

            f.channel().closeFuture().sync(); // 等待服务端监听端口关闭
        } finally {
            group.shutdownGracefully();
        }
    }

    public static void main(String[] args) throws Exception {
        int port = 8081;
        new DelimiterBasedFrameDecoderEchoClient().connect("127.0.0.1", port);
    }
}

```

### `DelimiterBasedFrameDecoderEchoClientHandler`

```java
package com.toughchow.io.netty.echoserver;

import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelHandlerAdapter;
import io.netty.channel.ChannelHandlerContext;

/**
 * Created by toughChow
 * 2019-03-19 20:02
 */
public class DelimiterBasedFrameDecoderEchoClientHandler extends ChannelHandlerAdapter{

    static final String ECHO_REQ = "Hello ToughChow.$_";

    int counter = 0;

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        ctx.close();
    }

    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        for (int i = 0; i < 10 ; i++) {
            ctx.writeAndFlush(Unpooled.copiedBuffer(ECHO_REQ.getBytes()));

        }
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        System.out.println("This is " + ++counter + " times receive server : [" + msg + " ]");
    }

    @Override
    public void channelReadComplete(ChannelHandlerContext ctx) throws Exception {
        ctx.flush();
    }
}

```



# FixedLengthFrameDecoder

## 示例

### `FixedLengthFrameDecoderEchoServer`

```java
package com.toughchow.io.netty.echoserver;

import io.netty.bootstrap.ServerBootstrap;
import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelOption;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.handler.codec.DelimiterBasedFrameDecoder;
import io.netty.handler.codec.FixedLengthFrameDecoder;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.logging.LogLevel;
import io.netty.handler.logging.LoggingHandler;

/**
 * Created by toughChow
 * 2019-03-19 19:22
 */
public class FixedLengthFrameDecoderEchoServer {
    public void bind(int port) throws Exception {
        EventLoopGroup bossGroup = new NioEventLoopGroup();
        EventLoopGroup workerGroup = new NioEventLoopGroup();
        try {
            ServerBootstrap b = new ServerBootstrap();
            b.group(bossGroup, workerGroup)
                    .channel(NioServerSocketChannel.class)
                    .option(ChannelOption.SO_BACKLOG, 100)
                    .handler(new LoggingHandler(LogLevel.INFO))
                    .childHandler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel ch) throws Exception {
                            ch.pipeline().addLast(new FixedLengthFrameDecoder(20));
                            ch.pipeline().addLast(new StringDecoder());
                            ch.pipeline().addLast(new FixedLengthFrameDecoderEchoServerHandler());
                        }
                    });

            ChannelFuture f = b.bind(port).sync(); //绑定端口 同步等待成功

            f.channel().closeFuture().sync(); // 等待服务端监听端口关闭
        } finally {
            bossGroup.shutdownGracefully();
            workerGroup.shutdownGracefully();
        }
    }

    public static void main(String[] args) throws Exception {
        int port = 8081;
        new FixedLengthFrameDecoderEchoServer().bind(port);
    }
}

```

### `FixedLengthFrameDecoderEchoServerHandler`

```java
package com.toughchow.io.netty.echoserver;

import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelHandlerAdapter;
import io.netty.channel.ChannelHandlerContext;

/**
 * Created by toughChow
 * 2019-03-19 19:54
 */
public class FixedLengthFrameDecoderEchoServerHandler extends ChannelHandlerAdapter{

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        cause.printStackTrace();
        ctx.close();
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        System.out.println("Receive client : [" + msg + " ]");
    }
}

```

# 总结

​	`DelimiterBasedFrameDecoder`用于对使用分隔符结尾的消息进行自动解码，`FixedLengthDecoder`用于对固定长度的消息进行自动解码。

​	在一般情况下，只需将`DelimiterBasedFrameDecoder`或`FixedLengthDecoder`添加到对应`ChannelPipeline`的起始位即可。
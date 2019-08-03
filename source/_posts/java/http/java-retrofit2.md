---
title: Retrofit2调用远程接口
tags: http
categories: ['后端','Java']
date: 2019/03/08
---

# Retrofit2调用远程接口

## 前言

调用远程接口其中一种实现便是以retrofit2的方式实现，以下笔记备注一下实现步骤。

## 准备工作

### pom文件引入

使用`retrofit2`需要在`pom.xml`引入相关依赖

```xml
<dependency>
    <groupId>com.google.code.gson</groupId>
    <artifactId>gson</artifactId>
</dependency>
<dependency>
    <groupId>com.squareup.okhttp3</groupId>
    <artifactId>okhttp</artifactId>
    <version>3.8.1</version>
</dependency>
<dependency>
    <groupId>com.squareup.okhttp3</groupId>
    <artifactId>logging-interceptor</artifactId>
    <version>3.8.1</version>
</dependency>
<dependency>
    <groupId>com.squareup.retrofit2</groupId>
    <artifactId>retrofit</artifactId>
    <version>2.3.0</version>
</dependency>
<dependency>
    <groupId>com.squareup.retrofit2</groupId>
    <artifactId>converter-gson</artifactId>
    <version>2.3.0</version>
</dependency>
<dependency>
    <groupId>org.apache.httpcomponents</groupId>
    <artifactId>httpclient</artifactId>
    <version>4.5.2</version>
</dependency>
```

### 工具类编写

这里我们需要一个`HttpProxy`工具类

```java
package com.viroyal.common.http;

import okhttp3.OkHttpClient;
import okhttp3.ResponseBody;
import okhttp3.internal.platform.Platform;
import okhttp3.logging.HttpLoggingInterceptor;
import org.slf4j.LoggerFactory;
import retrofit2.Converter;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

import javax.net.ssl.SSLSocketFactory;
import java.lang.annotation.Annotation;
import java.lang.reflect.Type;
import java.util.HashMap;
import java.util.Map;

public class HttpProxy {
    private static org.slf4j.Logger logger = LoggerFactory.getLogger(HttpProxy.class);

    public static final HttpProxy INSTANCE = new HttpProxy();
    private static Map<Class<?>, Object> HTTP_PROXIES_MAP = new HashMap<>();
    private static Map<Class<?>, Object> HTTPS_PROXIES_MAP = new HashMap<>();

    /**
     * @param clazz
     * @param host
     * @param <T>
     * @return
     */
    public synchronized <T> Object getApiProxy(Class<T> clazz, String host) {
        if (HTTP_PROXIES_MAP.containsKey(clazz)) {
            return HTTP_PROXIES_MAP.get(clazz);
        }

        HttpLoggingInterceptor logInterceptor = new HttpLoggingInterceptor((String s) -> {
        });
        logInterceptor.setLevel(HttpLoggingInterceptor.Level.BODY);
        OkHttpClient okHttpClient = new OkHttpClient.Builder().addInterceptor(logInterceptor).build();
        Retrofit retrofitUser = new Retrofit.Builder()
                .baseUrl(host)
                .client(okHttpClient)
                .addConverterFactory(new EmptyBodyConverterFactory())
                .addConverterFactory(GsonConverterFactory.create())
                .build();
        Object apiProxy = retrofitUser.create(clazz);
        HTTP_PROXIES_MAP.put(clazz, apiProxy);
        return apiProxy;
    }

    /**
     * @param clazz
     * @param host
     * @param sslSocketFactory
     * @param <T>
     * @return
     */
    public synchronized <T> Object getApiProxy(
            Class<T> clazz,
            String host,
            SSLSocketFactory sslSocketFactory) {
        if (HTTPS_PROXIES_MAP.containsKey(clazz)) {
            return HTTPS_PROXIES_MAP.get(clazz);
        }

        HttpLoggingInterceptor logInterceptor = new HttpLoggingInterceptor((String s) -> {
        });
        logInterceptor.setLevel(HttpLoggingInterceptor.Level.BODY);
        OkHttpClient okHttpClient = new OkHttpClient.Builder()
                .addInterceptor(logInterceptor)
                .sslSocketFactory(sslSocketFactory, Platform.get().trustManager(sslSocketFactory))
                .hostnameVerifier((String, SSLSession) -> {
                    logger.debug("ssl hostname verifier with host: {}", host);
                    return true;
                }).build();

        Retrofit retrofitUser = new Retrofit.Builder()
                .baseUrl(host)
                .client(okHttpClient)
                .addConverterFactory(new EmptyBodyConverterFactory())
                .addConverterFactory(GsonConverterFactory.create())
                .build();

        Object apiProxy = retrofitUser.create(clazz);
        HTTPS_PROXIES_MAP.put(clazz, apiProxy);
        return apiProxy;
    }

    class EmptyBodyConverterFactory extends Converter.Factory {
        @Override
        public Converter<ResponseBody, ?> responseBodyConverter(Type type, Annotation[] annotations, Retrofit retrofit) {
            return (ResponseBody body) -> {
                if (body.contentLength() == 0) return null;
                return retrofit.nextResponseBodyConverter(this, type, annotations).convert(body);
            };
        }
    }
}
```

## 接口声明

把需要引用的接口`api`完成，其中除了`@POST`还包括`@GET`等注解。

```java
package com.viroyal.user.command;

import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.Header;
import retrofit2.http.POST;

public interface ApiCommand {

    @POST("/unified/message/v1/msg/deliver")
    Call<Object> command(@Header(value = "auth_key") String appKey,
                         @Header(value = "auth_secret") String authSecret,
                         @Header(value = "app_id") String appId,
                         @Header(value = "mdc_value") String mdcValue,
                         @Body Object obj);
}
```

# http实现

此处，由于`host`为http请求，所以不需要`SSLSocketFactory`(`https`跳过安全验证的工厂)

```java
package com.viroyal.user.command;

import com.google.gson.Gson;
import com.viroyal.common.http.HttpProxy;
import com.viroyal.common.pojo.ExtraResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import retrofit2.Response;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * Created by toughChow
 * 2019-03-08 14:36
 */
@Component
public class MessageDeliverCommand {

    Logger logger = LoggerFactory.getLogger(this.getClass());

    @Value("${msg_host}")
    protected String msgHost;
    @Value("${auth_key}")
    protected String authKey;
    @Value("${auth_secret}")
    protected String authSecret;
    @Value("${app_id}")
    protected String appId;
    @Value("${mdc_value}")
    protected String mdcValue;

    public Object smokeSensorNotification(String phone, String position, String imei) throws IOException {
        Map map = new HashMap();
        map.put("type", 0);
        map.put("action", "smoker_sensor");
        map.put("mobile", phone);
        map.put("param", position + "," + imei);
        logger.info("Smoke sensor: post cmd with body : {}", new Gson().toJson(map));
        ApiCommand apiCommand = (ApiCommand) HttpProxy.INSTANCE.getApiProxy(ApiCommand.class, msgHost);
        Response<Object> response = apiCommand.command(authKey, authSecret, appId, mdcValue, map).execute();
        if (response.errorBody() != null) {
            String result = response.errorBody().string();
            logger.error("Smoke sensor response: {}", result);
            return com.viroyal.common.pojo.Response.SYSTEM_BUSY;
        }
        return new ExtraResponse(response.body());
    }
}
```

# https实现

若`host`为`https`则需要注入`javax.net.ssl.SSLSocketFactory`

```java
package com.viroyal.user.command;

import com.google.gson.Gson;
import com.viroyal.common.http.HttpProxy;
import com.viroyal.common.pojo.ExtraResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import retrofit2.Response;

import javax.net.ssl.SSLSocketFactory
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * Created by toughChow
 * 2019-03-08 14:36
 */
@Component
public class MessageDeliverCommand {

    Logger logger = LoggerFactory.getLogger(this.getClass());

    @Value("${msg_host}")
    protected String msgHost;
    @Value("${auth_key}")
    protected String authKey;
    @Value("${auth_secret}")
    protected String authSecret;
    @Value("${app_id}")
    protected String appId;
    @Value("${mdc_value}")
    protected String mdcValue;
    @Autowired
    private SSLSocketFactory sslSocketFactory;

    public Object smokeSensorNotification(String phone, String position, String imei) throws IOException {
        Map map = new HashMap();
        map.put("type", 0);
        map.put("action", "smoker_sensor");
        map.put("mobile", phone);
        map.put("param", position + "," + imei);
        logger.info("Smoke sensor: post cmd with body : {}", new Gson().toJson(map));
        ApiCommand apiCommand = (ApiCommand) HttpProxy.INSTANCE.getApiProxy(ApiCommand.class, msgHost, sslSocketFactory);
        Response<Object> response = apiCommand.command(authKey, authSecret, appId, mdcValue, map).execute();
        if (response.errorBody() != null) {
            String result = response.errorBody().string();
            logger.error("Smoke sensor response: {}", result);
            return com.viroyal.common.pojo.Response.SYSTEM_BUSY;
        }
        return new ExtraResponse(response.body());
    }
}
```


---
title: MockMvc测试
tags: junit
categories: Java
date: 2019/03/08
---

# SpringBoot MockMvc Junit4进行单元测试

## 前言

使用SpringBoot MockMvc测试是快速测试的一种手段，需要在`pom.xml`文件中加入依赖

```xml
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-test</artifactId>
</dependency>
```

在测试类中加入如下注解

```java
@RunWith(SpringRunner.class)
@SpringBootTest
```

## controller测试

### 第一种

```java
package com.viroyal.user.controller;

import net.minidev.json.JSONObject;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;
import org.springframework.test.web.servlet.result.MockMvcResultHandlers;
import org.springframework.test.web.servlet.result.MockMvcResultMatchers;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import java.util.HashMap;
import java.util.Map;

@RunWith(SpringRunner.class)
@SpringBootTest
public class SysUserControllerTest {

    private MockMvc mvc;

    @Autowired
    private WebApplicationContext wac;

    @Before
    public void setUp() {
        this.mvc = MockMvcBuilders.webAppContextSetup(this.wac).build();
    }

    @After
    public void tearDown() {

    }

    @Test
    public void add() throws Exception {
        Map map = new HashMap();
        map.put("username","tough");
        map.put("password","123456");
        map.put("phone","17623677587");
        String jsonObject = JSONObject.toJSONString(map);
        System.out.println(jsonObject);
        MockHttpServletRequestBuilder requestBuilder = MockMvcRequestBuilders.post("/v1/sys/user/add")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonObject);

        ResultActions result = mvc.perform(requestBuilder);

        MvcResult mvcResult = result.andExpect(MockMvcResultMatchers.status().isOk())
                .andDo(MockMvcResultHandlers.print())
                .andReturn();// 返回执行请求的结果
        System.out.println(mvcResult.getResponse().getContentAsString());

    }

}
```

### 第二种

```
package com.viroyal.user.controller;

import net.minidev.json.JSONObject;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;
import org.springframework.test.web.servlet.result.MockMvcResultHandlers;
import org.springframework.test.web.servlet.result.MockMvcResultMatchers;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import java.util.HashMap;
import java.util.Map;

@RunWith(SpringRunner.class)
@SpringBootTest
public class SysUserControllerTest {

    private MockMvc mvc;

    @Autowired
    private WebApplicationContext wac;

    @Before
    public void setUp() {
        this.mvc = MockMvcBuilders.webAppContextSetup(this.wac).build();
    }

    @After
    public void tearDown() {

    }

    @Test
    public void login() throws Exception {
        Map map = new HashMap();
        map.put("username","tough");
        map.put("password","123456");

        mvc.perform(MockMvcRequestBuilders.post("/v1/sys/user/login")
            .contentType(MediaType.APPLICATION_JSON)
            .content(JSONObject.toJSONString(map)))
            .andExpect(MockMvcResultMatchers.status().isOk())
            .andExpect(MockMvcResultMatchers.jsonPath("errorCode").value(1000));
     
}
```

## Service层测试

原理和以上很相同，只需将dao层注入即可

```java
package com.viroyal.smart.smokesensor.service;

import com.viroyal.smart.smokesensor.dao.SmokeSensorRptDao;
import com.viroyal.smart.smokesensor.domain.SmokeSensorRptPO;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@RunWith(SpringRunner.class)
@SpringBootTest
public class SmokeSensorDeviceServiceImplTest {

    @Autowired
    private SmokeSensorRptDao smokeSensorRptDao;

    @Test
    public void reportAll() throws Exception {
        List list = new ArrayList();
        String[] str = new String[]{"866971030530914","866971030530708"};
        SmokeSensorRptPO smokeSensorRptPO = smokeSensorRptDao.findFirstByImeiInOrderByCtTimeDesc(Arrays.asList(str));
        System.out.println(smokeSensorRptPO.toString());
    }

}
```


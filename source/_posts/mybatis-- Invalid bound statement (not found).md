# mybatis-- Invalid bound statement (not found)

## 异常描述

`org.apache.ibatis.binding.BindingException: Invalid bound statement (not found) `

## 解决方法

在pom.xml文件中的build中添加以下代码：

```java
<resources>
        <resource>
            <directory>src/main/java</directory>
            <includes>
                <include>**/*.xml</include>
            </includes>
            <filtering>false</filtering>
        </resource>
</resources>
```


---
title: cas-v5.3.6骨架搭建
types: cas
categories: cas
---

​	由于公司使用JDK版本为1.8，而cas 6.x需要JDK 11，因此在cas 5.3.x的基础上搭建cas。

# 脚手架下载

​	在[cas-overlay-template](https://github.com/apereo/cas-overlay-template)官网选择`Branches`为5.3的分支，下载到本地。由于通过Maven仓库去下载`cas-server-webapp-tomcat:war:5.3.6`速度很慢，所以我们选择通过迅雷到[oss.sonatype.org](https://oss.sonatype.org/content/repositories/releases/org/apereo/cas/cas-server-webapp-tomcat/5.3.6/)下载源码后移入本地`maven`仓库。

​	`maven`自动加载完成后会生成overlays文件，将`org.apereo.cas.cas-server-webapp-tomcat-5.3.6/WEB-INF/classes`下的`application.properties`文件拷贝到`src/main/resources`中。

# 文件配置

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd ">
    <modelVersion>4.0.0</modelVersion>
    <groupId>org.hereyour.cas</groupId>
    <artifactId>cas-overlay</artifactId>
    <packaging>war</packaging>
    <version>1.0</version>

    <dependencies>
        <dependency>
            <groupId>org.apereo.cas</groupId>
            <artifactId>cas-server-webapp${app.server}</artifactId>
            <version>${cas.version}</version>
            <type>war</type>
            <scope>runtime</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <version>${springboot.version}</version>
                <configuration>
                    <mainClass>${mainClassName}</mainClass>
                    <addResources>true</addResources>
                    <executable>${isExecutable}</executable>
                    <layout>WAR</layout>
                </configuration>
                <executions>
                    <execution>
                        <goals>
                            <goal>repackage</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-war-plugin</artifactId>
                <version>2.6</version>
                <configuration>
                    <warName>cas</warName>
                    <failOnMissingWebXml>false</failOnMissingWebXml>
                    <recompressZippedFiles>false</recompressZippedFiles>
                    <archive>
                        <compress>false</compress>
                        <manifestFile>${manifestFileToUse}</manifestFile>
                    </archive>
                    <overlays>
                        <overlay>
                            <groupId>org.apereo.cas</groupId>
                            <artifactId>cas-server-webapp${app.server}</artifactId>
                        </overlay>
                    </overlays>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.3</version>
            </plugin>
        </plugins>
        <finalName>cas</finalName>
    </build>

    <properties>
        <cas.version>5.3.6</cas.version>
        <springboot.version>2.0.0.RELEASE</springboot.version>
        <!-- app.server could be -jetty, -undertow, -tomcat, or blank if you plan to provide appserver -->
        <app.server>-tomcat</app.server>

        <mainClassName>org.springframework.boot.loader.WarLauncher</mainClassName>
        <isExecutable>false</isExecutable>
        <manifestFileToUse>${project.build.directory}/war/work/org.apereo.cas/cas-server-webapp${app.server}/META-INF/MANIFEST.MF</manifestFileToUse>

        <maven.compiler.source>1.8</maven.compiler.source>
        <maven.compiler.target>1.8</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

</project>
```

​	通过`maven`工具打包生成war包后，可在`tomcat`中或者`./build.cmd`启动即可。使用`application.properties`中定义好的用户名密码登录可进行测试

```properties
cas.authn.accept.users=casuser::Mellon
```


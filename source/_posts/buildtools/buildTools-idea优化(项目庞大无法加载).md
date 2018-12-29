---

title: gradle项目过于庞大无法加载完成
tags: idea
categories: BuildTools
date: 2018/11/30
---

# 前言

​	最近在接触cas-server统一认证系统，从github得到源码后导入idea，加载gradle文件加载到一半就报VM内存爆满，重试了一晚发现不行。

# 解决方案

更改一下idea的配置文件idea.vmoptions就可以了。tips：机器内存需要6G以上，不然卡爆。

```
-Xms1024m
-Xms1024m
-Xmx6144m
-XX:ReservedCodeCacheSize=512m
-XX:+UseCompressedOops
-Dfile.encoding=UTF-8
-XX:+UseConcMarkSweepGC
-XX:SoftRefLRUPolicyMSPerMB=50
-ea
-Dsun.io.useCanonCaches=false
-Djava.net.preferIPv4Stack=true
-XX:+HeapDumpOnOutOfMemoryError
-XX:-OmitStackTraceInFastThrow
-Xverify:none

-XX:ErrorFile=$USER_HOME/java_error_in_idea_%p.log
-XX:HeapDumpPath=$USER_HOME/java_error_in_idea.hprof
-Xbootclasspath/a:../lib/boot.jar
-XX:MaxMetaspaceSize=2048m
```


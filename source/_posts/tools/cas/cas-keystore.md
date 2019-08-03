---
title: cas-server中KeyStore配置
tags: keytool
categories: ['工具','cas']
date: 2018/11/30
---

# 生成key服务端密钥文件

`keytool -genkeypair -keyalg RSA -keysize 1024 -sigalg SHA1withRSA -validity 36500 -alias sav.cas.com -keystore d:/thekeystore.thekeystore -dname "CN=sav.cas.com,L=NanJing,ST=JiangSu,C=CN"`

# 生成证书

`keytool -exportcert -alias sav.cas.com -keystore d:/thekeystore.thekeystore -file d:/thekeystore.cer -rfc`

# 导入cacerts证书库文件

` keytool -import -alias sav.cas.com -keystore 'D:\Program Files\Java\jdk1.8.0_172\jre\lib\security\cacerts' -file D:/thekeystore.cer -trustcacerts`

# 查看生成的key

`keytool -list -v -keystore thekeystore.thekeystore`



# 生成客户端密钥库文件

`keytool -import -trustcacerts -alias cas -storepass changeit -file thekeyst
ore.cer -keystore thekeystore`

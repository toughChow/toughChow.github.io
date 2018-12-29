---
title: cas-v5.3.6JDBC认证
types: cas
categories: cas
date: 2018/11/30
---

# 创建数据库

```sql
CREATE DATABASE /*!32312 IF NOT EXISTS*/`db_ids` /*!40100 DEFAULT CHARACTER SET utf8 */;

USE `db_ids`;

/*Table structure for table `sys_user` */

DROP TABLE IF EXISTS `sys_user`;

CREATE TABLE `sys_user` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `group_id` int(2) NOT NULL COMMENT '用户组别',
  `user_id` varchar(20) NOT NULL COMMENT '用户id',
  `school_id` varchar(20) DEFAULT NULL COMMENT '学校id',
  `department_id` int(10) DEFAULT NULL COMMENT '部门id',
  `user_name` varchar(40) DEFAULT NULL COMMENT '用户名',
  `sex` int(2) DEFAULT NULL COMMENT '1:男；2:女',
  `phone` varchar(20) DEFAULT NULL COMMENT '手机号',
  `qq` varchar(15) DEFAULT NULL COMMENT 'QQ号',
  `weChat` varchar(20) DEFAULT NULL COMMENT '微信号',
  `password` varchar(100) DEFAULT NULL COMMENT '密码',
  `MD5Password` varchar(100) DEFAULT NULL COMMENT 'MD5(16位小写)',
  `email` varchar(20) DEFAULT NULL COMMENT '邮箱',
  `address` varchar(200) DEFAULT NULL COMMENT '地址',
  `qq_openId` varchar(40) DEFAULT NULL COMMENT 'qq标识码',
  `wechat_openId` varchar(40) DEFAULT NULL COMMENT '微信标识码',
  `ticket` varchar(100) DEFAULT NULL,
  `expired_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'ticket失效时间',
  `user_expired_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '登录失效时间',
  `state` int(2) DEFAULT NULL COMMENT '1:有效；0无效',
  `userState` int(2) DEFAULT NULL COMMENT '人员状态',
  `stu_id` varchar(20) DEFAULT NULL COMMENT '家长账号绑定的学生id',
  `update_time` timestamp NULL DEFAULT NULL,
  `firstname` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=11426 DEFAULT CHARSET=utf8;

/*Data for the table `sys_user` */

insert  into `sys_user`(`id`,`group_id`,`user_id`,`school_id`,`department_id`,`user_name`,`sex`,`phone`,`qq`,`weChat`,`password`,`MD5Password`,`email`,`address`,`qq_openId`,`wechat_openId`,`ticket`,`expired_time`,`user_expired_time`,`state`,`userState`,`stu_id`,`update_time`,`firstname`) values (11425,1,'1','1002',NULL,'admin',NULL,NULL,NULL,NULL,'7c4a8d09ca3762af61e59520943dc26494f8941b',NULL,NULL,NULL,NULL,NULL,NULL,'2018-11-28 14:39:17','2018-11-28 14:39:17',NULL,NULL,NULL,NULL,NULL);

```

# 添加pom依赖

```xml
        <dependency>
            <groupId>org.apereo.cas</groupId>
            <artifactId>cas-server-support-jdbc</artifactId>
            <version>${cas.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apereo.cas</groupId>
            <artifactId>cas-server-support-jdbc-drivers</artifactId>
            <version>${cas.version}</version>
        </dependency>
        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <version>5.1.36</version>
        </dependency>
```

# 去掉静态用户的配置

```properties
cas.authn.accept.users=casuser::Mellon
```

# 新增JDBC认证

​	在`application.perperties`文件中新增如下属性

```properties
#添加jdbc认证
cas.authn.jdbc.query[0].sql=SELECT * FROM sys_user WHERE user_name=?
#那一个字段作为密码字段
cas.authn.jdbc.query[0].fieldPassword=password
#配置数据库连接
cas.authn.jdbc.query[0].url=jdbc:mysql://localhost:3306/db_ids?useUnicode=true&amp;characterEncoding=utf8
cas.authn.jdbc.query[0].dialect=org.hibernate.dialect.MySQL5Dialect
#数据库用户名
cas.authn.jdbc.query[0].user=root
#数据库密码
cas.authn.jdbc.query[0].password=
#mysql驱动
cas.authn.jdbc.query[0].driverClass=com.mysql.jdbc.Driver
```

# 新增加密方式

​	在`application.properties`文件新增SHA-1加密方式

```properties

#配置加密策略
cas.authn.jdbc.query[0].passwordEncoder.type=DEFAULT
cas.authn.jdbc.query[0].passwordEncoder.characterEncoding=UTF-8
cas.authn.jdbc.query[0].passwordEncoder.encodingAlgorithm=SHA-1
#Query Database Authentication 数据库查询校验用户名结束
```

​	到这里就可以进行测试了!
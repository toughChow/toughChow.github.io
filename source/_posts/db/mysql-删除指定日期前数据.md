---
title: mysql删除指定日期前数据
tags: mysql
categories: db
---

# 需求

​	由于数据上报产生数据量过大，因此需要定期删除无用数据。

# 程序方式

​	mysql语句如下：

```mysql
DELETE FROM t_iot_cb_device_data_changed WHERE EVENT_TIME IS NULL OR DATE(EVENT_TIME) <= DATE(DATE_SUB(NOW(),INTERVAL 15 DAY))
```

​	其中`EVENT_TIME`为要进行判断的时间依据。

​	此处为删除15天以前的数据，若需要删除几个月以前的数据，（以三个月为例）则为 `INTERVAL 3 MONTH`。

# 通过存储过程解决

## 1. 创建存储过程

```mysql
DROP PROCEDURE IF EXISTS pro_clean_data;
CREATE PROCEDURE pro_clean_data()
    BEGIN  
      DELETE FROM t_iot_cb_device_data_changed WHERE EVENT_TIME IS NULL OR DATE(EVENT_TIME) <= DATE(DATE_SUB(NOW(),INTERVAL 15 DAY));
    END
```

## 2. 创建事件

```mysql
CREATE EVENT IF NOT EXISTS event_time_cleaner
ON SCHEDULE EVERY 1 DAY STARTS '2018-12-19  01:00:00' 
ON COMPLETION PRESERVE 
DO CALL pro_clean_data();
```


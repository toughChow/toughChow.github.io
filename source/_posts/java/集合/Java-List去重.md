---
title: 多关键字List去重
tags: Collection
categories: ['后端','Java']
date: 2018/12/12
---

# List去重（n个条件去重）

​	最近遇到一个情况，需要在一个List<Object>中去除包含多个字段相同的重复对象。寻找Lambda无果，只好使用一下方法。

## 问题说明

​	目前存在DepotLogs对象，其中的barCode和posId可能存在两个DepotLogs对象的两个属性值相同，因此需要去除重复对象只留一条。DepotLogs对象如下

```java
@Data
public class DepotLogsPO {
	private Long id;
    private String barCode;
    private Long posId;
    private String action;
}
```

## 解决方法

​	通过重写DepotLogs的equals方法解决问题

### 重写equals方法

```java
@Override
public boolean equals(Object obj) {
    if(obj == null) {
        return false;
    }
    if(this == obj) {
        return true;
    }
    DepotLogsPO depotLogsPO = (DepotLogsPO) obj;
    if(this.getPosId().compareTo(depotLogsPO.getPosId()) == 0
       && this.getBarCode().equals(depotLogsPO.getBarCode())){
        return true;
    }
    return false;
}
```

### 过滤

```java
private List<DepotLogsPO> getNoRepeatPostIdAndBarCodeDepotLogsList(List<DepotLogsPO> depotLogsPOS) {
    List<DepotLogsPO> list = new ArrayList<>();
    if(CollectionUtils.isNotEmpty(depotLogsPOS)) {
        for (DepotLogsPO po : depotLogsPOS) {
            if(!list.contains(po)) {
                list.add(po);
            }
        }
    }
    return list;
}
```

​	至此，问题就解决了。设想过Lambda的方法实现

```java
List<DepotLogsPO> contents = page.getContent();
List<DepotLogsPO> tmps = new ArrayList<>();
contents.forEach(content -> {
    DepotLogsPO depotLogsPO = contents.stream().filter(
        v -> { boolean flag = v.getPosId() == content.getPosId() && v.getBarCode().equals(content.getBarCode());
        return flag;
    }).distinct().collect(Collectors.toList()).get(0);
    tmps.add(depotLogsPO);
});
```

​	但是其中content中也存在重复对象，感觉解决起来特别麻烦。若有大神知道怎么用Lambda解决，还望多多指点。

------

# List多字段去重

​	根据`devId`和`cmd`去重，如下：

```java
List<SmartLightDispatcherPO> distinctList = lists.stream().collect(Collectors.collectingAndThen(
                Collectors.toCollection(() -> new TreeSet<>(Comparator.comparing(o -> o.getDevId() + ";" + o.getCmd()))), ArrayList::new
        ));
```


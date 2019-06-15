---
title: vue入门
date: 2019/01/31
categories: ['前端']
tags: ['vue']       
comments: true
---
# 简介

​	使用npm

## 脚手架创建

```
vue init webpack viroyal-demo
```

## 安装插件

```shell
npm i vant -S
npm i axios -S
```

# store

### 引入

```shell
npm i vuex-persistedstate -S
```

### 持久化

```javascript
import createPersistedState from 'vuex-persistedstate'
plugins: [createPersistedState()]
```

### 代码

#### store.js

```javascript
import Vue from 'vue'
import vuex from 'vuex'
import createPersistedState from 'vuex-persistedstate'

Vue.use(vuex)

let store = new vuex.Store({
  state: {
    userClass: ''
  },
  mutations: {
    setUserClass(state, data) {
      state.userClass = data
    }
  },
  plugins: [createPersistedState()]
})

export default store

```

#### main.js

```javascript
import Vue from 'vue'
import store from '@/store/store'

new Vue({
  el: '#app',
  router,
  store
})

```

### 引用

```javascript
// 赋值
_this.$store.commit('setUserClass', JSON.stringify(classMsgArr))
// 调用
_this.$store.state.classMsgArr
```


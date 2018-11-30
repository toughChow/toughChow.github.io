---
title: Hexo-Next小记
tags: hexo
categories: 建站
---
# Hexo简易安装

## 前置条件

`npm install -g hexo-cli`

## 安装hexo

`npm install -g hexo-cli`

# 插件

## 代码复制功能

### clipboardjs

​	下载第三方插件[clipboard.min.js](https://raw.githubusercontent.com/zenorocha/clipboard.js/master/dist/clipboard.min.js)，在next主题下的`source\js\src`目录下新建`clipboard-use.js`

```javascript
!function (e, t, a) { 
  /* code */
  var initCopyCode = function(){
    var copyHtml = '';
    copyHtml += '<button class="btn-copy" data-clipboard-snippet="">';
    copyHtml += '  <i class="fa fa-globe"></i><span>copy</span>';
    copyHtml += '</button>';
    $(".highlight .code pre").before(copyHtml);
    new ClipboardJS('.btn-copy', {
        target: function(trigger) {
            return trigger.nextElementSibling;
        }
    });
  }
  initCopyCode();
}(window, document);
```

​	在next主题下的`source\css\_custom\custom.styl`添加如下代码

```css
//代码块复制按钮
.highlight{
//方便copy代码按钮（btn-copy）的定位
  position: relative;
}
.btn-copy {
  display: inline-block;
  cursor: pointer;
  background-color: #eee;
  background-image: linear-gradient(#fcfcfc,#eee);
  border: 1px solid #d5d5d5;
  border-radius: 3px;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
  -webkit-appearance: none;
  font-size: 13px;
  font-weight: 700;
  line-height: 20px;
  color: #333;
  -webkit-transition: opacity .3s ease-in-out;
  -o-transition: opacity .3s ease-in-out;
  transition: opacity .3s ease-in-out;
  padding: 2px 6px;
  position: absolute;
  right: 5px;
  top: 5px;
  opacity: 0;
}
.btn-copy span {
  margin-left: 5px;
}
.highlight:hover .btn-copy{
  opacity: 1;
}
```

### 引用

​	在next主题下的`layout\_layout.swig`文件中引用clipboardjs

```javascript
<script type="text/javascript" src="/js/src/clipboard.min.js"></script>
<script type="text/javascript" src="/js/src/clipboard-use.js"></script>
```

​	这样，复制功能就ok惹。

## 评论系统-Gitmen

​	

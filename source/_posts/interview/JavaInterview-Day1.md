---
title: Java面试题小记
tags: 面试题
categories: Java
---

1. `short s1 = 1; s1 = s1 + 1;有错吗?short s1 = 1; s1 += 1;有错吗？`

   答：对于short s1 = 1; s1 = s1 + 1;由于1是int类型，因此s1+1运算结果也是int 型，需要强制转换类型才能赋值给short型。而short s1 = 1; s1 += 1;可以正确编译，因为s1+= 1;相当于s1 = (short)(s1 + 1);其中有隐含的强制类型转换。

2. `输出如下代码结果`

   ```java
   public class Test {
       public static void main(String[] args) {
           Integer f1 = 100, f2 = 100, f3 = 150, f4 = 150;
           System.out.println(f1 == f2);
           System.out.println(f3 == f4);
       }
   }
   ```

   答案：true false（参见`Integer.valueOf()源码`

3. `&和&&的区别？`

   &运算符有两种用法：(1)`按位与`；(2)`逻辑与`。&&运算符是`短路与`运算。`短路与`指如果&&左边的表达式的值是false，右边的表达式会被直接短路掉，不会进行运算。



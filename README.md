[中文说明](#cn-title)
# Naive Factorial

Naive x86_64 assembly for generating binary factorial tables

## Introduction

Even a seemingly small integer like 512 has a factorial whose binary representation has more than three thousand bits, which cannot be stored in a 64-bit register and computed directly using the hardware multiplier. In this project we use ASCII strings to represent arbitrary binary (unsigned) integers, e.g. the binary 10 is represented by string `"01"` (bit order reversed), whose little-endian
layout in the memory is like

```
addr+0: 0x30
addr+1: 0x31
addr+2: 0x00
```
Based on this string representation, we define addition (`long_add`) as usual, i.e., as a series of full adders. Multiplication (`long_multiply`) is then defined as a shift adder. The factorial function  (`factorial`) is implemented by embedding the multiplication function in a decrement-and-multiply loop.

We also tried to display the binary numbers in decimal notation. For this we defined a binary-to-decimal converter (`rep_div`) which translates, e.g. "11001" to "91" (the numbers shall be read from right to left), from binary nineteen to decimal nineteen. The converter (`rep_div`) is implemented as repeated binary division (`long_div`), which in turn is based on binary subtraction (`long_sub`) and  increment (`num_inc`). Subtraction is implemented as simultaneous decrement (`num_dec`) of the minuend and the subtrahend.

## Performance

The binary factorial computation has satisfactory speed when the base of the factorial (e.g. the *base* of 5! is 5) is not more than 500. Therefore it is rather quick (10 mins) to produce a
*binary* factorial table with the base ranging from 0 to 520. 

However, conversion from binary to decimal is already intolerably slow when the binary number represents 14!. For 15!, it is even impossible to complete the conversion before the OS automatically kills the thread. Consequently we cannot use the program to produce a decimal factorial table whose largest base number is beyond 14.

## How to Use

The program is tested on an x86_64 machine running Ubuntu 20.04.6 LTS. The assembler is NASM.
```
make
./test > factbl.html
```
The macro TBL_COUNTER_MAX controls the size of the table, and TBL_COUNTER_MAX-1 is the largest base number. 

## Model of the Program

There are five independent buffers named I, II, III, IV and V. They act as registers for large integers in the same way `rax`, `rbx` etc. are registers for 64-bit integers.  The  buffers I through IV are supposed to be long and of the same size specified by the macro ARITH_BUFFER_SIZE. The buffer V is supposed to be short, whose size is specified by SMALL_BUFFER_SIZE. All the buffers exist through out the life of the program and are shared by all routines. A note on terminology used in the comments of the code， as follows.

- Buffers I, II and III are individually referred to as a "MULTIPLY long buffer".
- Buffer IV is referred to simply as "long buffer", and buffer V as "small buffer".

The factorial algorithm is non-recursive. The order of computation is like （（（（5）\*4）\*3）\*2）\*1 rather than 5\*（4\*（3\*（2\*（1））））.

## Binary to Decimal Conversion

The binary to decimal conversion logic are removed from the factorial-table-generation logic due
 to its low performance. However， they can still be found, together with other test codes, in [recycle.asm](./recycle.asm).



# 大整数阶乘程序说明书 {#cntitle}



##     简介      

看似很小的整数，比如512，它的阶乘有三千多位（二进制）数，单一寄存器无法存储，
也无法直接使用x86_64CPU的内置乘法器计算。为了计算尽可能大的整数阶乘，现将
二进制整数以ASCII字符串的形式存储。比如二进制数字10（就是十进制的2）用字符
串表示为“01”，在内存中是：
```
addr+0: 0x30
addr+1: 0x31
addr+2: 0x00
```
在此“字符串二进制数”基础上，用全加器串列方法定义加法（long_add），用移位相加
的方法定义乘法（long_multiply），再用循环相乘的方法定义阶乘（factorial），
结果以“字符串二进制数”形式存储在4KB缓冲区中。

为了将阶乘结果转化为十进制（比如“01”变成“2”， “001”变成“4”，等等），定义了适
用于十以内字符串二进制数直接转换成字符串十进制数的函数（bin2dec_digit）。
对于表示十（含）以上整数的的字符串二进制数，为了将其转换为对应字符串十进制数，
定义了字符串二进制数的增一（num_inc）和减一（num_dec）函数。用减一函数定义了
减法（long_sub），用减法和增一函数定义了除法（long_div），最终定义了二进制转
换十进制的函数（rep_div）。


##    优缺点     

优点：阶乘算法速度较快（至少500以内数字阶乘没有明显等待）。制作一张0至520的*二进制*阶乘表大概耗时10分钟。
缺点：字符串二进制数转字符串十进制,从14的阶乘开始，速度非常缓慢，要20-30分钟甚至更长
     时间才能完成。15的阶乘结果的十进制转换干脆就因时间太长被操作系统掐了。因此无法制作最大基数超过14的十进制阶乘表。


##   上手测试    


生成一个1到10的阶乘表

- 准备：x86_64，(Ubuntu) Linux, NASM汇编器
- 第一步，在calc.asm第8行，修改TBL_COUNTER_MAX值为11。一般地，TBL_COUNTER_MAX-1 即为阶乘表中最大的输入数字。
- 第二步，在工程路径下make
- 第三步，运行可执行文件test, 将输出至stdout的数据流导入一个空白HTML文件
- 第四步，浏览器打开，观赏结果

```
第二、三步
$ make
$ ./test > factbl.html
```

##   程序模型    


有五个相互独立缓冲区（buffer）, 依次标号为I，II, III, IV, V。
这些缓冲区扮演大整数寄存器的功能,就像`rax`和`rbx`之于64位整数一样。
其中缓冲区I至IV为大缓冲区，长度统一由宏ARITH_BUFFER_SIZE定义。
缓冲区V为小缓冲区， 长度由宏SMALL_BUFFER_SIZE定义。这五个缓冲区
存在于整个程序运行周期，由所有函数共享。在源代码的注释中，

- 缓冲区IV和V还分别被称为 long buffer 和 small buffer； 
- 缓冲区I,II,III还分别被称为一个MULTIPLY long buffer


本程序的阶乘计算没有采用递归，所以计算顺序不是， 比如5\*（4\*（3\*（2\*（1）））），
而是（（（（5）\*4）\*3）\*2）\*1。这种算法不构成瓶颈，进制转化才是瓶颈。


## 十进制转化


由于效率低下，相关代码已被移入回收站[recycle.asm](./recycle.asm).

运行开始后，首先创建上述缓冲区，然后跳转至.test_rep_div标签（rep_div即为
瓶颈-低效的进制转换程序），将阶乘的基数（比如5的阶乘基数是5）转为十进制并输出
至STDOUT。接着，程序跳转至.test_factorial标签，开始计算阶乘，并将结果转换
为十进制， 输出至STDOUT。最后，将阶乘基数加一，重新开始新一轮的计算。


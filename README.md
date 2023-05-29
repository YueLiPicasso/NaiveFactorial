# Naive Big Integer Arithmetic in x86 Assembly 

Even a seemingly small integer like 512 has a factorial whose binary representation has more than three thousand bits, which cannot be stored in a 64-bit register and computed directly using the hardware multiplier. We define an x86 assembly library for arbitrary-precision unsigned integer arithmetic, and use it to build a factorial table.

## How to Use

The program is tested on an Intel(R) Core(TM) i5-4210U CPU @ 1.70GHz running Ubuntu 20.04.6 LTS. The assembler is NASM 2.14.02. The macro `TBL_COUNTER_MAX` controls the size of the table (default 521), and `TBL_COUNTER_MAX-1` is the largest base number. 


### Generate a Binary Factorial Table

```
make
./test > factbl_bin.html
```
Under the default setting, a factorial table for 0 to 250 shall be generated in the HTML file, where the numbers are binary. You may view the HTML in a web browser even before the program finishes execution, to see the progress and feel the speed of the code. 

### Generate a Decimal Factorial Table

To generate a decimal factorial table, just comment the Line 70 of the source code, save the file, and then
```
make
./test > facttbl_dec.html
```

### Warning on Execution Time

Under the default setting, generating a binary table takes about 10 mins, but the majority of the results are displayed within 5 seconds. The decimal factorial table takes much longer time to build. See [Performance Analysis](#performance-analysis).


## Implementation Details


### Internal Number Representation 

We use ASCII strings to represent arbitrary binary (unsigned) integers, e.g. the binary 10 is represented by string `"01"` (bit order reversed), whose little-endian
layout in the memory is like

```
addr+0: 0x30
addr+1: 0x31
addr+2: 0x00
```

### Addition

Based on the string representation of binary numbers, we define addition (`long_add`) by means of a classic ripple-carry adder operating on two input strings, checking one pair of bytes at a time, which represent two binary digits to be added by a full adder, together with a carry in; the sum is a new string and neither of the augend and addend buffers are modified during addition.

### Multiplication

 Multiplication (`long_multiply`) is then defined as a shift adder. Shift of the multiplier (or multiplicand) is done explicitly by copying the whole string to a buffer with a desired offset, then set to ASCII 0 (0x30) for all bytes whose index is lower than the offset (zero padding). The shifted number is then added to a string from the partial-sum buffer (initialized to zero), and the result, which is initially stored in another buffer, is copied back to the partial-sum buffer, waiting to be added upon again. 

### Factorial

 The factorial function  (`factorial`) is implemented by embedding the multiplication function in a decrement-and-multiply loop. For instance, to compute the factorial of 5, we first copy the string representation of binary 5 to two buffers -- a small buffer and a long buffer. Since factorial is growing quickly, we do  not expect to compute factorials of very large numbers, therefore the base of the factorial (in our example, 5) is stored in a small buffer. After initialization of the buffers, the decrement-and-multiply loop starts by decrementing the number in the small buffer, and multiply it with the number in the long buffer, until the number in the small buffer reaches 1. 

### Subtraction

Subtraction is implemented as simultaneous decrement (`num_dec`) of the minuend and the subtrahend, until one of them reaches zero. If the minuend reaches zero before the subtrahend, the minuend must be smaller than the subtrahend so an error is signalled. Otherwise if the subtrahend reaches zero before or at the same time as the minuend, then the value remaining in the minuend buffer is just the difference. Subtraction therefore modifies the content of the buffers that provide the minuend and the subtrahend.


### Division 

 Division (`long_div`) is repeated subtraction (`long_sub`) while incrementing (`num_inc`) a counter. The divisor is repeatedly subtracted from the dividend buffer until the number in the dividend buffer is smaller than the divisor, which is returned as the remainder. A counter is incremented for each successful subtraction and when subtraction stops, the number in this counter is the quotient. The increment operation works on our string representation of binary numbers and returns such strings as well.


### Binary-to-Decimal Conversion

To display the binary numbers in decimal notation, we define a binary-to-decimal string converter (`rep_div`) which translates, e.g. the string "11001" to "91" (the numbers shall be read from right to left), from binary nineteen to decimal nineteen. The converter (`rep_div`) is implemented as repeated binary division.

### Memory Usage and Buffer Names

There are five independent buffers named I, II, III, IV and V.  The  buffers I through IV are supposed to be long and of the same size specified by the macro ARITH_BUFFER_SIZE. The buffer V is supposed to be short, whose size is specified by SMALL_BUFFER_SIZE. All the buffers exist through out the life of the program and are shared by all routines. 

- Buffers I, II and III are individually referred to as a "MULTIPLY long buffer".
- Buffer IV is referred to simply as "long buffer", and buffer V as "small buffer".

 
## Performance Analysis

### Moderate Multiplication Delay

The frequent string copy and zero padding in multiplication is a source of latency. The decrement-and-multiply loop used by the factorial routine may well be replaced by an increment-and-multiply loop so that we can build on the results of earlier factorial computations. However, the binary factorial computation has satisfactory speed when the base of the factorial is not more than 500. Therefore it is kind of quick (10 mins) to produce a *binary* factorial table with the base ranging from 0 to 520. 

### Serious Radix Conversion Delay

Conversion from binary to decimal is already intolerably slow (about 30 mins) when the binary number represents 14!. For 15!, it is even impossible to complete the conversion before the OS automatically kills the thread. Consequently we cannot use the program to produce a decimal factorial table whose largest base number is beyond 14. The reason is that the binary-to-decimal conversion is repeated division by ten, and division is implemented by repeated subtraction, which in turn is repeated decrement on the binary-representing strings. For example, to convert the number one thousand from binary to decimal, our algorithm first divides one thousand by ten to get the first decimal digit 0, which involves subtracting ten for a hundred times ; then from the quotient which is one hundred, subtracts ten for ten times (performing division), to get the second decimal digit 0; then subtracts from the new quotient, which is ten, for one time to get the third decimal digit 0 (and this is the third division); finally there is one more division of one by ten (involving a subtraction between one and ten) to get the last digit 1. There are in total one hundred and eleven subtractions of ten, and every such subtraction requires 10 decrements for both the minuend and subtrahend. The total number of decrement operations is about `111 * 10 * 2 = 2220`.  In general, to convert number N from binary to decimal, we need (2.22...2)N string decrement operations, where the length of 2.22...2 is proportionate to the length of decimal N; and as N grows larger, the coefficient 2.2...2 would approach 20/9. For factorial of 15, the number of string decrement needed for radix conversion is about 2.9 trillion.  Note that the decrement operation is on strings, which has complex logic and takes much more than one clock cycle to complete. Even if the decrement takes one clock cycle, 2.9 trillion decrements would take 19 days for my 1.70GHz processor to complete.








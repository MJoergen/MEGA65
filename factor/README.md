# Integer Factorization

This design can factorize a (large) integer N.

What this means is that given an integer N, this design will find two numbers A and B,
such that A\*B = N.

## Performance
With the following parameters:
* G_NUM_WORKERS = 32
* G_PRIME_ADDR_SIZE = 6
* G_DATA_SIZE = 132
* G_VECTOR_SIZE = 64

factoring small numbers take the following time:
| number | factors     | cycles
| ------ | -------     | ------
|   2059 |   29 *   71 | 1083
|   4559 |   47 *   97 |  992
|  19549 |  113 *  173 | 1347
|  26329 |  113 *  233 | 2627
|  35119 |  173 *  203 |  988
|  40309 |  173 *  233 | 2384
|3837523 | 1093 * 3511 | 4101

Factoring larger numbers take (on average, in clock cycles):
| bits | count |  min |    max | smooth |
| ---- | ----- | ---- |   ---- | ------ |
|  16  |   30  |  519 |   8478 |   2726 |
|  18  |   41  |  394 |  12530 |   3008 |
|  20  |   49  |  869 |  27082 |   4035 |
|  22  |   46  |  390 |  86673 |   5129 |
|  24  |   68  |  887 | 181553 |   8350 |
|  26  |   67  |  490 |  37491 |   6283 |
|  28  |   66  |  411 |  56730 |   7308 |
|  30  |   71  | 1744 |  38966 |   8425 |

A very rough estimate of the average number of cycles for this range is the following formula:
150 \* 2^sqrt(bits).

Factoring even larger numbers take (on average, in seconds):
| bits | seconds |
| ---- |  ------ |
|  72  |   0.022 |
|  74  |   0.033 |
|  76  |   0.042 |
|  78  |   0.064 |
|  80  |   0.082 |
|  82  |   0.113 |
|  84  |   0.164 |
|  86  |   0.206 |
|  88  |   0.319 |
|  90  |   0.490 |
|  92  |   0.804 |
|  94  |   0.939 |
|  96  |   1.534 |
|  98  |   1.739 |
| 100  |   2.824 |
| 102  |   4.058 |
| 104  |   6.651 |

A very rough estimate of the average number of seconds for this range is the following formula:
26.6^(sqrt(bits) - 9.69)

A combined formula for both ranges is:
1.32^((sqrt(bits) - 3.5)^2 - 38.5)


Utilization report for the factor\_inst shows:
* LUTS      = 60290
* Registers = 52761
* Slices    = 18962
* LUTRAM    =  1084
* BRAM      =   104

Frequency: 126.3 MHz

## Description of algorithm

The method used is quite involved and proceeds in five stages. In the first stage a
sequence of numbers are generated, and in the subsequent stages the output from the
previous stage is processed and (some of them) passed on to the next stage.

In the following I'll describe each stage, and give as example the integer N = 4559.

## Stage 1
The first stage generates a sequence of tuples (x, p, w) satisfying
x^2 = p\*w mod N, where |p| < 2\*sqrt(N) and |w| = 1. The important part here is that p is "small",
i.e. contains only half as many digits as N.

Starting with N=4559, stage 1 generates the following sequence (note that p < 2\*sqrt(4559) = 135):

|    x  |    p  |     w |
| ----- | ----- | ----- |
|   67  |   70  |    -1 |
|   68  |   65  |     1 |
|  135  |   11  |    -1 |
| 1553  |   98  |     1 |
| 1688  |   31  |    -1 |
| 2058  |   53  |     1 |
| 1245  |   35  |    -1 |
| 1234  |   50  |     1 |
| 3713  |   47  |    -1 |

So for instance, the fourth row shows that 1553^2 = 98 mod 4559.

## Stage 2
The second stage takes as input the number p and does two things:
1. It factors out any square numbers from p, i,e. it writes p as
p = s^2 * q, where s is the largest possible solution. In other words,
q has no square divisors.
2. It then factors q into its prime divisors, i.e. writes q = Product p_i.
Note here that each prime p_i appears with power at most 1.

All-in-all. the number p is written as p = s^2 * Product p_i.
Only a limited number of primes p_i is considered for this factorization, so not all
numbers p will be factored in stage 2.

In stage 2 we also have to decide on a set of primes.

For this example with N=4559 let's choose the first eight primes: 2, 3, 5, 7, 11, 13, 17,
and 19.

We then get this result:

| row |   x   |   p   |    s           | 19 | 17 | 13 | 11 | 7 | 5 | 3 | 2 | w=-1 |
| --- | ----- | ----- | -------------- | -- | -- | -- | -- | - | - | - | - | ---- |
|   1 |   67  |   70  |    1           |  . |  . |  . |  . | X | X | . | X |  X   |
|   2 |   68  |   65  |    1           |  . |  . |  X |  . | . | X | . | . |  .   |
|   3 |  135  |   11  |    1           |  . |  . |  . |  X | . | . | . | . |  X   |
|   4 | 1553  |   98  |    7           |  . |  . |  . |  . | . | . | . | X |  .   |
|     | 1688  |   31  |  not factored  |
|     | 2058  |   53  |  not factored  |
|   5 | 1245  |   35  |    1           |  . |  . |  . |  . | X | X | . | . |  X   |
|   6 | 1234  |   50  |    5           |  . |  . |  . |  . | . | . | . | X |  .   |
|     | 3713  |   47  |  not factored  |  . |  . |  . |  . | . | . | . | . |  X   |
 
Translated to equations this gives the following results:

1.   67^2 mod 4559 = -70 = 1^2 * 7 * 5 * 2 * (-1)
2.   68^2 mod 4559 = 65 = 1^2 * 13 * 5
3.  135^2 mod 4559 = -11 = 1^2 * 11 * (-1)
4. 1553^2 mod 4559 = 98 = 7^2 * 2
5. 1245^2 mod 4559 = -35 = 1^2 * 7 * 5 * (-1)
6. 1234^2 mod 4559 = 50 = 5^2 * 2


## Stage 3
This stage takes as input the list of factors p_i and sign w, and finds a combination of
previous factors such that each prime p_i and sign w appears an even number of times.

So after rows 1-5 are received, this stage outputs rows 1, 4, and 5, corresponding to an
even occurrence of the primes 7, 5, 2, and -1.

And after row 6 is received, the output is rows 4 and 6, corresponding to an even
occurrence of the prime 2.

## Stage 4
This stage multiplies the rows selected from the previous stage and outputs the square
root of both sides. This is always possible. The output will be two numbers X and Y that
satisfy
X^2 = Y^2 mod N.

So the first processing happens when rows 1, 4, and 5 are sent. The product of these rows
show that:
(67\*1553\*1245)^2 mod 4559 = 70\*98\*35 = (1\*7\*1)^2 \* (7 \* 5 \* 2)^2

The output is therefore the numbers X = 67\*1553\*1245 = 4069 mod 4559 and Y = 7 \* 7 \* 5 \* 2 = 490 mod 4559.

The next set of rows from stage 3 show that:
(1553\*1234)^2 mod 4559 = 98\*50 = (7\*5)^2 \* (2)^2.

The output is therefore the numbers X = 1553\*1234 = 1622 mod 4559 and Y = 7 \* 5 \* 2 = 70 mod 4559.

## Stage 5
This stage calculates gcd(X+Y,N). This result may sometimes be 0 or 1, but if it is larger
than 1 then this is a factor of N.

In the first case gcd(4069+490,4559) = 0, so no new factor found.
In the second case gcd(1622+70,4559) = 47, and indeed 47 is a factor of 4559.

# Links
* https://core.ac.uk/download/pdf/217142258.pdf
* https://math.dartmouth.edu/~carlp/PDF/implementation.pdf


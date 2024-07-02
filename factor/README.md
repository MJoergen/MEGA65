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
|   2059 |   29 *   71 | 1048
|   4559 |   47 *   97 |  926
|  19549 |  113 *  173 | 1324
|  26329 |  113 *  233 | 2446
|  35119 |  173 *  203 |  964
|  40309 |  173 *  233 | 2337
|3837523 | 1093 * 3511 | 3880

Factoring larger numbers take (on average):
| bits | count |  min |    max | smooth |
| ---- | ----- | ---- |   ---- | ------ |

|  16  |   30  |  501 |   7628 |   2576 |
|  17  |   37  |  343 |  10679 |   2855 |
|  18  |   41  |  376 |  11226 |   2862 |
|  19  |   45  |  911 |   8999 |   3689 |
|  20  |   49  |  851 |  23692 |   3789 |
|  21  |   51  | 1129 |  47705 |   4619 |
|  22  |   46  |  373 |  74275 |   4725 |
|  23  |   57  | 1090 |  16546 |   4706 |
|  24  |   68  | 1549 | 154269 |   7479 |
|  25  |   50  | 1309 |  51845 |   6222 |
|  26  |   67  |  463 |  32268 |   5746 |
|  27  |   68  | 1236 |  30571 |   6624 |
|  28  |   66  |  380 |  48046 |   6607 |
|  29  |   73  |  960 | 111320 |   6323 |
|  30  |   71  | 1723 |  33267 |   7644 |

A very rough estimate of the number of cycles is the following formula:
150 \* 2^sqrt(bits)

Utilization report for the factor\_inst shows:
* LUTS      = 60384
* Registers = 52136
* Slices    = 18428
* LUTRAM    =  1084
* BRAM      =   104

Frequency: 120 MHz

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


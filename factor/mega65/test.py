#!/usr/bin/env -S python3 -u

import serial
import time
import math
import statistics
from sympy import simplify

ser = serial.Serial(
    port='/dev/ttyUSB1',
    baudrate=2000000,
    timeout=10,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    bytesize=serial.EIGHTBITS
)

def factor(n):
    packet = [48+int(character, 16) for character in str(n)] + [13, 10]
    byte_array = bytearray(packet)
    ser.write(byte_array)
    t = time.time()
    while True:
        res = ser.readline()
        if len(res) > 2 and hex(res[-1]) == "0xa":
            t = time.time() - t
            f = int(res.strip())
            assert (n%f) == 0
            return f, t
        print('*',end='')

def is_square(n):
    s = int(math.sqrt(n))
    return s*s == n

def isprime(n):
    return simplify(n).is_prime

def has_small_factor(n):
    if (n%2) == 0:
        return True
    for d in range(3, 1000, 2):
        if (n%d) == 0:
            return True
    return False

def sweep(nn,c):
    stats = []
    for n in range(nn, nn+c*1000):
        if is_square(n) or isprime(n) or has_small_factor(n):
            continue
        f,t = factor(n)
        stats += [t]
        if len(stats) == c:
            break
        print('.',end='')
    return stats

def verify(n):
    print(n,end='')
    f,t = factor(n)
    print(f" : {f} | {t:4.3f}")
    assert (n%f) == 0

for i in range(70, 110, 2):
    t = time.time()
    stats = sweep(2**i + 1000000, 100)
    stats.sort()
    smooth = statistics.mean(stats[2:-2])
    stddev = statistics.stdev(stats[2:-2])
    t = (time.time() - t)/60
    print(f"\nbits={i}, smooth={smooth:4.3f}, stddev={stddev:4.3f}, mins={t:4.1f}")


#verify(2059)
#verify(2**30+93)
#verify(2**40+63)
#verify(2**50+33)
#verify(2**60+63)
#verify(2**70+63)
#verify(2**80+93)
#verify(2**90+33)
#verify(2**100+3)
#verify(2**110+63)
#verify(2**120+3)
print('Done')



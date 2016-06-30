import time
import timeit
from speedtest_objects import *

b = Extents()
b.count = 10.0
b.extents.northwest.x = 1.0
b.extents.northwest.y = 2
b.extents.southeast.x = 4.0
b.extents.southeast.y = 5
b.extents.northsouth.x = 4.0
b.extents.northsouth.y = 5
bs = b.extents.pack()

bb = BoundingBox(b.extents.northwest, b.extents.southeast, b.extents.northsouth)

print(bs)
print(bs == cBoundingBox(bs).pack())
print(dict(cBoundingBox(bs).items()))

tt = []

def formatTime(elapsed, count):
	return "{:.3f} us ({})".format(elapsed/count*1000000.0, count)

start = time.time()
for i in range(1000): BoundingBox(bs)
tt.append(time.time() - start)
print("old", formatTime(tt[-1], 1000))

start = time.time()
for i in range(10000): cBoundingBox(bs)
tt.append(time.time() - start)
print("new", formatTime(tt[-1], 10000))

start = time.time()
for i in range(10000): PyBoundingBox(bs)
tt.append(time.time() - start)
print("cls", formatTime(tt[-1], 10000))

print("{:.0f}%".format(tt[-2] / tt[-1] * 100))
print()

print("pack")

cbb = cBoundingBox(bs)
pybb = PyBoundingBox(bs)

start = time.time()
for i in range(10000): bb.pack()
tt.append(time.time() - start)
print("old", formatTime(tt[-1], 10000))

start = time.time()
for i in range(10000): cbb.pack()
tt.append(time.time() - start)
print("new", formatTime(tt[-1], 10000))

start = time.time()
for i in range(10000): pybb.pack()
tt.append(time.time() - start)
print("cls", formatTime(tt[-1], 10000))

print("{:.0f}%".format(tt[-2] / tt[-1] * 100))
print()

bs = b.pack()

start = time.time()
for i in range(10000): cExtents(bs)
tt.append(time.time() - start)
print("new", formatTime(tt[-1], 10000))

start = time.time()
for i in range(10000): PyExtents(bs)
tt.append(time.time() - start)
print("cls", formatTime(tt[-1], 10000))

print("{:.0f}%".format(tt[-2] / tt[-1] * 100))
print()

E = Extents(bs)

cE = cExtents(bs)
print(cE.extents.northwest.y, dict(cE.items()))
pyE = PyExtents(bs)
print(pyE.extents.northwest.y)

start = time.time()
for i in range(10000): E.extents.northwest.x
tt.append(time.time() - start)
print("old", formatTime(tt[-1], 10000))

start = time.time()
for i in range(10000): E['extents.northwest.x']
tt.append(time.time() - start)
print("old", formatTime(tt[-1], 10000))

start = time.time()
for i in range(100000): cE['extents.northwest.x']
tt.append(time.time() - start)
print("new", formatTime(tt[-1], 100000))

start = time.time()
for i in range(100000): cE.extents.northwest.x
tt.append(time.time() - start)
print("new", formatTime(tt[-1], 100000))

start = time.time()
for i in range(100000): pyE.extents.northwest.x
tt.append(time.time() - start)
print("cls", formatTime(tt[-1], 100000))

print("{:.0f}%".format(tt[-2] / tt[-1] * 100))
print()

#print("old", timeit.timeit("p.unpack(ps)", setup="from __main__ import p, ps", number=100000))
#print("new", timeit.timeit("np.unpack(ps)", setup="from __main__ import np, ps", number=100000))
#print("cls", timeit.timeit("cp.unpack(ps)", setup="from __main__ import cp, ps", number=100000))

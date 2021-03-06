SerializableObject
============

A pythonic semantic for describing binary data structures and associated python objects.

Installation
------------

```
pip install cypyserialize
```


Basic Usage
-----------

For this first example we're going to define a simple 2D point with the attributes `x` and `y` representing binary doubles.

```Python
class Point(cypyserialize.SerializableObject):
    "Basic point class"
    x = cypyserialize.double()
    y = cypyserialize.double()
```

Object instances of the `Point` class, which extends the `SerializableObject`, can be initialized in several different ways. First, omitting any parameters the instance will be populated with default values (here we haven't specified defaults so 0.0 is assumed). The attributes can be assigned values after initialization.

```Python
>>> p = Point() # create default instance
>>> list(p.items())
[('x', None), ('y', None)]
>>> p.x = 5000.0 # set x
>>> p.y = 300.5 # set y
>>> list(p.items())
[('x', 5000.0), ('y', 300.5)]
```

Alternately, the object can be initialized with our values. The parameter order should match the order specified in the class attribute `_field_order`.

```Python
>>> p = Point(5000.0, 300.5)
>>> list(p.items())
[('x', 5000.0), ('y', 300.5)]
```

Or we can use the attribute names if we forgot the order.

```Python
>>> p = Point(y=300.5, x=5000.0)
>>> list(p.items())
[('x', 5000.0), ('y', 300.5)]
```

Or mix the two (just remeber that after the first named parameter subsequent parameters will have to be named as well).

```Python
>>> p = Point(5000.0, y=300.5)
>>> list(p.items())
[('x', 5000.0), ('y', 300.5)]
```

To get the binary representation just call the class method `pack`

```Python
>>> p.pack()
bytearray(b'\x00\x00\x00\x00\x00\x88\xb3@\x00\x00\x00\x00\x00\xc8r@')
```

Lastly, we can initialize with a binary string.

```Python
>>> p = Point(b'\x00\x00\x00\x00\x00\x88\xb3@\x00\x00\x00\x00\x00\xc8r@')
>>> list(p.items())
[('x', 5000.0), ('y', 300.5)]
```

Using Substructures
-------------------

We're going to reuse the `Point` class to describe a rectangular bounding box with two attributes, the northwest and southeast corners.

```Python
class BoundingBox(cypyserialize.SerializableObject):
    northwest = Point()
    southeast = Point()
```

Seriously, it's that easy. Let's initialize one of these.

```Python
>>> bb = BoundingBox()
>>> list(bb.items())
[('northwest', <Point object>), ('southeast',  <Point object>)]
```

Let's try that again but with some points

```Python
>>> bb = BoundingBox(Point(0.0, 10.0), Point(15.0, 0.0))
>>> bb.northwest.y
10.0
>>> bb.southeast.x
15.0
```

Overloading
-----------

Subclasses of SerializableObject can be extended and overloaded. This can be especially handy if you have a standard structure that you don't want to redefine.

Here we're going to make a simple datagram structure with a start and end flag, a timestamp and some arbitrary body that we'll overload in a second.

```Python
class GenericDatagram(cypyserialize.SerializableObject):
    STX = cypyserialize.uchar(value=0x02)
    timestamp = cypyserialize.uint()
    body = cypyserialize.none()
    ETX = cypyserialize.uchar(value=0x03)
```

Now that we have generic datagram lets make it a wrapper on the BoundingBox structure we defined earlier as an extension of the GenericDatagram structure.

```Python
class BoundingBoxDatagram(GenericDatagram):
    body = BoundingBox()
```

That's it. Lets create one of this. We'll set the timestamp and get the binary.

```Python
>>> p = BoundingBoxDatagram()
>>> p.timestamp = time.time()
>>> p.body = BoundingBox(Point(0, 10), Point(10, 0))
>>> p.items()
[('STX', 2), ('timestamp', 1398373100.412985), ('body', <__main__.BoundingBox object at 0xb713f3c4>), ('ETX', 3)]
>>> p.pack()
'\x02...'
```

Arrays of Substructures
-----------------------

Now we're going to reuse the point structure to describe a path as a series of points with a description.

```Python
class Path(cypyserialize.SerializableObject):
    # the points
    points = cypyserialize.SerializableArray(
        Point(),
        count=cypyserialize.uint()
    )
```

`count` with be the field type that is used to read and write the number of `Point()` objects in the structure.

Byte Order
----------

_**Currently Unsupported**_

Byte order is always little endian at present.

Custom Computed Attributes
--------------------------

```Python
class BetterBoundingBox(BoundingBox):
    def __init__(self):
        self.area = (self.southeast.x - self.northwest.x) * \
                    (self.northwest.y - self.southeast.y)
```

Note that we need to accept `args` and `kargs`, we don't need to call the superclass __init__ though as it wasn't defined on BoundingBox.

Lets try it out.

```Python
>>> bb = BetterBoundingBox(Point(0,10),Point(10,0))
>>> print bb.area
100
```
import sys
import struct
import pyximport

pyximport.install()
import src as cypyserialize

sys.path.append("..\\qpstools\\libs\\")
import structObject as structobject


class Point(structobject.structObject):
    "Basic point class"
    _field_order = ['x', 'y']
    x = structobject.ctype_double()
    y = structobject.ctype_uint()


class Point3D(structobject.structObject):
    "Basic point class"
    _field_order = ['x', 'y', 'z']
    x = structobject.ctype_double()
    y = structobject.ctype_double()
    z = structobject.ctype_double()


class BoundingBox(structobject.structObject):
    _field_order = ['northwest', 'southeast', 'northsouth']
    northwest = Point
    southeast = Point
    northsouth = Point


class Extents(structobject.structObject):
    _field_order = ['count', 'extents']
    count = structobject.ctype_double()
    extents = BoundingBox


class cPoint(cypyserialize.StructObjectBase):
    "Basic point class"
    x = cypyserialize.double()
    y = cypyserialize.uint()


class cPoint3D(cypyserialize.StructObjectBase):
    "Basic point class"
    x = cypyserialize.double()
    y = cypyserialize.double()
    z = cypyserialize.double()


class cBoundingBox(cypyserialize.StructObjectBase):
    northwest = cPoint()
    southeast = cPoint()
    northsouth = cPoint()


class cExtents(cypyserialize.StructObjectBase):
    count = cypyserialize.double()
    extents = cBoundingBox()


class PyPoint():
    struct = struct.Struct("=dI")

    def __init__(self, bindata=None):
        self.x = None
        self.y = None
        if bindata is not None:
            self.unpack(bindata)

    def unpack(self, bindata):
        self.x, self.y = self.struct.unpack(bindata)

    def pack(self):
        return self.struct.pack(self.x, self.y)


class PyBoundingBox():
    struct = struct.Struct("=dIdIdI")

    def __init__(self, bindata=None):
        self.northwest = PyPoint()
        self.southeast = PyPoint()
        self.northsouth = PyPoint()
        if bindata is not None:
            self.unpack(bindata)

    def unpack(self, bindata):
        self.northwest.x, self.northwest.y, \
            self.southeast.x, self.southeast.y, \
            self.northsouth.x, self.northsouth.y = self.struct.unpack(bindata)

    def pack(self):
        return self.struct.pack(
            self.northwest.x, self.northwest.y,
            self.southeast.x, self.southeast.y,
            self.northsouth.x, self.northsouth.y)


class PyExtents():
    struct = struct.Struct("=ddIdIdI")

    def __init__(self, bindata=None):
        self.count = None
        self.extents = PyBoundingBox()
        if bindata is not None:
            self.unpack(bindata)

    def unpack(self, bindata):
        self.count, \
            self.extents.northwest.x, self.extents.northwest.y, \
            self.extents.southeast.x, self.extents.southeast.y, \
            self.extents.northsouth.x, \
            self.extents.northsouth.y = self.struct.unpack(bindata)

    def pack(self):
        return self.struct.pack(
            self.count,
            self.extents.northwest.x, self.extents.northwest.y,
            self.extents.southeast.x, self.extents.southeast.y,
            self.extents.northsouth.x, self.extents.northsouth.y)

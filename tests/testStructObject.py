from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
from __future__ import unicode_literals

import sys
import unittest
import struct
import calendar
import time

sys.path.append("..\\")

import cypyserialize


class Point(cypyserialize.SerializableObject):
    "Basic po1 class"
    x = cypyserialize.double()
    y = cypyserialize.double()


class Point3D(cypyserialize.SerializableObject):
    "Basic point class"
    x = cypyserialize.double()
    y = cypyserialize.double()
    z = cypyserialize.double()


class BoundingBox(cypyserialize.SerializableObject):
    northwest = Point()
    southeast = Point()


class SerializableObjectTests(unittest.TestCase):

    def testByte(self):
        class GenericContainer(cypyserialize.SerializableObject):
            a = cypyserialize.schar()
            b = cypyserialize.uchar()
        s = struct.pack("bB", -2**6, 2**7)
        obj = GenericContainer(s)
        self.assertEqual(obj.a, -2**6)
        self.assertEqual(obj.b, 2**7)

    def testShort(self):
        class GenericContainer(cypyserialize.SerializableObject):
            a = cypyserialize.short()
            b = cypyserialize.ushort()
        s = struct.pack("hH", -2**14, 2**15)
        obj = GenericContainer(s)
        self.assertEqual(obj.a, -2**14)
        self.assertEqual(obj.b, 2**15)

    def testInt(self):
        class GenericContainer(cypyserialize.SerializableObject):
            a = cypyserialize.sint()
            b = cypyserialize.uint()
        s = struct.pack("iI", -2**30, 2**31)
        obj = GenericContainer(s)
        self.assertEqual(obj.a, -2**30)
        self.assertEqual(obj.b, 2**31)

    def testLongLong(self):
        class GenericContainer(cypyserialize.SerializableObject):
            a = cypyserialize.longlong()
            b = cypyserialize.ulonglong()
        s = struct.pack("qQ", -2**62, 2**63)
        obj = GenericContainer(s)
        self.assertEqual(obj.a, -2**62)
        self.assertEqual(obj.b, 2**63)

    def testInitSetByAttribute(self):
        p = Point()
        self.assertEqual(list(p.items()), [('x', None), ('y', None)])
        p.x = 5000.0
        p.y = 300.5
        self.assertEqual(list(p.items()), [('x', 5000.0), ('y', 300.5)])

    def testInitImplicitOrder(self):
        p = Point(5000.0, 300.5)
        self.assertEqual(list(p.items()), [('x', 5000.0), ('y', 300.5)])

    def testInitExplicitNames(self):
        p = Point(y=300.5, x=5000.0)
        self.assertEqual(list(p.items()), [('x', 5000.0), ('y', 300.5)])

    def testInitMixedOrdering(self):
        p = Point(5000.0, y=300.5)
        self.assertEqual(list(p.items()), [('x', 5000.0), ('y', 300.5)])

    def testInitImplicitList(self):
        p = Point((5000.0, 300.5))
        self.assertEqual(list(p.items()), [('x', 5000.0), ('y', 300.5)])

    def testInitExplicitDict(self):
        p = Point({'x': 5000.0, 'y': 300.5})
        self.assertEqual(list(p.items()), [('x', 5000.0), ('y', 300.5)])

    def testPack(self):
        p = Point(5000.0, 300.5)
        self.assertEqual(p.pack(), struct.pack('dd', 5000.0, 300.5))

    def testPackWithSubstructure(self):
        bb = BoundingBox(Point(0.0, 10.0), southeast=Point(15.0, 0.0))
        self.assertEqual(bb.pack(), struct.pack(b'dddd', 0.0, 10.0, 15.0, 0.0))

    def testPackWithSetter(self):
        class Generic(cypyserialize.SerializableObject):
            timestamp = cypyserialize.uint(
                setter=calendar.timegm,
                getter=time.gmtime
            )

        t = Generic(timestamp=time.gmtime(100))
        self.assertEqual(t.pack(), struct.pack('I', 100))

    def testUnpackWithGetter(self):
        class Generic(cypyserialize.SerializableObject):
            timestamp = cypyserialize.uint(
                setter=calendar.timegm,
                getter=time.gmtime
            )

        t = Generic(struct.pack('I', 100))
        self.assertEqual(t.timestamp, time.gmtime(100))

    def testGetItemWithString(self):
        bb = BoundingBox(Point(0.0, 10.0), southeast=Point(15.0, 0.0))
        self.assertEqual(bb['northwest.y'], 10.0)
        self.assertEqual(bb.northwest['y'], 10.0)

    def testGetItemWithInt(self):
        p = Point(5000.0, 300.5)
        self.assertEqual(p[1], 300.5)
        self.assertRaises(IndexError, p.__getitem__, 3)

    def testGetItemWithSlice(self):
        p = Point(5000.0, 300.5)
        self.assertEqual(p[:], [5000.0, 300.5])
        self.assertEqual(p[:1], [5000.0])
        self.assertEqual(p[1:], [300.5])

    def testGetItemWithObj(self):
        p = Point(5000.0, 300.5)
        self.assertRaises(Exception, p.__getitem__, int)

    def testSetItemWithString(self):
        bb = BoundingBox()
        bb['northwest.y'] = 15.0
        self.assertEqual(bb.northwest.y, 15.0)
        bb.northwest['y'] = 20.0
        self.assertEqual(bb.northwest.y, 20.0)

    def testSetItemWithInt(self):
        p = Point()
        p[1] = 300.5
        self.assertEqual(p.y, 300.5)
        self.assertRaises(IndexError, p.__setitem__, 3, 500.0)

    def testSetItemWithSlice(self):
        p = Point()
        p[:] = [5000.0, 300.5]
        self.assertEqual(p.values(), [5000.0, 300.5])
        p[:1] = [5000.0]
        self.assertEqual(p.x, 5000.0)
        p[1:] = [300.5]
        self.assertEqual(p.y, 300.5)

    def testSetItemWithObj(self):
        p = Point()
        self.assertRaises(Exception, p.__setitem__, int)

    def testOverloading(self):
        class GenericBoundingBox(cypyserialize.SerializableObject):
            northwest = cypyserialize.none()
            southeast = cypyserialize.none()

        class BoundingBox3D(GenericBoundingBox):
            northwest = Point3D()
            southeast = Point3D()

        bb = BoundingBox3D(Point3D(10.0, 20.0, 30.0))
        self.assertEqual(bb.northwest.z, 30.0)

    def testOverloadingNotImplemented(self):
        class GenericBoundingBox(cypyserialize.SerializableObject):
            northwest = cypyserialize.none()
            southeast = cypyserialize.none()
        GenericBoundingBox()  # has to be instanciated once
        self.assertRaises(NotImplementedError, GenericBoundingBox)

    def testInitWithWrongObjectTypeForField(self):
        self.assertRaises(TypeError, BoundingBox, Point3D())

    def testSetAttrWithWrongObjectTypeForField(self):
        bb = BoundingBox()
        p = Point3D()
        self.assertRaises(TypeError, bb.__setattr__, 'northwest', p)

    def testUpdateWithDict(self):
        p = Point()
        p.update({'y': 300.5, 'x': 5000.0})
        self.assertEqual(list(p.items()), [('x', 5000.0), ('y', 300.5)])

    def testUpdateWithList(self):
        p = Point()
        p.update([('y', 300.5), ('x', 5000.0)])
        self.assertEqual(list(p.items()), [('x', 5000.0), ('y', 300.5)])

    def testUpdateWithNamed(self):
        p = Point()
        p.update(y=300.5, x=5000.0)
        self.assertEqual(list(p.items()), [('x', 5000.0), ('y', 300.5)])

    def testUpdateWithBoth(self):
        p = Point()
        p.update({'y': 300.5}, x=5000.0)
        self.assertEqual(list(p.items()), [('x', 5000.0), ('y', 300.5)])
        p.update([('y', 400.5)], x=6000.0)
        self.assertEqual(list(p.items()), [('x', 6000.0), ('y', 400.5)])

    def testUpdateWithBothOrderPrecidence(self):
        p = Point()
        p.update({'x': 6000.0}, x=5000.0)
        self.assertEqual(p.x, 5000.0)

    def testUpdateWithBadType(self):
        p = Point()
        self.assertRaises(TypeError, p.update, 5000.0)

    def testUpdateWithTooManyParameters(self):
        p = Point()
        msg = "update expected at most 1 arguments, got 2"
        self.assertRaisesRegex(TypeError, msg, p.update, 5000.0, 6000.0)

    def testSize(self):
        bb = BoundingBox()
        self.assertEqual(bb.size, 32)

    def testUnpack(self):
        s = struct.pack('dddd', 0.0, 10.0, 15.0, 0.0)
        bb = BoundingBox(s)
        self.assertEqual(list(bb.northwest.items()), [('x', 0.0), ('y', 10.0)])
        self.assertEqual(list(bb.southeast.items()), [('x', 15.0), ('y', 0.0)])

    def testLen(self):
        bb = BoundingBox()
        p = Point3D()
        self.assertEqual(len(bb), 2)
        self.assertEqual(len(p), 3)

    def testOverloadingFixesIssue1(self):
        # covers fix #1
        class GenericDatagram(cypyserialize.SerializableObject):
            STX = cypyserialize.uchar(value=0x02)
            timestamp = cypyserialize.uint()
            body = cypyserialize.none()
            ETX = cypyserialize.uchar(value=0x03)

        class BoundingBoxDatagram(GenericDatagram):
            body = BoundingBox()

        bbgram = BoundingBoxDatagram(timestamp=100)
        self.assertEqual(bbgram.timestamp, 100)

    def testOverloadingWithNewFieldRaisesException(self):
        class Generic(cypyserialize.SerializableObject):
            myfield = cypyserialize.none()
        with self.assertRaises(Exception):
            class Overload(Generic):
                newfield = Point()
            Overload()

    def testSlotsWithOverloading(self):
        class BetterBoundingBox(BoundingBox):
            __slots__ = ('area', )

            def __init__(self, *args, **kargs):
                self.area = (self.southeast.x - self.northwest.x) * \
                            (self.northwest.y - self.southeast.y)

        bb = BetterBoundingBox(Point(0, 10), Point(10, 0))
        self.assertEqual(bb.area, 100)

    @unittest.expectedFailure
    def testRemappingOnChildAttributesIssue1(self):
        # child attributes are descriptors that change their interal reference
        # to point to a values list in the root object on access. This is
        # problemetic if people want a reference to the child attribute, as
        # currently the values it points to can change if they interact with
        # another instance of the root parent.

        bb = BoundingBox()  # should be all 'None'
        southeast = bb.southeast  # grabbing the child object
        bb2 = BoundingBox(Point(5, 5), Point(10, 10))

        self.assertNotEqual(southeast.values(), bb2.southeast.values())
        # we should not have remapped, so they should still not be equal
        self.assertNotEqual(southeast.values(), bb2.southeast.values())

        # we should have the same values as bb
        self.assertEqual(southeast.values() == bb.southeast.values())  # False

if __name__ == '__main__':
    unittest.main()

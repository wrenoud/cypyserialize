from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
from __future__ import unicode_literals

import unittest
import struct
import sys

sys.path.append("..\\")

import cypyserialize


class Point(cypyserialize.SerializableObject):
    "Basic point class"
    x = cypyserialize.double()
    y = cypyserialize.double()


class Path(cypyserialize.SerializableObject):
    # the points
    points = cypyserialize.SerializableArray(
        Point(),
        count=cypyserialize.uint()
    )


class DoubleList(cypyserialize.SerializableObject):
    count = cypyserialize.uint(default=6)
    doubles = cypyserialize.SerializableArray(cypyserialize.double(), 6)


class structArrayTests(unittest.TestCase):

    def testAppendSimpleObject(self):
        d = DoubleList()

        d.doubles.append(3)
        d.doubles.append(4)

        self.assertEqual(d.doubles[1], 4)

    def testAppend(self):
        p = Path()
        p.points.append(0.0, 10.0)
        self.assertEqual(list(p.points[0].items()), [('x', 0.0), ('y', 10.0)])

    def testPack(self):
        p = Path()
        p.points.append(0.0, 10.0)
        self.assertEqual(p.pack(), struct.pack('<Idd', 1, 0.0, 10.0))

    def testUnpack(self):
        s = struct.pack('<Idddd', 2, 0.0, 10.0, 10.0, 20.0)
        p = Path(s)
        self.assertEqual(list(p.points[0].items()), [('x', 0.0), ('y', 10.0)])
        self.assertEqual(list(p.points[1].items()), [('x', 10.0), ('y', 20.0)])

    def testObjectTypeStructFieldWOLenIssue6(self):
        class generic_string(cypyserialize.SerializableObject):
            text = cypyserialize.SerializableArray(
                cypyserialize.char()
            )

        s = bytes('Hello World', "ASCII")
        o = generic_string(bytes('Hello World', "ASCII"))
        self.assertEqual(o.text[:], [x for x in s])

    def testBadObjectType(self):
        with self.assertRaises(Exception):
            cypyserialize.SerializableArray(Point)

    def testAssignObjectByIndex(self):
        p = Path()
        for i in range(4):
            p.points.append(i*10.0, i*10.0)
        p.points[0].x = 3.14159
        self.assertEqual(p.points[0].x, 3.14159)

    def testAssignFieldByIndex(self):
        d = DoubleList()

        d.doubles.append(4)
        d.doubles.append(4)
        d.doubles[0] = 3.14
        self.assertEqual(d.doubles[0], 3.14)

if __name__ == '__main__':
    unittest.main()

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
from __future__ import unicode_literals

import unittest
import struct
import sys

sys.path.append("..\\")

import src as cypyserialize


class Point(cypyserialize.StructObjectBase):
    "Basic point class"
    x = cypyserialize.double()
    y = cypyserialize.double()


class Path(cypyserialize.StructObjectBase):
    # the number of points in the path
    point_count = cypyserialize.uint()
    # the points
    points = cypyserialize.StructArrayBase(
        object_type=Point(),
        count=lambda self: self.point_count
    )


class DoubleList(cypyserialize.StructObjectBase):
    count = cypyserialize.uint(default=6)
    doubles = cypyserialize.StructArrayBase(cypyserialize.double(), 6)


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
        self.assertEqual(p.pack(), struct.pack('Idd', 1, 0.0, 10.0))

    def testUnpack(self):
        p = Path(struct.pack('Idddd', 2, 0.0, 10.0, 10.0, 20.0))
        self.assertEqual(list(p.points[0].items()), [('x', 0.0), ('y', 10.0)])
        self.assertEqual(list(p.points[1].items()), [('x', 10.0), ('y', 20.0)])
        self.assertEqual(p.point_count, 2)

    def testObjectTypeStructFieldWOLenIssue6(self):
        class generic_string(cypyserialize.StructObjectBase):
            text = cypyserialize.StructArrayBase(
                object_type=cypyserialize.char()
            )

        s = bytes('Hello World', "ASCII")
        o = generic_string(bytes('Hello World', "ASCII"))
        self.assertEqual(o.text[:], [bytes(chr(x), "ASCII") for x in s])

    def testBadObjectType(self):
        with self.assertRaises(Exception):
            cypyserialize.StructArrayBase(object_type=Point)

if __name__ == '__main__':
    unittest.main()

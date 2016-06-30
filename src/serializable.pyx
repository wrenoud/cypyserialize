# cython: profile=True
# 

import inspect
import types
import struct as structure

from libc.stdint cimport int8_t, uint8_t, int16_t, uint16_t, int32_t, uint32_t, int64_t, uint64_t

cimport cython

from .serializers cimport *

string_types = None
try:
    unicode
    # python 2
    string_types = (str, unicode)
except:
    # python 3
    string_types = (bytes, str)

# global counter used to detect declaration order
cdef uint64_t STRUCT_OBJECT_COUNTER = 0

cdef class Serializeable(object):
    """Descriptor class used for modeling a binary field or a fixed array of fields

    """
    cdef:
        readonly uint64_t __id               # instance id, used to infer declaration order of fields 
        readonly unicode  __name             # field name used to identify instance in parent container
        readonly uint64_t __index            # field index in parent container

    def __cinit__(self, *args, **kargs):
        global STRUCT_OBJECT_COUNTER

        self.__id = STRUCT_OBJECT_COUNTER = STRUCT_OBJECT_COUNTER + 1
        self.__name = None

    cpdef SetName(self, name):
        self.__name = name

    cpdef SetIndex(self, index):
        self.__index = index

cdef class SerializableField(Serializeable):
    """
    Acts as a descriptor class for a class attribute in a BinaryObjectBase
    """
    __flat = True # boolean flag indicating if size is reportable a-priori

    cdef:
        public bytes    __format  # a struct Format String, see https://docs.python.org/3.5/library/struct.html#format-strings
        public object   __python_t
        object          __default
        list            __setters
        list            __getters
        list            __validators
        serializer_t    _unpacker
        deserializer_t  _packer
        readonly size_t size

    def AddSetter(self, func):
        if self.__setters is None:
            self.__setters = []
        self.__setters.append(func)

    def AddGetter(self, func):
        if self.__getters is None:
            self.__getters = []
        self.__getters.append(func)

    def AddValidator(self, func):
        if self.__validators is None:
            self.__validators = []
        self.__validators.append(func)

    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.__default = None
        self.__setters = []
        self.__getters = []
        self.__validators = []
        self.__name = None

        if default is not None: self.__default = default
        if getter is not None: self.AddGetter(getter)
        if setter is not None: self.AddSetter(setter)
        if value is not None:
            self.__default = value

            def match_value(x):
                return x == value

            self.AddValidator(match_value)

    def __get__(self, parent, parent_type):
        if parent is None:
            return self
        return self.get_by__index(parent, self.__index)

    def __set__(self, parent, value):
        if value is None:
            parent.__values[self.__index] = self.__default
        else:
            self.set_by__index(parent, self.__index, value)

    cdef inline object get_by__index(self, Serializeable parent, uint64_t index):
        cdef object _tmp = parent.__values[index]
        for getter in self.__getters:
            _tmp = getter(_tmp)
        return _tmp

    cdef inline object set_by__index(self, Serializeable parent, uint64_t index, object value):
        for setter in self.__setters:
            value = setter(value)
        if self.__validators is not None:
            self.validate(value)
        parent.__values[index] = value

    def validate(self, value):
        if self.__validators is not None:
            for validator in self.__validators:
                if not validator(value):
                    raise Exception("Failed validator: {} with value {}".format(validator.__name__, value))

    cdef object _unpack(self, const unsigned char * buffer, uint32_t * offset):
        return make_object_from_variant(self._unpacker(buffer, offset))


cdef class pad(SerializableField):
    """padding byte"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.__format = b'x'
        self.__python_t = str
        self._unpacker = get_uint8
        self._packer = set_uint8
        self.size = sizeof(uint8_t)


cdef class char(SerializableField):
    """string of length 1"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.__format = b'c'
        self.__python_t = str
        self._unpacker = get_uint8
        self._packer = set_uint8
        self.size = sizeof(uint8_t)


cdef class schar(SerializableField):
    """signed char"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.__format = b'b'
        self.__python_t = int
        self._unpacker = get_int8
        self._packer = set_int8
        self.size = sizeof(int8_t)


cdef class uchar(SerializableField):
    """unsigned char"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.__format = b'B'
        self.__python_t = int
        self._unpacker = get_uint8
        self._packer = set_uint8
        self.size = sizeof(uint8_t)


cdef class bool(SerializableField):
    """boolean value"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.__format = b'?'
        self.__python_t = bool
        self._unpacker = get_uint8
        self._packer = set_uint8
        self.size = sizeof(uint8_t)


cdef class short(SerializableField):
    """short"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.__format = b'h'
        self.__python_t = int
        self._unpacker = get_int16
        self._packer = set_int16
        self.size = sizeof(int16_t)


cdef class ushort(SerializableField):
    """unsigned short"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.__format = b'H'
        self.__python_t = int
        self._unpacker = get_uint16
        self._packer = set_uint16
        self.size = sizeof(uint16_t)


cdef class sint(SerializableField):
    """signed integer"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.__format = b'i'
        self.__python_t = int
        self._unpacker = get_int32
        self._packer = set_int32
        self.size = sizeof(int32_t)


cdef class uint(SerializableField):
    """unsigned integer"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.__format = b'I'
        self.__python_t = int
        self._unpacker = get_uint32
        self._packer = set_uint32
        self.size = sizeof(uint32_t)

# aliases for int32 types
cdef class long(sint): pass
cdef class ulong(uint): pass


cdef class longlong(SerializableField):
    """signed long"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.__format = b'l'
        self.__python_t = int
        self._unpacker = get_int64
        self._packer = set_int64
        self.size = sizeof(int64_t)


cdef class ulonglong(SerializableField):
    """unsigned long"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.__format = b'L'
        self.__python_t = int
        self._unpacker = get_uint64
        self._packer = set_uint64
        self.size = sizeof(uint64_t)


cdef class double(SerializableField):
    """double"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.__format = b'd'
        self.__python_t = float
        self._unpacker = get_double
        self._packer = set_double
        self.size = sizeof(double)


cdef class float(SerializableField):
    """float"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.__format = b'f'
        self.__python_t = float
        self._unpacker = get_float
        self._packer = set_float
        self.size = sizeof(float)


class none(SerializableField):
    pass


native = b'='
little_endian = b'<'
big_endian = b'>'
network = b'!'

cdef class SerializableBase(Serializeable):
    cdef:
        readonly bint __flat
        public list __values

cdef class SerializableObject(SerializableBase):
    __slots__ = ()
    # __flat = True           # boolean flag indicating if size is reportable a-priori, assumed true until shown to be not
    # _partial_class = False # flag indicating child fields have been defined, but not as readable type

    def __cinit__(self, *args, **kargs):
        cdef uint32_t argc = len(args)
        cdef uint32_t kargc = len(kargs)

        if "_field_order" not in self.__class__.__dict__:
            sz = 0
            fields = []
            self.__class__._partial_class = False
            self.__class__.__flat = True

            is_subclass_of_base = SerializableObject in self.__class__.__bases__

            # migrate any superclass fields into subclass
            if not is_subclass_of_base:
                _base = self.__class__.__bases__[0]
                _base() # create an instance to force creation of _field_order
                for key in _base._field_order:
                    if key not in self.__class__.__dict__:
                        setattr(self.__class__, key, _base.__dict__[key])

                # adopt parent's field order
                self.__class__._field_order = _base._field_order

                # ensure attributes are included in _field_order
                for key, attr in self.__class__.__dict__.items():
                    if issubclass(attr.__class__, Serializeable) and key not in _base._field_order:
                        raise Exception("Class attribute '{}' is not not a sublass of StructBase, it's order cannot be determined.".format(key))

            # update status based on fields
            for key, attr in self.__class__.__dict__.items():
                if isinstance(attr, none):
                    self.__class__._partial_class = True
                if issubclass(attr.__class__, Serializeable):
                    if not attr.__flat:
                        self.__class__.__flat = False
                    attr.SetName(key)
                    fields.append((key, attr.__id))
                    if not isinstance(attr, none):
                        sz += attr.size

            self.__class__._size = sz

            # we'll need to make the _field_order if we don't have a parent that already figured it out
            if is_subclass_of_base:
                # sort by id
                fields = sorted(fields, key=lambda item: item[1])
                # grab names
                self.__class__._field_order = []
                for i, (field__name, creation__index) in enumerate(fields):
                    self.__class__.__dict__[field__name].SetIndex(i)
                    self.__class__._field_order.append(field__name)
        
        elif self.__class__._partial_class:
            raise NotImplementedError('{} has NoneType fields that must be implemented in a subclass'.format(self.__class__.__name__))

        # handle special cases where list or dict used
        if argc == 1:
            if isinstance(args[0], (list, tuple)):
                args = args[0]
            elif isinstance(args[0], dict):
                kargs = args[0]
                args=[]
      
        # check for binary data
        if len(args) == 1 and isinstance(args[0], string_types + (memoryview, type(b''))):
            self.unpack(args[0])
        elif len(args) > 0 or len(kargs) > 0:
            self.__values = []
            for i, field__name in enumerate(self.__class__._field_order):
                self.__values.append(None)
                # assign order parameter and defaults for remainder
                if i < len(args):
                    self.__setattr__(field__name, args[i])

            if len(kargs) > 0:
                self.update(kargs)
        else:
            self.__values = []
            # no information to populate, need to fill up with empty data just in case
            for i in range(self.__len__()):
                self.__values.append(None)

    def AddSetter(self, func, field__name):
        if field__name in self.__class__._field_order:
            self.__class__.__dict__[field__name].AddSetter(func)
        else:
            raise AttributeError("{} is not an attribute of {}".format(field__name, self.__class__.__name__))

    def AddGetter(self, func, field__name):
        if field__name in self.__class__._field_order:
            self.__class__.__dict__[field__name].AddSetter(func)
        else:
            raise AttributeError("{} is not an attribute of {}".format(field__name, self.__class__.__name__))

    def AddValidator(self, func, field__name):
        if field__name in self.__class__._field_order:
            self.__class__.__dict__[field__name].AddSetter(func)
        else:
            raise AttributeError("{} is not an attribute of {}".format(field__name, self.__class__.__name__))

    cdef inline void check_container(self, Serializeable parent, uint64_t index):
        """Checks that an appropriate empty value had been set for this field in it's parent"""
        cdef int i, n = self.__len__()
        if parent.__values[index] is None:
            # hasn't been initialized in parent, set all values to none
            parent.__values[index] = []
            for i in range(n):
                parent.__values[index].append(None)

    def __get__(self, parent, parent_type):
        if parent is None:
            return self
        else:
            return self.get_by__index(parent, self.__index)

    def __set__(self, parent, value):
        self.set_by__index(parent, self.__index, value)

    cdef inline object get_by__index(self, Serializeable parent, uint64_t index):
        # kansas city shuffle
        # retrieve values from parent, for now we'll masquerade as this parent's child
        self.check_container(parent, index)
        self.__values = parent.__values[index]
        return self

    cdef inline int set_by__index(self, Serializeable parent, uint64_t index, object value) except 1:
        self.check_container(parent, index)
        if issubclass(value.__class__, self.__class__):
            # copy pointer to outside values
            parent.__values[index] = value.__values
        else:
            raise TypeError("'{}' must be of type '{}', given '{}'".format(self.__name, self.__class__.__name__, value.__class__.__name__))

    def __setitem__(self, key, value):
        if isinstance(key, string_types):
            if '.' in key:
                field__names = key.split('.')
                obj = self.__getattribute__(field__names[0])
                for field__name in field__names[1:-1]:
                    obj = obj.__getattribute__(field__name)
                obj.__setattr__(field__names[-1], value)
            else:
                self.__setattr__(key, value)
        elif isinstance(key, int):
            if key < len(self.__class__._field_order):
                self.__setattr__(self.__class__._field_order[key], value)
            else:
                raise IndexError("Index: {} not in object".format(key))
        elif isinstance(key, slice):
            field__names = self.__class__._field_order[key]
            for i, field__name in enumerate(field__names):
                self.__setattr__(field__name, value[i])
        else:
            raise Exception("Unrecognized index: {} ({})".format(key, type(key)))

    def __getitem__(self, key):
        if isinstance(key, string_types):
            if '.' in key:
                _field__names = key.split('.')
                obj = self.__getattribute__(_field__names[0])
                for _field__name in _field__names[1:]:
                    obj = obj.__getattribute__(_field__name)
                return obj
            else:
                return self.__getattribute__(key)
        elif isinstance(key, int):
            if key < len(self.__class__._field_order):
                return self.__getattribute__(self.__class__._field_order[key])
            else:
                raise IndexError("Index: {} not in object".format(key))
        elif isinstance(key, slice):
            result = []
            for field__name in self.__class__._field_order[key]:
                field = self.__class__.__dict__[field__name]
                if issubclass(field.__class__, SerializableField):
                    result.append(field.__get__(self, self.__class__))
                elif issubclass(field.__class__, SerializableObject):
                    result.append(field)
            return result
        else:
            raise KeyError("Unrecognized index: {} ({})".format(key, type(key)))

    def __len__(self):
        return len(self.__class__._field_order)

    property size:
        def __get__(self):
            cdef int sz = 0
            if self.__class__.__flat:
                return self.__class__._size
            else:
                for key in self.__class__.__dict__['_field_order']:
                    sz += self.__class__.__dict__[key].size
                return sz

    def keys(self):
        return self.__class__._field_order

    def values(self):
        values = []
        for key in self.__class__._field_order:
            values.append(self.__getattribute__(key))
        return values

    def items(self):
        return zip(self.__class__._field_order, self.values())

    def unpack(self, bindata):
        cdef uint32_t offset
        self.__values = []
        self._unpack(bindata, &offset, self.__values)
        # self._size = offset

    cdef int _unpack(self, const unsigned char * bindata, uint32_t * offset, list container) except -1:
        cdef str field__name
        cdef object field
        cdef list _field_list = self.__class__._field_order
        
        for field__name in _field_list:
            field = self.__class__.__dict__[field__name]

            if issubclass(field.__class__, SerializableField):
                container.append(make_object_from_variant((<SerializableField>field)._unpacker(bindata, offset)))
            elif issubclass(field.__class__, SerializableObject):
                container.append([])
                SerializableObject._unpack(field, bindata, offset, container[-1])
            elif issubclass(field.__class__, SerializableArray):
                container.append([])
                SerializableArray._unpack(field, bindata, offset, container[-1], self)
            else:
                raise Exception("Attempted to use unknown Serializeable ({}) to unpack.".format(type(field)))

    def pack(self):
        cdef bytearray buff = bytearray()
        self._pack(buff, self.__values)
        return buff

    cdef int _pack(self, bytearray buff, list container) except -1:
        cdef str field__name
        cdef object field
        cdef list _field_list = self.__class__._field_order
        
        for field__name in _field_list:
            field = self.__class__.__dict__[field__name]

            if container[field.__index] is None:
                raise Exception("{} not set".format(field__name))

            if issubclass(field.__class__, SerializableField):
                (<SerializableField>field)._packer(buff, container[field.__index])
            elif issubclass(field.__class__, SerializableObject):
                SerializableObject._pack(field, buff, container[field.__index])
            elif issubclass(field.__class__, SerializableArray):
                SerializableArray._pack(field, buff, container[field.__index])
            else:
                raise Exception("Attempted to use unknown Serializeable ({}) to unpack.".format(type(field)))

    def update(self, *args, **kargs):
        "Same functionality as dict.update(). "
        # if unnamed parameters used lets update the kargs and work from there
        if len(args) == 1:
            if isinstance(args[0], dict):
                # named parameters take precedence
                _tmp = args[0]
                _tmp.update(kargs)
                kargs = args[0]
            elif isinstance(args[0], (list, tuple)):
                # named parameters take precedence
                _tmp = dict(args[0])
                _tmp.update(kargs)
                kargs = _tmp
            else:
                raise TypeError("parameter type '{}' not supported by update".format(args[0].__class__.__name__))
        elif len(args) > 1:
            raise TypeError('update expected at most 1 arguments, got {}'.format(len(args)))

        for key, value in kargs.items():
            self.__setattr__(key,value)


cdef class SerializableArray(SerializableBase):
    cdef:
        readonly Serializeable __element_t
        object __count

    def __cinit__(self, __element_t, count=None):
        self.__flat = False
        if isinstance(count, int):
            self.__flat = True
        
        self.__count = count
        self.__element_t = __element_t

        if not issubclass(__element_t.__class__, Serializeable):
            raise Exception("Not an instance of a class that subclasses Serializeable")

        if self.__count is None:
            if not self.__element_t.__flat:
                raise Exception("Unbounded size unsupported in SerializableArray for variable size type {}".format(__element_t.__class__.__name__))

        self.__values = []

    def __get__(self, parent, parent_type):
        if parent is not None:
            # kansas city shuffle
            # retrieve values from parent, for now we'll masquerade as this parent's child
            if parent.__values[self.__index] is None:
                # hasn't been initialized in parent, set all values to none
                # self.__set__(parent, None)
                parent.__values[self.__index] = []
            self.__values = parent.__values[self.__index]
        return self

    def __set__(self, parent, value):
        # create empty dict in parent
        if value is None:
            self.__values = parent.__values[self.__index] = []
        elif issubclass(value.__class__, self.__class__):
            # copy pointer to outside values
            parent.__values[self.__index] = value.__values
        elif issubclass(value.__class__, list):
            parent.__values[self.__index] = value
        elif issubclass(value.__class__, tuple):
            parent.__values[self.__index] = list(value)
        else:
            raise TypeError("'{}' must be of type '{}', given '{}'".format(self.__name, self.__class__.__name__, value.__class__.__name__))

    def __len__(self):
        return len(self.__values)

    def __getitem__(self, key):
        if isinstance(key, int):
            if issubclass(self.__element_t.__class__, SerializableField):
                return (<SerializableField>self.__element_t).get_by__index(self, key)
            elif issubclass(self.__element_t.__class__, SerializableObject):
                return (<SerializableObject>self.__element_t).get_by__index(self, key)
        elif isinstance(key, slice):
            values = []
            for i in range(*key.indices(self.__len__())):
                values.append(self.__getitem__(i))
            return values
        else:

            raise Exception("Unrecognized index: {}".format(key))

    def __setitem__(self, key, value):
        if isinstance(key, int):
            if key < self.__len__():
                if issubclass(self.__element_t.__class__, SerializableField):
                    (<SerializableField>self.__element_t).set_by__index(self, key, value)
                elif issubclass(self.__element_t.__class__, SerializableObject):
                    (<SerializableObject>self.__element_t).set_by__index(self, key, value)
            else:
                raise IndexError("Index: {} not in object".format(key))
        elif isinstance(key, slice):
            if issubclass(self.__element_t.__class__, SerializableField):
                for i, index in enumerate(key.indices(self.__len__())):
                    (<SerializableField>self.__element_t).set_by__index(self, index, value)
            elif issubclass(self.__element_t.__class__, SerializableObject):
                for i, index in enumerate(key.indices(self.__len__())):
                    (<SerializableObject>self.__element_t).set_by__index(self, index, value)
        else:
            raise Exception("Unrecognized index: {}".format(key))

    def append(self, *args, **kargs):
        if issubclass(self.__element_t.__class__, SerializableField):
            self.__values.append(None)
            (<SerializableField>self.__element_t).set_by__index(self, self.__len__() - 1, args[0])
        elif issubclass(self.__element_t.__class__, SerializableObject):
            # TODO: this is ineficient, it creates a new descriptor for each item
            obj = self.__element_t.__class__(*args,**kargs)
            self.__values.append(obj.__values)

    property size:
        def __get__(self):
            if issubclass(self.__element_t.__class__, SerializableField):
                return self.__element_t.size * self.__len__()
            elif issubclass(self.__element_t.__class__, SerializableObject) and self.__element_t.__flat:
                return self.__element_t.size * self.__len__()
            else:
                size = 0
                for obj in self.__values:
                    size += obj.size
                return size

    cdef int _unpack(self, const unsigned char * bindata, uint32_t * offset, list container, object parent) except -1:
        cdef int i, count = 0

        if self.__count is None:
            count = len(bindata) - offset[0] - len(bindata) % self.__element_t.size
        else:
            if isinstance(self.__count, SerializableField):
                count = make_object_from_variant((<SerializableField>self.__count)._unpacker(bindata, offset))
            elif isinstance(self.__count, int):
                count = self.__count
            else: # callable, i.e. lambda
                count = self.__count(parent)

        if issubclass(self.__element_t.__class__, SerializableField):
            for i in range(count):
                container.append(make_object_from_variant((<SerializableField>self.__element_t)._unpacker(bindata, offset)))
        elif issubclass(self.__element_t.__class__, SerializableObject):
            for i in range(count):
                container.append([])
                SerializableObject._unpack(self.__element_t, bindata, offset, container[-1])

    cdef int _pack(self, bytearray buff, list container) except -1:
        cdef int i, count = len(container)

        # if we're responsible for serializing the length we do it now
        if isinstance(self.__count, SerializableField):
            (<SerializableField>self.__count)._packer(buff, count)
       
        if issubclass(self.__element_t.__class__, SerializableField):
            for i in range(count):
                (<SerializableField>self.__element_t)._packer(buff, container[i])
        elif issubclass(self.__element_t.__class__, SerializableObject):
            for i in range(count):
                SerializableObject._pack(self.__element_t, buff, container[i])
        else:
            raise Exception("Attempted to use unknown Serializeable ({}) to unpack.".format(type(self.__element_t)))



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
        readonly uint64_t _id               # instance id, used to infer declaration order of fields 
        readonly unicode  _name             # field name used to identify instance in parent container
        readonly uint64_t _index            # field index in parent container

    def __cinit__(self, *args, **kargs):
        global STRUCT_OBJECT_COUNTER

        self._id = STRUCT_OBJECT_COUNTER = STRUCT_OBJECT_COUNTER + 1
        self._name = None

    cpdef SetName(self, name):
        self._name = name

    cpdef SetIndex(self, index):
        self._index = index

cdef class SerializableField(Serializeable):
    """
    Acts as a descriptor class for a class attribute in a BinaryObjectBase
    """
    _flat = True # boolean flag indicating if size is reportable a-priori

    cdef:
        public bytes format  # a struct Format String, see https://docs.python.org/3.5/library/struct.html#format-strings
        public object _python_type
        object _default
        list _structs
        list _setters
        list _getters
        list _validators
        serializer_t _unpacker
        deserializer_t _packer
        readonly size_t size

    #cpdef unpack(self, char * binbuffer, long offset, dict container):
    #    container[self._name] = (<double*>&binbuffer[offset])[0]
    
    def AddSetter(self, func):
        if self._setters is None:
            self._setters = []
        self._setters.append(func)

    def AddGetter(self, func):
        if self._getters is None:
            self._getters = []
        self._getters.append(func)

    def AddValidator(self, func):
        if self._validators is None:
            self._validators = []
        self._validators.append(func)

    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self._default = None
        self._setters = []
        self._getters = []
        self._validators = []
        self._name = None

        if default is not None: self._default = default
        if getter is not None: self.AddGetter(getter)
        if setter is not None: self.AddSetter(setter)
        if value is not None:
            self._default = value

            def match_value(x):
                return x == value

            self.AddValidator(match_value)

    def __get__(self, parent, parent_type):
        if parent is None:
            return self
        return self.get_by_index(parent, self._index)

    def __set__(self, parent, value):
        if value is None:
            parent.__values[self._index] = self._default
        else:
            self.set_by_index(parent, self._index, value)

    cdef inline object get_by_index(self, Serializeable parent, uint64_t index):
        cdef object _tmp = parent.__values[index]
        for getter in self._getters:
            _tmp = getter(_tmp)
        return _tmp

    cdef inline object set_by_index(self, Serializeable parent, uint64_t index, object value):
        for setter in self._setters:
            value = setter(value)
        if self._validators is not None:
            self.validate(value)
        parent.__values[index] = value

    def validate(self, value):
        if self._validators is not None:
            for validator in self._validators:
                if not validator(value):
                    raise Exception("Failed validator: {} with value {}".format(validator.__name__, value))

    cdef object _unpack(self, const unsigned char * buffer, long * offset):
        return make_object_from_variant(self._unpacker(buffer, offset))


cdef class pad(SerializableField):
    """padding byte"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.format = b'x'
        self._python_type = str
        self._unpacker = get_uint8
        self._packer = set_uint8
        self.size = sizeof(uint8_t)


cdef class char(SerializableField):
    """string of length 1"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.format = b'c'
        self._python_type = str
        self._unpacker = get_uint8
        self._packer = set_uint8
        self.size = sizeof(uint8_t)


cdef class schar(SerializableField):
    """signed char"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.format = b'b'
        self._python_type = int
        self._unpacker = get_int8
        self._packer = set_int8
        self.size = sizeof(int8_t)


cdef class uchar(SerializableField):
    """unsigned char"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.format = b'B'
        self._python_type = int
        self._unpacker = get_uint8
        self._packer = set_uint8
        self.size = sizeof(uint8_t)


cdef class bool(SerializableField):
    """boolean value"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.format = b'?'
        self._python_type = bool
        self._unpacker = get_uint8
        self._packer = set_uint8
        self.size = sizeof(uint8_t)


cdef class short(SerializableField):
    """short"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.format = b'h'
        self._python_type = int
        self._unpacker = get_int16
        self._packer = set_int16
        self.size = sizeof(int16_t)


cdef class ushort(SerializableField):
    """unsigned short"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.format = b'H'
        self._python_type = int
        self._unpacker = get_uint16
        self._packer = set_uint16
        self.size = sizeof(uint16_t)


cdef class sint(SerializableField):
    """signed integer"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.format = b'i'
        self._python_type = int
        self._unpacker = get_int32
        self._packer = set_int32
        self.size = sizeof(int32_t)


cdef class uint(SerializableField):
    """unsigned integer"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.format = b'I'
        self._python_type = int
        self._unpacker = get_uint32
        self._packer = set_uint32
        self.size = sizeof(uint32_t)

# aliases for int32 types
cdef class long(sint): pass
cdef class ulong(uint): pass


cdef class longlong(SerializableField):
    """signed long"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.format = b'l'
        self._python_type = int
        self._unpacker = get_int64
        self._packer = set_int64
        self.size = sizeof(int64_t)


cdef class ulonglong(SerializableField):
    """unsigned long"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.format = b'L'
        self._python_type = int
        self._unpacker = get_uint64
        self._packer = set_uint64
        self.size = sizeof(uint64_t)


cdef class double(SerializableField):
    """double"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.format = b'd'
        self._python_type = float
        self._unpacker = get_double
        self._packer = set_double
        self.size = sizeof(double)


cdef class float(SerializableField):
    """float"""
    def __cinit__(self, default=None, getter=None, setter=None, value=None):
        self.format = b'f'
        self._python_type = float
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
        readonly bint _flat
        public list __values

cdef class SerializableObject(SerializableBase):
    __slots__ = ()
    # _flat = True           # boolean flag indicating if size is reportable a-priori, assumed true until shown to be not
    # _partial_class = False # flag indicating child fields have been defined, but not as readable type

    def __cinit__(self, *args, **kargs):
        cdef long argc = len(args)
        cdef long kargc = len(kargs)

        if "_field_order" not in self.__class__.__dict__:
            sz = 0
            fields = []
            self.__class__._partial_class = False
            self.__class__._flat = True

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
                    if not attr._flat:
                        self.__class__._flat = False
                    attr.SetName(key)
                    fields.append((key, attr._id))
                    if not isinstance(attr, none):
                        sz += attr.size

            self.__class__._size = sz

            # we'll need to make the _field_order if we don't have a parent that already figured it out
            if is_subclass_of_base:
                # sort by id
                fields = sorted(fields, key=lambda item: item[1])
                # grab names
                self.__class__._field_order = []
                for i, (field_name, creation_index) in enumerate(fields):
                    self.__class__.__dict__[field_name].SetIndex(i)
                    self.__class__._field_order.append(field_name)
        
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
            for i, field_name in enumerate(self.__class__._field_order):
                self.__values.append(None)
                # assign order parameter and defaults for remainder
                if i < len(args):
                    self.__setattr__(field_name, args[i])

            if len(kargs) > 0:
                self.update(kargs)
        else:
            self.__values = []
            # no information to populate, need to fill up with empty data just in case
            for i in range(self.__len__()):
                self.__values.append(None)

    def AddSetter(self, func, field_name):
        if field_name in self.__class__._field_order:
            self.__class__.__dict__[field_name].AddSetter(func)
        else:
            raise AttributeError("{} is not an attribute of {}".format(field_name, self.__class__.__name__))

    def AddGetter(self, func, field_name):
        if field_name in self.__class__._field_order:
            self.__class__.__dict__[field_name].AddSetter(func)
        else:
            raise AttributeError("{} is not an attribute of {}".format(field_name, self.__class__.__name__))

    def AddValidator(self, func, field_name):
        if field_name in self.__class__._field_order:
            self.__class__.__dict__[field_name].AddSetter(func)
        else:
            raise AttributeError("{} is not an attribute of {}".format(field_name, self.__class__.__name__))

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
            return self.get_by_index(parent, self._index)

    def __set__(self, parent, value):
        self.set_by_index(parent, self._index, value)

    cdef inline object get_by_index(self, Serializeable parent, uint64_t index):
        # kansas city shuffle
        # retrieve values from parent, for now we'll masquerade as this parent's child
        self.check_container(parent, index)
        self.__values = parent.__values[index]
        return self

    cdef inline int set_by_index(self, Serializeable parent, uint64_t index, object value) except 1:
        self.check_container(parent, index)
        if issubclass(value.__class__, self.__class__):
            # copy pointer to outside values
            parent.__values[index] = value.__values
        else:
            raise TypeError("'{}' must be of type '{}', given '{}'".format(self._name, self.__class__.__name__, value.__class__.__name__))

    def __setitem__(self, key, value):
        if isinstance(key, string_types):
            if '.' in key:
                field_names = key.split('.')
                obj = self.__getattribute__(field_names[0])
                for field_name in field_names[1:-1]:
                    obj = obj.__getattribute__(field_name)
                obj.__setattr__(field_names[-1], value)
            else:
                self.__setattr__(key, value)
        elif isinstance(key, int):
            if key < len(self.__class__._field_order):
                self.__setattr__(self.__class__._field_order[key], value)
            else:
                raise IndexError("Index: {} not in object".format(key))
        elif isinstance(key, slice):
            field_names = self.__class__._field_order[key]
            for i, field_name in enumerate(field_names):
                self.__setattr__(field_name, value[i])
        else:
            raise Exception("Unrecognized index: {} ({})".format(key, type(key)))

    def __getitem__(self, key):
        if isinstance(key, string_types):
            if '.' in key:
                _field_names = key.split('.')
                obj = self.__getattribute__(_field_names[0])
                for _field_name in _field_names[1:]:
                    obj = obj.__getattribute__(_field_name)
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
            for field_name in self.__class__._field_order[key]:
                field = self.__class__.__dict__[field_name]
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
            if self.__class__._flat:
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
        cdef long offset
        self.__values = []
        self._unpack(bindata, &offset, self.__values)
        # self._size = offset

    cdef int _unpack(self, const unsigned char * bindata, long * offset, list container) except -1:
        cdef str field_name
        cdef object field
        cdef list _field_list = self.__class__._field_order
        
        for field_name in _field_list:
            field = self.__class__.__dict__[field_name]

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
        cdef str field_name
        cdef object field
        cdef list _field_list = self.__class__._field_order
        
        for field_name in _field_list:
            field = self.__class__.__dict__[field_name]

            if container[field._index] is None:
                raise Exception("{} not set".format(field_name))

            if issubclass(field.__class__, SerializableField):
                (<SerializableField>field)._packer(buff, container[field._index])
            elif issubclass(field.__class__, SerializableObject):
                SerializableObject._pack(field, buff, container[field._index])
            elif issubclass(field.__class__, SerializableArray):
                SerializableArray._pack(field, buff, container[field._index])
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
        readonly Serializeable object_type
        object _length

    def __cinit__(self, object_type, count=None):
        #if "_flat" not in self.__class__.__dict__:
        self._flat = False
        if isinstance(count, int):
            self._flat = True
        
        self._length = count
        self.object_type = object_type

        if not issubclass(object_type.__class__, Serializeable):
            raise Exception("Not an instance of a class that subclasses Serializeable")

        if self._length is None:
            if not self.object_type._flat:
                raise Exception("Unbounded size unsupported in SerializableArray for variable size type {}".format(object_type.__class__.__name__))

        self.__values = []

    def __get__(self, parent, parent_type):
        if parent is not None:
            # kansas city shuffle
            # retrieve values from parent, for now we'll masquerade as this parent's child
            if parent.__values[self._index] is None:
                # hasn't been initialized in parent, set all values to none
                # self.__set__(parent, None)
                parent.__values[self._index] = []
            self.__values = parent.__values[self._index]
        return self

    def __set__(self, parent, value):
        # create empty dict in parent
        if value is None:
            self.__values = parent.__values[self._index] = []
        elif issubclass(value.__class__, self.__class__):
            # copy pointer to outside values
            parent.__values[self._index] = value.__values
        elif issubclass(value.__class__, list):
            parent.__values[self._index] = value
        elif issubclass(value.__class__, tuple):
            parent.__values[self._index] = list(value)
        else:
            raise TypeError("'{}' must be of type '{}', given '{}'".format(self._name, self.__class__.__name__, value.__class__.__name__))

    def __len__(self):
        return len(self.__values)

    def __getitem__(self, key):
        if isinstance(key, int):
            if issubclass(self.object_type.__class__, SerializableField):
                return (<SerializableField>self.object_type).get_by_index(self, key)
            elif issubclass(self.object_type.__class__, SerializableObject):
                return (<SerializableObject>self.object_type).get_by_index(self, key)
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
                if issubclass(self.object_type.__class__, SerializableField):
                    (<SerializableField>self.object_type).set_by_index(self, key, value)
                elif issubclass(self.object_type.__class__, SerializableObject):
                    (<SerializableObject>self.object_type).set_by_index(self, key, value)
            else:
                raise IndexError("Index: {} not in object".format(key))
        elif isinstance(key, slice):
            if issubclass(self.object_type.__class__, SerializableField):
                for i, index in enumerate(key.indices(self.__len__())):
                    (<SerializableField>self.object_type).set_by_index(self, index, value)
            elif issubclass(self.object_type.__class__, SerializableObject):
                for i, index in enumerate(key.indices(self.__len__())):
                    (<SerializableObject>self.object_type).set_by_index(self, index, value)
        else:
            raise Exception("Unrecognized index: {}".format(key))

    def append(self, *args, **kargs):
        if issubclass(self.object_type.__class__, SerializableField):
            self.__values.append(None)
            (<SerializableField>self.object_type).set_by_index(self, self.__len__() - 1, args[0])
        elif issubclass(self.object_type.__class__, SerializableObject):
            # TODO: this is ineficient, it creates a new descriptor for each item
            obj = self.object_type.__class__(*args,**kargs)
            self.__values.append(obj.__values)

    property size:
        def __get__(self):
            if issubclass(self.object_type.__class__, SerializableField):
                return self.object_type.size * self.__len__()
            elif issubclass(self.object_type.__class__, SerializableObject) and self.object_type._flat:
                return self.object_type.size * self.__len__()
            else:
                size = 0
                for obj in self.__values:
                    size += obj.size
                return size

    cdef int _unpack(self, const unsigned char * bindata, long * offset, list container, object parent) except -1:
        cdef int i, count = 0

        if self._length is None:
            count = len(bindata) - offset[0] - len(bindata) % self.object_type.size
        else:
            if isinstance(self._length, SerializableField):
                count = make_object_from_variant((<SerializableField>self._length)._unpacker(bindata, offset))
            elif isinstance(self._length, int):
                count = self._length
            else: # callable, i.e. lambda
                count = self._length(parent)

        if issubclass(self.object_type.__class__, SerializableField):
            for i in range(count):
                container.append(make_object_from_variant((<SerializableField>self.object_type)._unpacker(bindata, offset)))
        elif issubclass(self.object_type.__class__, SerializableObject):
            for i in range(count):
                container.append([])
                SerializableObject._unpack(self.object_type, bindata, offset, container[-1])

    cdef int _pack(self, bytearray buff, list container) except -1:
        cdef int i, count = len(container)

        # if we're responsible for serializing the length we do it now
        if isinstance(self._length, SerializableField):
            (<SerializableField>self._length)._packer(buff, count)
       
        if issubclass(self.object_type.__class__, SerializableField):
            for i in range(count):
                (<SerializableField>self.object_type)._packer(buff, container[i])
        elif issubclass(self.object_type.__class__, SerializableObject):
            for i in range(count):
                SerializableObject._pack(self.object_type, buff, container[i])
        else:
            raise Exception("Attempted to use unknown Serializeable ({}) to unpack.".format(type(self.object_type)))



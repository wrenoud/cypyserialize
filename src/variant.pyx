
cdef variant_container make_int8_variant(int8_t value) nogil:
    cdef variant_container var
    var.type = INT8
    var.value.var_int8 = value
    return var

cdef variant_container make_uint8_variant(uint8_t value) nogil:
    cdef variant_container var
    var.type = UINT8
    var.value.var_uint8 = value
    return var

cdef variant_container make_int16_variant(int16_t value) nogil:
    cdef variant_container var
    var.type = INT16
    var.value.var_int16 = value
    return var

cdef variant_container make_uint16_variant(uint16_t value) nogil:
    cdef variant_container var
    var.type = UINT16
    var.value.var_uint16 = value
    return var

cdef variant_container make_int32_variant(int32_t value) nogil:
    cdef variant_container var
    var.type = INT32
    var.value.var_int32 = value
    return var

cdef variant_container make_uint32_variant(uint32_t value) nogil:
    cdef variant_container var
    var.type = UINT32
    var.value.var_uint32 = value
    return var

cdef variant_container make_int64_variant(int64_t value) nogil:
    cdef variant_container var
    var.type = INT64
    var.value.var_int64 = value
    return var

cdef variant_container make_uint64_variant(uint64_t value) nogil:
    cdef variant_container var
    var.type = UINT64
    var.value.var_uint64 = value
    return var

cdef variant_container make_double_variant(double value) nogil:
    cdef variant_container var
    var.type = DOUBLE
    var.value.var_double = value
    return var

cdef variant_container make_float_variant(float value) nogil:
    cdef variant_container var
    var.type = FLOAT
    var.value.var_float = value
    return var

cdef object make_object_from_variant(variant_container var):
    if var.type == INT8:
        return var.value.var_int8
    elif var.type == UINT8:
        return var.value.var_uint8
    elif var.type == INT16:
        return var.value.var_int16
    elif var.type == UINT16:
        return var.value.var_uint16
    elif var.type == INT32:
        return var.value.var_int32
    elif var.type == UINT32:
        return var.value.var_uint32
    elif var.type == INT64:
        return var.value.var_int64
    elif var.type == UINT64:
        return var.value.var_uint64
    elif var.type == DOUBLE:
        return var.value.var_double
    elif var.type == FLOAT:
        return var.value.var_float

cdef class PyVariant(object):

    def __cinit(self, variant_container var):
        self._var = var

    property value:
        def __get__(self):
            if self._var.type == INT8:
                return self._var.value.var_int8
            elif self._var.type == UINT8:
                return self._var.value.var_uint8
            elif self._var.type == INT16:
                return self._var.value.var_int16
            elif self._var.type == UINT16:
                return self._var.value.var_uint16
            elif self._var.type == INT32:
                return self._var.value.var_int32
            elif self._var.type == UINT32:
                return self._var.value.var_uint32
            elif self._var.type == INT64:
                return self._var.value.var_int64
            elif self._var.type == UINT64:
                return self._var.value.var_uint64
            elif self._var.type == DOUBLE:
                return self._var.value.var_double
            elif self._var.type == FLOAT:
                return self._var.value.var_float

        def __set__(self, value):
            if self._var.type == INT8:
                self._var.value.var_int8 = value
            elif self._var.type == UINT8:
                self._var.value.var_uint8 = value
            elif self._var.type == INT16:
                self._var.value.var_int16 = value
            elif self._var.type == UINT16:
                self._var.value.var_uint16 = value
            elif self._var.type == INT32:
                self._var.value.var_int32 = value
            elif self._var.type == UINT32:
                self._var.value.var_uint32 = value
            elif self._var.type == INT64:
                self._var.value.var_int64 = value
            elif self._var.type == UINT64:
                self._var.value.var_uint64 = value
            elif self._var.type == DOUBLE:
                self._var.value.var_double = value
            elif self._var.type == FLOAT:
                self._var.value.var_float = value

    cdef variant_container GetVariant(self):
        return self._var
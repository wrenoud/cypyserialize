from libc.stdint cimport int8_t, uint8_t, int16_t, uint16_t, int32_t, uint32_t, int64_t, uint64_t

cdef enum variant_type:
    INT8
    UINT8
    INT16
    UINT16
    INT32
    UINT32
    INT64
    UINT64
    DOUBLE
    FLOAT

cdef union variant_union:
    int8_t   var_int8
    uint8_t  var_uint8
    int16_t  var_int16
    uint16_t var_uint16
    int32_t  var_int32
    uint32_t var_uint32
    int64_t  var_int64
    uint64_t var_uint64
    double   var_double
    float    var_float

cdef struct variant_container:
    variant_type type
    variant_union value

cdef variant_container make_int8_variant(int8_t value) nogil
cdef variant_container make_uint8_variant(uint8_t value) nogil
cdef variant_container make_int16_variant(int16_t value) nogil
cdef variant_container make_uint16_variant(uint16_t value) nogil
cdef variant_container make_int32_variant(int32_t value) nogil
cdef variant_container make_uint32_variant(uint32_t value) nogil
cdef variant_container make_int64_variant(int64_t value) nogil
cdef variant_container make_uint64_variant(uint64_t value) nogil
cdef variant_container make_double_variant(double value) nogil
cdef variant_container make_float_variant(float value) nogil

cdef object make_object_from_variant(variant_container var)

cdef class PyVariant(object):
    cdef public variant_container _var

    cdef variant_container GetVariant(self)
from .variant cimport *

ctypedef variant_container (*serializer_t)(const unsigned char *, long *)

cdef variant_container get_int8(const unsigned char * binbuffer, long *offset)
cdef variant_container get_uint8(const unsigned char * binbuffer, long *offset)
cdef variant_container get_int16(const unsigned char * binbuffer, long *offset)
cdef variant_container get_uint16(const unsigned char * binbuffer, long *offset)
cdef variant_container get_int32(const unsigned char * binbuffer, long *offset)
cdef variant_container get_uint32(const unsigned char * binbuffer, long *offset)
cdef variant_container get_int64(const unsigned char * binbuffer, long *offset)
cdef variant_container get_uint64(const unsigned char * binbuffer, long *offset)
cdef variant_container get_double(const unsigned char * binbuffer, long *offset)
cdef variant_container get_float(const unsigned char * binbuffer, long *offset)

ctypedef void (*deserializer_t)(bytearray, object)

cdef void set_int8(bytearray binbuffer, object var)
cdef void set_uint8(bytearray binbuffer, object var)
cdef void set_int16(bytearray binbuffer, object var)
cdef void set_uint16(bytearray binbuffer, object var)
cdef void set_int32(bytearray binbuffer, object var)
cdef void set_uint32(bytearray binbuffer, object var)
cdef void set_int64(bytearray binbuffer, object var)
cdef void set_uint64(bytearray binbuffer, object var)
cdef void set_double(bytearray binbuffer, object var)
cdef void set_float(bytearray binbuffer, object var)
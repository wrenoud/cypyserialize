
# int8_t
cdef variant_container get_int8(const unsigned char * binbuffer, long *offset):
    cdef variant_container var
    var = make_int8_variant((<int8_t*>&binbuffer[offset[0]])[0])
    offset[0] += sizeof(int8_t)
    return var

cdef void set_int8(bytearray buff, object obj):
    cdef int i
    cdef int8_t value = obj
    for i in range(sizeof(int8_t)):
        buff.append((<uint8_t *>&value)[i])

# uint8_t
cdef variant_container get_uint8(const unsigned char * binbuffer, long *offset):
    cdef variant_container var
    var = make_uint8_variant((<uint8_t*>&binbuffer[offset[0]])[0])
    offset[0] += sizeof(uint8_t)
    return var

cdef void set_uint8(bytearray buff, object obj):
    cdef int i
    cdef uint8_t value = obj
    for i in range(sizeof(uint8_t)):
        buff.append((<uint8_t *>&value)[i])

# int16_t
cdef variant_container get_int16(const unsigned char * binbuffer, long *offset):
    cdef variant_container var
    var = make_int16_variant((<int16_t*>&binbuffer[offset[0]])[0])
    offset[0] += sizeof(int16_t)
    return var

cdef void set_int16(bytearray buff, object obj):
    cdef int i
    cdef int16_t value = obj
    for i in range(sizeof(int16_t)):
        buff.append((<uint8_t *>&value)[i])

# uint16_t
cdef variant_container get_uint16(const unsigned char * binbuffer, long *offset):
    cdef variant_container var
    var = make_uint16_variant((<uint16_t*>&binbuffer[offset[0]])[0])
    offset[0] += sizeof(uint16_t)
    return var

cdef void set_uint16(bytearray buff, object obj):
    cdef int i
    cdef uint16_t value = obj
    for i in range(sizeof(uint16_t)):
        buff.append((<uint8_t *>&value)[i])

# int32_t
cdef variant_container get_int32(const unsigned char * binbuffer, long *offset):
    cdef variant_container var
    var = make_int32_variant((<int32_t*>&binbuffer[offset[0]])[0])
    offset[0] += sizeof(int32_t)
    return var

cdef void set_int32(bytearray buff, object obj):
    cdef int i
    cdef int32_t value = obj
    for i in range(sizeof(int32_t)):
        buff.append((<uint8_t *>&value)[i])

# uint32_t
cdef variant_container get_uint32(const unsigned char * binbuffer, long *offset):
    cdef variant_container var
    var = make_uint32_variant((<uint32_t*>&binbuffer[offset[0]])[0])
    offset[0] += sizeof(uint32_t)
    return var

cdef void set_uint32(bytearray buff, object obj):
    cdef int i
    cdef uint32_t value = obj
    for i in range(sizeof(uint32_t)):
        buff.append((<uint8_t *>&value)[i])

# int64_t
cdef variant_container get_int64(const unsigned char * binbuffer, long *offset):
    cdef variant_container var
    var = make_int64_variant((<int64_t*>&binbuffer[offset[0]])[0])
    offset[0] += sizeof(int64_t)
    return var

cdef void set_int64(bytearray buff, object obj):
    cdef int i
    cdef int64_t value = obj
    for i in range(sizeof(int64_t)):
        buff.append((<uint8_t *>&value)[i])

# uint64_t
cdef variant_container get_uint64(const unsigned char * binbuffer, long *offset):
    cdef variant_container var
    var = make_uint64_variant((<uint64_t*>&binbuffer[offset[0]])[0])
    offset[0] += sizeof(uint64_t)
    return var

cdef void set_uint64(bytearray buff, object obj):
    cdef int i
    cdef uint64_t value = obj
    for i in range(sizeof(uint64_t)):
        buff.append((<uint8_t *>&value)[i])

# double
cdef variant_container get_double(const unsigned char * binbuffer, long *offset):
    cdef variant_container var
    var = make_double_variant((<double*>&binbuffer[offset[0]])[0])
    offset[0] += sizeof(double)
    return var

cdef void set_double(bytearray buff, object obj):
    cdef int i
    cdef double value = obj
    for i in range(sizeof(double)):
        buff.append((<uint8_t *>&value)[i])

# float
cdef variant_container get_float(const unsigned char * binbuffer, long *offset):
    cdef variant_container var
    var = make_float_variant((<float*>&binbuffer[offset[0]])[0])
    offset[0] += sizeof(float)
    return var

cdef void set_float(bytearray buff, object obj):
    cdef int i
    cdef float value = obj
    for i in range(sizeof(float)):
        buff.append((<uint8_t *>&value)[i])


if __name__ == "__main__":
    types = []
    for i in [8,16,32,64]:
        for s in ['','u']:
           types.append([s + "int" + str(i),'_t'])

    types.append(['double', ''])
    types.append(['float', ''])

    for p,s in types:
            print("""
    # {0}{1}
    cdef variant_container get_{0}(const unsigned char * binbuffer, long *offset):
        cdef variant_container var
        var = make_{0}_variant((<{0}{1}*>&binbuffer[offset[0]])[0])
        offset[0] += sizeof({0}{1})
        return var

    cdef void set_{0}(bytearray buff, object obj):
        cdef int i
        cdef {0}{1} value = obj
        for i in range(sizeof({0}{1})):
            buff.append((<uint8_t *>&value)[i])""".format(p,s))

module utils.value;

import tagvalue;
import std.exception;

/// Emplace value at address $(D p).
/// Assumes that enough memory is allocated at that address.
/// (You can find needed amount of memory with $(D sizeInBytes) function)
void emplaceValue(ubyte* p, ref Value v) {
    enforce(!v.is_nothing, "null value can't be stored in BAM");

    auto tag = v.tag;
    auto size = tag >> 5; // element size

    static ubyte* arrayPointer(ref Value v) {
        // if value contains array, as a tagged union, it has the following layout:
        //
        // Value = size_t
        //         void*
        //         other stuff...
        return cast(ubyte*)(*(cast(size_t*)(&v) + 1));
    }

    if ((tag & 1) == 0) { // primitive type
        *p++ = cast(ubyte)v.bam_typeid;

        p[0 .. size] = (cast(ubyte*)(&v))[0 .. size];
    } else {
        
        auto bytes = *cast(size_t*)(&v) * (tag >> 5);

        if (v.is_string) {
            *p++ = cast(ubyte)v.bam_typeid;
            
            p[0 .. bytes] = arrayPointer(v)[0 .. bytes];
            p[bytes] = 0; // trailing zero

        } else {
            *p++ = cast(ubyte)'B';
            *p++ = cast(ubyte)v.bam_typeid;

            *(cast(uint*)p) = cast(uint)(bytes / size); // # of elements
            p += uint.sizeof;

            p[0 .. bytes] = arrayPointer(v)[0 .. bytes];
        }
    }
}

/// Calculate size in bytes which value will consume in BAM file.
size_t sizeInBytes(ref Value v) {
    enforce(!v.is_nothing, "null value can't be stored in BAM");

    auto tag = v.tag;

    if ((tag & 1) == 0) {
        return char.sizeof + (tag >> 5); // primitive type
    } 

    auto bytes = *cast(size_t*)(&v) * (tag >> 5);

    if (v.is_string) {
        return char.sizeof + bytes + char.sizeof; // trailing zero
    } else {
        return 2 * char.sizeof + uint.sizeof + bytes;
    }
}

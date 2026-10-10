#include <cstdint>
#include <cstddef>
#include <cstring>

// Compatibility stubs for MSVC STL vectorized algorithms referenced by prebuilt
// Firebase C++ SDK libraries compiled with newer MSVC toolsets (VS 2022 / v143).
// This enables clean linking on Visual Studio 2019 (v142).

extern "C" {

const void* __cdecl __std_find_trivial_1(const void* _First, const void* _Last, uint8_t _Val) {
    const uint8_t* cur = static_cast<const uint8_t*>(_First);
    const uint8_t* end = static_cast<const uint8_t*>(_Last);
    while (cur < end) {
        if (*cur == _Val) return cur;
        ++cur;
    }
    return end;
}

const void* __cdecl __std_find_trivial_8(const void* _First, const void* _Last, uint64_t _Val) {
    const uint64_t* cur = static_cast<const uint64_t*>(_First);
    const uint64_t* end = static_cast<const uint64_t*>(_Last);
    while (cur < end) {
        if (*cur == _Val) return cur;
        ++cur;
    }
    return end;
}

const void* __cdecl __std_find_last_trivial_1(const void* _First, const void* _Last, uint8_t _Val) {
    const uint8_t* cur = static_cast<const uint8_t*>(_Last);
    const uint8_t* start = static_cast<const uint8_t*>(_First);
    while (cur > start) {
        --cur;
        if (*cur == _Val) return cur;
    }
    return static_cast<const uint8_t*>(_Last);
}

void* __cdecl __std_remove_8(void* _First, void* _Last, uint64_t _Val) {
    uint64_t* cur = static_cast<uint64_t*>(_First);
    uint64_t* end = static_cast<uint64_t*>(_Last);
    while (cur < end && *cur != _Val) {
        ++cur;
    }
    if (cur == end) return end;
    uint64_t* next = cur + 1;
    while (next < end) {
        if (*next != _Val) {
            *cur = *next;
            ++cur;
        }
        ++next;
    }
    return cur;
}

size_t __cdecl __std_find_first_of_trivial_pos_1(
    const char* const _First1,
    const size_t _Count1,
    const char* const _First2,
    const size_t _Count2) {
    for (size_t i = 0; i < _Count1; ++i) {
        const char ch = _First1[i];
        for (size_t j = 0; j < _Count2; ++j) {
            if (ch == _First2[j]) {
                return i;
            }
        }
    }
    return static_cast<size_t>(-1);
}

size_t __cdecl __std_find_last_of_trivial_pos_1(
    const char* const _First1,
    const size_t _Count1,
    const char* const _First2,
    const size_t _Count2) {
    for (size_t i = _Count1; i > 0; --i) {
        const char ch = _First1[i - 1];
        for (size_t j = 0; j < _Count2; ++j) {
            if (ch == _First2[j]) {
                return i - 1;
            }
        }
    }
    return static_cast<size_t>(-1);
}

} // extern "C"

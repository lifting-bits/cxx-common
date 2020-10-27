set(LIBRARY_ROOT "${CXX_COMMON_REPOSITORY_ROOT}/drdecode")

set(DRDECODE_FOUND TRUE)
set(DRDECODE_INCLUDE_DIRS "${LIBRARY_ROOT}/include")

set(DRDECODE_LIBRARIES
    ${LIBRARY_ROOT}/lib64/release/libdrdecode.a
    ${LIBRARY_ROOT}/lib64/libdrhelper.a
)

mark_as_advanced(FORCE DRDECODE_FOUND)
mark_as_advanced(FORCE DRDECODE_INCLUDE_DIRS)
mark_as_advanced(FORCE DRDECODE_LIBRARIES)




include(${CMAKE_CURRENT_LIST_DIR}/../../shared_cmake/llvm-17.cmake)

set(ref_hsh llvmorg-${VERSION})
set(rep_sha256 df68879cb3f23489e19bbec4aac1898d213e837132072f8bbc1a49eb561c8cc7ccdb6ae9202b68b0915c84c8f2b41e536ab690697eb8ab8c9f44d5ae600b575b)

set(patches 0001-Fix-install-paths.patch
    0006-Fix-libffi.patch
    0020-fix-FindZ3.cmake.patch
    0021-fix-find_dependency.patch
    0026-fix-prefix-path-calc.patch
    0029-Do-not-attempt-macro-expansion-on-invalid-sourceloc.patch)

cmake_language(CALL llvm-17-port llvm/llvm-project ${ref_hsh} ${rep_sha256} main ${patches})
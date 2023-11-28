include(${CMAKE_CURRENT_LIST_DIR}/../../shared_cmake/llvm-17.cmake)

set(ref_hsh b779442fffcf46f2dfc104217e1413d7d5b538d6)
set(rep_sha256 700ddc8c4b39b260a2041385128ef2bbe3bf6c0ff45d933d3d50d15f737892e2c7e817a4a11cda606b91364b99b10c884b76e040b321696effac7ce172720552)

set(patches 0001-Fix-install-paths.patch
    0006-Fix-libffi.patch
    0020-fix-FindZ3.cmake.patch
    0021-fix-find_dependency.patch
    0026-fix-prefix-path-calc.patch
    0029-Do-not-attempt-macro-expansion-on-invalid-sourceloc.patch)

cmake_language(CALL llvm-17-port trail-of-forks/llvm-project ${ref_hsh} ${rep_sha256} ian/custom-callingconvention-assignfns ${patches})
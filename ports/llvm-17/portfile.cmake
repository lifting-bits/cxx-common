

include(${CMAKE_CURRENT_LIST_DIR}/../../shared_cmake/llvm-17.cmake)

if("liftingbits-llvm" IN_LIST FEATURES)
    set(ref_hsh b779442fffcf46f2dfc104217e1413d7d5b538d6)
    set(rep_sha256 700ddc8c4b39b260a2041385128ef2bbe3bf6c0ff45d933d3d50d15f737892e2c7e817a4a11cda606b91364b99b10c884b76e040b321696effac7ce172720552)

    set(patches 0001-Fix-install-paths.patch 0006-Fix-libffi.patch 0020-fix-FindZ3.cmake.patch 0021-fix-find_dependency.patch 0026-fix-prefix-path-calc.patch 0029-Do-not-attempt-macro-expansion-on-invalid-sourceloc.patch)
else()
    set(ref_hsh llvmorg-${VERSION})
    set(rep_sha256 df68879cb3f23489e19bbec4aac1898d213e837132072f8bbc1a49eb561c8cc7ccdb6ae9202b68b0915c84c8f2b41e536ab690697eb8ab8c9f44d5ae600b575b)

    set(patches 0001-Fix-install-paths.patch 0006-Fix-libffi.patch 0020-fix-FindZ3.cmake.patch 0021-fix-find_dependency.patch 0026-fix-prefix-path-calc.patch 0029-Do-not-attempt-macro-expansion-on-invalid-sourceloc.patch)
endif()

cmake_language(CALL llvm-17-port llvm/llvm-project ${ref_hsh} ${rep_sha256} main ${patches})
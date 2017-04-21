#!/usr/bin/env bash

TEMPLATE_DESCRIPTOR_LIST=(
    "remill:llvm39,xed,gtest,glog,gflags,protobuf"
    "mcsema:llvm38,protobuf"
    "remill-experimental:llvm39,clang,gflags,glog,gtest"
    "everything:xed,llvm,clang,gflags,gtest,protobuf,glog"
)

LIBRARY_LIST=(
    "xed"
    "llvm"
    "clang"
    "gflags"
    "gtest"
    "protobuf"
    "glog"
)

DEFAULT_LLVM_VERSION=39

function main
{
    local target_list=`GetTargetListFromCommandLine $@`
    if [ -z "$target_list" ] ; then
        ShowUsage

        if [ $# -eq 1 ] && [ "$1" == "--help" ] ; then
            return 0
        fi

        printf "===\n\nInvalid parameter!\n"
        return 1
    fi

    printf "Target list: ${target_list}\n"

    local root_install_directory="$3"
    printf "Root install directory: ${root_install_directory}\n"

    local install_folder_name=`basename "$root_install_directory"`
    if [[ "$install_folder_name" != "libraries" ]] ; then
        printf "Please enter the full path of a folder named 'libraries'\n"
        return 1
    fi

    if [ -d "$root_install_directory" ] ; then
        rm -rf "$root_install_directory" 2> /dev/null
        if [ $? -ne 0 ] ; then
            printf "Failed to erase the following folder: ${root_install_directory}\n"
            return 1
        fi
    fi

    mkdir -p "$root_install_directory" 2> /dev/null
    if [ $? -ne 0 ] ; then
        printf "Failed to create the install directory\n"
        return 1
    fi

    printf "Checking dependencies...\n"
    CheckDependencies || return 1

    # notice the 'sort -u' command! it's important because we expect to find the 'clang''
    # before the 'llvm' in order to set the 'install_clang' flag before we call InstallLLVM!
    echo "$target_list" | tr ',' '\n' | sort -u | while read target_name ; do
        if [[ "$target_name" == "clang" ]] ; then
            local install_clang=1
            continue

        elif [[ "$target_name" == "llvm"* ]] ; then
            local llvm_version="${target_name:4}"
            target_name="llvm"
        fi

        if [[ "$target_name" == "xed" ]] ; then
            InstallXED "${root_install_directory}/xed" || return 1

        elif [[ "$target_name" == "gflags" ]] ; then
            InstallGoogleGflags "${root_install_directory}/gflags" || return 1

        elif [[ "$target_name" == "gtest" ]] ; then
            InstallGoogleTest "${root_install_directory}/googletest" || return 1

        elif [[ "$target_name" == "protobuf" ]] ; then
            InstallGoogleProtocolBuffers "${root_install_directory}/protobuf" || return 1

        elif [[ "$target_name" == "glog" ]] ; then
            InstallGoogleGlog "${root_install_directory}/glog" || return 1

        elif [[ "$target_name" == "llvm" ]] ; then
            if [ -z "$llvm_version" ] ; then
                llvm_version="${DEFAULT_LLVM_VERSION}"
            fi

            if [ -z "$install_clang" ] ; then
                local install_clang=0
            fi

            InstallLLVM "$llvm_version" "$install_clang" "${root_install_directory}/llvm" || return 1

        else
            printf "Unknown target!\n"
            return 1
        fi
    done

    if [ $? -eq 1 ] ; then
        return 1
    fi

    InstallCMakeModules "${root_install_directory}/cmake" || return 1

    rm "$LOG_FILE" 2> /dev/null

    printf "\nAdd the following line to your .bashrc/.zshenv file:\n"
    printf "  export TRAILOFBITS_LIBRARIES=${root_install_directory}\n"

    printf "\nAdd the following to your CMakeLists.txt file:\n"
    printf "  set(LIBRARY_REPOSITORY_ROOT \$ENV{TRAILOFBITS_LIBRARIES})\n"
    printf "  include(\"\${LIBRARY_REPOSITORY_ROOT}/cmake/repository.cmake\")\n"

    printf "\nYou can clean up this folder using git clean -ffdx!\n"
    return 0
}

function GetTargetListFromCommandLine
{
    if [ $# -ne 3 ] ; then
        return 0
    fi

    local command="$1"
    local parameters="$2"

    if [[ "$command" == "--template" ]] ; then
        for template_descriptor in ${TEMPLATE_DESCRIPTOR_LIST[@]} ; do
            local template_name=`echo "$template_descriptor" | cut -d ':' -f 1`
            local target_list=`echo "$template_descriptor" | cut -d ':' -f 2`

            if [[ "$template_name" == "$parameters" ]] ; then
                printf "$target_list"
                return 0
            fi
        done

    elif [[ "$command" == "--targets" ]] ; then
        echo "$parameters" | tr ',' '\n' | sort -u | while read selected_library_name ; do
            local selected_library_valid=0

            for available_library_name in ${LIBRARY_LIST[@]} ; do
                if [[ "$selected_library_name" == "llvm"* ]] ; then
                    selected_library_name="llvm"
                fi

                if [[ "$selected_library_name" == "$available_library_name" ]] ; then
                    selected_library_valid=1
                    break
                fi
            done

            if [ "$selected_library_valid" -eq 0 ] ; then
                echo "error"
                return 1
            else
                return 0
            fi
        done

        if [ $? -ne 0 ] ; then
            return 0
        fi

        printf "$parameters"
        return 0

    else
        return 0
    fi

    return 0
}

function ShowUsage
{
    printf "Usage:\n"
    printf "\tinstall_libraries.sh --template <name> /path/to/libraries\n"
    printf "\tinstall_libraries.sh --targets <lib1,..> /path/to/libraries\n"
    printf "\tinstall_libraries.sh --help\n\n"

    printf "Templates:\n"

    for template_descriptor in ${TEMPLATE_DESCRIPTOR_LIST[@]} ; do
        local template_name=`echo "$template_descriptor" | cut -d ':' -f 1`
        local target_list=`echo "$template_descriptor" | cut -d ':' -f 2 | tr ',' ' '`

        printf "\t${template_name}: ($target_list)\n"
    done

    printf "\n"

    printf "Targets:\n"
    printf "\txed\n"
    printf "\tllvm\n"
    printf "\tgflags\n"
    printf "\tgtest\n"
    printf "\tprotobuf\n"
    printf "\tglog\n"
    printf "\tclang\n\n"

    printf "The LLVM and clang version can be selected by appending the version\n"
    printf "number to the llvm target name. Example: llvm39, llvm38\n\n"

    printf "To install clang, you also have to add llvm to the target list (it is\n"
    printf "ignored otherwise).\n\n"

    return 0
}

function CheckDependencies
{
    # todo
    return 0
}

function ShowLog
{
    printf "An error as occurred and the script has terminated.\n"

    if [ ! -f "$LOG_FILE" ] ; then
        printf "No output log found\n"
        return 1
    fi

    printf "Output log follow\n================\n"
    cat "$LOG_FILE"
    printf "\n================\n"

    return 0
}

function InstallXED
{
    if [ $# -ne 1 ] ; then
        printf "Usage:\n"
        printf "\tInstallXED /path/to/libraries"

        return 1
    fi

    printf "\nXED\n"

    local install_directory="$1"
    printf " > Install directory: ${install_directory}\n"

    # acquire or update the source code
    rm "$LOG_FILE" 2> /dev/null
    if [ ! -d "xed" ] ; then
        printf " > Acquiring the source code...\n"
        git clone "https://github.com/intelxed/xed.git" xed >> "$LOG_FILE" 2>&1
    else
        printf " > Updating the source code...\n"
        ( cd "xed" && git pull origin master ) >> "$LOG_FILE" 2>&1
    fi

    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # acquire or update the build system for xed
    rm "$LOG_FILE" 2> /dev/null
    if [ ! -d "mbuild" ] ; then
        printf " > Acquiring the build system...\n"
        git clone "https://github.com/intelxed/mbuild.git" mbuild >> "$LOG_FILE" 2>&1
    else
        printf " > Updating the mbuild source code...\n"
        ( cd "mbuild" && git pull origin master ) >> "$LOG_FILE" 2>&1
    fi

    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # build and install the library
    printf " > Installing...\n"
    rm "$LOG_FILE" 2> /dev/null
    ( cd xed && python2 mfile.py "--prefix=${install_directory}" install ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    return 0
}

function InstallLLVM
{
    if [ $# -ne 3 ] ; then
        printf "Usage:\n"
        printf "\tInstallLLVM <version> <install_clang> /path/to/libraries\n\n"
        printf "version: the major and minor release without separators (i.e.: 38, 39)\n"
        printf "install_clang: pass 1 to install clang or 0 to skip it\n"

        return 1
    fi

    printf "\nLLVM\n"

    local version="$1"
    local install_clang="$2"
    local install_directory="$3"

    printf " > Version: ${version}\n"

    printf " > Installing Clang: "
    if [ "$install_clang" -eq 1 ] ; then
        printf "yes"
    else
        printf "no"
    fi
    printf "\n"

    printf " > Install directory: ${install_directory}\n"

    # acquire or update the source code
    rm "$LOG_FILE" 2> /dev/null
    if [ ! -d "llvm" ] ; then
        printf " > Acquiring the source code for LLVM...\n"
        git clone --depth 1 -b "release_${version}" "https://github.com/llvm-mirror/llvm.git" llvm >> "$LOG_FILE" 2>&1
    else
        printf " > Updating the source code for LLVM...\n"
        ( cd "llvm" && git pull origin "release_${version}" ) >> "$LOG_FILE" 2>&1
    fi

    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    if [ "$install_clang" -eq 1 ] ; then
        rm "$LOG_FILE" 2> /dev/null
        if [ ! -d "llvm/tools/clang" ] ; then
            printf " > Acquiring the source code for Clang...\n"
            git clone --depth 1 -b "release_${version}" "https://github.com/llvm-mirror/clang.git" llvm/tools/clang >> "$LOG_FILE" 2>&1
        else
            printf " > Updating the source code for Clang...\n"
            ( cd "llvm/tools/clang" && git pull origin "release_${version}" ) >> "$LOG_FILE" 2>&1
        fi

        if [ $? -ne 0 ] ; then
            ShowLog
            return 1
        fi
    fi

    # run cmake
    printf " > Configuring...\n"

    if [ ! -d "llvm-build" ] ; then
        mkdir "llvm-build" 2> /dev/null
        if [ $? -ne 0 ] ; then
            printf "Failed to create the build directory for LLVM: llvm-build\n"
            return 1
        fi
    fi

    rm "$LOG_FILE" 2> /dev/null
    ( cd "llvm-build" && cmake "-DCMAKE_INSTALL_PREFIX=${install_directory}" -DCMAKE_BUILD_TYPE="Release" -DLLVM_TARGETS_TO_BUILD="X86" -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_TESTS=OFF "../llvm" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # build and install
    printf " > Building...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "llvm-build" && make -j "$PROCESSOR_COUNT" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    printf " > Installing...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "llvm-build" && make install ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    return 0
}

function InstallGoogleGflags
{
    if [ $# -ne 1 ] ; then
        printf "Usage:\n"
        printf "\tInstallGoogleGflags /path/to/libraries"

        return 1
    fi

    printf "\nGoogle gflags\n"

    local install_directory="$1"
    printf " > Install directory: ${install_directory}\n"

    # acquire or update the source code
    rm "$LOG_FILE" 2> /dev/null
    if [ ! -d "gflags" ] ; then
        printf " > Acquiring the source code...\n"
        git clone "https://github.com/gflags/gflags.git" gflags >> "$LOG_FILE" 2>&1
    else
        printf " > Updating the source code...\n"
        ( cd "gflags" && git pull origin master ) >> "$LOG_FILE" 2>&1
    fi

    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # run cmake
    printf " > Configuring...\n"

    if [ ! -d "gflags-build" ] ; then
        mkdir "gflags-build" 2> /dev/null
        if [ $? -ne 0 ] ; then
            printf "Failed to create the build directory for Google gflags: gflags-build\n"
            return 1
        fi
    fi

    rm "$LOG_FILE" 2> /dev/null
    ( cd "gflags-build" && cmake "-DCMAKE_INSTALL_PREFIX=${install_directory}" -DCMAKE_BUILD_TYPE="Release" "../gflags" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # build and install
    printf " > Building...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "gflags-build" && make -j "$PROCESSOR_COUNT" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    printf " > Installing...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "gflags-build" && make install ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    return 0
}

function InstallGoogleTest
{
    if [ $# -ne 1 ] ; then
        printf "Usage:\n"
        printf "\tInstallGoogleTest /path/to/libraries"

        return 1
    fi

    printf "\nGoogle Test\n"

    local install_directory="$1"
    printf " > Install directory: ${install_directory}\n"

    # acquire or update the source code
    rm "$LOG_FILE" 2> /dev/null
    if [ ! -d "googletest" ] ; then
        printf " > Acquiring the source code...\n"
        git clone "https://github.com/google/googletest.git" googletest >> "$LOG_FILE" 2>&1
    else
        printf " > Updating the source code...\n"
        ( cd "googletest" && git pull origin master ) >> "$LOG_FILE" 2>&1
    fi

    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # run cmake
    printf " > Configuring...\n"

    if [ ! -d "googletest-build" ] ; then
        mkdir "googletest-build" 2> /dev/null
        if [ $? -ne 0 ] ; then
            printf "Failed to create the build directory for Google googletest: googletest-build\n"
            return 1
        fi
    fi

    rm "$LOG_FILE" 2> /dev/null
    ( cd "googletest-build" && cmake "-DCMAKE_INSTALL_PREFIX=${install_directory}" -DCMAKE_BUILD_TYPE="Release" "../googletest" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # build and install
    printf " > Building...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "googletest-build" && make -j "$PROCESSOR_COUNT" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    printf " > Installing...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "googletest-build" && make install ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    return 0
}

function InstallGoogleProtocolBuffers
{
    if [ $# -ne 1 ] ; then
        printf "Usage:\n"
        printf "\tInstallGoogleProtocolBuffers /path/to/libraries"

        return 1
    fi

    printf "\nGoogle Protocol Buffers\n"

    local install_directory="$1"
    printf " > Install directory: ${install_directory}\n"

    # acquire or update the source code
    rm "$LOG_FILE" 2> /dev/null
    if [ ! -d "protobuf" ] ; then
        printf " > Acquiring the source code...\n"
        git clone "https://github.com/google/protobuf.git" protobuf >> "$LOG_FILE" 2>&1
    else
        printf " > Updating the source code...\n"
        ( cd "protobuf" && git pull origin master ) >> "$LOG_FILE" 2>&1
    fi

    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # configure
    printf " > Configuring...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "protobuf" && ./autogen.sh ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    rm "$LOG_FILE" 2> /dev/null
    ( cd "protobuf" && ./configure "--prefix=${install_directory}" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # build and install
    printf " > Building...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "protobuf" && make -j "$PROCESSOR_COUNT" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    printf " > Installing...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "protobuf" && make install ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    return 0
}

function InstallGoogleGlog
{
    if [ $# -ne 1 ] ; then
        printf "Usage:\n"
        printf "\tInstallGoogleGlog /path/to/libraries"

        return 1
    fi

    printf "\nGoogle Logging module\n"

    local install_directory="$1"
    printf " > Install directory: ${install_directory}\n"

    # acquire or update the source code
    rm "$LOG_FILE" 2> /dev/null
    if [ ! -d "glog" ] ; then
        printf " > Acquiring the source code...\n"
        git clone "https://github.com/google/glog.git" glog >> "$LOG_FILE" 2>&1
    else
        printf " > Updating the source code...\n"
        ( cd "glog" && git pull origin master ) >> "$LOG_FILE" 2>&1
    fi

    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # run cmake
    printf " > Configuring...\n"

    if [ ! -d "glog-build" ] ; then
        mkdir "glog-build" 2> /dev/null
        if [ $? -ne 0 ] ; then
            printf "Failed to create the build directory for Google glog: glog-build\n"
            return 1
        fi
    fi

    rm "$LOG_FILE" 2> /dev/null
    ( cd "glog-build" && cmake "-DCMAKE_INSTALL_PREFIX=${install_directory}" -DCMAKE_BUILD_TYPE="Release" "../glog" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # build and install
    printf " > Building...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "glog-build" && make -j "$PROCESSOR_COUNT" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    printf " > Installing...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "glog-build" && make install ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    return 0
}

function InstallCMakeModules
{
    if [ $# -ne 1 ] ; then
        printf "Usage:\n"
        printf "\tInstallCMakeModules /path/to/libraries"

        return 1
    fi

    printf "\nCMake modules...\n"

    local build_sh_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    local install_directory="$1"

    printf " > Install directory: ${install_directory}\n"

    printf " > Copying...\n"
    rm "$LOG_FILE" 2> /dev/null
    cp -rp "$build_sh_directory/cmake" "$install_directory" >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    return 0
}

LOG_FILE="installer.log"

if [[ "$OSTYPE" == "darwin"* ]]; then
    PROCESSOR_COUNT=`sysctl -n hw.ncpu`
else
    PROCESSOR_COUNT=`nproc`
fi

main $@
exit $?

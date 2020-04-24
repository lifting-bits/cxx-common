ARG LLVM_VERSION=800
ARG arch=aarch64
ARG BOOTSTRAP=/opt/trailofbits/bootstrap
ARG LIBRARIES=/opt/trailofbits/libraries
ARG UBUNTU_BASE=arm64v8/ubuntu:18.04

FROM ${UBUNTU_BASE} as base
ARG BOOTSTRAP
ARG LIBRARIES
ARG LLVM_VERSION

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -qqy python3 python3-pip build-essential \
         liblzma-dev clang libssl-dev && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install -U pip setuptools
RUN pip3 install requests

RUN mkdir -p /cxx-common
WORKDIR /cxx-common
COPY . ./

RUN mkdir -p "${BOOTSTRAP}" && mkdir -p "${LIBRARIES}"

RUN ./pkgman.py \
  --c_compiler=/usr/bin/clang \
  --cxx_compiler=/usr/bin/clang++ \
  --repository_path="${BOOTSTRAP}" \
  --packages=cmake && \
  rm -rf build && mkdir build && \
  rm -rf sources && mkdir sources

RUN ./pkgman.py \
  --c_compiler=/usr/bin/clang \
  --cxx_compiler=/usr/bin/clang++ \
  --llvm_version=${LLVM_VERSION} \
  --verbose \
  --exclude_libcxx \
  "--additional_paths=${BOOTSTRAP}/cmake/bin" \
  "--repository_path=${LIBRARIES}" \
  "--packages=llvm" && \
  rm -rf build && mkdir build && \
  rm -rf sources && mkdir sources

FROM base as cxx-common-build

WORKDIR /cxx-common
ARG BOOTSTRAP
ARG LIBRARIES

RUN ./pkgman.py \
  --cxx_compiler="${LIBRARIES}/llvm/bin/clang++" \
  --c_compiler="${LIBRARIES}/llvm/bin/clang" \
  --verbose \
  "--additional_paths=${BOOTSTRAP}/cmake/bin:${LIBRARIES}/llvm/bin" \
  "--repository_path=${LIBRARIES}" \
  "--packages=cmake,capstone,google,xed,capnproto" && \
  rm -rf build && mkdir build && \
  rm -rf sources && mkdir sources

ENTRYPOINT ["/bin/bash"]

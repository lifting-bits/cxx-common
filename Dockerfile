ARG LLVM_VERSION=800
ARG BOOTSTRAP=/opt/trailofbits/bootstrap
ARG LIBRARIES=/opt/trailofbits/libraries
ARG UBUNTU_BASE=ubuntu:18.04

FROM ${UBUNTU_BASE} as base
ARG BOOTSTRAP
ARG LIBRARIES
ARG LLVM_VERSION

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -qqy --no-install-recommends liblzma5 libssl1.1 && \
    rm -rf /var/lib/apt/lists/*

# bootstrap image should be what's needed to get a more reproducible build
# environment for cxx-common
FROM base as bootstrap
ARG BOOTSTRAP
ARG LIBRARIES
ARG LLVM_VERSION

RUN apt-get update && \
    apt-get install -qqy ninja-build python2.7 python3 python3-pip build-essential ccache \
         liblzma-dev clang libssl-dev && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install -U pip setuptools
RUN pip3 install requests

RUN mkdir -p /cxx-common
WORKDIR /cxx-common

# Will try to use cache at './cache'
# Get cache using
#   docker build -t cxx-common-build --target cxx-common-build .
#   docker run --rm --entrypoint /bin/bash -v $(pwd)/cache:/tmp cxx-common-build -c "cp -r ./cache /tmp"
COPY . ./

RUN mkdir -p "${BOOTSTRAP}" && mkdir -p "${LIBRARIES}"

RUN ./pkgman.py \
  --c_compiler=/usr/bin/clang \
  --cxx_compiler=/usr/bin/clang++ \
  --verbose \
  --use_ccache \
  --repository_path="${BOOTSTRAP}" \
  --packages=cmake

RUN ./pkgman.py \
  --c_compiler=/usr/bin/clang \
  --cxx_compiler=/usr/bin/clang++ \
  --llvm_version=${LLVM_VERSION} \
  --verbose \
  --use_ccache \
  --exclude_libcxx \
  "--additional_paths=${BOOTSTRAP}/cmake/bin" \
  "--repository_path=${LIBRARIES}" \
  "--packages=z3,llvm"

# cxx-common-build should be image that contains all dependencies necessary to
# build cxx-common
FROM bootstrap as cxx-common-build
ARG BOOTSTRAP
ARG LIBRARIES

RUN mkdir -p /cache && ./pkgman.py \
  --cxx_compiler="${LIBRARIES}/llvm/bin/clang++" \
  --c_compiler="${LIBRARIES}/llvm/bin/clang" \
  --verbose \
  --use_ccache \
  "--additional_paths=${BOOTSTRAP}/cmake/bin:${LIBRARIES}/llvm/bin" \
  "--repository_path=${LIBRARIES}" \
  "--packages=cmake,google,xed"

# dist image should be minimal artifact image
FROM base as dist
ARG LIBRARIES

COPY --from=cxx-common-build ${LIBRARIES} ${LIBRARIES}

ENTRYPOINT ["/bin/bash"]

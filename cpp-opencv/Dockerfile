# Build stage
FROM ubuntu:22.04 AS builder
LABEL maintainer="Christian Berger <christian.berger@gu.se>"

ENV DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      cmake \
      make \
      linux-headers-generic \
      git \
      libx11-dev \
      nasm \
      clang \
      g++ \
      gcc \
      build-essential \
      wget \
      libopencv-dev \
      libopencv-highgui-dev \
      libopencv-imgproc-dev

# Force clang to be the default cc/c++
RUN ln -sf /usr/bin/clang /usr/bin/cc && \
    ln -sf /usr/bin/clang++ /usr/bin/c++

# Ensure that libyuv is installed correctly
RUN mkdir -p /tmp/src && \
    cd /tmp/src && \
    git clone https://chromium.googlesource.com/libyuv/libyuv && \
    cd libyuv && \
    rm -rf build && mkdir build && cd build && \
    cmake .. && \
    make && \
    make install

# Ensure OpenH264 is correctly linked with libyuv
RUN mkdir -p /tmp/src && \
    cd /tmp/src && \
    git clone --depth 1 --branch v2.2.0 https://github.com/cisco/openh264.git && \
    cd openh264 && \
    make PREFIX=/tmp -j$(nproc) && \
    make install PREFIX=/tmp

# Copy source & build your app
COPY . /opt/sources
WORKDIR /opt/sources
RUN mkdir build && cd build && \
    cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/tmp \
      ../ && \
    make -j$(nproc) && \
    make install

# Download the OpenH264 .so (if you need the .so in /tmp)
RUN cd /tmp && \
    wget -q http://ciscobinary.openh264.org/libopenh264-2.2.0-linux64.6.so.bz2 && \
    mv libopenh264-2.2.0-linux64.6.so.bz2 libopenh264.so.6.bz2

# Final image
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Runtime deps
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      libx11-6 \
      libopencv-core4.5 \
      libopencv-highgui4.5 \
      libopencv-imgproc4.5 \
      libstdc++6

# Copy libyuv static lib if needed (for static linking)
COPY --from=builder /usr/lib/x86_64-linux-gnu/libyuv.a /usr/lib/x86_64-linux-gnu/

# Copy the OpenH264 .so
COPY --from=builder /usr/lib/libopenh264.so* /usr/lib/

# Copy your app executable (the project name is "experimental")
COPY --from=builder /tmp/bin/experimental /usr/bin/experimental

# Update linker cache
RUN ldconfig

ENTRYPOINT ["/usr/bin/experimental"]

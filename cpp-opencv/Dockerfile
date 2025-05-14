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
      libopencv-imgproc-dev \
      pkg-config

# Force clang to be the default cc/c++
RUN update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100 && \
    update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++ 100

# Install OpenH264 properly with headers and libraries
RUN mkdir -p /tmp/src && \
    cd /tmp/src && \
    git clone --depth 1 --branch v2.3.1 https://github.com/cisco/openh264.git && \
    cd openh264 && \
    make -j$(nproc) && \
    make install

# Install libyuv
RUN mkdir -p /tmp/src && \
    cd /tmp/src && \
    git clone https://chromium.googlesource.com/libyuv/libyuv && \
    cd libyuv && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr .. && \
    make -j$(nproc) && \
    make install

# Copy source & build your app
COPY . /opt/sources
WORKDIR /opt/sources
RUN mkdir build && cd build && \
    cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/tmp \
      -DCMAKE_PREFIX_PATH=/usr/local \
      ../ && \
    make -j$(nproc) && \
    make install

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
      libopencv-videoio4.5 \  
      libopencv-imgcodecs4.5 \
      libstdc++6 \
      libgomp1

# Copy OpenH264 libraries
COPY --from=builder /usr/local/lib/libopenh264.so* /usr/lib/

# Copy libyuv libraries
COPY --from=builder /usr/lib/libyuv.so* /usr/lib/

# Copy your app executable
COPY --from=builder /tmp/bin/experimental /usr/bin/experimental

# Update linker cache
RUN ldconfig

ENTRYPOINT ["/usr/bin/experimental"]
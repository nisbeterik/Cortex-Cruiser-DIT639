# Build stage
FROM ubuntu:22.04 AS builder
ENV DEBIAN_FRONTEND=noninteractive

# Install only essential build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    cmake \
    make \
    git \
    wget \
    nasm \
    g++ \
    libopencv-dev \
    libopencv-highgui-dev \
    libopencv-imgproc-dev

# Install OpenH264
RUN mkdir -p /tmp/src && \
    cd /tmp/src && \
    git clone --depth 1 --branch v2.3.1 https://github.com/cisco/openh264.git && \
    cd openh264 && \
    make CXXFLAGS="-O2 -DNDEBUG" -j2 && \
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

# First copy JUST the common directory
COPY ./common /opt/sources/common

# Then copy the performance directory
COPY ./performance /opt/sources/performance

# Verify the copied structure
RUN ls -la /opt/sources && \
    ls -la /opt/sources/common && \
    ls -la /opt/sources/common/include && \
    ls -la /opt/sources/common/src

WORKDIR /opt/sources/performance

# Build with absolute path to common
RUN mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX=/tmp \
          .. && \
    make -j$(nproc) && \
    make install

# Final image
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Set system time to fix future timestamps
RUN apt-get update && \
    apt-get install -y --no-install-recommends tzdata && \
    ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# Only install runtime dependencies
RUN rm -f /etc/apt/sources.list.d/* && \
    apt-get clean && \
    apt-get update -oAcquire::AllowInsecureRepositories=true && \
    apt-get install -y --allow-unauthenticated debian-archive-keyring && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    libx11-6 \
    libopencv-core4.5 \
    libopencv-highgui4.5 \
    libopencv-imgproc4.5 \
    libopencv-videoio4.5 \
    libopencv-imgcodecs4.5 \
    libstdc++6 \
    libgomp1 && \
    rm -rf /var/lib/apt/lists/*

# Copy libraries
COPY --from=builder /usr/local/lib/libopenh264.so* /usr/lib/
COPY --from=builder /usr/lib/libyuv.so* /usr/lib/

# Copy application
COPY --from=builder /tmp/bin/performance /usr/bin/
RUN ldconfig

ENTRYPOINT ["/usr/bin/performance"]
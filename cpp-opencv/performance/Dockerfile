# Build stage
FROM ubuntu:20.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    cmake \
    make \
    git \
    wget \
    bzip2 \
    nasm \
    g++ \
    libopencv-dev \
    libopencv-highgui-dev \
    libopencv-imgproc-dev

# Install OpenH264 v2.3.1 (provides libopenh264.so.6)
RUN wget https://github.com/cisco/openh264/releases/download/v2.3.1/libopenh264-2.3.1-linux-arm64.so.bz2 && \
    bunzip2 libopenh264-2.3.1-linux-arm64.so.bz2 && \
    mv libopenh264-2.3.1-linux-arm64.so /usr/lib/libopenh264.so.6 && \
    chmod +x /usr/lib/libopenh264.so.6 && \
    ldconfig

# Install libyuv
RUN mkdir -p /tmp/src && \
    cd /tmp/src && \
    git clone https://chromium.googlesource.com/libyuv/libyuv && \
    cd libyuv && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr .. && \
    make -j$(nproc) && \
    make install

# Build application
COPY . /opt/sources
WORKDIR /opt/sources
RUN mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/tmp .. && \
    make -j$(nproc) && \
    make install

# Final image
FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libx11-6 \
    libopencv-core4.2 \
    libopencv-highgui4.2 \
    libopencv-imgproc4.2 \
    libopencv-videoio4.2 \
    libopencv-imgcodecs4.2 \
    libstdc++6 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy OpenH264 library
COPY --from=builder /usr/lib/libopenh264.so.6 /usr/lib/
COPY --from=builder /usr/lib/libyuv.so* /usr/lib/

# Copy application
COPY --from=builder /tmp/bin/experimental /usr/bin/

RUN ldconfig

ENTRYPOINT ["/usr/bin/experimental"]
FROM alpine:latest AS builder

WORKDIR /opt/sources
ADD . .

RUN apk add --no-cache --virtual build-deps cmake g++ make && \
    mkdir -p build && cd build && \
    cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_EXE_LINKER_FLAGS="-static" .. && \
    make && make test && helloworld-Runner && \
    strip helloworld && \
    cp helloworld /tmp/ && \
    apk del build-deps

FROM scratch
WORKDIR /opt
COPY --from=builder /tmp/helloworld .
ENTRYPOINT ["/opt/helloworld"]

# Use alpine as image to reduce overhead - ref https://hub.docker.com/_/alpine (searched after suggestion by llm)
# Remove maintainer tags
# Use --no-cache and --virtual - ref https://stackoverflow.com/questions/46221063/what-is-build-deps-for-apk-add-virtual-command (searched after suggestion)
# Use -static to avoid dynamic library dependencies in binary - ref https://stackoverflow.com/questions/24648357/compiling-a-static-executable-with-cmake (searched after suggestion)
# Use strip to reduce size of cpp binary - ref https://man7.org/linux/man-pages/man1/strip.1p.html
# Use scratch as final base image to avoid alpine overhead - ref https://docs.docker.com/reference/dockerfile/#from (searched after suggestion)


FROM debian:bullseye-slim AS builder

RUN apt-get update && \
   apt-get install -y upx-ucl git libisal-dev libdeflate-dev gcc binutils make g++ autoconf automake

RUN git clone https://github.com/OpenGene/fastp && \
   cd fastp && \
   make -j && \
   for LIB in $(ldd fastp | awk '{if (match($3,"/")){ print $3 }}'); do  LIB_NAME=$(basename "$LIB") cp "$LIB" "./$LIB_NAME"; done && \
   strip fastp && \
   strip *.so* && \
   upx fastp 

FROM gcr.io/distroless/base
# copy the binary from the builder stage
COPY --from=builder /fastp/fastp /usr/local/bin/fastp
# copy the required shared libraries
COPY --from=builder /fastp/libisal.so.2 /lib/x86_64-linux-gnu/
COPY --from=builder /fastp/libdeflate.so.0 /lib/x86_64-linux-gnu/
COPY --from=builder /fastp/libstdc++.so.6 /lib/x86_64-linux-gnu/
COPY --from=builder /fastp/libgcc_s.so.1 /lib/x86_64-linux-gnu/

ENTRYPOINT ["/usr/local/bin/fastp"]

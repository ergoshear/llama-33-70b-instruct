FROM rocm/dev-ubuntu-22.04:latest AS builder

RUN apt-get update && apt-get install -y build-essential cmake git

RUN git clone https://github.com/ggerganov/llama.cpp.git /app
WORKDIR /app

# Compile specifically for Strix Halo (gfx1151) routing Flash Attention through rocWMMA
RUN cmake -B build -DGGML_HIP=ON \
    -DAMDGPU_TARGETS=gfx1151 \
    -DGGML_HIP_ROCWMMA_FATTN=ON \
    -DCMAKE_BUILD_TYPE=Release
RUN cmake --build build --config Release --target llama-server -j$(nproc)

FROM rocm/dev-ubuntu-22.04:latest
COPY --from=builder /app/build/bin/llama-server /usr/local/bin/

# Force ROCm to utilize tuned hipBLASLt matrix multiplication kernels for gfx1151
ENV ROCBLAS_USE_HIPBLASLT=1

EXPOSE 8080

ENTRYPOINT ["llama-server"]
CMD ["--hf-repo", "bartowski/Llama-3.3-70B-Instruct-GGUF", \
     "--hf-file", "Llama-3.3-70B-Instruct-Q4_K_M.gguf", \
     "--n-gpu-layers", "999", \
     "--ctx-size", "32768", \
     "--cache-type-k", "q8_0", \
     "--cache-type-v", "q8_0", \
     "--flash-attn", \
     "--host", "0.0.0.0", \
     "--port", "8080"]

# Llama 3.3 70B Instruct on Ryzen AI Max+ 395 (Strix Halo)

This container builds a ROCm `llama.cpp` server for a Linux host with an AMD
Ryzen AI Max+ 395 and Radeon 8060S (`gfx1151`). The 128 GiB LPDDR5X memory is
shared by the CPU and integrated GPU. Firmware determines the GPU memory
carveout; it is not a separate 128 GiB VRAM pool.

## Image and model

- The image uses ROCm 7.2.3 and builds llama.cpp commit
  [`8345f333951c661d166b00e6f9362e553768f292`](https://github.com/ggml-org/llama.cpp/commit/8345f333951c661d166b00e6f9362e553768f292)
  for `gfx1151`, with HIP virtual memory management disabled.
- The model is `Llama-3.3-70B-Instruct-Q4_K_M.gguf` from
  [bartowski/Llama-3.3-70B-Instruct-GGUF](https://huggingface.co/bartowski/Llama-3.3-70B-Instruct-GGUF).
  Reserve about 45 GB for the model volume (the exact file size can vary).
- The downloader pins a Hugging Face commit on first use, resumes partial
  downloads, and verifies the completed file against the revision's LFS SHA256.
  Set `MODEL_REVISION` to a full commit SHA on the first download to select a
  specific revision. Use a new volume to change revisions.

The default server uses a 32,768-token context, one parallel slot, Q4_0 K/V
cache, Flash Attention, and up to 99 GPU layers. A 70B model's weights and
runtime buffers need substantial shared memory. The required GPU carveout and
usable context depend on the host firmware, model file, ROCm runtime, and other
GPU processes. If startup reports an allocation failure, lower `GPU_LAYERS`
or `CTX_SIZE`. Confirm the startup log shows the context actually allocated.

Runtime options can be set with `GPU_LAYERS`, `CTX_SIZE`, `PARALLEL`, `THREADS`,
`BATCH_SIZE`, `UBATCH_SIZE`, `CACHE_TYPE_K`, `CACHE_TYPE_V`, `FLASH_ATTN`,
`TEMP`, `TOP_P`, and `TOP_K`.

## Host requirements

The Linux host must have a working `amdgpu` driver and expose `/dev/kfd` and
`/dev/dri`. The container supplies ROCm user space; it does not install a host
kernel driver. Confirm the host kernel and distribution support Strix Halo and
that ROCm can see the GPU before starting.

## Build and download

Run from this directory. These examples use Podman; Docker can use the same
device mappings.

```sh
podman build --format docker -t llama-3.3-70b-strix-halo .
podman volume create llama-3.3-70b-model
podman run --rm -v llama-3.3-70b-model:/models \
  --entrypoint /usr/local/bin/download-model \
  llama-3.3-70b-strix-halo
```

The public model does not need a token. If authentication is required, pass
`HF_TOKEN` or `HUGGINGFACE_API_KEY` only to the download container. Model files
stay in the named volume, not in the image or repository.

## Run the server

```sh
podman run -d --name llama-3.3-70b \
  --device /dev/kfd --device /dev/dri \
  --group-add keep-groups \
  -v llama-3.3-70b-model:/models:ro \
  -p 127.0.0.1:8080:8080 \
  llama-3.3-70b-strix-halo
podman logs -f llama-3.3-70b
```

Keep the API bound to loopback as shown. If it must be reachable remotely,
place it behind an authenticated TLS proxy.

Check readiness and make a small request after the model finishes loading:

```sh
curl -fsS http://127.0.0.1:8080/health
curl -fsS http://127.0.0.1:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"llama-3.3-70b-instruct","messages":[{"role":"user","content":"Summarize the purpose of a reverse proxy."}],"max_tokens":128,"temperature":0}'
```

The image has not been built or run on the target host as part of this change.
Verify GPU visibility, model loading, and an inference request on the host
before relying on the server.

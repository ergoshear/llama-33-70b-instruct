#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
    exec /opt/llama.cpp/build/bin/llama-server \
        --model /models/Llama-3.3-70B-Instruct-Q4_K_M.gguf \
        --alias llama-3.3-70b-instruct \
        --host 0.0.0.0 --port 8080 \
        --n-gpu-layers "${GPU_LAYERS:-32}" \
        --ctx-size "${CTX_SIZE:-32768}" \
        --parallel "${PARALLEL:-1}" \
        --threads "${THREADS:-16}" \
        --batch-size "${BATCH_SIZE:-256}" \
        --ubatch-size "${UBATCH_SIZE:-128}" \
        --cache-type-k "${CACHE_TYPE_K:-q8_0}" \
        --cache-type-v "${CACHE_TYPE_V:-q8_0}" \
        --flash-attn "${FLASH_ATTN:-on}" --jinja \
        --temp "${TEMP:-0.6}" --top-p "${TOP_P:-0.9}" --top-k "${TOP_K:-40}"
fi

exec /opt/llama.cpp/build/bin/llama-server "$@"

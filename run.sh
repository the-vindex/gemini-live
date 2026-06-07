#!/bin/bash

# Deactivate conda to avoid library conflicts
if [ ! -z "$CONDA_DEFAULT_ENV" ]; then
    conda deactivate 2>/dev/null || true
fi

# Unset conda environment variables
unset CONDA_DEFAULT_ENV
unset CONDA_PREFIX

# Activate virtual environment
source gem-env/bin/activate

# Set library path to prefer system libraries over conda
export LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

# Run Gemini Live Cam in audio-only mode
python3 gemini-live-cam.py --mode none

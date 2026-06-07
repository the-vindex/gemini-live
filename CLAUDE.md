# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Gemini Live Cam is a Python application that streams real-time audio and optionally video (camera or screen) to Google Gemini's Live API. It enables interactive multimodal conversations with voice responses using the `google-genai` SDK.

## Setup and Environment

1. **Virtual Environment**: Create and activate using `python3 -m venv gem-env && source gem-env/bin/activate` (Linux/macOS) or `python -m venv gem-env && gem-env\Scripts\activate` (Windows)

2. **Dependencies**: Install via `pip install google-genai opencv-python pyaudio pillow mss python-dotenv` or use `pip install -r requirements.txt`

3. **Environment Variables**: Create a `.env` file with `GEMINI_API_KEY=your_api_key_here` (see `sample.env`)

## Running the Application

The main script is `gemini-live-cam.py` and supports three modes:

- **Camera mode** (default): `python gemini-live-cam.py --mode camera`
- **Screen capture mode**: `python gemini-live-cam.py --mode screen`
- **Audio only**: `python gemini-live-cam.py --mode none`

Interactive commands while running:
- Type messages at the `message >` prompt to send text to Gemini
- Type `q` to quit

## Architecture

### Core Components

**AudioLoop Class** (gemini-live-cam.py:67-261): Main orchestrator that manages all async tasks and the Gemini Live API session.

**Async Task Pipeline**:
- `listen_audio()`: Captures microphone input at 16kHz PCM
- `get_frames()` or `get_screen()`: Captures camera/screen at ~1 FPS
- `send_realtime()`: Sends audio/video to Gemini via `session.send_realtime_input()`
- `receive_audio()`: Receives responses from Gemini websocket
- `play_audio()`: Plays back Gemini's audio responses at 24kHz
- `send_text()`: Handles text input from console

**Queue Architecture**:
- `out_queue`: Outbound media (audio chunks, video frames) → sent to Gemini
- `audio_in_queue`: Inbound audio from Gemini → played to speakers
- Uses `asyncio.Queue` for thread-safe async communication

### Key Technical Details

**API Configuration** (gemini-live-cam.py:52-62):
- Model: `gemini-2.0-flash-live-001` (v1alpha API)
- Response modalities: AUDIO only (during experimental preview)
- Voice: "Leda" prebuilt voice
- Tools: Google Search enabled

**Media Handling**:
- Audio: 16kHz mono PCM input, 24kHz output, 1024-byte chunks
- Video/Screen: JPEG format, base64 encoded, 1024x1024 max, 1 FPS
- BGR→RGB conversion for camera frames (gemini-live-cam.py:107) to prevent color distortion

**Session Management**:
- Uses `client.aio.live.connect()` context manager
- All tasks run in `asyncio.TaskGroup` for coordinated lifecycle
- Interruption handling: clears `audio_in_queue` on turn completion (gemini-live-cam.py:216-217)

## Important Implementation Notes

- All blocking I/O (camera read, audio capture, PyAudio operations) wrapped in `asyncio.to_thread()` to prevent pipeline overflow
- Session must be initialized before sending/receiving; tasks check `self.session is not None`
- Color space conversion is critical: OpenCV captures BGR, but PIL/Gemini expect RGB
- Exception handling uses `ExceptionGroup` for async task errors

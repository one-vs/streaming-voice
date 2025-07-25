"""Module with wrapper for pretrained CTC acoustic model."""

from __future__ import annotations

import os
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from pathlib import Path

import numpy as np
import numpy.typing as npt
import onnxruntime as ort
from huggingface_hub import hf_hub_download
from typing_extensions import Self, TypeAlias


def get_available_gpus() -> list[dict[str, str | int]]:
    """Get list of available CUDA GPUs.

    Returns:
        List of GPU info dictionaries with 'id', 'name', 'memory' keys

    """
    gpus = []
    try:
        import pynvml

        pynvml.nvmlInit()
        device_count = pynvml.nvmlDeviceGetCount()

        for i in range(device_count):
            handle = pynvml.nvmlDeviceGetHandleByIndex(i)
            name = pynvml.nvmlDeviceGetName(handle)
            # Handle both string and bytes return types
            if isinstance(name, bytes):
                name = name.decode("utf-8")
            memory_info = pynvml.nvmlDeviceGetMemoryInfo(handle)
            memory_gb = memory_info.total // (1024**3)

            gpus.append(
                {
                    "id": i,
                    "name": name,
                    "memory": f"{memory_gb}GB",
                },
            )
    except ImportError:
        # pynvml not available, fallback to basic detection
        if "CUDAExecutionProvider" in ort.get_available_providers():
            gpus.append(
                {
                    "id": 0,
                    "name": "CUDA Device 0",
                    "memory": "Unknown",
                },
            )
    except (RuntimeError, OSError) as e:
        # NVML error, but CUDA might still be available
        print(f"⚠️ NVML error: {e}")
        if "CUDAExecutionProvider" in ort.get_available_providers():
            gpus.append(
                {
                    "id": 0,
                    "name": "CUDA Device 0",
                    "memory": "Unknown",
                },
            )

    return gpus


def _create_ort_session(model_path: str | Path, use_gpu: bool = True, gpu_device_id: int = 0) -> ort.InferenceSession:
    """Create ONNX Runtime session with optimal providers.

    Args:
        model_path: Path to the ONNX model file
        use_gpu: Whether to try using GPU providers (default: True)

    Returns:
        Configured ONNX Runtime InferenceSession

    """
    providers = []

    # Check if GPU should be used and is available
    if use_gpu:
        available_providers = ort.get_available_providers()

        # Add CUDA provider if available
        if "CUDAExecutionProvider" in available_providers:
            providers.append(
                (
                    "CUDAExecutionProvider",
                    {
                        "device_id": gpu_device_id,
                        "arena_extend_strategy": "kNextPowerOfTwo",
                        "gpu_mem_limit": 4 * 1024 * 1024 * 1024,  # 4GB limit
                        "cudnn_conv_algo_search": "EXHAUSTIVE",
                        "do_copy_in_default_stream": True,
                        "cudnn_conv_use_max_workspace": True,  # Use maximum workspace
                    },
                ),
            )
            print("🚀 Using CUDA GPU acceleration with optimizations")

        # Add DirectML provider if available (Windows)
        elif "DmlExecutionProvider" in available_providers:
            providers.append("DmlExecutionProvider")
            print("🚀 Using DirectML GPU acceleration")

        # Add OpenVINO provider if available
        elif "OpenVINOExecutionProvider" in available_providers:
            providers.append("OpenVINOExecutionProvider")
            print("🚀 Using OpenVINO acceleration")

    # Always add CPU as fallback
    providers.append("CPUExecutionProvider")

    # Create session options for better performance
    sess_options = ort.SessionOptions()
    sess_options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
    sess_options.execution_mode = ort.ExecutionMode.ORT_SEQUENTIAL

    # Optimize for GPU performance
    if use_gpu and any("CUDA" in str(p) or "Dml" in str(p) for p in providers):
        # GPU optimizations
        sess_options.enable_mem_pattern = True  # Enable memory pattern optimization
        sess_options.enable_cpu_mem_arena = False  # Disable CPU memory arena for GPU
        sess_options.enable_mem_reuse = True  # Enable memory reuse
        # Reduce logging for better performance
        sess_options.log_severity_level = 3  # Only show errors (reduces Memcpy warnings)
    else:
        # CPU optimizations
        sess_options.enable_mem_pattern = True
        sess_options.enable_cpu_mem_arena = True
        sess_options.enable_mem_reuse = True

    # Set number of threads based on environment or CPU count
    num_threads = int(os.environ.get("ORT_NUM_THREADS", os.cpu_count() or 4))
    sess_options.intra_op_num_threads = num_threads
    sess_options.inter_op_num_threads = 1

    print(f"🔧 ONNX Runtime providers: {[p[0] if isinstance(p, tuple) else p for p in providers]}")

    session = ort.InferenceSession(str(model_path), sess_options, providers=providers)

    # Additional GPU optimizations after session creation
    if use_gpu and any("CUDA" in str(p) or "Dml" in str(p) for p in providers):
        try:
            # Try to enable additional CUDA optimizations
            if hasattr(session, "set_providers"):
                # Ensure CUDA provider is prioritized
                current_providers = session.get_providers()
                if "CUDAExecutionProvider" in current_providers:
                    print("✅ CUDA provider successfully initialized")
                else:
                    print("⚠️ CUDA provider not active, using fallback")
        except (AttributeError, RuntimeError) as e:
            print(f"⚠️ GPU optimization warning: {e}")

    return session


class StreamingCTCModel:
    """Wrapper for a pretrained CTC acoustic model, running with ONNX Runtime.

    This class handles inference with a CTC-based acoustic model and supports
    batched streaming inputs. It provides factory methods to load the model
    from Hugging Face or from a local file, and exposes a forward method to compute
    log-probabilities from audio chunks.
    """

    InputType: TypeAlias = npt.NDArray[np.int32]
    OutputType: TypeAlias = npt.NDArray[np.float16]
    StateType: TypeAlias = npt.NDArray[np.float16]

    SAMPLE_RATE = 8000
    MEAN_TIME_BIAS = 0.33  # in seconds
    AUDIO_CHUNK_SAMPLES = 2400  # in audio samples
    FRAME_SIZE = 0.03  # in seconds
    STATE_SIZE = 219729

    _ort_sess: ort.InferenceSession

    @classmethod
    def from_hugging_face(cls, *, use_gpu: bool = True) -> Self:
        """Load and initialize the model from Hugging Face Hub.

        Downloads the model if not present locally, and initializes
        an ONNX inference session.

        Args:
            use_gpu (bool): Whether to try using GPU acceleration (default: True).

        Returns:
            Self: An instance of StreamingCTCModel ready for inference.

        """
        model_path = cls.download_from_hugging_face()
        return cls.from_local(model_path, use_gpu=use_gpu)

    @classmethod
    def download_from_hugging_face(cls) -> str:
        """Download the model from Hugging Face Hub.

        Returns:
            str: Path to the downloaded ONNX model file.

        """
        return hf_hub_download(
            "t-tech/T-one",
            "model.onnx",
        )

    @classmethod
    def from_local(cls, model_path: str | Path, *, use_gpu: bool = True, gpu_device_id: int = 0) -> Self:
        """Initialize the model from a local ONNX file.

        Args:
            model_path (str | Path): Path to the ONNX model file.
            use_gpu (bool): Whether to try using GPU acceleration (default: True).

        Returns:
            Self: An instance of StreamingCTCModel ready for inference.

        """
        ort_sess = _create_ort_session(model_path, use_gpu=use_gpu, gpu_device_id=gpu_device_id)
        return cls(ort_sess)

    def __init__(self, ort_sess: ort.InferenceSession) -> None:
        """Create instance of StreamingCTCModel from onnx session."""
        self._ort_sess = ort_sess

    def forward(self, audio_chunk: InputType, state: StateType | None = None) -> tuple[OutputType, StateType]:
        """Run the CTC acoustic model on a single audio chunk.

        Converts raw audio to frame-level log-probabilities using ONNX Runtime. Maintains
        model state for streaming.

        Args:
            audio_chunk (InputType): A batch or single audio chunk to process.
            state (StateType | None): Previous state, or None to initialize.

        Returns:
            Tuple[OutputType, StateType]:
                - OutputType: Model log-probabilities for each frame.
                - StateType: Updated state to pass into the next call.

        """
        if not isinstance(audio_chunk, np.ndarray):
            raise TypeError(f"Incorrect 'audio_chunk' type: expected np.ndarray, but got {type(audio_chunk)}")
        if audio_chunk.shape[1:] != (self.AUDIO_CHUNK_SAMPLES, 1):
            raise ValueError(
                f"Shape of 'audio_chunk' must be (B, {self.AUDIO_CHUNK_SAMPLES}, 1), but got {audio_chunk.shape}",
            )
        if audio_chunk.dtype != np.int32:
            raise ValueError(f"Incorrect dtype of 'audio_chunk': expected np.int32, but got {audio_chunk.dtype}")
        if audio_chunk.min() < -32768 or audio_chunk.max() > 32767:
            raise ValueError(
                "Samples in 'audio_chunk' must be in range [-32768; 32767], "
                f"but it is in range [{audio_chunk.min()}; {audio_chunk.max()}]",
            )
        batch_size = audio_chunk.shape[0]
        if state is None:
            state = np.zeros((batch_size, self.STATE_SIZE), dtype=np.float16)  # Create empty initial states
        if not isinstance(state, np.ndarray):
            raise TypeError(f"Incorrect 'state' type: expected np.ndarray or None, but got {type(state)}")
        if state.shape != (batch_size, self.STATE_SIZE):
            raise ValueError(f"Shape of 'state' must be ({batch_size}, {self.STATE_SIZE}), but got {state.shape}")
        if state.dtype != np.float16:
            raise ValueError(f"Incorrect dtype of 'state': expected np.int32, but got {state.dtype}")

        return self._ort_sess.run(None, {"signal": audio_chunk, "state": state})

# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )
DISTUTILS_SINGLE_IMPL=1

inherit distutils-r1 cuda toolchain-funcs

DESCRIPTION="Optimized quantization and inference library for LLMs on consumer GPUs"
HOMEPAGE="https://github.com/turboderp-org/exllamav3"
SRC_URI="https://github.com/turboderp-org/exllamav3/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# cuda: compile the CUDA extension (default on this machine, RTX 4090 / sm_89)
# rocm: compile the ROCm/HIP extension instead
# flash-attn: pull in flash-linear-attention (linear-attention kernels)
# guidance: LLM structured-generation support via llguidance
IUSE="cuda rocm flash-attn guidance"

REQUIRED_USE="?? ( cuda rocm )"

RESTRICT="test"  # no network-touching test harness shipped; builds offline

RDEPEND="
	>=sci-ml/pytorch-2.6[${PYTHON_SINGLE_USEDEP}]
	sci-ml/tokenizers[${PYTHON_SINGLE_USEDEP}]
	dev-python/safetensors[${PYTHON_SINGLE_USEDEP}]
	dev-python/marisa-trie[${PYTHON_SINGLE_USEDEP}]
	dev-python/numpy[${PYTHON_SINGLE_USEDEP}]
	dev-python/rich[${PYTHON_SINGLE_USEDEP}]
	dev-python/pydantic[${PYTHON_SINGLE_USEDEP}]
	dev-python/pillow[${PYTHON_SINGLE_USEDEP}]
	dev-python/pyyaml[${PYTHON_SINGLE_USEDEP}]
	dev-python/typing-extensions[${PYTHON_SINGLE_USEDEP}]
	guidance? ( dev-python/llguidance[${PYTHON_SINGLE_USEDEP}] )
	flash-attn? ( dev-python/flash-linear-attention[${PYTHON_SINGLE_USEDEP}] )
"
BDEPEND="
	${RDEPEND}
	dev-build/ninja
	cuda? ( >=dev-util/nvidia-cuda-toolkit-12.9:= )
	rocm? ( >=dev-util/hip-5.7:= )
"

# Strip the PyPI "ninja" dep (we use the system dev-build/ninja binary) and
# make the optional extras non-fatal so the build does not require them.
python_prepare_all() {
	sed -i -e '/^ninja$/d' requirements.txt 2>/dev/null || true
	# Keep install_requires but drop the two optional/heavy extras already
	# represented as USE flags above.
	sed -i \
		-e '/llguidance/d' \
		-e '/flash-linear-attention/d' \
		setup.py || die
	distutils-r1_python_prepare_all
}

src_configure() {
	# nvcc must be on PATH for torch's cpp_extension. cuda.eclass does not
	# expose a helper here, so ensure it explicitly (typically /opt/cuda/bin).
	if use cuda; then
		export PATH="/opt/cuda/bin:${PATH}"
		if ! command -v nvcc >/dev/null 2>&1; then
			die "nvcc not found on PATH; install dev-util/nvidia-cuda-toolkit (>=12.9)"
		fi
		# Torch's cpp_extension probes TORCH_CUDA_ARCH_LIST; default to the GPU
		# present (RTX 4090 = sm_89). Override via env for other GPUs.
		if [[ -z ${TORCH_CUDA_ARCH_LIST} ]]; then
			export TORCH_CUDA_ARCH_LIST="8.9"
		fi
	fi
	# Make sure the C++ extension actually compiles during install (not JIT).
	export EXLLAMA_NOCOMPILE=
	default
}

python_compile_all() {
	# distutils-r1 builds the extension per-impl in the compile phase via
	# the CUDAExtension entry in setup.py; nothing extra to do here.
	:
}

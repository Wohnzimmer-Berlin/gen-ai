# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cuda toolchain-funcs

DESCRIPTION="Optimized quantization and inference library for LLMs on consumer GPUs"
HOMEPAGE="https://github.com/turboderp-org/exllamav3"
SRC_URI="https://github.com/turboderp-org/exllamav3/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

IUSE="cuda rocm flash-attn guidance"
REQUIRED_USE="?? ( cuda rocm )"
RESTRICT="test"

RDEPEND="
	>=sci-ml/pytorch-2.6
	>=sci-ml/tokenizers-0.21.1
	>=sci-ml/safetensors-0.3.2
	dev-python/marisa-trie
	dev-python/filelock
	>=dev-python/numpy-2.1.0
	dev-python/rich
	dev-python/pydantic
	dev-python/pillow
	dev-python/pyyaml
	dev-python/typing-extensions
	guidance? ( >=dev-python/llguidance-1.7.0 )
	flash-attn? ( >=dev-python/flash-linear-attention-0.5.0 )
"
BDEPEND="
	${RDEPEND}
	dev-build/ninja
	cuda? ( >=dev-util/nvidia-cuda-toolkit-12.9:= )
	rocm? ( >=dev-util/hip-5.7:= )
"

src_prepare() {
	sed -i -e '/^ninja$/d' requirements.txt 2>/dev/null || true
	sed -i \
		-e '/llguidance/d' \
		-e '/flash-linear-attention/d' \
		setup.py || die
	default
}

src_configure() {
	if use cuda; then
		export PATH="/opt/cuda/bin:${PATH}"
		if ! command -v nvcc >/dev/null 2>&1; then
			die "nvcc not found on PATH; install dev-util/nvidia-cuda-toolkit (>=12.9)"
		fi
		if [[ -z ${TORCH_CUDA_ARCH_LIST} ]]; then
			export TORCH_CUDA_ARCH_LIST="8.9"
		fi
	fi
	export EXLLAMA_NOCOMPILE=
	default
}

src_compile() {
	python3 setup.py build_ext --inplace || die
}

src_install() {
	python3 setup.py install --root="${D}" --optimize=2 || die
}

# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=setuptools

inherit cmake distutils-r1

DESCRIPTION="Triton language and compiler for custom GPU kernels"
HOMEPAGE="https://github.com/openai/triton"
SRC_URI="https://github.com/openai/triton/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="cuda amd"
REQUIRED_USE="cuda? ( !amd )"
RESTRICT="test"

RDEPEND="
	cuda? ( >=dev-util/nvidia-cuda-toolkit-12.0:= )
	amd? ( dev-util/roctracer )
"
DEPEND="${RDEPEND}"
BDEPEND="
	dev-build/cmake
	dev-build/ninja
	dev-python/pybind11
	>=dev-python/setuptools-69
	dev-python/wheel
	llvm-core/mlir
	sys-libs/zlib
"

src_prepare() {
	sed -i -e 's/-Werror//g' CMakeLists.txt setup.py 2>/dev/null || true
	default
	cmake_src_prepare
}

src_configure() {
	if use cuda; then
		if [[ -x /opt/cuda/bin/nvcc ]]; then
			export CUDA_HOME="/opt/cuda"
		elif [[ -x /usr/bin/nvcc ]]; then
			export CUDA_HOME="/usr"
		fi
		if [[ -z ${TORCH_CUDA_ARCH_LIST} ]]; then
			local gpu_arch
			gpu_arch=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>/dev/null \
				| head -1 | tr -d ' ')
			if [[ -n "${gpu_arch}" ]]; then
				export TORCH_CUDA_ARCH_LIST="${gpu_arch}"
			else
				export TORCH_CUDA_ARCH_LIST="8.9"
			fi
		fi
	fi
	export LLVM_EXTERNAL_LIT=""
	mycmakeargs=(
		-G Ninja
		-DTRITON_BUILD_PYTHON_MODULE=ON
		-DTRITON_USE_CUDA=$(usex cuda ON OFF)
		-DTRITON_BUILD_PROTON=OFF
		-DCMAKE_CUDA_ARCHITECTURES=${TORCH_CUDA_ARCH_LIST}
	)
	cmake_src_configure
}

src_compile() {
	cmake_build
}

src_install() {
	python3 -m pip install --root="${D}" . || die
}

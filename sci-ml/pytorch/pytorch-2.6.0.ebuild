# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=setuptools

inherit cmake distutils-r1 cuda flag-o-matic toolchain-funcs

DESCRIPTION="PyTorch deep learning framework"
HOMEPAGE="https://pytorch.org/ https://github.com/pytorch/pytorch"
SRC_URI="https://github.com/pytorch/pytorch/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"
IUSE="cuda rocm test"
REQUIRED_USE="?? ( cuda rocm )"
RESTRICT="!test? ( test )"

DEPEND="
	dev-python/numpy
	dev-python/pyyaml
	dev-python/typing-extensions
	dev-python/filelock
	dev-python/fsspec
	dev-python/jinja
	dev-python/networkx
	dev-python/sympy
	dev-python/packaging
	cuda? ( >=dev-util/nvidia-cuda-toolkit-12.0:= )
"
RDEPEND="${DEPEND}"
BDEPEND="
	dev-build/cmake
	dev-build/ninja
	dev-python/setuptools
	dev-python/wheel
	dev-python/pybind11
	dev-util/ninja
"

PATCHES=(
)

src_prepare() {
	default
	cmake_src_prepare
}

src_configure() {
	export TORCH_CUDA_ARCH_LIST="8.9"
	export CMAKE_CUDA_ARCHITECTURES="89"
	mycmakeargs=(
		-G Ninja
		-DCMAKE_BUILD_TYPE=Release
		-DPYTHON_EXECUTABLE="$(python3 -c 'import sys; print(sys.executable)')"
		-DUSE_CUDA=$(usex cuda ON OFF)
		-DUSE_ROCM=$(usex rocm ON OFF)
		-DUSE_NCCL=OFF
		-DUSE_MPI=OFF
		-DUSE_OPENMP=ON
		-DUSE_FBGEMM=OFF
		-DUSE_XNNPACK=OFF
		-DUSE_MKLDNN=OFF
	)
	cmake_src_configure
}

src_compile() {
	cmake_build
}

src_install() {
	einsinto /usr/lib/python3.14/site-packages
	python3 -m pip install --root="${D}" . || die
}

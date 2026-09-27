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
IUSE="cuda"
REQUIRED_USE="cuda"
RESTRICT="test"

RDEPEND="
	cuda? ( >=dev-util/nvidia-cuda-toolkit-12.0:= )
"
DEPEND="${RDEPEND}"
BDEPEND="
	dev-build/cmake
	dev-build/ninja
	dev-python/pybind11
	>=dev-python/setuptools-69
	dev-python/wheel
"

src_prepare() {
	sed -i -e 's/-Werror//g' CMakeLists.txt setup.py 2>/dev/null || true
	default
}

src_configure() {
	local mycmakeargs=(
		-G Ninja
		-DTRITON_BUILD_PYTHON_MODULE=ON
		-DTRITON_USE_CUDA=ON
		-DCMAKE_CUDA_ARCHITECTURES=89
	)
	cmake_src_configure
}

src_compile() {
	cmake_build
}

src_install() {
	python3 -m pip install --root="${D}" . || die
}

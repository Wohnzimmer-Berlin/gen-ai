# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..14} )
DISTUTILS_USE_PEP517=setuptools

inherit cuda distutils-r1

DESCRIPTION="Fast linear attention models and layers"
HOMEPAGE="https://github.com/fla-org/flash-linear-attention"
SRC_URI="https://files.pythonhosted.org/packages/d2/76/c180949eae5161b9fcf4c928cab52f0c257ce84c1a59b4462b1d2b6e5883/flash_linear_attention-${PV}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

IUSE="cuda"
RESTRICT="test"

RDEPEND="
	>=sci-ml/pytorch-2.6
	cuda? ( dev-python/triton )
"
BDEPEND="
	${RDEPEND}
	cuda? ( >=dev-util/nvidia-cuda-toolkit-12.9:= )
"

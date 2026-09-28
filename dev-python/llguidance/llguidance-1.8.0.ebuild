# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..14} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1

DESCRIPTION="Bindings for the Low-level Guidance (llguidance) Rust library"
HOMEPAGE="https://github.com/guidance-ai/llguidance"
SRC_URI="https://github.com/guidance-ai/llguidance/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

IUSE=""
RESTRICT="test"

RDEPEND=">=dev-python/rustworkx-0.14.0"
BDEPEND="${RDEPEND}"

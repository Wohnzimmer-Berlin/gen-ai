# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit

DESCRIPTION="Fast State-of-the-Art Tokenizers optimized for Research and Production"
HOMEPAGE="https://github.com/huggingface/tokenizers"
SRC_URI="https://github.com/huggingface/tokenizers/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/packaging
"
BDEPEND="
	${RDEPEND}
	dev-python/maturin
	virtual/rust
"

RESTRICT="test"

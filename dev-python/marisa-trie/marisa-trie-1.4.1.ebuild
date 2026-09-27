# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1

DESCRIPTION="Sparse marisa trie implementation for Python"
HOMEPAGE="https://github.com/pytries/marisa-trie"
SRC_URI="https://files.pythonhosted.org/packages/source/m/marisa-trie/marisa_trie-${PV}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="
	dev-python/cython
	dev-python/setuptools
"
RDEPEND="${DEPEND}"

S="${WORKDIR}/marisa_trie-${PV}"

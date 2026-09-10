EAPI=8

DESCRIPTION="System group for the llama.cpp server"
HOMEPAGE="https://github.com/ggml-org/llama.cpp"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

pkg_postinst() {
	enewgroup llama
}
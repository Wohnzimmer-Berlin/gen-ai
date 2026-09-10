EAPI=8

DESCRIPTION="System user and group for the llama.cpp server"
HOMEPAGE="https://github.com/ggml-org/llama.cpp"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

RDEPEND="acc-group/llamacpp"

pkg_postinst() {
	enewuser llama -1 llama /var/lib/llama.cpp /sbin/nologin
}
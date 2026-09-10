# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2 

EAPI=8

# Latest upstream tag (bump when updating)
TAG="b10826"
MY_P="llama.cpp-${TAG}"

inherit cmake edo toolchain-funcs cuda systemd

DESCRIPTION="LLM inference engine (GGUF) — server, CLI, quantize, perplexity, embedding, RPC"
HOMEPAGE="https://github.com/ggml-org/llama.cpp"

SRC_URI="https://github.com/ggml-org/llama.cpp/archive/refs/tags/${TAG}.tar.gz -> ${MY_P}.tar.gz"

S="${WORKDIR}/${MY_P}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# CPU flags from ggml's X86_CPU_FLAGS (mirrored for direct mapping)
X86_CPU_FLAGS=(
	avx
	avx_vnni
	avx2
	avx512_bf16
	avx512bw
	avx512f
	avx512vbmi
	avx512_vnni
	bmi2
	fma3
	f16c
	sse4_2
)
CPU_FLAGS=( "${X86_CPU_FLAGS[@]/#/cpu_flags_x86_}" )
IUSE="${CPU_FLAGS[*]} cuda openmp server rpc examples test vulkan blas opencl rocm sycl metal llamafile curl native system-ggml systemd openrc"

REQUIRED_USE="
	|| ( cuda opencl vulkan rocm sycl metal )
	?? ( cuda rocm )
	server? ( || ( systemd openrc ) )
"

RESTRICT="!test? ( test )"

RDEPEND="
	curl? ( net-misc/curl:= )
	vulkan? ( media-libs/vulkan-loader )
	blas? ( virtual/blas )
	opencl? ( virtual/opencl )
	server? (
		acc-user/llamacpp
		systemd? ( sys-apps/systemd )
		openrc? ( sys-apps/openrc )
	)
	rocm? (
		>=dev-util/hip-7.2
		>=sci-libs/hipBLAS-7.2
	)
	sycl? ( dev-util/intel-oneapi-compiler-dpcpp-cpp )
	metal? ( dev-libs/metal )
	system-ggml? (
		>=sci-ml/ggml-0.23.0:=
		cuda? ( >=sci-ml/ggml-0.23.0:=[cuda] )
		vulkan? ( >=sci-ml/ggml-0.23.0:=[vulkan] )
		blas? ( >=sci-ml/ggml-0.23.0:=[blas] )
		opencl? ( >=sci-ml/ggml-0.23.0:=[opencl] )
		rocm? ( >=sci-ml/ggml-0.23.0:=[rocm] )
	)
"
DEPEND="${RDEPEND}
	cuda? ( >=dev-util/nvidia-cuda-toolkit-12.9:= )
	vulkan? ( dev-util/vulkan-headers media-libs/shaderc )
"
BDEPEND="
	dev-build/cmake
	dev-build/ninja
"

pkg_pretend() {
	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp
}

pkg_setup() {
	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp
}

# Default CUDA arch for RTX 4090 (sm_89); override via LLAMA_CUDA_ARCH env
: "${LLAMA_CUDA_ARCH:=8.9}"

src_prepare() {
	use cuda && cuda_src_prepare
	cmake_src_prepare
}

src_configure() {
	use cuda && export PATH="/opt/cuda/bin:${PATH}"

	# Build llama.cpp against the system ggml instead of the bundled one
	local mycmakeargs=(
		-DLLAMA_USE_SYSTEM_GGML="$(usex system-ggml ON OFF)"
		-DGGML_CUDA="$(usex cuda ON OFF)"
		-DGGML_HIP="$(usex rocm ON OFF)"
		-DGGML_VULKAN="$(usex vulkan ON OFF)"
		-DGGML_OPENCL="$(usex opencl ON OFF)"
		-DGGML_SYCL="$(usex sycl ON OFF)"
		-DGGML_METAL="$(usex metal ON OFF)"
		-DGGML_OPENMP="$(usex openmp ON OFF)"
		-DGGML_BLAS="$(usex blas ON OFF)"
		-DGGML_LLAMAFILE="$(usex llamafile ON OFF)"
		-DLLAMA_SERVER="$(usex server ON OFF)"
		-DLLAMA_BUILD_SERVER=ON
		-DLLAMA_RPC="$(usex rpc ON OFF)"
		-DLLAMA_CURL="$(usex curl ON OFF)"
		-DLLAMA_BUILD_EXAMPLES="$(usex examples ON OFF)"
		-DLLAMA_BUILD_TESTS="$(usex test ON OFF)"
		-DBUILD_SHARED_LIBS=ON
		-DCMAKE_POSITION_INDEPENDENT_CODE=ON
		-DGGML_NATIVE="$(usex native ON OFF)"
	)

	# CPU feature flags (map from cpu_flags_x86_* USE flags)
	mycmakeargs+=(
		-DGGML_AVX="$(usex cpu_flags_x86_avx ON OFF)"
		-DGGML_AVX_VNNI="$(usex cpu_flags_x86_avx_vnni ON OFF)"
		-DGGML_AVX2="$(usex cpu_flags_x86_avx2 ON OFF)"
		-DGGML_AVX512_BF16="$(usex cpu_flags_x86_avx512_bf16 ON OFF)"
		-DGGML_AVX512_VBMI="$(usex cpu_flags_x86_avx512vbmi ON OFF)"
		-DGGML_AVX512_VNNI="$(usex cpu_flags_x86_avx512_vnni ON OFF)"
		-DGGML_BMI2="$(usex cpu_flags_x86_bmi2 ON OFF)"
		-DGGML_FMA="$(usex cpu_flags_x86_fma3 ON OFF)"
		-DGGML_F16C="$(usex cpu_flags_x86_f16c ON OFF)"
		-DGGML_SSE42="$(usex cpu_flags_x86_sse4_2 ON OFF)"
	)

	# Enable AVX512 if ANY of the avx512 flags are present
	if use cpu_flags_x86_avx512f || use cpu_flags_x86_avx512bw; then
		mycmakeargs+=( -DGGML_AVX512=ON )
	else
		mycmakeargs+=( -DGGML_AVX512=OFF )
	fi

	# CUDA architecture targeting
	use cuda && mycmakeargs+=( -DCMAKE_CUDA_ARCHITECTURES="${LLAMA_CUDA_ARCH}" )

	cmake_src_configure
}

src_compile() {
	use cuda && cuda_add_sandbox -w
	cmake_src_compile
}

src_test() {
	use test || return 0
	cmake_build llama-test
	./bin/llama-test || die "llama.cpp tests failed"
}

src_install() {
	cmake_src_install

	dodoc README.md 2>/dev/null || true

	if use server; then
		keepdir /var/lib/llama.cpp/models
		if use openrc; then
			newconfd "${FILESDIR}/llama-server.confd" llama-server
			newinitd "${FILESDIR}/llama-server.initd" llama-server
		fi
		use systemd && systemd_dounit "${FILESDIR}/llama-server.service"
	fi
}

pkg_postinst() {
	elog "llama.cpp ${TAG} installed (system ggml from ::gentoo)."
	elog "Binaries: llama-server, llama-cli, llama-quantize, llama-perplexity,"
	elog "          llama-embedding, llama-gguf-split, llama-gguf-hash ..."
	if use cuda; then
		elog "CUDA build targeted sm_${LLAMA_CUDA_ARCH} (RTX 4090)."
		elog "Retarget with LLAMA_CUDA_ARCH=8.6 in the build environment."
	fi
	if use native; then
		elog "GGML_NATIVE=ON: binary is optimized for THIS build machine's GPU only."
		elog "Not portable to other GPUs of the same architecture."
	fi
	elog "Models (GGUF) are not bundled — provide your own or use ollama."
}
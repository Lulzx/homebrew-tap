class Cumetal < Formula
  desc "CUDA compiler and compatibility runtime for Apple Metal"
  homepage "https://github.com/Lulzx/cuda-metal"
  url "https://github.com/Lulzx/cuda-metal/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "febf5e8c5dbaba5e1ef5d63ba82b11a2db2912f9fccb48835179da2afc63af0d"
  license "Apache-2.0"
  head "https://github.com/Lulzx/cuda-metal.git", branch: "main"

  depends_on "cmake" => :build
  depends_on arch: :arm64
  depends_on "llvm"
  depends_on macos: :sonoma

  def install
    odie "Apple's Xcode Command Line Tools are required." unless File.executable?("/usr/bin/xcrun")

    %w[metal metallib].each do |tool|
      next if quiet_system("/usr/bin/xcrun", "--find", tool)

      odie "Apple's #{tool} tool is required. Install Xcode or the Metal Toolchain component."
    end

    args = std_cmake_args + %W[
      -DCUMETAL_BUILD_TESTS=OFF
      -DCUMETAL_ENABLE_BINARY_SHIM=OFF
      -DLLVM_DIR=#{formula_opt_lib("llvm")}/cmake/llvm
    ]

    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build", "--parallel"
    system "cmake", "--install", "build"
  end

  def caveats
    <<~EOS
      CuMetal also needs Apple's Metal compiler. If `xcrun --find metal`
      fails, install Xcode or the Metal Toolchain component.

      The optional libcuda.dylib binary-compatibility shim is intentionally
      disabled. Homebrew installs the recommended source-first path.
    EOS
  end

  test do
    assert_match "cumetal 0.3.0", shell_output("#{bin}/cumetal version")
    system bin/"cumetal", "doctor"

    (testpath/"vector_add.cu").write <<~CUDA
      #include <cstdio>
      #include <cuda_runtime.h>

      __global__ void add_one(int *value) {
        if (threadIdx.x == 0) *value += 1;
      }

      int main() {
        int host = 41;
        int *device = nullptr;
        if (cudaMalloc(&device, sizeof(host)) != cudaSuccess) return 1;
        if (cudaMemcpy(device, &host, sizeof(host), cudaMemcpyHostToDevice) != cudaSuccess) return 2;
        add_one<<<1, 1>>>(device);
        if (cudaDeviceSynchronize() != cudaSuccess) return 3;
        if (cudaMemcpy(&host, device, sizeof(host), cudaMemcpyDeviceToHost) != cudaSuccess) return 4;
        cudaFree(device);
        std::printf("%d\\n", host);
        return host == 42 ? 0 : 5;
      }
    CUDA

    system bin/"cumetalc", testpath/"vector_add.cu", "-o", testpath/"vector_add"
    ENV["CUMETAL_TRACE_GPU"] = "1"
    output = shell_output("#{testpath}/vector_add 2>&1")
    assert_match(/^42$/, output)
    assert_match "device=apple_gpu", output
    assert_match "launch_success=true", output
  end
end

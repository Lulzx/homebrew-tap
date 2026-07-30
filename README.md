# Lulzx Homebrew Tap

## CuMetal

CuMetal compiles supported CUDA source for Apple Metal on Apple Silicon.
It requires macOS 14 or newer and Apple's Metal Toolchain.

```bash
brew install lulzx/tap/cumetal
cumetal doctor
cumetalc vectorAdd.cu -o vectorAdd
./vectorAdd
```

The formula installs CuMetal's recommended source-first path. The optional
`libcuda.dylib` binary compatibility shim is intentionally disabled.

Alternatively, tap the repository first:

```bash
brew tap lulzx/tap
brew install cumetal
```

In a `Brewfile`:

```ruby
tap "lulzx/tap"
brew "cumetal"
```

CuMetal source and compatibility documentation live in
[`Lulzx/cuda-metal`](https://github.com/Lulzx/cuda-metal).

## Updating

```bash
brew update
brew upgrade cumetal
```

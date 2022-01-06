# PDFmerger.jl

[![Build Status](https://github.com/scheidan/PDFmerger.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/scheidan/PDFmerger.jl/actions/workflows/CI.yml?query=branch%3Amain) [![Coverage](https://codecov.io/gh/scheidan/PDFmerger.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/scheidan/PDFmerger.jl)



A simple package to merge pdf files on Linux, OS X and Windows.

## Usage

### Merge pdf files

```Julia
merge_pdfs(["file_1.pdf", "file_1.pdf", "file_2.pdf"], "merged.pdf")
```
Note, the same files can be merged multiple times.

Use the `cleanup` option to delete the single files after merging:
```Julia
merge_pdfs(["file_1.pdf", "file_1.pdf", "file_2.pdf"], "merged.pdf", cleanup=true)
```

### Append to a file

Appending with `append_pdf!` is particularly useful to create a single pdf
that contains multiple plots on separate pages:
```Julia
using Plots

for i in 1:5
    p = plot(rand(33), title="$i");
    savefig(p, "temp.pdf")
    append_pdf!("allplots.pdf", "temp.pdf", cleanup=true)
end
```
All five plots are contained in `allplots.pdf` and the temporary file is deleted.


## Acknowledgments

All the heavy lifting is done by
[`Poppler`](https://poppler.freedesktop.org/). Thanks to the maintainers
of `Poppler` and [`Poppler_jll.jl`](https://github.com/JuliaBinaryWrappers/Poppler_jll.jl)!

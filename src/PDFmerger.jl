module PDFmerger

import Base.Filesystem
using Poppler_jll: pdfunite, pdfinfo, pdfseparate
using Distributed: myid

export merge_pdfs, split_pdf, append_pdf!

"""
```
  merge_pdfs(files::Vector{AbstractString}, destination::AbstractString = "merged.pdf";
                    cleanup::Bool = false)
```

Merge all PDF files listed in `files` into a PDF named `destination`. Returns the name
 of the destination file.

## Arguments

- `files`: array of file names to merge
- `destination`: name of the newly created pdf
- `cleanup`: if `true`, all `files` are deleted after merging
"""
function merge_pdfs(files::Vector{T}, destination::AbstractString="merged.pdf";
                    cleanup::Bool = false) where T <: AbstractString
    # Get the process ID of the current Julia process and the ID of the current
    # worker thread, such that separate process and workers create separate
    # temporary files and do not mess up files of other workers.
    process_id = getpid()
    thread_id = myid()
    identifier_stub = "_$(process_id)_$(thread_id)_"
    if destination ∈ files
        # rename existing file
        Filesystem.mv(destination, destination * identifier_stub)
        files[files .== destination] .=  destination * identifier_stub
    end

    # Merge large number of files iteratively, because there
    # is a (OS dependent) limit how many files 'pdfunit' can handle at once.
    # See: https://gitlab.freedesktop.org/poppler/poppler/-/issues/334
    filemax = 200

    k = 1
    for files_part in Base.Iterators.partition(files, filemax)
        if k == 1
            outfile_tmp2 = "_temp_destination_$(identifier_stub)_$k"

            run(`$(pdfunite()) $files_part $outfile_tmp2`)

        else
            outfile_tmp1 = "_temp_destination_$(identifier_stub)_$(k-1)"
            outfile_tmp2 = "_temp_destination_$(identifier_stub)_$k"

            run(`$(pdfunite()) $outfile_tmp1 $files_part $outfile_tmp2`)

        end
        k += 1
    end

    # rename last file
    Filesystem.mv("_temp_destination_$(identifier_stub)_$(k-1)", destination, force=true)

    # remove temp files
    Filesystem.rm(destination * identifier_stub, force=true)
    Filesystem.rm.("_temp_destination_$(identifier_stub)_$(i)" for i in 1:(k-2))
    if cleanup
        Filesystem.rm.(files, force=true)
    end

    destination
end



"""
```
  append_pdf!(file1::AbstractString, file2::AbstractString;
              create::Bool = true, cleanup::Bool = false)
```

Appends the PDF `file2` to PDF `file1`.

## Arguments

- `create`: if `true`, `file1` is created if not existing.
- `cleanup`: if `true`, all `file2` is deleted after appending

## Example

Create a single PDF containing a page for each plot:
```Julia
using Plots

for i in 1:5
    p = plot(rand(33));
    savefig(p, "temp.pdf")
    append_pdf!("allplots.pdf", "temp.pdf", cleanup=true)
end
```
"""
function append_pdf!(file1::AbstractString, file2::AbstractString;
                     create::Bool = true, cleanup::Bool = false)
    if Filesystem.isfile(file1)
        merge_pdfs([file1, file2], file1, cleanup=cleanup)
    else
        create || error("File '$file1' does not exist!")
        if cleanup
            Filesystem.mv(file2, file1)
        else
            Filesystem.cp(file2, file1)
        end
    end
end


"""
Count pages numbers
"""
function n_pages(file)
    str = read(`$(pdfinfo()) $file`, String)

    m = match(r"Pages:\s+(?<npages>\d+)", str)
    isnothing(m) && error("Could not extract number of pages from:\n\n $str")
    parse(Int, m[:npages])
end


"""
```
  split_pdf(file::AbstractString; cleanup::Bool = false)
```

Split a pdf document in separated pages.

## Arguments

- `file`: name of file to be splitted
- `cleanup`: if `true`, `file` is deleted after splitting
"""
function split_pdf(file::AbstractString; cleanup=false)

    file_no_ending = replace(file, r"\.pdf$" => "")

    n = n_pages(file) |> ndigits
    numberformat = n > 1 ? "%0$(n)d" : "%d"

    run(`$(pdfseparate()) $file $(file_no_ending)_$numberformat.pdf`)

    if cleanup
        Filesystem.rm(file, force=true)
    end

end


end

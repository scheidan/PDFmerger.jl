module PDFmerger

import Base.Filesystem
using Poppler_jll: pdfunite, pdfinfo

export merge_pdfs, append_pdf!

function merge_pdfs(files::Vector{T}, destination::AbstractString="merged.pdf";
                    cleanup=false) where T <: AbstractString
    if destination in files
        # rename existing file
        Filesystem.mv(destination, destination * "_x_")
        files[files .== destination] .=  destination * "_x_"
    end

    # merge pdf
    pdfunite() do unite
        run(`$unite $files $destination`)
    end

    # remove temp files
    Filesystem.rm(destination * "_x_", force=true)
    if cleanup
        Filesystem.rm.(files, force=true)
    end

    destination
end

merge_pdfs(file::AbstractString, destination::AbstractString="merged.pdf"; kwargs...) =
    merge_pdfs([file], destination; kwargs...)

function append_pdf!(file1::AbstractString, file2::AbstractString; create=true, cleanup=false)
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
Count number of pages
"""
function n_pages(file)
    io = IOBuffer()
    pdfinfo() do info
        run(pipeline(`$info $file`, stdout=io))
    end
    str = String(take!(io))

    n = match(r"Pages:\s+(?<npages>\d+)", str)[:npages]
    parse(Int, n)
end

end

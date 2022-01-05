module PDF_merger

import Base.Filesystem
using Poppler_jll: pdfunite

export merge_pdfs, append_pdf!

function merge_pdfs(files::Vector, destination="merged.pdf"; cleanup=false)
    if destination in files
        # rename existing file
        Filesystem.mv(destination, "_x_" * destination)
        files[files .== destination] .= "_x_" * destination
    end

    # merge pdf
    pdfunite() do unite
        run(`$unite $files $destination`)
    end

    # remove temp files
    Filesystem.rm("_x_" * destination)
    if cleanup
        Filesystem.rm.(files, force=true)
    end

end


function append_pdf!(file1, file2; create=true, cleanup=false)
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


end

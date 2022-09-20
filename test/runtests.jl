using PDFmerger
using Test
import Base.Filesystem

test_files = [joinpath(pkgdir(PDFmerger), "test", "file_1.pdf"),
              joinpath(pkgdir(PDFmerger), "test", "file_2.pdf")]

function make_n_copies(file, n)
    for i in 1:n
        cp(file, replace(file, r"\.pdf$" => "$(i).pdf"), force=true)
    end
end

@testset "merge_pdfs" begin

    # -- no cleanup
    # setup test directory
    test_dir = mktempdir()
    single_files = joinpath.(test_dir, ["file_1.pdf", "file_2.pdf"])
    cp.(test_files, single_files)

    out_file = joinpath(test_dir, "out.pdf")

    merge_pdfs(single_files, out_file)
    @test PDFmerger.n_pages(out_file) == 2

    merge_pdfs(single_files, out_file)
    @test PDFmerger.n_pages(out_file) == 2

    # test merging existing file with itself
    merge_pdfs([single_files..., out_file], out_file)
    @test PDFmerger.n_pages(out_file) == 2 + 2

    @test readdir(test_dir) |> length == 3
    @test all(PDFmerger.n_pages.(single_files) .== 1)

    # -- with cleanup
    # setup test directory
    test_dir = mktempdir()
    single_files = joinpath.(test_dir, ["file_1.pdf", "file_2.pdf"])
    cp.(test_files, single_files)

    out_file = joinpath(test_dir, "out.pdf")

    merge_pdfs(single_files, out_file, cleanup=true)
    @test PDFmerger.n_pages(out_file) == 2
    @test readdir(test_dir) |> length == 1


    # -- large number of files
    # setup test directory
    test_dir = mktempdir()
    single_file = joinpath(test_dir, "file.pdf")
    cp(test_files[1], single_file)

    out_file = joinpath(test_dir, "out.pdf")

    n = 1500
    make_n_copies(single_file, n)
    readdir(test_dir)
    merge_pdfs([joinpath(test_dir, "file$i.pdf") for i in 1:n], out_file, cleanup=true)
    @test PDFmerger.n_pages(out_file) == n
    @test readdir(test_dir) |> length == 2
end


@testset "append_pdf" begin

    # -- no cleanup
    # setup test directory
    test_dir = mktempdir()
    single_files = joinpath.(test_dir, ["file_1.pdf", "file_2.pdf"])
    cp.(test_files, single_files)

    out_file = joinpath(test_dir, "out.pdf")

    @test_throws ErrorException append_pdf!(out_file, single_files[1], create=false)

    for k in 1:10
        append_pdf!(out_file, single_files[1])
        @test PDFmerger.n_pages(out_file) == k
    end

    # test existing file with itself
    append_pdf!(out_file, out_file)
    @test PDFmerger.n_pages(out_file) == 2*10
    @test all(PDFmerger.n_pages.(single_files) .== 1)

    @test readdir(test_dir) |> length == 3

    # -- with cleanup
    # setup test directory
    test_dir = mktempdir()
    single_files = joinpath.(test_dir, ["file_1.pdf", "file_2.pdf"])
    cp.(test_files, single_files)

    out_file = joinpath(test_dir, "out.pdf")

    readdir(test_dir)
    @test_throws ErrorException append_pdf!(out_file, single_files[1], create=false, cleanup=true)

    readdir(test_dir)

    append_pdf!(out_file, single_files[1], cleanup=true)

    @test PDFmerger.n_pages(out_file) == 1
    @test "out.pdf" ∈ readdir(test_dir)
    @test "file_1.pdf" ∉ readdir(test_dir)


    append_pdf!(out_file, single_files[2], cleanup=true)
    @test PDFmerger.n_pages(out_file) == 2
    @test "out.pdf" ∈ readdir(test_dir)
    @test "file_2.pdf" ∉ readdir(test_dir)

    # test existing file with itself
    append_pdf!(out_file, out_file, cleanup=true)
    @test PDFmerger.n_pages(out_file) == 2*2

    @test readdir(test_dir) |> length == 1

end

@testset "split_pdf" begin

    # -- no cleanup
    # setup test directory
    test_dir = mktempdir()
    single_files = joinpath.(test_dir, ["file_1.pdf", "file_2.pdf"])
    cp.(test_files, single_files)
    merged_file = joinpath(test_dir, "test.pdf")
    merge_pdfs(single_files, merged_file, cleanup=true)

    split_pdf(merged_file)
    @test length(readdir(test_dir)) == 3

    # - split file with a single page
    # setup test directory
    test_dir = mktempdir()
    single_files = joinpath.(test_dir, ["file_1.pdf", "file_2.pdf"])
    cp.(test_files, single_files)

    split_pdf(single_files[1])
    @test "file_1_1.pdf" ∈ readdir(test_dir)

    # -- with cleanup
    # setup test directory
    test_dir = mktempdir()
    single_files = joinpath.(test_dir, ["file_1.pdf", "file_2.pdf"])
    cp.(test_files, single_files)
    merged_file = joinpath(test_dir, "test.pdf")
    merge_pdfs(single_files, merged_file, cleanup=true)

    split_pdf(merged_file, cleanup=true)
    @test length(readdir(test_dir)) == 2


end

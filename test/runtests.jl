using PDFmerger
using Test
import Base.Filesystem

test_files = [joinpath(pkgdir(PDFmerger), "test/file_1.pdf"),
              joinpath(pkgdir(PDFmerger), "test/file_2.pdf")]

@testset "merge_pdfs" begin

    # -- no cleanup
    # setup test directory
    test_dir = Filesystem.mktempdir()
    single_files = joinpath.(test_dir, ["file_1.pdf", "file_2.pdf"])
    Filesystem.cp.(test_files, single_files)

    out_file = joinpath(test_dir, "out.pdf")

    merge_pdfs(single_files, out_file)
    @test PDFmerger.n_pages(out_file) == 2

    merge_pdfs(single_files, out_file)
    @test PDFmerger.n_pages(out_file) == 2

    # test existing file with itself
    merge_pdfs([single_files..., out_file], out_file)
    @test PDFmerger.n_pages(out_file) == 2 + 2

    @test readdir(test_dir) |> length == 3
    @test all(PDFmerger.n_pages.(single_files) .== 1)

    # -- with cleanup
    # setup test directory
    test_dir = Filesystem.mktempdir()
    single_files = joinpath.(test_dir, ["file_1.pdf", "file_2.pdf"])
    Filesystem.cp.(test_files, single_files)

    out_file = joinpath(test_dir, "out.pdf")

    merge_pdfs(single_files, out_file, cleanup=true)
    @test PDFmerger.n_pages(out_file) == 2
    @test readdir(test_dir) |> length == 1

    # -- single file
    # setup test directory
    test_dir = Filesystem.mktempdir()
    single_files = joinpath.(test_dir, ["file_1.pdf", "file_2.pdf"])
    Filesystem.cp.(test_files, single_files)


    merge_pdfs(single_files[1], single_files[1], cleanup=true)

    @test PDFmerger.n_pages(single_files[1]) == 1
    @test "file_1.pdf" ∈ readdir(test_dir)

end


@testset "append_pdf" begin

    # -- no cleanup
    # setup test directory
    test_dir = Filesystem.mktempdir()
    single_files = joinpath.(test_dir, ["file_1.pdf", "file_2.pdf"])
    Filesystem.cp.(test_files, single_files)

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
    test_dir = Filesystem.mktempdir()
    single_files = joinpath.(test_dir, ["file_1.pdf", "file_2.pdf"])
    Filesystem.cp.(test_files, single_files)

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

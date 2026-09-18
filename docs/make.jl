using ImmutableRNGs
using Documenter

project_path = Base.Filesystem.joinpath(Base.Filesystem.dirname(Base.source_path()), "..")

DocMeta.setdocmeta!(ImmutableRNGs, :DocTestSetup, :(using ImmutableRNGs); recursive = true)

# some paths for links
readme_path = joinpath(project_path, "README.md")
index_path = joinpath(project_path, "docs/src/index.md")
license_path = "https://github.com/szabo137/ImmutableRNGs.jl/blob/main/LICENSE"

# Copy README.md from the project base folder and use it as the start page
open(readme_path, "r") do readme_in
    readme_string = read(readme_in, String)

    # replace relative links in the README.md
    readme_string = replace(readme_string, "[MIT](LICENSE)" => "[MIT]($(license_path))")

    open(index_path, "w") do readme_out
        write(readme_out, readme_string)
    end
end

#const page_rename = Dict("developer.md" => "Developer docs") # Without the numbers
const numbered_pages = [
    file for file in readdir(joinpath(@__DIR__, "src")) if
        file != "index.md" && splitext(file)[2] == ".md"
]


try
    makedocs(;
        modules = [ImmutableRNGs],
        authors = "Uwe Hernandez Acosta <u.hernandez@hzdr.de>",
        #repo = "https://github.com/szabo137/ImmutableRNGs.jl/blob/{commit}{path}#{line}",
        repo = Documenter.Remotes.GitHub("szabo137", "ImmutableRNGs.jl"),
        sitename = "ImmutableRNGs.jl",
        format = Documenter.HTML(;
            prettyurls = get(ENV, "CI", "false") == "true",
            canonical = "https://szabo137.github.io/ImmutableRNGs.jl",
            assets = String[],
        ),
        pages = ["index.md"; numbered_pages]
    )
finally
    # doing some garbage collection
    @info "GarbageCollection: remove generated landing page"
    rm(index_path)
end

deploydocs(; repo = "github.com/szabo137/ImmutableRNGs.jl")

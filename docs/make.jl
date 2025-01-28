using Documenter, DocumenterVitepress
using SatcomCoordinates

should_deploy = get(ENV,"SHOULD_DEPLOY", get(ENV, "CI", "") === "true")

repo = get(ENV, "REPOSITORY", "JuliaSatcomFramework/SatcomCoordinates.jl")
remote = Documenter.Remotes.GitHub(repo)
authors = "Alberto Mengali <alberto.mengali@esa.int>, Matteo Conti <matteo.conti@esa.int>"
sitename = "SatcomCoordinates.jl"
devbranch = "main"
pages = [
    "Home" => "index.md",
    "Performance Examples" => "performance.md",
]

makedocs(;
    sitename = sitename,
    modules = [SatcomCoordinates],
    warnonly = true,
    authors=authors,
    repo = remote,
    pagesonly = true, # This only builds the source files listed in pages
    pages = pages,
    format = MarkdownVitepress(;
        repo = replace(Documenter.Remotes.repourl(remote), r"^https?://" => ""),
        devbranch,
        # install_npm = should_deploy, # Use the built-in npm when running on CI. (Does not work locally on windows!)
        build_vitepress = should_deploy, # Automatically build when running on CI. (Only works with built-in npm!)
        md_output_path = should_deploy ? ".documenter" : ".", # When automatically building, the output should be in build./.documenter, otherwise just output to build/
        #deploy_decision,
    ),
    clean = should_deploy,
)

if should_deploy
    repo_url = "https://github.com/" * repo
    deploydocs(;repo=repo_url)
end
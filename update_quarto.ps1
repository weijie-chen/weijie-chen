# Ensure NuGet provider is installed
try {
    if (-not (Get-PackageProvider -ListAvailable -Name NuGet)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
    }
} catch {
    Write-Output "Error installing NuGet provider: $_"
    exit 1
}

# Ensure PowerShell-Yaml module is installed for the current user
try {
    if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
        Install-Module -Name powershell-yaml -Force -Scope CurrentUser
    }
    Import-Module powershell-yaml
} catch {
    Write-Output "Error installing or importing PowerShell-Yaml module: $_"
    exit 1
}

# Function to copy repository contents
function Copy-RepoContents {
    param (
        [string]$sourceDir,
        [string]$targetDir
    )

    if (Test-Path $targetDir) {
        Remove-Item -Path $targetDir -Recurse -Force
    }
    Copy-Item -Path $sourceDir -Destination $targetDir -Recurse
}

# Function to convert .ipynb to .qmd recursively
function Convert-IpynbToQmd {
    param (
        [string]$path
    )
    Get-ChildItem -Path $path -Recurse -Filter *.ipynb | ForEach-Object {
        quarto convert $_.FullName
    }
    Get-ChildItem -Path $path -Recurse -Filter *.ipynb | Remove-Item
}

# Function to generate _quarto.yml for a directory
function New-QuartoYml {
    param (
        [string]$path,
        [string]$projectTitle
    )

    $chapters = Get-ChildItem -Path $path -Filter *.qmd -Recurse | Sort-Object FullName | ForEach-Object {
        @{
            chapter = $_.BaseName
            file = $_.FullName.Substring($path.Length + 1).Replace("\", "/")
        }
    }

    $content = @{
        project = @{
            type = "book"
            title = $projectTitle
        }
        book = @{
            chapters = $chapters
        }
    }

    $yamlContent = $content | ConvertTo-Yaml
    Set-Content -Path (Join-Path $path "_quarto.yml") -Value $yamlContent
}

# Paths to the original repositories and the target directory
$repos = @(
    @{source = "F:\8887_github_repos\Basic-Statistics-With-Python"; target = "F:\8887_github_repos\weijie-chen\basic-statistics"; title = "Basic Statistics"},
    @{source = "F:\8887_github_repos\Bayesian-Statistics-Econometrics"; target = "F:\8887_github_repos\weijie-chen\bayesian-statistics"; title = "Bayesian Statistics"},
    @{source = "F:\8887_github_repos\Econometrics-With-Python"; target = "F:\8887_github_repos\weijie-chen\econometrics"; title = "Econometrics"},
    @{source = "F:\8887_github_repos\Linear-Algebra-With-Python"; target = "F:\8887_github_repos\weijie-chen\linear-algebra"; title = "Linear Algebra"},
    @{source = "F:\8887_github_repos\Time-Series-and-Financial-Engineering-With-Python"; target = "F:\8887_github_repos\weijie-chen\financial-engineering"; title = "Financial Engineering"}
)

# Process each repository
foreach ($repo in $repos) {
    Write-Output "Processing repository: $($repo.source)"
    
    # Copy contents
    Copy-RepoContents -sourceDir $repo.source -targetDir $repo.target
    
    # Convert .ipynb files to .qmd and remove .ipynb files
    Convert-IpynbToQmd -path $repo.target
    
    # Generate _quarto.yml
    New-QuartoYml -path $repo.target -projectTitle $repo.title
}

# Render the Quarto project
Write-Output "Rendering Quarto project..."
quarto render

Write-Output "Conversion, YAML generation, and rendering completed."

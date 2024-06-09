#!/bin/bash

# Ensure jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq could not be found, installing..."
    sudo apt-get update && sudo apt-get install -y jq
fi

# Ensure pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "pip could not be found, installing..."
    sudo apt update && sudo apt install -y python3-pip
fi

# Ensure yq is installed
if ! command -v yq &> /dev/null; then
    echo "yq could not be found, installing..."
    pip3 install yq
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
fi

# Ensure quarto is installed
if ! command -v quarto &> /dev/null; then
    echo "quarto could not be found, installing..."
    sudo apt install wget
    wget https://github.com/quarto-dev/quarto-cli/releases/download/v1.2.313/quarto-1.2.313-linux-amd64.deb
    sudo dpkg -i quarto-1.2.313-linux-amd64.deb
fi

# Function to copy repository contents
copy_repo_contents() {
    local sourceDir="$1"
    local targetDir="$2"

    if [ -d "$targetDir" ]; then
        rm -rf "$targetDir"
    fi
    cp -r "$sourceDir" "$targetDir"
}

# Function to convert .ipynb to .qmd recursively
convert_ipynb_to_qmd() {
    local path="$1"
    find "$path" -name '*.ipynb' -exec quarto convert {} \;
    find "$path" -name '*.ipynb' -delete
}

# Function to generate _quarto.yml for a directory
new_quarto_yml() {
    local path="$1"
    local projectTitle="$2"

    chapters=$(find "$path" -name '*.qmd' | sort)

    # Initialize the YAML content
    yml_content="project:\n  type: book\n  title: \"$projectTitle\"\n\nbook:\n  chapters:\n"

    # Append each chapter to the YAML content
    while IFS= read -r chapter; do
        chapter_name=$(basename "$chapter" .qmd)
        relative_path=$(realpath --relative-to="$path" "$chapter")
        yml_content+="    - chapter: \"$chapter_name\"\n      file: \"$relative_path\"\n"
    done <<< "$chapters"

    # Write the YAML content to _quarto.yml
    echo -e "$yml_content" > "$path/_quarto.yml"
}

# Paths to the original repositories and the target directory
declare -A repos=(
    ["Basic Statistics"]="/mnt/f/8887_github_repos/Basic-Statistics-With-Python:/mnt/f/8887_github_repos/weijie-chen/basic-statistics"
    ["Bayesian Statistics"]="/mnt/f/8887_github_repos/Bayesian-Statistics-Econometrics:/mnt/f/8887_github_repos/weijie-chen/bayesian-statistics"
    ["Econometrics"]="/mnt/f/8887_github_repos/Econometrics-With-Python:/mnt/f/8887_github_repos/weijie-chen/econometrics"
    ["Linear Algebra"]="/mnt/f/8887_github_repos/Linear-Algebra-With-Python:/mnt/f/8887_github_repos/weijie-chen/linear-algebra"
    ["Financial Engineering"]="/mnt/f/8887_github_repos/Time-Series-and-Financial-Engineering-With-Python:/mnt/f/8887_github_repos/weijie-chen/financial-engineering"
)

# Process each repository
for title in "${!repos[@]}"; do
    IFS=':' read -r source target <<< "${repos[$title]}"
    echo "Processing repository: $source"
    
    # Copy contents
    copy_repo_contents "$source" "$target"
    
    # Convert .ipynb files to .qmd and remove .ipynb files
    convert_ipynb_to_qmd "$target"
    
    # Generate _quarto.yml
    new_quarto_yml "$target" "$title"
done

# Render the Quarto project
echo "Rendering Quarto project..."
quarto render

echo "Conversion, YAML generation, and rendering completed."

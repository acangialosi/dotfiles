# Sample of a personal automation script
git config --global user.name "Anthony Cangialosi [MS]"
git config --global user.email 5457010+acangialosi@users.noreply.github.com

# Set dark mode
winget configure '.\personal-dev-env.yaml' --accept-configuration-agreements

# Setup OMP
oh-my-posh font install --user CascadiaCode
Set-Content -Path $PROFILE -Value 'oh-my-posh --init --shell pwsh --config ~/jandedobbeleer.omp.json | Invoke-Expression'
Install-Module -Name Terminal-Icons -Repository PSGallery -Force    
Import-Module -Name Terminal-Icons

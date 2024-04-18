# Setup OMP
oh-my-posh font install --user CascadiaCode
Set-Content -Path $PROFILE -Value 'oh-my-posh --init --shell pwsh --config ~/jandedobbeleer.omp.json | Invoke-Expression'
Install-Module -Name Terminal-Icons -Repository PSGallery -Force    
Import-Module -Name Terminal-Icons


# Setup VS Settings
$vssettingpath = join-path (get-location).path '\visualstudio\settings\devbox'
[System.Environment]::SetEnvironmentVariable('VS_UNIFIED_SETTINGS_PROFILE', $vssettingpath, 'User')
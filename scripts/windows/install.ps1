param(
    [string]$Python="py -3.12"
)
Write-Host "Creating virtual environment"
& $Python -m venv .venv
Write-Host "Activating environment"
.\.venv\Scripts\python.exe -m pip install `
    --upgrade pip
Write-Host "Installing offline wheels"
.\.venv\Scripts\pip.exe install `
    --no-index `
    --find-links wheels `
    -r requirements.txt
Write-Host "Installation complete"

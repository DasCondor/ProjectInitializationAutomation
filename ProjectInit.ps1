# Project initialization functions for your PowerShell profile.
# Add this line to $PROFILE:
#   . "C:\path\to\ProjectInitializationAutomation\ProjectInit.ps1"
# Works in Windows PowerShell 5.1 and PowerShell 7. No Python needed.

function Get-ProjectConfigPath {
    if ($env:PROJECTINIT_CONFIG) { $env:PROJECTINIT_CONFIG } else { Join-Path $HOME '.projectinit.json' }
}

function Get-ProjectConfig {
    # Defaults (the env vars are the ones the windows_OS scripts use), overridden by the saved file.
    $cfg = [ordered]@{
        ProjectsFolder = $env:mp
        TemplateFolder = Join-Path $HOME 'ProjectTemplates'
        Provider       = 'github'
        AzureOrg       = $env:ado_org
        AzureProject   = $env:ado_project
    }
    $path = Get-ProjectConfigPath
    if (Test-Path $path) {
        $saved = Get-Content $path -Raw | ConvertFrom-Json
        foreach ($p in $saved.PSObject.Properties) {
            if ($p.Value -and $cfg.Contains($p.Name)) { $cfg[$p.Name] = $p.Value }
        }
    }
    [pscustomobject]$cfg
}

function Set-ProjectConfig {
    [CmdletBinding()]
    param(
        [string]$ProjectsFolder,
        [string]$TemplateFolder,
        [ValidateSet('github', 'azure', 'local')][string]$Provider,
        [string]$AzureOrg,
        [string]$AzureProject
    )
    $cfg = Get-ProjectConfig
    foreach ($k in $PSBoundParameters.Keys) {
        if (-not $cfg.PSObject.Properties[$k]) { continue }
        $v = $PSBoundParameters[$k]
        if ($k -like '*Folder') {
            New-Item -ItemType Directory -Path $v -Force | Out-Null
            $v = (Resolve-Path -LiteralPath $v).ProviderPath
        }
        $cfg.$k = $v
    }
    $cfg | ConvertTo-Json | Set-Content -LiteralPath (Get-ProjectConfigPath) -Encoding UTF8
    $cfg
}

function Set-TemplateFolder {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)][string]$Path)
    $cfg = Set-ProjectConfig -TemplateFolder $Path
    Write-Host "Template folder: $($cfg.TemplateFolder)"
}

function Get-Template {
    $folder = (Get-ProjectConfig).TemplateFolder
    if (Test-Path $folder) { Get-ChildItem -LiteralPath $folder -Directory | Select-Object -ExpandProperty Name }
}

function New-Template {
    # New-Template <name>               -> empty template folder to fill in
    # New-Template <name> -From <path>  -> template copied from an existing folder (without its .git)
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)][string]$Name,
        [Parameter(Position = 1)][string]$From
    )
    $dest = Join-Path (Get-ProjectConfig).TemplateFolder $Name
    if (Test-Path $dest) { throw "Template '$Name' already exists at $dest" }
    if ($From -and -not (Test-Path -LiteralPath $From -PathType Container)) { throw "Folder not found: $From" }
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    if ($From) {
        Get-ChildItem -LiteralPath $From -Force | Where-Object { $_.Name -ne '.git' } |
            Copy-Item -Destination $dest -Recurse -Force
    }
    Write-Host "Template '$Name' created at $dest"
}

function New-Project {
    # New-Project <name> [<template>] [-Provider github|azure|local] [-NoOpen]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)][string]$Name,
        [Parameter(Position = 1)][string]$Template,
        [ValidateSet('github', 'azure', 'local')][string]$Provider,
        [switch]$NoOpen
    )
    $cfg = Get-ProjectConfig
    if (-not $Provider) { $Provider = $cfg.Provider }
    if (-not $cfg.ProjectsFolder) { throw 'No projects folder set. Run: Set-ProjectConfig -ProjectsFolder <path>' }
    $dir = Join-Path $cfg.ProjectsFolder $Name
    if (Test-Path $dir) { throw "$dir already exists" }
    if ($Template) {
        $tpl = Join-Path $cfg.TemplateFolder $Template
        if (-not (Test-Path $tpl -PathType Container)) { throw "Template '$Template' not found in $($cfg.TemplateFolder)" }
    }

    # Create the remote first so a failure leaves nothing behind locally.
    $remote = $null
    if ($Provider -eq 'github') {
        $token = $env:GITHUB_TOKEN
        if (-not $token) { $token = $env:gt }
        if (-not $token -and (Get-Command gh -ErrorAction SilentlyContinue)) { $token = gh auth token }
        if (-not $token) { throw 'No GitHub token. Set $env:GITHUB_TOKEN or sign in with: gh auth login' }
        try {
            $repo = Invoke-RestMethod -Method Post -Uri 'https://api.github.com/user/repos' `
                -Headers @{ Authorization = "Bearer $token"; Accept = 'application/vnd.github+json' } `
                -ContentType 'application/json' -Body (@{ name = $Name } | ConvertTo-Json)
        }
        catch { throw "GitHub refused to create '$Name': $($_.Exception.Message) $($_.ErrorDetails.Message)" }
        $remote = $repo.clone_url
    }
    elseif ($Provider -eq 'azure') {
        $pat = $env:AZURE_PAT
        if (-not $pat) { $pat = $env:ado_pat }
        if (-not ($pat -and $cfg.AzureOrg -and $cfg.AzureProject)) {
            throw 'Azure DevOps needs $env:AZURE_PAT and: Set-ProjectConfig -AzureOrg <org> -AzureProject <project>'
        }
        $basic = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
        $uri = 'https://dev.azure.com/{0}/{1}/_apis/git/repositories?api-version=7.1' -f `
            [uri]::EscapeDataString($cfg.AzureOrg), [uri]::EscapeDataString($cfg.AzureProject)
        try {
            $repo = Invoke-RestMethod -Method Post -Uri $uri -Headers @{ Authorization = "Basic $basic" } `
                -ContentType 'application/json' -Body (@{ name = $Name } | ConvertTo-Json)
        }
        # ErrorDetails is left out here: for a wrong org it is a whole HTML page.
        catch { throw "Azure DevOps refused to create '$Name': $($_.Exception.Message) Check the organization, project and token." }
        # A bad PAT comes back as 203 + an HTML sign-in page instead of an error.
        $remote = $repo.remoteUrl
        if (-not $remote) { throw 'Azure DevOps did not create the repo. Check the token (needs Code: Read, write & manage scope).' }
    }

    New-Item -ItemType Directory -Path $dir | Out-Null
    if ($Template) { Copy-Item -Path (Join-Path $tpl '*') -Destination $dir -Recurse -Force }
    $readme = Join-Path $dir 'README.md'
    if (-not (Test-Path $readme)) { "# $Name" | Set-Content -LiteralPath $readme }

    Set-Location -LiteralPath $dir
    git init -q
    git add .
    git commit -q -m 'Initial commit'
    if ($remote) {
        git remote add origin $remote
        git push -u origin HEAD
        if ($LASTEXITCODE -ne 0) { Write-Warning "Repo created at $remote but the push failed." }
    }
    Write-Host "Project '$Name' created at $dir"
    if (-not $NoOpen -and (Get-Command code -ErrorAction SilentlyContinue)) { code . }
}

Set-Alias -Name create -Value New-Project

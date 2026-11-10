Fork of [KalleHallden/ProjectInitializationAutomation](https://github.com/KalleHallden/ProjectInitializationAutomation) that can create the remote repository on **GitHub or Azure DevOps**.

### Install: 
```bash
git clone "https://github.com/DasCondor/ProjectInitializationAutomation.git"
cd ProjectInitializationAutomation
pip install -r requirements.txt
touch .env
Then open the .env file and fill it in using one of the formats at the bottom of this README.
source ~/.my_commands.sh
```

### Usage:
```bash
To run the script type in 'create <name of your folder>'
```
The repository is created on the provider set by `PROVIDER` in `.env` (`github` if unset), then a local folder is created, initialised and pushed over SSH.

### Env File Format (GitHub):
```bash
PROVIDER="github"
GITHUB_TOKEN="ghp_yourPersonalAccessToken"
FILEPATH="/path/to/your/project/"
```
`USERNAME`/`PASSWORD` from the original project are still read if `GITHUB_TOKEN` is not set, but GitHub no longer accepts password logins for its API.

### Env File Format (Azure DevOps):
```bash
PROVIDER="azure"
AZURE_ORG="your-organization"
AZURE_PROJECT="Your Project"
AZURE_PAT="yourPersonalAccessToken"
FILEPATH="/path/to/your/project/"
```
- The project must already exist; the new repo is created inside it.
- Create the token under *User settings > Personal access tokens* with the **Code: Read, write & manage** scope.
- The push uses SSH, so add your public key under *User settings > SSH public keys*.

Windows users: see [windows_OS](windows_OS/README.md), or use the PowerShell version below.

## PowerShell profile functions

`ProjectInit.ps1` is a standalone port (no Python) with project templates. Add it to your profile:
```powershell
Add-Content $PROFILE '. "C:\path\to\ProjectInitializationAutomation\ProjectInit.ps1"'
```

### One-time setup:
```powershell
Set-ProjectConfig -ProjectsFolder C:\dev -Provider github   # github | azure | local
Set-TemplateFolder C:\dev\_templates                        # default: ~\ProjectTemplates
Set-ProjectConfig -AzureOrg your-organization -AzureProject "Your Project"   # only for azure
```
Settings are saved in `~\.projectinit.json`. Tokens are never saved there; they are read from:
- GitHub: `$env:GITHUB_TOKEN`, or the GitHub CLI if you are signed in with `gh auth login`
- Azure DevOps: `$env:AZURE_PAT`

### Templates:
```powershell
New-Template python -From C:\dev\some-project   # copy an existing folder (its .git is left out)
New-Template blank                              # empty template folder to fill in yourself
Get-Template                                    # list templates
```

### Create a project:
```powershell
create my-app                    # alias for New-Project
create my-app python             # start from the "python" template
create my-app -Provider azure    # override the default provider once
create my-app -Provider local    # no remote repo
```
This creates the remote repo, copies the template into `<ProjectsFolder>\my-app`, commits, pushes over HTTPS, and opens VS Code (`-NoOpen` to skip).

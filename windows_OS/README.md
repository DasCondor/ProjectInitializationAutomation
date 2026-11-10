### pre-setup:
```
create env vars :
> projects directory as - "mp"
> Github token as      - "gt"

for Azure DevOps also create :
> organization name as                                  - "ado_org"
> project name (must already exist) as                  - "ado_project"
> personal access token (Code: Read, write & manage) as - "ado_pat"
```

### setup: 
```bash
git clone "https://github.com/DasCondor/ProjectInitializationAutomation.git"
cd ProjectInitializationAutomation/windows_OS
pip install -r requirements.txt

path:
add the "windows_OS" folder directory to path
```

### Usage:
```bash
Command to run the program type

'create <project_name>'       - repo on GitHub
'create <project_name> a'     - repo on Azure DevOps
'create <project_name> l'     - for just locally
```
Remote repos are pushed over HTTPS; Git Credential Manager will ask you to sign in the first time.

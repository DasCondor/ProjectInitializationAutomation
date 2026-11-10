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

Windows users: see [windows_OS](windows_OS/README.md).

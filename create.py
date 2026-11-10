import sys
import os
from dotenv import load_dotenv

load_dotenv()

path = os.getenv("FILEPATH")
provider = os.getenv("PROVIDER", "github").lower()


def create_github(name):
    from github import Github
    token = os.getenv("GITHUB_TOKEN")
    # GitHub no longer accepts passwords for the API; USERNAME/PASSWORD kept for old .env files.
    g = Github(token) if token else Github(os.getenv("USERNAME"), os.getenv("PASSWORD"))
    return g.get_user().create_repo(name).ssh_url


def create_azure(name):
    from azure_devops import create_repo
    return create_repo(os.environ["AZURE_ORG"], os.environ["AZURE_PROJECT"],
                       os.environ["AZURE_PAT"], name)["sshUrl"]


def create():
    folderName = str(sys.argv[1])
    if provider == "github":
        remote = create_github(folderName)
    elif provider == "azure":
        remote = create_azure(folderName)
    else:
        sys.exit(f"Unknown PROVIDER '{provider}' (use 'github' or 'azure')")
    os.makedirs(path + folderName)
    print(f"Succesfully created repository {folderName}", file=sys.stderr)
    # stdout is read by .my_commands.sh as the git remote
    print(remote)

if __name__ == "__main__":
    create()

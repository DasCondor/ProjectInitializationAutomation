import sys
import os

foldername = str(sys.argv[1])
provider = sys.argv[2] if len(sys.argv) > 2 else "github"
path = os.environ.get('mp')         # add projects dirctory to the env vars
_dir = path + '/' + foldername

if provider == "azure":
    # azure_devops.py lives in the repo root
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
    from azure_devops import create_repo
    # add Azure DevOps organization, project and personal access token to the env vars
    remote = create_repo(os.environ['ado_org'], os.environ['ado_project'],
                         os.environ['ado_pat'], foldername)['remoteUrl']
else:
    from github import Github
    token = os.environ.get('gt')    # add github token to the env vars
    remote = Github(token).get_user().create_repo(foldername).clone_url

commands = [f'echo "# {foldername}" >> README.md',
            'git init',
            f'git remote add origin {remote}',
            'git add .',
            'git commit -m "Initial commit"',
            'git push -u origin HEAD']

os.mkdir(_dir)
os.chdir(_dir)

for c in commands:
    os.system(c)

print(f'{foldername} created locally')
os.system('code .')

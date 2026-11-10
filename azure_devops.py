from urllib.parse import quote

import requests


def create_repo(org, project, pat, name):
    """Create a git repo in an Azure DevOps project. Returns the API's repo dict
    (includes "sshUrl" and "remoteUrl")."""
    url = f"https://dev.azure.com/{quote(org)}/{quote(project)}/_apis/git/repositories?api-version=7.1"
    r = requests.post(url, json={"name": name}, auth=("", pat), timeout=30)
    # A bad PAT comes back as 203 + an HTML sign-in page, so only 201 is success.
    if r.status_code != 201:
        try:
            detail = r.json().get("message", r.text)
        except ValueError:
            detail = "check the organization, project and token (needs Code: Read, write & manage scope)"
        raise SystemExit(f"Azure DevOps refused to create {name} (HTTP {r.status_code}): {detail}")
    return r.json()

#!/usr/bin/env bash
# Create a new service from this template, ready to deploy on push.
# Usage: scripts/new-service.sh <name> <port>     e.g. scripts/new-service.sh recipes-api 8830
# Needs: gh logged in, ssh zephyrus working. Creates the private repo Zaher503/<name> in ../<name>.
set -euo pipefail
name=${1:?service name, e.g. recipes-api}
port=${2:?port, e.g. 8830}
owner=Zaher503
here=$(cd "$(dirname "$0")/.." && pwd)

gh repo create "$owner/$name" --private --template "$owner/service-template" --clone --description "$name"
cd "$name"
sed -i "s/my-service/$name/g; s/\"8800\"/\"$port\"/g" .github/workflows/cd.yml compose.yaml app/main.py
sed -i "s/8800/$port/g" Dockerfile compose.yaml
git add -A && git commit -q -m "Set the service name and port" && git push -q
# One runner per repo, and the folder the deploy writes to
"$here/scripts/add-runner.sh" "$name" "$name"
ssh zephyrus "sudo install -d -o zaher -g zaher /opt/$name"
echo "Done. Put the real settings in /opt/$name/.env on the Zephyrus, then push to main to deploy."

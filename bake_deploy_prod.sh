#!/bin/bash
set -ex

expected_branch="main"

current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" != "$expected_branch" ]]; then
  echo "❌ You are on branch '$current_branch'. Please switch to '$expected_branch' before deploying."
  exit 1
fi

if [[ -n $(git status --porcelain) ]]; then
  echo "❌ You have uncommitted changes. Please commit or stash them before deploying."
  exit 1
fi

export DOMAIN=unmute.sh
# Note that using non-Mistral models also requires changing the vLLM args in ./swarm-deploy.yml
export KYUTAI_LLM_MODEL=google/gemma-3-12b-it
export DOCKER_HOST=ssh://root@${DOMAIN}

echo "If you get an connection error, do: ssh root@${DOMAIN}"

docker buildx bake -f ./swarm-deploy.yml --allow=ssh --push
docker stack deploy --with-registry-auth --prune --compose-file ./swarm-deploy.yml llm-wrapper

#!/usr/bin/env bash

# requirements:
# - aws CLI
# - helm CLI
# - jq

set -euo pipefail

BUCKET="${HELM_MIRROR_BUCKET_NAME:-bucket-name-change-me}"
REGION="${BUCKET_REGION:-ap-southeast-1}"

mirror-helm() {
    local repoName=$1
    local chartName=$2
    local versionConstraint=$3
    local repo=$4
    
    mkdir -p $repoName
    aws s3 sync s3://$BUCKET/charts/$repoName/ $repoName --region $REGION
    helm repo add $repoName $repo
    helm repo update
    versions=$(helm search repo $repoName/$chartName --version $versionConstraint --versions --output json | jq --raw-output '.[].version')
    for v in ${versions[@]}
    do
        echo pulling chart $repoName/$chartName:$v ...
        helm pull $repoName/$chartName --version $v -d $repoName
    done
    
    helm repo index $repoName
    aws s3 sync $repoName s3://$BUCKET/charts/$repoName/ --region $REGION
}

# the helm pull command supports version constraint so you can do version constraint like this: ^2.0.0
mirror-helm "argo" "argo-cd" "^5.16.0" "https://argoproj.github.io/argo-helm"

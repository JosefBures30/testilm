$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\env.ps1')

$mount = "type=bind,source=$($env:TESTILM_ROOT),target=/workspace"
& docker run --rm `
    --mount $mount `
    --workdir /workspace/local-stack `
    --env TESTILM_ROOT=/workspace `
    python:3.12-alpine python prepare.py

if ($LASTEXITCODE -ne 0) {
    throw "Local stack preparation failed with exit code $LASTEXITCODE."
}

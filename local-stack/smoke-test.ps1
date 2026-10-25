$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\env.ps1')

$baseUrl = 'http://localhost:8000'
$envFile = Join-Path $env:TESTILM_ROOT 'local-stack\.env'
if (-not (Test-Path $envFile)) {
    throw "Missing $envFile. Start the stack and run prepare.py first."
}

$credentials = @{}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        $credentials[$matches[1]] = $matches[2]
    }
}

$tokenJson = & curl.exe --fail --silent --show-error `
    --request POST "$baseUrl/kc/realms/ILM/protocol/openid-connect/token" `
    --header 'Content-Type: application/x-www-form-urlencoded' `
    --data-urlencode 'grant_type=password' `
    --data-urlencode 'client_id=ilm' `
    --data-urlencode "client_secret=$($credentials['OIDC_CLIENT_SECRET'])" `
    --data-urlencode "username=$($credentials['ILM_ADMIN_USERNAME'])" `
    --data-urlencode "password=$($credentials['ILM_ADMIN_PASSWORD'])"
if ($LASTEXITCODE -ne 0) {
    throw 'Keycloak token request failed.'
}

$accessToken = ($tokenJson | ConvertFrom-Json).access_token
if (-not $accessToken) {
    throw 'Keycloak did not return an access token.'
}

$authorization = "Authorization: Bearer $accessToken"
$usersJson = & curl.exe --fail --silent --show-error `
    "$baseUrl/api/v1/users" --header $authorization
if ($LASTEXITCODE -ne 0) {
    throw 'Authenticated Core user-list request failed.'
}

$rolesJson = & curl.exe --fail --silent --show-error `
    "$baseUrl/api/v1/roles" --header $authorization
if ($LASTEXITCODE -ne 0) {
    throw 'Authenticated Core role-list request failed.'
}

$users = ConvertFrom-Json -InputObject $usersJson
$roles = ConvertFrom-Json -InputObject $rolesJson
$admin = $users | Where-Object { $_.username -eq $credentials['ILM_ADMIN_USERNAME'] }
$roleNames = @($roles | ForEach-Object { $_.name })

if (-not $admin) {
    throw "Core did not return the expected user '$($credentials['ILM_ADMIN_USERNAME'])'."
}
if ($roleNames -notcontains 'superadmin') {
    throw 'Core did not return the expected superadmin role.'
}

Write-Output 'PASS: Keycloak issued an access token.'
Write-Output "PASS: Core returned $($users.Count) user(s), including the ILM administrator."
Write-Output "PASS: Core returned $($roles.Count) role(s), including superadmin."

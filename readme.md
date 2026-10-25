# Test-Ilm

This repository collects the ILM source projects and local development setup.

## Test project environment

Load the environment file for your shell from the repository root. It sets
`TESTILM_ROOT` to the repository directory without relying on a machine-specific
path:

```cmd
call .\env.cmd
```

```powershell
. .\env.ps1
```

```bash
source ./env.sh
```

The environment files contain no credentials. The local stack keeps generated
development credentials in `test-ilm/.env`, which is ignored by Git.

For test details, see [test-ilm/README.md](./test-ilm/README.md).

## Test project output folder

Test folder is located in `.\test-ilm`, under which, there can be found details
about test output - `.\test-ilm\output\test.md`
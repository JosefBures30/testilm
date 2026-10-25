# TestIlm

This repository collects the ILM source projects and local development setup.

## Project environment

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
development credentials in `local-stack/.env`, which is ignored by Git.

For local stack instructions, see [local-stack/README.md](./local-stack/README.md).

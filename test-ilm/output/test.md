Test description:
-----------------

1. Checkout, Assemble And Deploy ILM platform (local docker)
2. Make small change in sources.
3. Test those changes.
4. Deploy changed binaries for ILM.
5. Hand over result over git.

ad 1.
`test-ilm/` contains the local Docker Compose configuration and helper scripts.
`test-ilm/compose.yaml` starts the platform services locally.
`test-ilm/output/deploy.txt` records the local Docker startup and container status.

ad 2.
`core/`, `fe-administrator/`, `interfaces/`, and `helm-charts/` contain the
project source files and local changes.

ad 3.
`test-ilm/smoke-test.ps1` runs the read-only API smoke test.
`test-ilm/output/test.md` describes this test project.
`test-ilm/output/*.png` contains screenshots.
`test-ilm/output/deploy.txt` contains Docker command output for reference.

ad 4.
From `test-ilm/`, start the stack with
`docker compose --env-file .env -f compose.yaml up -d`.

ad 5.
All source projects and local setup are kept in this `testilm` repository.
The nested upstream Git metadata was removed intentionally; changes are
committed to this repository.

import json
import os
import re
import secrets
from pathlib import Path


HERE = Path(__file__).resolve().parent
ROOT = Path(os.environ.get("TESTILM_ROOT", HERE.parent)).resolve()
GENERATED = HERE / "generated"
HELM = ROOT / "helm-charts" / "charts"
ENV_FILE = HERE / ".env"


def read_env():
    if not ENV_FILE.exists():
        values = {
            "POSTGRES_USER": "ilmuser",
            "POSTGRES_PASSWORD": secrets.token_urlsafe(32),
            "POSTGRES_DB": "ilmdb",
            "RABBITMQ_ADMIN_USERNAME": "ilmadmin",
            "RABBITMQ_ADMIN_PASSWORD": secrets.token_urlsafe(32),
            "RABBITMQ_PROVISIONER_USERNAME": "ilm-provisioner",
            "RABBITMQ_PROVISIONER_PASSWORD": secrets.token_urlsafe(32),
            "RABBITMQ_PROXY_USERNAME": "ilm-proxy",
            "RABBITMQ_PROXY_PASSWORD": secrets.token_urlsafe(32),
            "RABBITMQ_CORE_USERNAME": "ilm-core",
            "RABBITMQ_CORE_PASSWORD": secrets.token_urlsafe(32),
            "RABBITMQ_TQM_USERNAME": "ilm-tqm",
            "RABBITMQ_TQM_PASSWORD": secrets.token_urlsafe(32),
            "KEYCLOAK_ADMIN_USERNAME": "kcadmin",
            "KEYCLOAK_ADMIN_PASSWORD": secrets.token_urlsafe(32),
            "ILM_ADMIN_USERNAME": "ilm-admin",
            "ILM_ADMIN_PASSWORD": secrets.token_urlsafe(32),
            "ILM_ADMIN_FIRST_NAME": "ILM",
            "ILM_ADMIN_LAST_NAME": "Administrator",
            "ILM_ADMIN_EMAIL": "admin@localhost",
            "OIDC_CLIENT_SECRET": secrets.token_urlsafe(32),
        }
        ENV_FILE.write_text(
            "# Local development credentials. Do not commit this file.\n"
            + "".join(f"{key}={value}\n" for key, value in values.items()),
            encoding="utf-8",
        )
        return values

    values = {}
    for line in ENV_FILE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            key, separator, value = line.partition("=")
            if not separator:
                raise ValueError(f"Invalid .env line: {line!r}")
            values[key] = value

    required = {
        "POSTGRES_USER",
        "POSTGRES_PASSWORD",
        "POSTGRES_DB",
        "RABBITMQ_ADMIN_USERNAME",
        "RABBITMQ_ADMIN_PASSWORD",
        "RABBITMQ_PROVISIONER_USERNAME",
        "RABBITMQ_PROVISIONER_PASSWORD",
        "RABBITMQ_PROXY_USERNAME",
        "RABBITMQ_PROXY_PASSWORD",
        "RABBITMQ_CORE_USERNAME",
        "RABBITMQ_CORE_PASSWORD",
        "RABBITMQ_TQM_USERNAME",
        "RABBITMQ_TQM_PASSWORD",
        "KEYCLOAK_ADMIN_USERNAME",
        "KEYCLOAK_ADMIN_PASSWORD",
        "ILM_ADMIN_USERNAME",
        "ILM_ADMIN_PASSWORD",
        "ILM_ADMIN_FIRST_NAME",
        "ILM_ADMIN_LAST_NAME",
        "ILM_ADMIN_EMAIL",
        "OIDC_CLIENT_SECRET",
    }
    missing = sorted(required - values.keys())
    if missing:
        raise ValueError(f"Missing keys in .env: {', '.join(missing)}")
    return values


def replace_once(text, pattern, replacement, label):
    updated, count = re.subn(pattern, lambda _: replacement, text, count=1, flags=re.MULTILINE)
    if count != 1:
        raise ValueError(f"Could not render exactly one {label} placeholder (found {count})")
    return updated


def render_realm(env):
    source = (HELM / "keycloak-internal" / "realms" / "ilm-2.18.0_realm.json").read_text(encoding="utf-8")
    source = source[source.index("\n{\n") + 1:]
    values = {
        "username": env["ILM_ADMIN_USERNAME"],
        "firstName": env["ILM_ADMIN_FIRST_NAME"],
        "lastName": env["ILM_ADMIN_LAST_NAME"],
        "email": env["ILM_ADMIN_EMAIL"],
    }
    for field, value in values.items():
        source = replace_once(
            source,
            rf'"{field}": \{{\{{ required .*?\}}\}}',
            f'"{field}": {json.dumps(value)}',
            f"Keycloak {field}",
        )
    source = replace_once(
        source,
        r'"value": \{\{ required "Password must be provided: .*?\}\}',
        f'"value": {json.dumps(env["ILM_ADMIN_PASSWORD"])}',
        "Keycloak admin password",
    )
    source = replace_once(
        source,
        r'"rootUrl": "https://\{\{ required "Hostname must be provided: .*?\}\}"',
        '"rootUrl": "http://localhost:8000"',
        "Keycloak ILM client root URL",
    )
    source = replace_once(
        source,
        r'"secret": \{\{ required "Client secret must be provided: .*?\}\},',
        f'"secret": {json.dumps(env["OIDC_CLIENT_SECRET"])},',
        "Keycloak client secret",
    )
    source = replace_once(
        source,
        r'^\s*\{\{ \.Values\.ilm\.redirectUri\.login .*?\}\}$',
        '        "http://localhost:8000/api/login/oauth2/code/internal"',
        "Keycloak login redirect",
    )
    source = replace_once(
        source,
        r'"post\.logout\.redirect\.uris": \{\{ \.Values\.ilm\.redirectUri\.postLogout .*?\}\},',
        '"post.logout.redirect.uris": "http://localhost:8000/administrator/",',
        "Keycloak logout redirect",
    )
    if "{{" in source:
        raise ValueError("Unrendered Helm template expression remains in Keycloak realm")
    try:
        json.loads(source)
    except json.JSONDecodeError as error:
        lines = source.splitlines()
        excerpt = "\n".join(lines[max(0, error.lineno - 3):error.lineno + 2])
        raise ValueError(f"Invalid rendered Keycloak realm at line {error.lineno}:\n{excerpt}") from error
    (GENERATED / "ilm-realm.json").write_text(source, encoding="utf-8")


def render_rabbitmq(env):
    template = (HELM / "messaging-rabbitmq" / "templates" / "_definitions_json.tpl").read_text(encoding="utf-8")
    source = template[template.index("\n{\n") + 1:template.rfind("\n{{- end }}")]
    placeholders = {
        "$username": env["RABBITMQ_ADMIN_USERNAME"],
        "$password": env["RABBITMQ_ADMIN_PASSWORD"],
        "$provisionerUsername": env["RABBITMQ_PROVISIONER_USERNAME"],
        "$provisionerPassword": env["RABBITMQ_PROVISIONER_PASSWORD"],
        "$proxyUsername": env["RABBITMQ_PROXY_USERNAME"],
        "$proxyPassword": env["RABBITMQ_PROXY_PASSWORD"],
        "$coreUsername": env["RABBITMQ_CORE_USERNAME"],
        "$corePassword": env["RABBITMQ_CORE_PASSWORD"],
        "$timeQualityMonitorUsername": env["RABBITMQ_TQM_USERNAME"],
        "$timeQualityMonitorPassword": env["RABBITMQ_TQM_PASSWORD"],
        "$virtualHost": "/",
    }
    for key, value in placeholders.items():
        source = source.replace("{{ " + key + " }}", value)
    if "{{" in source:
        raise ValueError("Unrendered Helm template expression remains in RabbitMQ definitions")
    json.loads(source)
    (GENERATED / "rabbitmq-definitions.json").write_text(source, encoding="utf-8")


def main():
    env = read_env()
    GENERATED.mkdir(exist_ok=True)
    render_realm(env)
    render_rabbitmq(env)
    for path in (HERE / "register-oidc.sh", HERE / "rabbitmq-enabled-plugins"):
        path.write_bytes(path.read_bytes().replace(bytes([13, 10]), bytes([10])))
    print("Generated local realm and RabbitMQ definitions.")
    print(f"Development login credentials are stored in: {ENV_FILE}")


if __name__ == "__main__":
    main()

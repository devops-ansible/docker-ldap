# Documentation

This directory holds further documentation on how the repository and also GitHub workflow is configured.

## Secret `LEGO_TEST_CONFIG`

This secret is used to configure the test case for LEGO certificate challenges. It is a base64 encoded JSON string with this basic strucutre:

```json
{
    "LEGO_ACCOUNT_EMAIL": "mail@example.com",
    "LEGO_CERT_DOMAIN": "*.auth-test.example.com",
    "LEGO_DNS_PROVIDER": "..."
}
```

There have to be additional environmental variables within the JSON object according to the used DNS provider (e.g. `cloudflare`, `route53`, `inwx`, ... ). Those have to be also part of this JSON string.

The JSON is passed as base64 encoded value – for that, one could use this `bash` command to generate the value:

```sh
cat <<EOF | base64 -w 0
{
    "LEGO_ACCOUNT_EMAIL": "..."
}
EOF
```

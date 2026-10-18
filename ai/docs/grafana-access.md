# Give Codex read-only Grafana access

Use the official Grafana MCP server on the same machine as Codex. It connects to
your Grafana over your local network, so Grafana does not need to be public. Plugin
discovery did not find a Grafana connector in this session; more integrations may
be available in the [plugin directory](https://chatgpt.com/plugins).

1. In Grafana, create a dedicated service account with the **Viewer** role and a
   token with an expiry. Keep the ClickHouse datasource on its existing read-only
   `grafana_reader` credentials. A Grafana Viewer token is not a replacement for
   database read-only grants.
2. Install the official [Grafana MCP server](https://grafana.com/docs/grafana/latest/developer-resources/mcp/clients/codex/)
   binary for your platform. Set `GRAFANA_URL` to your Grafana base URL (for the
   current host, typically `http://docker01.voidmoose.local:3000`) and set
   `GRAFANA_SERVICE_ACCOUNT_TOKEN` privately in the environment that starts Codex.
   Do not paste the token into chat, commit it, or put it in the game's configuration.
3. Add the following to your user-level `~/.codex/config.toml`, replacing the binary
   path with its actual installation location:

```toml
[mcp_servers.grafana]
command = "C:/Tools/mcp-grafana.exe"
args = ["--disable-write", "--enable-query", "--enabled-tools", "search,datasource,dashboard,sql,runpanelquery"]
env_vars = ["GRAFANA_URL", "GRAFANA_SERVICE_ACCOUNT_TOKEN"]
```

4. Restart the Codex extension/app so it inherits the environment and loads the new
   server. Ask Codex to list Grafana dashboards and inspect the `telemetry-clickhouse`
   datasource, then query QA/bot events for the current build.

`--disable-write` prevents Grafana edits. `--enable-query` allows SQL and panel
queries with the datasource's read-only database account. The selected categories
expose dashboard search, datasource discovery and the queries needed for ClickHouse.
Use a current server release that supports these flags. Authentication uses the
service account token, not your Grafana administrator password.

References: [Grafana authentication](https://grafana.com/docs/grafana/latest/developer-resources/mcp/configure/authentication/),
[Grafana read-only/query controls](https://grafana.com/docs/grafana/latest/developer-resources/mcp/configure/enable-and-disable-tools/),
and [Codex MCP configuration](https://developers.openai.com/codex/mcp).

This guide prepares access; no MCP server, token or live Grafana connection was
installed or verified by the repository changes.

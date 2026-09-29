# noctalia plugins

A single Noctalia plugin source.

## Install

1. Noctalia → Settings → Plugins → Sources → add `https://github.com/zumik3-del/noctalia_plugins`
2. Refresh, then install **Opencode Go Usage**.

## Opencode Go Usage

Shows how much of your Opencode Go (Zen) subscription you have used. A bar capsule
reports one limit at a glance, and a details panel breaks the 5-hour, weekly and
monthly meters down with progress bars, reset countdowns and daily headroom.

Usage is read from `https://opencode.ai/console/api/go/status` — the meters are
`access.meters.fiveHour` / `.week` / `.month` (`usedMicroCents` /
`limitMicroCents`), with reset times from `resetsAt` (the monthly limit uses
`access.endsAt`). This JSON API may break if opencode.ai changes it.

You need an Opencode Go (Zen) account and its API key (`oc_sk_...`), pasted into
**Settings → Plugins → Opencode Go Usage → API key**. The key is sent to opencode.ai
as a `Bearer` token in the `Authorization` header.

The plugin spawns no processes and writes no files: it uses Noctalia's built-in HTTP
client, so there are no external dependencies to install.

See [`opencode-go-usage/README.md`](opencode-go-usage/README.md) for the full
documentation, settings and entry ids.

---
type: Reference
title: Dev environment hosts
description: Hosts the cloud dev environment must allow to check the published repository.
tags: [dev-environment, network]
generated: { by: claude-code/2.1.310, at: 2026-10-25T13:00:00Z }
---

# Hosts

Found blocked by the cloud environment's proxy on 2026-10-25 (`curl` →
`CONNECT tunnel failed, response 403`):

- `flatpak.nexumia.de`: the published repository (index, `.flatpakrepo`,
  ostree `repo/`), to check a deploy end to end.
- `suitably.github.io`: the Pages default address, to check that it
  redirects to the custom domain.

After `flatpak.nexumia.de` was allowed (2026-10-25, ~09:50 UTC) the
proxy answered `502` (allowed, but the host could not be reached), and
the last deploy reported its environment URL as `http://flatpak.nexumia.de/`
(Pages had the custom domain but no HTTPS yet). Check the DNS record and
the Pages settings first; see the README setup steps.

On 2026-10-25 ~11:30 UTC, after the `flatpak` CNAME was added in
Cloudflare (the zone that actually serves nexumia.de; the record in
Infomaniak's zone editor had no effect), `flatpak.nexumia.de` reached
GitHub Pages but still presented the `*.github.io` certificate until
GitHub issued the custom-domain certificate.

Building the site (`scripts/build-site.sh`) only needs GitHub release
downloads, which work through `gh`.

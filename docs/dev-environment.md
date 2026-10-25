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

Building the site (`scripts/build-site.sh`) only needs GitHub release
downloads, which work through `gh`.

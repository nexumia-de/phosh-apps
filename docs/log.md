# Directory Update Log

## 2026-10-25
* **Update**: `apps.txt` lists `suitably/cirro`, where the Wetterblick code moved.
* **Creation**: [Dev environment hosts](dev-environment.md): `flatpak.nexumia.de` and `suitably.github.io` are blocked in the cloud environment.
* **Update**: Repository served at the custom domain `https://flatpak.nexumia.de/`, remote and file renamed to `nexumia` / `nexumia.flatpakrepo` (see the toolkit decision [domain-based names](../../phosh-toolkit/docs/decisions/domain-names.md)). README lists the DNS and Pages custom-domain setup; the `flatpak` record must be plain DNS (not a reverse-proxy route such as Pangolin) and overrides a wildcard.

## 2026-10-24
* **Initialization**: Created the repository: `apps.txt`, `scripts/build-site.sh` (imports the bundles, signs, writes `.flatpakrepo`, one `.flatpakref` per app and an index page) and the Pages publish workflow. Verified locally with a Wetterblick x86_64 bundle: signed install over HTTP, AppStream data with icons, `.flatpakref` install, no update for an unchanged re-import.

# Directory Update Log

## 2026-10-25
* **Update**: `apps.txt` lists `nexumia-de/cirro` (the current owner; `suitably/cirro` only worked through GitHub's redirect); README links and commands name `nexumia-de`. The actions in `publish.yml` are pinned to commit SHAs with the version as comment (toolkit [dependency updates](../../phosh-toolkit/docs/dependency-updates.md)).
* **Update**: The site's index page links the support page on Liberapay, and `.github/FUNDING.yml` lists it (toolkit [support for development](../../phosh-toolkit/docs/support.md)).
* **Update**: `build-site.sh` publishes two channels per app (toolkit decision [release channels from main and tags](../../phosh-toolkit/docs/decisions/release-channels.md)): the stable app from the newest non-pre-release release (a tag `v<version>`; none fails the run) and, if present, the nightly app `<app id>.Devel` from the pre-release `nightly`. The rolling release `latest` is no longer read. README and `AGENTS.md` updated.
* **Update**: README and [dev environment](dev-environment.md): nexumia.de DNS is served by Cloudflare, Infomaniak is only the registrar; the `flatpak` CNAME belongs in Cloudflare (DNS only). With it, the host reaches GitHub Pages; HTTPS waits for GitHub's certificate.
* **Update**: Dependabot keeps the GitHub Actions in `publish.yml` current. The apps' CI now also releases source bundles (`<bundle>-sources-<arch>.flatpak`), which `build-site.sh` imports like the app bundles, so the repository serves `runtime/<app id>.Sources` (see the toolkit's [licensing](../../phosh-toolkit/docs/licensing.md)). [Dev environment](dev-environment.md): `flatpak.nexumia.de` answered `502` after being allowed; the deploy URL was still `http://`.
* **Update**: `apps.txt` lists `suitably/cirro`, where the Wetterblick code moved.
* **Creation**: [Dev environment hosts](dev-environment.md): `flatpak.nexumia.de` and `suitably.github.io` are blocked in the cloud environment.
* **Update**: Repository served at the custom domain `https://flatpak.nexumia.de/`, remote and file renamed to `nexumia` / `nexumia.flatpakrepo` (see the toolkit decision [domain-based names](../../phosh-toolkit/docs/decisions/domain-names.md)). README lists the DNS and Pages custom-domain setup; the `flatpak` record must be plain DNS (not a reverse-proxy route such as Pangolin) and overrides a wildcard.

## 2026-10-24
* **Initialization**: Created the repository: `apps.txt`, `scripts/build-site.sh` (imports the bundles, signs, writes `.flatpakrepo`, one `.flatpakref` per app and an index page) and the Pages publish workflow. Verified locally with a Wetterblick x86_64 bundle: signed install over HTTP, AppStream data with icons, `.flatpakref` install, no update for an unchanged re-import.

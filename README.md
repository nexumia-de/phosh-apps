# phosh-apps

One Flatpak repository with all suitably Phosh apps, served from GitHub
Pages under the custom domain <https://flatpak.nexumia.de/>. Each app keeps its own
repository; this one only collects their builds.

## Install on the phone

Open <https://flatpak.nexumia.de/> on the phone and tap an
app: GNOME Software installs it and adds the repository. Or once, in a
terminal:

```sh
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --user --if-not-exists nexumia https://flatpak.nexumia.de/nexumia.flatpakrepo
```

After that every app shows up in GNOME Software and updates arrive there.

## How it works

1. An app repository builds with the
   [phosh-toolkit Flatpak workflow](https://github.com/nexumia-de/phosh-toolkit/blob/main/docs/flatpak-workflow.md)
   and `release: true` (plus `nightly: true`): a tag `v<version>`
   attaches the x86_64 and aarch64 bundles to its GitHub Release (the
   stable app), every push to `main` replaces those of the pre-release
   `nightly` (the app `<app id>.Devel`, e.g. "Cirro (Nightly)"). See
   [release channels](https://github.com/nexumia-de/phosh-toolkit/blob/main/docs/flatpak-workflow.md#release-channels).
2. `.github/workflows/publish.yml` downloads, for every repository in
   [apps.txt](apps.txt), the bundles of its newest non-pre-release
   release and, if present, of `nightly` (or, for a line
   `owner/repo <tag>`, of release `<tag>`: the ATL engine), imports them into a signed
   repository (`scripts/build-site.sh`) and deploys it to Pages. It runs
   when an app notifies it, daily at 04:17 UTC, on pushes here and by
   hand.

Details: [phosh-toolkit/docs/app-repository.md](https://github.com/nexumia-de/phosh-toolkit/blob/main/docs/app-repository.md).

## One-time setup

1. **Pages**: Settings → Pages → Source: *GitHub Actions*; Custom
   domain: `flatpak.nexumia.de`, then *Enforce HTTPS*. DNS for
   nexumia.de is served by **Cloudflare** (Infomaniak is only the
   registrar and shows "external DNS zone"; records in its zone editor
   are ignored). In Cloudflare: `flatpak  CNAME  <owner>.github.io.`
   (the owner of this repository), proxy status **DNS only**. This is a plain DNS record, not a reverse-proxy
   route (e.g. Pangolin): GitHub must see its own IP to issue the HTTPS
   certificate. A specific `flatpak` record wins over a wildcard
   `*.nexumia.de` that points to a proxy. Also verify `nexumia.de` in the account or
   organization settings (Pages → Add a domain, a DNS TXT record) so no
   other GitHub account can claim the subdomain.
   The workflow takes the site URL from Pages, so the published remote
   files use the custom domain once it is set.
2. **Signing key** (on your own machine, needs `gpg` and `gh`):

   ```sh
   export GNUPGHOME=$(mktemp -d)
   gpg --batch --passphrase '' --quick-gen-key 'nexumia Phosh apps' ed25519 sign never
   gpg --armor --export-secret-keys | gh secret set FLATPAK_GPG_KEY --repo nexumia-de/phosh-apps
   gpg --armor --export-secret-keys > phosh-apps-signing-key.asc   # back it up safely
   ```

   Keep the backup: with a new key, every phone has to remove and re-add
   the repository.
3. **Optional, instant publishing**: create a fine-grained token with
   *Contents: read and write* on `nexumia-de/phosh-apps` and store it as
   secret `PUBLISH_TOKEN` in each app repository. Without it, new builds
   appear after the daily run (or start *Publish* by hand).
4. **Branch protection**: Settings → Rules → Rulesets → *Import a
   ruleset* with [.github/rulesets/main.json](.github/rulesets/main.json)
   (no required checks: no workflow runs on pull requests). See the
   toolkit's [branch protection](https://github.com/nexumia-de/phosh-toolkit/blob/main/docs/branch-protection.md).

## Add an app

1. In the app repository's Flatpak workflow, pass `release: true` and
   `publish-repo: nexumia-de/phosh-apps` and give the job
   `permissions: { contents: write }` (see the toolkit docs).
2. Push its first tag `v<version>`, then add `owner/repo` to
   [apps.txt](apps.txt); a listed app without a stable release fails
   the publish run.

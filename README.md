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
   [phosh-toolkit Flatpak workflow](https://github.com/suitably/phosh-toolkit/blob/main/docs/flatpak-workflow.md)
   and `release: true`; every push to `main` attaches the x86_64 and
   aarch64 bundles to its rolling release `latest`.
2. `.github/workflows/publish.yml` downloads the bundles of every
   repository in [apps.txt](apps.txt), imports them into a signed
   repository (`scripts/build-site.sh`) and deploys it to Pages. It runs
   when an app notifies it, daily at 04:17 UTC, on pushes here and by
   hand.

Details: [phosh-toolkit/docs/app-repository.md](https://github.com/suitably/phosh-toolkit/blob/main/docs/app-repository.md).

## One-time setup

1. **Pages**: Settings → Pages → Source: *GitHub Actions*; Custom
   domain: `flatpak.nexumia.de`, then *Enforce HTTPS*. DNS at the
   nexumia.de provider: `flatpak  CNAME  <owner>.github.io.` (the owner of
   this repository). Also verify `nexumia.de` in the account or
   organization settings (Pages → Add a domain, a DNS TXT record) so no
   other GitHub account can claim the subdomain.
   The workflow takes the site URL from Pages, so the published remote
   files use the custom domain once it is set.
2. **Signing key** (on your own machine, needs `gpg` and `gh`):

   ```sh
   export GNUPGHOME=$(mktemp -d)
   gpg --batch --passphrase '' --quick-gen-key 'nexumia Phosh apps' ed25519 sign never
   gpg --armor --export-secret-keys | gh secret set FLATPAK_GPG_KEY --repo suitably/phosh-apps
   gpg --armor --export-secret-keys > phosh-apps-signing-key.asc   # back it up safely
   ```

   Keep the backup: with a new key, every phone has to remove and re-add
   the repository.
3. **Optional, instant publishing**: create a fine-grained token with
   *Contents: read and write* on `suitably/phosh-apps` and store it as
   secret `PUBLISH_TOKEN` in each app repository. Without it, new builds
   appear after the daily run (or start *Publish* by hand).

## Add an app

1. In the app repository's Flatpak workflow, pass `release: true` and
   `publish-repo: suitably/phosh-apps` and give the job
   `permissions: { contents: write }` (see the toolkit docs).
2. Add `owner/repo` to [apps.txt](apps.txt).

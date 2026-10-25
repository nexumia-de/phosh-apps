@../phosh-toolkit/AGENTS.md

# phosh-apps

Publishes all suitably Phosh apps as one signed Flatpak repository on
GitHub Pages. No app code lives here: each app builds in its own
repository and attaches its bundles to GitHub Releases: a tag
`v<version>` for the stable app, the pre-release `nightly` for
`<app id>.Devel`.
The shared rules in ../phosh-toolkit/AGENTS.md apply as well.

- Add or remove an app by editing `apps.txt` only.
- Never commit the signing key; it lives in the secret `FLATPAK_GPG_KEY`.
- How the pieces fit together:
  [../phosh-toolkit/docs/app-repository.md](../phosh-toolkit/docs/app-repository.md).

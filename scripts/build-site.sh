#!/usr/bin/env bash
# Builds the static Flatpak repository site from the latest bundles of every
# app in apps.txt.
#
#   SITE_URL=https://flatpak.nexumia.de GPG_KEY_ID=<fingerprint> \
#     scripts/build-site.sh [bundle-dir] [out-dir]
#
# Without a bundle-dir argument the bundles are downloaded with gh from each
# app: the stable app from its newest tagged release (GitHub's "latest
# release", never a pre-release) and, if present, the nightly app
# <app id>.Devel from the pre-release "nightly". GNUPGHOME must hold the
# secret signing key.
set -euo pipefail

: "${SITE_URL:?set SITE_URL}" "${GPG_KEY_ID:?set GPG_KEY_ID}"
SITE_URL=${SITE_URL%/}
REMOTE=nexumia
TITLE="nexumia Phosh apps"
FLATHUB=https://dl.flathub.org/repo/flathub.flatpakrepo
# Voluntary support (phosh-toolkit docs/support.md).
SUPPORT_URL=https://liberapay.com/suitably

root=$(cd "$(dirname "$0")/.." && pwd)
bundles=${1:-}
out=${2:-$root/_site}

if [[ -z $bundles ]]; then
  bundles=$(mktemp -d)
  grep -Ev '^\s*(#|$)' "$root/apps.txt" | while read -r app; do
    dir=$bundles/${app//\//_}
    # A listed app without a stable release fails the run instead of
    # silently disappearing from the repository.
    gh release download --repo "$app" --pattern '*.flatpak' --dir "$dir/stable" ||
      { echo "$app has no stable release (a tag v<version>)" >&2; exit 1; }
    if gh release view nightly --repo "$app" >/dev/null 2>&1; then
      gh release download nightly --repo "$app" --pattern '*.flatpak' --dir "$dir/nightly"
    fi
  done
fi

rm -rf "$out"
mkdir -p "$out"
ostree init --mode=archive --repo="$out/repo"
sign=(--gpg-sign="$GPG_KEY_ID")
[[ -n ${GNUPGHOME:-} ]] && sign+=(--gpg-homedir="$GNUPGHOME")

shopt -s nullglob globstar
files=("$bundles"/**/*.flatpak)
(( ${#files[@]} )) || { echo "no bundles found in $bundles" >&2; exit 1; }
for f in "${files[@]}"; do
  echo "Importing $f"
  # Keeps the bundle's commit id, so re-publishing an unchanged app does
  # not show up as an update on the phone.
  flatpak build-import-bundle "${sign[@]}" "$out/repo" "$f"
done
flatpak build-update-repo "${sign[@]}" --title="$TITLE" \
  --default-branch=master --prune "$out/repo"

gpgkey=$(gpg --export "$GPG_KEY_ID" | base64 -w0)
cat > "$out/$REMOTE.flatpakrepo" <<EOR
[Flatpak Repo]
Title=$TITLE
Url=$SITE_URL/repo/
Homepage=$SITE_URL/
Comment=Phosh apps from nexumia.de
GPGKey=$gpgkey
EOR

# One .flatpakref per app (opening it in GNOME Software installs the app
# and adds the remote) and an index page.
apps=$(ostree refs --repo="$out/repo" | sed -n 's|^app/\([^/]*\)/.*|\1|p' | sort -u)
rows=""
for id in $apps; do
  ref=$(ostree refs --repo="$out/repo" | grep -m1 "^app/$id/")
  meta=$(ostree cat --repo="$out/repo" "$ref" "/files/share/metainfo/$id.metainfo.xml")
  IFS=$'\x1f' read -r name summary <<<"$(python3 -c '
import html, sys, xml.etree.ElementTree as ET
r = ET.fromstring(sys.stdin.read())
print(html.escape(r.findtext("name")) + "\x1f" + html.escape(r.findtext("summary")))' <<<"$meta")"
  arches=$(ostree refs --repo="$out/repo" | sed -n "s|^app/$id/\([^/]*\)/.*|\1|p" | paste -sd ' ')
  cat > "$out/$id.flatpakref" <<EOR
[Flatpak Ref]
Name=$id
Branch=master
Title=$name
Url=$SITE_URL/repo/
Homepage=$SITE_URL/
IsRuntime=false
SuggestRemoteName=$REMOTE
RuntimeRepo=$FLATHUB
GPGKey=$gpgkey
EOR
  rows+="<li><a href=\"$id.flatpakref\"><b>$name</b></a> – $summary <small>($id, $arches)</small></li>"
done

cat > "$out/index.html" <<EOR
<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$TITLE</title>
<style>body{font-family:sans-serif;max-width:40rem;margin:1rem auto;padding:0 1rem;line-height:1.5}
code,pre{background:#eee;padding:.1rem .3rem;overflow-x:auto}pre{padding:.5rem}</style>
</head><body>
<h1>$TITLE</h1>
<p>Tap an app to install it with GNOME Software, or add the whole
repository once with <a href="$REMOTE.flatpakrepo">$REMOTE.flatpakrepo</a>.
Apps use the GNOME runtime from Flathub.</p>
<ul>$rows</ul>
<pre>flatpak remote-add --user --if-not-exists flathub $FLATHUB
flatpak remote-add --user --if-not-exists $REMOTE $SITE_URL/$REMOTE.flatpakrepo</pre>
<p>The apps are free for everyone. If you want to support their
development, you can do so on <a href="$SUPPORT_URL">Liberapay</a>.</p>
</body></html>
EOR
echo "Site in $out"

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
# <app id>.Devel from the pre-release "nightly". A line "owner/repo <tag>"
# in apps.txt takes the bundles of that release instead (the ATL engine,
# a base app for app Flatpaks generated on the phone). A line
# "owner/repo <prefix>v*" is one app of a repository with several (domus):
# the stable app from the newest release whose tag matches, the nightly app
# from the pre-release "<prefix>nightly". The run fails if a
# stable release lacks the stable app (not only .Devel or the sources) for
# an architecture in STABLE_ARCHES. GNUPGHOME must hold the secret signing
# key.
set -euo pipefail

: "${SITE_URL:?set SITE_URL}" "${GPG_KEY_ID:?set GPG_KEY_ID}"
SITE_URL=${SITE_URL%/}
REMOTE=nexumia
TITLE="nexumia Phosh apps"
FLATHUB=https://dl.flathub.org/repo/flathub.flatpakrepo
# Voluntary support (phosh-toolkit docs/support.md).
SUPPORT_URL=https://liberapay.com/suitably
# Architectures every stable app must be published for.
STABLE_ARCHES=${STABLE_ARCHES:-x86_64 aarch64}

root=$(cd "$(dirname "$0")/.." && pwd)
bundles=${1:-}
out=${2:-$root/_site}

if [[ -z $bundles ]]; then
  bundles=$(mktemp -d)
  grep -Ev '^\s*(#|$)' "$root/apps.txt" | while read -r app tag; do
    dir=$bundles/${app//\//_}
    if [[ $tag == *'*'* ]]; then
      prefix=${tag%v\*}
      [[ $tag == "${prefix}v*" && -n $prefix ]] ||
        { echo "$app: a tag pattern must be <prefix>v*, got $tag" >&2; exit 1; }
      dir+=_${prefix%-}
      stable=$(gh release list --repo "$app" --exclude-drafts --exclude-pre-releases \
        --limit 100 --json tagName,publishedAt \
        --jq 'sort_by(.publishedAt) | reverse | .[].tagName' |
        while read -r t; do [[ $t == $tag ]] && { echo "$t"; break; }; done || true)
      [[ -n $stable ]] || { echo "$app has no stable release $tag" >&2; exit 1; }
      gh release download "$stable" --repo "$app" --pattern '*.flatpak' --dir "$dir/stable"
      if gh release view "${prefix}nightly" --repo "$app" >/dev/null 2>&1; then
        gh release download "${prefix}nightly" --repo "$app" --pattern '*.flatpak' --dir "$dir/nightly"
      fi
      continue
    fi
    if [[ -n $tag ]]; then
      gh release download "$tag" --repo "$app" --pattern '*.flatpak' --dir "$dir/$tag" ||
        { echo "$app has no release $tag" >&2; exit 1; }
      continue
    fi
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
declare -A added # bundle directory -> the refs its bundles added
for f in "${files[@]}"; do
  echo "Importing $f"
  before=$(ostree refs --repo="$out/repo" | sort)
  # Keeps the bundle's commit id, so re-publishing an unchanged app does
  # not show up as an update on the phone.
  flatpak build-import-bundle "${sign[@]}" "$out/repo" "$f"
  added[$(dirname "$f")]+=$(comm -13 <(echo "$before") <(ostree refs --repo="$out/repo" | sort))$'\n'
done

# Every downloaded app must bring its stable app, not only .Devel or the
# sources: the stable release on every architecture in STABLE_ARCHES, a
# release <tag> on at least one.
if [[ -z ${1:-} ]]; then
  missing=()
  for dir in "$bundles"/*/*/; do
    dir=${dir%/} channel=${dir##*/} app=${dir%/*}
    app=${app##*/} app=${app/_//}
    [[ $channel == nightly ]] && continue
    refs=$(grep -E '^app/[^/]+/' <<<"${added[$dir]:-}" | grep -Ev '^app/[^/]+\.Devel/' || true)
    if [[ $channel == stable ]]; then
      for arch in $STABLE_ARCHES; do
        grep -q "^app/[^/]*/$arch/" <<<"$refs" || missing+=("$app: no stable app for $arch")
      done
    elif [[ -z $refs ]]; then
      missing+=("$app: no app in release $channel")
    fi
  done
  if (( ${#missing[@]} )); then
    printf '::error::%s\n' "${missing[@]}" >&2
    exit 1
  fi
fi
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
  # Base apps without metainfo (the ATL engine) are installed by id, not
  # from the page or GNOME Software.
  meta=$(ostree cat --repo="$out/repo" "$ref" "/files/share/metainfo/$id.metainfo.xml" 2>/dev/null) ||
    { echo "$id has no metainfo; not listed on the page"; continue; }
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

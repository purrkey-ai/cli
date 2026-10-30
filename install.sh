#!/usr/bin/env bash
set -euo pipefail

version="0.3.0"
base="https://github.com/purrkey-ai/cli/releases/download/v$version"
case "$(uname -s)" in
  Darwin) os=darwin ;;
  Linux) os=linux ;;
  *) printf 'Use install.ps1 on Windows. Supported Unix systems: macOS and Linux.\n' >&2; exit 1 ;;
esac
case "$(uname -m)" in
  arm64|aarch64) arch=arm64 ;;
  amd64|x86_64) arch=amd64 ;;
  *) printf 'Unsupported CPU architecture.\n' >&2; exit 1 ;;
esac

archive="agenttoolx-$version-$os-$arch.tar.gz"
stage="$(mktemp -d)"
pending=""
trap 'rm -rf "$stage"; if [ -n "$pending" ]; then rm -f "$pending"; fi' EXIT
curl --proto '=https' --tlsv1.2 -fsSL --retry 2 --connect-timeout 10 --max-time 120 "$base/$archive" -o "$stage/$archive"
curl --proto '=https' --tlsv1.2 -fsSL --retry 2 --connect-timeout 10 --max-time 120 "$base/SHA256SUMS" -o "$stage/SHA256SUMS"
awk -v name="$archive" '$2 == name { print }' "$stage/SHA256SUMS" > "$stage/selected.sha256"
if [ "$(wc -l < "$stage/selected.sha256" | tr -d ' ')" != 1 ]; then
  printf 'Release must contain exactly one checksum for %s.\n' "$archive" >&2
  exit 1
fi
(
  cd "$stage"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c selected.sha256
  else
    shasum -a 256 -c selected.sha256
  fi
)
tar -xzf "$stage/$archive" -C "$stage" atx
install_dir="${ATX_INSTALL_DIR:-$HOME/.local/bin}"
mkdir -p "$install_dir"
pending="$(mktemp "$install_dir/.atx.XXXXXX")"
install -m 0755 "$stage/atx" "$pending"
if [ "$("$pending" version)" != "$version" ]; then
  printf 'Downloaded CLI version does not match this installer.\n' >&2
  exit 1
fi
mv -f "$pending" "$install_dir/atx"
pending=""
printf 'Installed Purrkey CLI %s: %s/atx\n' "$version" "$install_dir"
case ":$PATH:" in
  *":$install_dir:"*) ;;
  *) printf 'Add the installation directory to PATH in your shell:\nexport PATH=%q:$PATH\n' "$install_dir" ;;
esac

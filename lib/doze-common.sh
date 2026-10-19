# Sourced by the Raycast entry scripts. Not a Raycast command.
# Locates the installed root helpers (see install.sh) and checks they are usable.

DOZE_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOZE_HELPER_DIR="/Library/Doze"
DOZE_HELPERS=(doze-on.sh doze-off.sh)

# Usage: doze_require_helpers [current]
# Exits if the helpers are not installed. With "current", also exits if the
# installed copies differ from this repo's, i.e. the repo was updated and
# install.sh has not been re-run. Stopping a doze only needs "installed", so a
# stale helper never blocks turning sleep back on.
doze_require_helpers() {
  local REQUIRE_CURRENT="${1:-}"
  local HELPER

  for HELPER in "${DOZE_HELPERS[@]}"; do
    if [ ! -x "$DOZE_HELPER_DIR/$HELPER" ]; then
      echo "Helpers not installed: run sudo ./install.sh in the doze folder"
      exit 1
    fi
    if [ "$REQUIRE_CURRENT" = "current" ] && ! cmp -s "$DOZE_REPO_DIR/helpers/$HELPER" "$DOZE_HELPER_DIR/$HELPER"; then
      echo "Helpers outdated: run sudo ./install.sh in the doze folder"
      exit 1
    fi
  done
}

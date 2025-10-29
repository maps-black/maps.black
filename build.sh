#! /usr/bin/env bash
set -xeuo pipefail

export LOCAL_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

. $LOCAL_SCRIPT_DIR/utils.sh

build() {
  set -xeuo pipefail

  export HOME="/root/"
  . "/root/.cargo/env"

  mkdir -p tilejson client styles fonts resourcetiles naturalearth-raster naturalearth-vector osm-vector gh-pages

  # TODO: Reactivate
  # cp $SCRIPT_DIR/fonts/fonts-*.squashfs ./fonts/
  cp $SCRIPT_DIR/tilejson/*.squashfs ./tilejson/
  cp $SCRIPT_DIR/client/*.squashfs ./client/
  cp $SCRIPT_DIR/styles/*.squashfs ./styles/
  # cp $SCRIPT_DIR/resourcetiles/*.pmtiles ./resourcetiles/

  (cd naturalearth-raster/ && . $SCRIPT_DIR/naturalearth-raster/build.sh && build)
  (cd naturalearth-vector/ && . $SCRIPT_DIR/naturalearth-vector/build.sh && build)
  (cd osm-vector/ && . $SCRIPT_DIR/osm-vector/build.sh && build)
  (cd gh-pages/ && . $SCRIPT_DIR/gh-pages/build.sh && build_extracts)
  link_all
}

gh_pages() {
  set -xeuo pipefail
  (cd gh-pages/ && . ./build.sh && build)
}

for var in "$@"; do
  "$var"
done

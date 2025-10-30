#!/usr/bin/env bash
set -xeuo pipefail
. ../utils.sh

build() {
  set -xeuo pipefail
  if [ ! -f ./client.squashfs ] || [ ! -z "$(find *.{sh,js,json,html,svg,png} -newer "./client.squashfs")" ]; then
    if [ ! -d node_modules ]; then
      npm ci
    fi
    rm -rf client client.squashfs
    mkdir -p client
    npm run build
    for f in client/*; do
      if [ ! -f "$f" ] || [[ $f == *".png" ]]; then
        continue
      fi
      if [[ $f == *".json" ]]; then
        jq -cr tostring "$f" | sponge "$f"
      fi
      gzip -9kf "$f"
      brotli -Zkf "$f"
    done
    cp -r demo_images ./client/demo_images
    find ./client -type d -exec chmod 777 {} \;
    mksquashfs ./client ./.client.squashfs -exit-on-error -quiet -noD -comp zstd -Xcompression-level 6 -fstime 0 -all-time 0 -no-xattrs -all-root -no-progress -no-exports &&
      mv -f ./.client.squashfs ./client.squashfs
    rm -rf client
  fi
}

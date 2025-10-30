#!/usr/bin/env bash
set -xeuo pipefail
. ../utils.sh

build() {
  (
    set -xeuo pipefail
    shopt -s globstar
    for sizeVariant in '-minimal' '-core' '-full'; do
      if [ ! -f ./resourcetiles$sizeVariant.pmtiles ] || [[ ../styles/styles.squashfs -nt "./resourcetiles$sizeVariant.pmtiles" ]] || [[ ../tilejson/tilejson.squashfs -nt "./resourcetiles$sizeVariant.pmtiles" ]] || [[ "../fonts/fontsprep$sizeVariant.squashfs" -nt "./resourcetiles$sizeVariant.pmtiles" ]]; then
        # Cleanup from previous runs
        if [ -d resourcetiles$sizeVariant ]; then
          umount ./resourcetiles$sizeVariant || true
          rm -rf ./resourcetiles$sizeVariant
        fi
        if [ -d fontsprep$sizeVariant ]; then
          umount ./fontsprep$sizeVariant || true
          rm -rf ./fontsprep$sizeVariant
        fi
        if [ -d styles ]; then
          umount ./styles || true
          rm -rf ./styles
        fi
        if [ -d tilejson ]; then
          umount ./tilejson || true
          rm -rf ./tilejson
        fi
        rm -rf ./resourcetiles$sizeVariant-upper ./resourcetiles$sizeVariant-work resourcetiles$sizeVariant.mbtiles resourcetiles$sizeVariant.pmtiles

        mkdir -p resourcetiles$sizeVariant ./fontsprep$sizeVariant ./resourcetiles$sizeVariant-upper ./resourcetiles$sizeVariant-work resourcetiles$sizeVariant ./styles ./tilejson
        mount ../fonts/fontsprep$sizeVariant.squashfs ./fontsprep$sizeVariant
        mount ../styles/styles.squashfs ./styles
        mount ../tilejson/tilejson.squashfs ./tilejson
        mount -t overlay overlay -o lowerdir=./fontsprep$sizeVariant,upperdir=./resourcetiles$sizeVariant-upper,workdir=./resourcetiles$sizeVariant-work ./resourcetiles$sizeVariant

        i=0
        mkdir -p resourcetiles$sizeVariant/19/0
        for _fileName in {styles,tilejson}/**/*; do
          if [[ "$_fileName" == *"icons"* ]] || [ ! -f "$_fileName" ]; then
            continue
          fi
          fileName="${_fileName#./}"
          cp "$fileName" resourcetiles$sizeVariant/19/0/$i.pbf
          jq --arg fileName "$fileName" -c -r '.files |= .+ [$fileName]' resourcetiles$sizeVariant/0/0/0.json | sponge resourcetiles$sizeVariant/0/0/0.json
          i=$((i + 1))
        done

        mv resourcetiles$sizeVariant/0/0/0.json resourcetiles$sizeVariant/0/0/0.pbf

        for fileName in resourcetiles$sizeVariant/0/*/* resourcetiles$sizeVariant/19/*/*; do
          if [[ $(file -b --mime-type "$fileName") != 'application/gzip' ]]; then
            gzip -9 "$fileName"
            mv -f "$fileName".gz "$fileName"
          fi
        done

        echo '{"name": "map resources", "format": "pbf", "minzoom": "0", "maxzoom": "21", "compression": "gzip"}' >resourcetiles$sizeVariant/metadata.json
        mb-util --silent resourcetiles$sizeVariant resourcetiles$sizeVariant.mbtiles --image_format="pbf"
        pmtiles convert resourcetiles$sizeVariant.mbtiles resourcetiles$sizeVariant.pmtiles
        rm -rf resourcetiles$sizeVariant.mbtiles

        # Cleanup
        if [ -d resourcetiles$sizeVariant ]; then
          umount ./resourcetiles$sizeVariant || true
          rm -rf ./resourcetiles$sizeVariant
        fi
        if [ -d fontsprep$sizeVariant ]; then
          umount ./fontsprep$sizeVariant || true
          rm -rf ./fontsprep$sizeVariant
        fi
        if [ -d styles ]; then
          umount ./styles || true
          rm -rf ./styles
        fi
        if [ -d tilejson ]; then
          umount ./tilejson || true
          rm -rf ./tilejson
        fi
        rm -rf ./resourcetiles$sizeVariant-upper ./resourcetiles$sizeVariant-work
      fi
    done
  )
}

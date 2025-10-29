#!/usr/bin/env bash
set -xeuo pipefail
. ../utils.sh

export shortbreadSources='{"shortbread": { "type": "vector", "url": "https://maps.black/tilejson/openstreetmap-shortbread.json" },"versatiles-shortbread": { "type": "vector", "url": "https://maps.black/tilejson/openstreetmap-shortbread.json" },"terrarium": { "type": "raster-dem", "encoding": "terrarium", "url": "https://maps.black/tilejson/terrarium.json" }}'

export protomapsSources='{"protomaps": { "type": "vector", "url": "https://maps.black/tilejson/openstreetmap-protomaps.json" },"terrarium": { "type": "raster-dem", "encoding": "terrarium", "url": "https://maps.black/tilejson/terrarium.json" }}'

export openmaptilesSources='{"openmaptiles": { "type": "vector", "url": "https://maps.black/tilejson/openstreetmap-openmaptiles.json" },"terrarium": { "type": "raster-dem", "encoding": "terrarium", "url": "https://maps.black/tilejson/terrarium.json" }}'

export openmaptilesSourcesWithNE='{"openmaptiles": { "type": "vector", "url": "https://maps.black/tilejson/openstreetmap-openmaptiles.json" },"terrarium": { "type": "raster-dem", "encoding": "terrarium", "url": "https://maps.black/tilejson/terrarium.json" },"naturalearth6-NE2_HR_SR_W_DR-WEBP": { "type": "raster", "url": "https://maps.black/naturalearth6-NE2_HR_SR_W_DR-WEBP.json" }}'

old_build() {
  # We do checking a bit different here than other datasets since these will be modified in this repo. Use openmaptiles as a sentinel for if we have downloaded the repo
  if [ ! -d openmaptiles ]; then
    (
      set -xeuo pipefail
      mkdir -p {shortbread,protomaps,openmaptiles}
      if [ ! -d shortbread/versatiles ]; then
        mkdir -p shortbread/versatiles
        cd shortbread/versatiles && echo "Building shortbread/versatiles"
        git clone --quiet https://github.com/versatiles-org/versatiles-style.git .versatiles
        (
          cd .versatiles
          git reset --hard v5.2.3
          npm i && npm run build-styles && npm run build-sprites
          (cd release/ && tar -xzvf styles.tar.gz)
        )
        for f in .versatiles/release/*/en.json; do
          filename="${f##*/}"
          _name="${f/\/en.json/}"
          name="${_name##*/}"
          mkdir -p "$name"
          cp "$f" "$name/style.json"
          cp ".versatiles/LICENSE.md" "$name/LICENSE.txt"
          cp -r ".versatiles/release/sprites" "$name/sprites"
          (cd .versatiles && git config --get remote.origin.url && git rev-parse --short HEAD) >"$name/SOURCE.txt"

          sprites="https://maps.black/styles/shortbread/versatiles/$name/sprites/basics/sprites"
          jq --arg sprites "$sprites" '.sprite[0].url = $sprites' "$name/style.json" | sponge "$name/style.json"

          jq --argjson sources "$shortbreadSources" '.sources = $sources' "$name/style.json" | sponge "$name/style.json"
        done
        rm -rf .versatiles
      fi
    )

    mkdir -p openmaptiles/{openmaptiles,openfreemap}

    (
      if [ ! -d openmaptiles/openmaptiles/openmaptiles ]; then
        mkdir -p openmaptiles/openmaptiles/openmaptiles
        cd openmaptiles/openmaptiles/openmaptiles && echo "Building openmaptiles/openmaptiles/openmaptiles"
        git clone --quiet https://github.com/maps-black/static-openmaptiles-style.git .static-openmaptiles-style
        cp .static-openmaptiles-style/style.json ./style.json
        cp .static-openmaptiles-style/LICENSE.md ./LICENSE.txt
        cp .static-openmaptiles-style/SOURCE.txt ./SOURCE.txt
        mkdir -p sprites/openmaptiles/sprites
        mv .static-openmaptiles-style/sprite* sprites/openmaptiles/sprites/

        sprite="https://maps.black/styles/openmaptiles/openmaptiles/openmaptiles/sprites/openmaptiles/sprites"
        jq --arg sprite "$sprite" '.sprite = $sprite' ./style.json | sponge ./style.json

        jq --argjson sources "$openmaptilesSources" '.sources = $sources' ./style.json | sponge ./style.json
        rm -rf .static-openmaptiles-style
      fi
    )
    (
      if [ ! -d openmaptiles/openmaptiles/basic ]; then
        mkdir -p openmaptiles/openmaptiles/basic
        cd openmaptiles/openmaptiles/basic && echo "Building openmaptiles/openmaptiles/basic"
        git clone --quiet https://github.com/openmaptiles/maptiler-basic-gl-style.git .maptiler-basic-gl-style
        cp .maptiler-basic-gl-style/style.json ./style.json
        cp .maptiler-basic-gl-style/LICENSE.md ./LICENSE.txt
        (cd .maptiler-basic-gl-style && git config --get remote.origin.url && git rev-parse --short HEAD) >./SOURCE.txt

        # This style has no sprites
        jq 'del(.sprite)' ./style.json | sponge ./style.json

        jq --argjson sources "$openmaptilesSources" '.sources = $sources' ./style.json | sponge ./style.json

        rm -rf .maptiler-basic-gl-style
      fi
    )
    (
      if [ ! -d openmaptiles/openmaptiles/bright ]; then
        mkdir -p openmaptiles/openmaptiles/bright
        cd openmaptiles/openmaptiles/bright && echo "Building openmaptiles/openmaptiles/bright"
        git clone --quiet https://github.com/openmaptiles/osm-bright-gl-style.git .osm-bright-gl-style
        cp .osm-bright-gl-style/style.json ./style.json
        cp .osm-bright-gl-style/LICENSE.md ./LICENSE.txt
        cp -r .osm-bright-gl-style/icons ./icons
        mkdir -p sprites/bright/
        spreet --unique --minify-index-file ./icons sprites/bright/sprites
        spreet --retina --unique --minify-index-file ./icons sprites/bright/sprites@2x
        (cd .osm-bright-gl-style && git config --get remote.origin.url && git rev-parse --short HEAD) >./SOURCE.txt

        sprite="https://maps.black/styles/openmaptiles/openmaptiles/bright/sprites/bright/sprites"
        jq --arg sprite "$sprite" '.sprite = $sprite' ./style.json | sponge ./style.json

        jq --argjson sources "$openmaptilesSources" '.sources = $sources' ./style.json | sponge ./style.json

        rm -rf .osm-bright-gl-style
      fi
    )
    (
      if [ ! -d openmaptiles/openmaptiles/positron ]; then
        mkdir -p openmaptiles/openmaptiles/positron
        cd openmaptiles/openmaptiles/positron && echo "Building openmaptiles/openmaptiles/positron"
        git clone --quiet https://github.com/openmaptiles/positron-gl-style.git .positron-gl-style
        cp .positron-gl-style/style.json ./style.json
        cp .positron-gl-style/LICENSE.md ./LICENSE.txt
        cp -r .positron-gl-style/icons ./icons
        mkdir -p sprites/positron/
        spreet --unique --minify-index-file ./icons sprites/positron/sprites
        spreet --retina --unique --minify-index-file ./icons sprites/positron/sprites@2x
        (cd .positron-gl-style && git config --get remote.origin.url && git rev-parse --short HEAD) >./SOURCE.txt

        sprite="https://maps.black/styles/openmaptiles/openmaptiles/positron/sprites/positron/sprites"
        jq --arg sprite "$sprite" '.sprite = $sprite' ./style.json | sponge ./style.json

        jq --argjson sources "$openmaptilesSources" '.sources = $sources' ./style.json | sponge ./style.json

        rm -rf .positron-gl-style
      fi
    )
    (
      if [ ! -d openmaptiles/openmaptiles/dark-matter ]; then
        mkdir -p openmaptiles/openmaptiles/dark-matter
        cd openmaptiles/openmaptiles/dark-matter && echo "Building openmaptiles/openmaptiles/dark-matter"
        git clone --quiet https://github.com/openmaptiles/dark-matter-gl-style.git .dark-matter-gl-style
        cp .dark-matter-gl-style/style.json ./style.json
        cp .dark-matter-gl-style/LICENSE.md ./LICENSE.txt
        cp -r .dark-matter-gl-style/icons ./icons
        mkdir -p sprites/dark-matter/
        spreet --unique --minify-index-file ./icons sprites/dark-matter/sprites
        spreet --retina --unique --minify-index-file ./icons sprites/dark-matter/sprites@2x
        (cd .dark-matter-gl-style && git config --get remote.origin.url && git rev-parse --short HEAD) >./SOURCE.txt

        sprite="https://maps.black/styles/openmaptiles/openmaptiles/dark-matter/sprites/dark-matter/sprites"
        jq --arg sprite "$sprite" '.sprite = $sprite' ./style.json | sponge ./style.json

        jq --argjson sources "$openmaptilesSources" '.sources = $sources' ./style.json | sponge ./style.json

        rm -rf .dark-matter-gl-style
      fi
    )
    (
      if [ ! -d openmaptiles/openmaptiles/maptiler-3d ]; then
        mkdir -p openmaptiles/openmaptiles/maptiler-3d
        cd openmaptiles/openmaptiles/maptiler-3d && echo "Building openmaptiles/openmaptiles/maptiler-3d"
        git clone --quiet https://github.com/openmaptiles/maptiler-3d-gl-style.git .maptiler-3d-gl-style
        cp .maptiler-3d-gl-style/style.json ./style.json
        cp .maptiler-3d-gl-style/LICENSE.md ./LICENSE.txt
        (cd .maptiler-3d-gl-style && git config --get remote.origin.url && git rev-parse --short HEAD) >./SOURCE.txt

        # This style has no sprites
        jq 'del(.sprite)' ./style.json | sponge ./style.json

        jq --argjson sources "$openmaptilesSources" '.sources = $sources' ./style.json | sponge ./style.json

        rm -rf .maptiler-3d-gl-style
      fi
    )
    (
      if [ ! -d openmaptiles/openmaptiles/terrain ]; then
        mkdir -p openmaptiles/openmaptiles/terrain
        cd openmaptiles/openmaptiles/terrain && echo "Building openmaptiles/openmaptiles/terrain"
        git clone --quiet https://github.com/openmaptiles/maptiler-terrain-gl-style.git .terrain-gl-style
        cp .terrain-gl-style/style.json ./style.json
        cp .terrain-gl-style/LICENSE.md ./LICENSE.txt

        (cd .terrain-gl-style && git config --get remote.origin.url && git rev-parse --short HEAD) >./SOURCE.txt

        # This style has no sprites
        jq 'del(.sprite)' ./style.json | sponge ./style.json

        jq --argjson sources "$openmaptilesSourcesWithNE" '.sources = $sources' ./style.json | sponge ./style.json

        rm -rf .terrain-gl-style
      fi
    )
    (
      if [ ! -d openmaptiles/openmaptiles/fiord ]; then
        mkdir -p openmaptiles/openmaptiles/fiord
        cd openmaptiles/openmaptiles/fiord && echo "Building openmaptiles/openmaptiles/fiord"
        git clone --quiet https://github.com/openmaptiles/fiord-color-gl-style.git .fiord-gl-style
        cp .fiord-gl-style/style.json ./style.json
        cp .fiord-gl-style/LICENSE.md ./LICENSE.txt
        cp -r .fiord-gl-style/icons ./icons
        mkdir -p sprites/fiord/
        spreet --unique --minify-index-file ./icons sprites/fiord/sprites
        spreet --retina --unique --minify-index-file ./icons sprites/fiord/sprites@2x
        (cd .fiord-gl-style && git config --get remote.origin.url && git rev-parse --short HEAD) >./SOURCE.txt

        sprite="https://maps.black/styles/openmaptiles/openmaptiles/fiord/sprites/fiord/sprites"
        jq --arg sprite "$sprite" '.sprite = $sprite' ./style.json | sponge ./style.json

        jq --argjson sources "$openmaptilesSources" '.sources = $sources' ./style.json | sponge ./style.json

        rm -rf .fiord-gl-style
      fi
    )
    (
      if [ ! -d openmaptiles/openmaptiles/toner ]; then
        mkdir -p openmaptiles/openmaptiles/toner
        cd openmaptiles/openmaptiles/toner && echo "Building openmaptiles/openmaptiles/toner"
        git clone --quiet https://github.com/openmaptiles/maptiler-toner-gl-style.git .toner-gl-style
        cp .toner-gl-style/style.json ./style.json
        cp .toner-gl-style/LICENSE.md ./LICENSE.txt
        cp -r .toner-gl-style/icons ./icons
        mkdir -p sprites/toner/
        spreet --unique --minify-index-file ./icons sprites/toner/sprites
        spreet --retina --unique --minify-index-file ./icons sprites/toner/sprites@2x
        (cd .toner-gl-style && git config --get remote.origin.url && git rev-parse --short HEAD) >./SOURCE.txt

        sprite="https://maps.black/styles/openmaptiles/openmaptiles/toner/sprites/toner/sprites"
        jq --arg sprite "$sprite" '.sprite = $sprite' ./style.json | sponge ./style.json

        jq --argjson sources "$openmaptilesSources" '.sources = $sources' ./style.json | sponge ./style.json

        rm -rf .toner-gl-style
      fi
    )
    (
      if [ ! -d openmaptiles/maputnik/liberty ]; then
        mkdir -p openmaptiles/maputnik/liberty
        cd openmaptiles/maputnik/liberty && echo "Building openmaptiles/maputnik/liberty"
        git clone --quiet https://github.com/maputnik/osm-liberty.git .liberty-gl-style
        cp .liberty-gl-style/style.json ./style.json
        cp .liberty-gl-style/LICENSE.md ./LICENSE.txt

        mkdir -p ./svgs/svgs_not_in_iconset/ ./svgs/svgs_iconset/ ./icons/
        cp -a .liberty-gl-style/svgs/svgs_not_in_iconset/. ./svgs/svgs_not_in_iconset/
        cp -a .liberty-gl-style/svgs/svgs_iconset/. ./svgs/svgs_iconset/
        cp -a .liberty-gl-style/svgs/svgs_not_in_iconset/. ./icons/
        cp -a .liberty-gl-style/svgs/svgs_iconset/. ./icons/
        mkdir -p sprites/liberty/
        spreet --unique --minify-index-file ./icons sprites/liberty/sprites
        spreet --retina --unique --minify-index-file ./icons sprites/liberty/sprites@2x
        (cd .liberty-gl-style && git config --get remote.origin.url && git rev-parse --short HEAD) >./SOURCE.txt

        sprite="https://maps.black/styles/openmaptiles/maputnik/liberty/sprites/liberty/sprites"
        jq --arg sprite "$sprite" '.sprite = $sprite' ./style.json | sponge ./style.json

        jq --argjson sources "$openmaptilesSourcesWithNE" '.sources = $sources' ./style.json | sponge ./style.json

        rm -rf .liberty-gl-style
      fi
    )
    (
      if [ ! -d openmaptiles/nst-guide/liberty-topo ]; then
        mkdir -p openmaptiles/nst-guide/liberty-topo
        cd openmaptiles/nst-guide/liberty-topo && echo "Building openmaptiles/nst-guide/liberty-topo"
        git clone --quiet https://github.com/nst-guide/osm-liberty-topo.git .liberty-topo-gl-style
        cp .liberty-topo-gl-style/style.json ./style.json
        cp .liberty-topo-gl-style/LICENSE.md ./LICENSE.txt

        mkdir -p ./svgs/svgs_not_in_iconset/ ./svgs/svgs_iconset/ ./icons/
        cp -a .liberty-topo-gl-style/svgs/svgs_not_in_iconset/. ./svgs/svgs_not_in_iconset/
        cp -a .liberty-topo-gl-style/svgs/svgs_iconset/. ./svgs/svgs_iconset/
        cp -a .liberty-topo-gl-style/svgs/svgs_not_in_iconset/. ./icons/
        cp -a .liberty-topo-gl-style/svgs/svgs_iconset/. ./icons/
        mkdir -p sprites/liberty-topo/
        spreet --unique --minify-index-file ./icons sprites/liberty-topo/sprites
        spreet --retina --unique --minify-index-file ./icons sprites/liberty-topo/sprites@2x
        (cd .liberty-topo-gl-style && git config --get remote.origin.url && git rev-parse --short HEAD) >./SOURCE.txt

        sprite="https://maps.black/styles/openmaptiles/nst-guide/liberty-topo/sprites/liberty-topo/sprites"
        jq --arg sprite "$sprite" '.sprite = $sprite' ./style.json | sponge ./style.json

        jq --argjson sources "$openmaptilesSourcesWithNE" '.sources = $sources' ./style.json | sponge ./style.json

        rm -rf .liberty-topo-gl-style
      fi
    )
    (
      if [ ! -d openmaptiles/qwant/basic ]; then
        mkdir -p openmaptiles/qwant/basic
        cd openmaptiles/qwant/basic && echo "Building openmaptiles/qwant/basic"
        git clone --quiet https://github.com/Qwant/qwant-basic-gl-style.git .basic-gl-style
        cp .basic-gl-style/style.json ./style.json
        cp .basic-gl-style/LICENSE.md ./LICENSE.txt
        cp -r .basic-gl-style/icons ./icons
        mkdir -p sprites/basic/
        spreet --unique --minify-index-file ./icons sprites/basic/sprites
        spreet --retina --unique --minify-index-file ./icons sprites/basic/sprites@2x
        (cd .basic-gl-style && git config --get remote.origin.url && git rev-parse --short HEAD) >./SOURCE.txt

        sprite="https://maps.black/styles/openmaptiles/qwant/basic/sprites/basic/sprites"
        jq --arg sprite "$sprite" '.sprite = $sprite' ./style.json | sponge ./style.json

        jq --argjson sources "$openmaptilesSources" '.sources = $sources' ./style.json | sponge ./style.json

        rm -rf .basic-gl-style
      fi
    )
    (
      if [ ! -d openmaptiles/openfreemap/bright ]; then
        mkdir -p openmaptiles/openfreemap/bright
        cd openmaptiles/openfreemap/bright && echo "Building openmaptiles/openfreemap/bright"
        git clone --quiet https://github.com/hyperknot/openfreemap-styles.git .openfreemap
        cp .openfreemap/styles/bright/style.json ./style.json
        cp .openfreemap/styles/bright/LICENSE.md ./LICENSE.txt
        cp -r .openfreemap/styles/bright/icons_unique ./icons
        cp -r .openfreemap/styles/bright/icons_not_used ./icons_not_used
        mkdir -p sprites/bright/
        spreet --unique --minify-index-file ./icons sprites/bright/sprites
        spreet --retina --unique --minify-index-file ./icons sprites/bright/sprites@2x
        (cd .openfreemap && git config --get remote.origin.url && git rev-parse --short HEAD) >./SOURCE.txt

        sprite="https://maps.black/styles/openmaptiles/openfreemap/bright/sprites/bright/sprites"
        jq --arg sprite "$sprite" '.sprite = $sprite' ./style.json | sponge ./style.json

        jq --argjson sources "$openmaptilesSources" '.sources = $sources' ./style.json | sponge ./style.json

        rm -rf .openfreemap
      fi
    )
    (
      if [ ! -d openmaptiles/openfreemap/dark ]; then
        mkdir -p openmaptiles/openfreemap/dark
        cd openmaptiles/openfreemap/dark && echo "Building openmaptiles/openfreemap/dark"
        git clone --quiet https://github.com/hyperknot/openfreemap-styles.git .openfreemap
        cp .openfreemap/styles/dark/style.json ./style.json
        cp .openfreemap/styles/dark/LICENSE.md ./LICENSE.txt
        cp -r .openfreemap/styles/dark/icons ./icons
        mkdir -p sprites/dark/
        spreet --unique --minify-index-file ./icons sprites/dark/sprites
        spreet --retina --unique --minify-index-file ./icons sprites/dark/sprites@2x
        (cd .openfreemap && git config --get remote.origin.url && git rev-parse --short HEAD) >./SOURCE.txt

        sprite="https://maps.black/styles/openmaptiles/openfreemap/dark/sprites/dark/sprites"

        jq --argjson sources "$openmaptilesSources" '.sources = $sources' ./style.json | sponge ./style.json

        rm -rf .openfreemap
      fi
    )
    (
      if [ ! -d openmaptiles/openfreemap/fiord ]; then
        mkdir -p openmaptiles/openfreemap/fiord
        cd openmaptiles/openfreemap/fiord && echo "Building openmaptiles/openfreemap/fiord"
        git clone --quiet https://github.com/hyperknot/openfreemap-styles.git .openfreemap
        cp .openfreemap/styles/fiord/style.json ./style.json
        cp .openfreemap/styles/fiord/LICENSE.md ./LICENSE.txt
        cp -r .openfreemap/styles/fiord/icons ./icons
        mkdir -p sprites/fiord/
        spreet --unique --minify-index-file ./icons sprites/fiord/sprites
        spreet --retina --unique --minify-index-file ./icons sprites/fiord/sprites@2x
        (cd .openfreemap && git config --get remote.origin.url && git rev-parse --short HEAD) >./SOURCE.txt

        sprite="https://maps.black/styles/openmaptiles/openfreemap/fiord/sprites/fiord/sprites"

        jq --argjson sources "$openmaptilesSources" '.sources = $sources' ./style.json | sponge ./style.json

        rm -rf .openfreemap
      fi
    )
    (
      if [ ! -d openmaptiles/openfreemap/liberty ]; then
        mkdir -p openmaptiles/openfreemap/liberty
        cd openmaptiles/openfreemap/liberty && echo "Building openmaptiles/openfreemap/liberty"
        git clone --quiet https://github.com/hyperknot/openfreemap-styles.git .openfreemap
        cp .openfreemap/styles/liberty/style.json ./style.json
        cp .openfreemap/styles/liberty/LICENSE.md ./LICENSE.txt

        mkdir -p ./icons/ ./svgs/
        cp -r .openfreemap/styles/liberty/svgs/svgs_not_in_iconset ./svgs/svgs_not_in_iconset
        cp -r .openfreemap/styles/liberty/svgs/svgs_iconset ./svgs/svgs_iconset
        cp -a ./svgs/svgs_iconset/. ./icons/
        cp -a ./svgs/svgs_not_in_iconset/. ./icons/

        mkdir -p sprites/liberty/
        spreet --unique --minify-index-file ./icons sprites/liberty/sprites
        spreet --retina --unique --minify-index-file ./icons sprites/liberty/sprites@2x
        (cd .openfreemap && git config --get remote.origin.url && git rev-parse --short HEAD) >./SOURCE.txt

        sprite="https://maps.black/styles/openmaptiles/openfreemap/liberty/sprites/liberty/sprites"
        jq --arg sprite "$sprite" '.sprite = $sprite' ./style.json | sponge ./style.json

        jq --argjson sources "$openmaptilesSourcesWithNE" '.sources = $sources' ./style.json | sponge ./style.json

        rm -rf .openfreemap
      fi
    )
    (
      if [ ! -d openmaptiles/openfreemap/positron ]; then
        mkdir -p openmaptiles/openfreemap/positron
        cd openmaptiles/openfreemap/positron && echo "Building openmaptiles/openfreemap/positron"
        git clone --quiet https://github.com/hyperknot/openfreemap-styles.git .openfreemap
        cp .openfreemap/styles/positron/style.json ./style.json
        cp .openfreemap/styles/positron/LICENSE.md ./LICENSE.txt
        cp -r .openfreemap/styles/bright/icons_unique ./icons
        cp -r .openfreemap/styles/bright/icons_not_used ./icons_not_used
        mkdir -p sprites/positron/
        spreet --unique --minify-index-file ./icons sprites/positron/sprites
        spreet --retina --unique --minify-index-file ./icons sprites/positron/sprites@2x
        (cd .openfreemap && git config --get remote.origin.url && git rev-parse --short HEAD) >./SOURCE.txt

        sprite="https://maps.black/styles/openmaptiles/openfreemap/positron/sprites/positron/sprites"
        jq --arg sprite "$sprite" '.sprite = $sprite' ./style.json | sponge ./style.json

        jq --argjson sources "$openmaptilesSources" '.sources = $sources' ./style.json | sponge ./style.json

        rm -rf .openfreemap
      fi
    )

    (
      if [ ! -d protomaps/protomaps ]; then
        mkdir -p protomaps/protomaps
        cd protomaps/protomaps && echo "Building protomaps/protomaps"
        if [ ! -d .basemaps ]; then
          git clone --quiet https://github.com/protomaps/basemaps.git .basemaps
          (
            cd .basemaps/styles
            npm ci
            npm run generate-styles 'https://maps.black'
          )
          (
            cd .basemaps/sprites
            for style in black dark grayscale light white; do
              spritegen refill.svg themes/$style.json dist/$style
            done
          )
        fi
        for style in black dark grayscale light white; do
          (
            if [ ! -d $style ]; then
              mkdir -p $style
              cd $style
              cp ../.basemaps/styles/dist/styles/$style/en.json ./style.json
              mkdir -p sprites/$style/
              cp ../.basemaps/sprites/dist/$style.json sprites/$style/sprites.json
              cp ../.basemaps/sprites/dist/$style.png sprites/$style/sprites.png
              cp ../.basemaps/sprites/dist/$style@2x.json sprites/$style/sprites@2x.json
              cp ../.basemaps/sprites/dist/$style@2x.png sprites/$style/sprites@2x.png
              cp ../.basemaps/LICENSE.md LICENSE.txt
              (cd ../.basemaps && git config --get remote.origin.url && git rev-parse --short HEAD) >./SOURCE.txt

              sprite="https://maps.black/styles/protomaps/protomaps/$style/sprites/$style/sprites"
              jq --arg sprite "$sprite" '.sprite = $sprite' ./style.json | sponge ./style.json

              jq --argjson sources "$protomapsSources" '.sources = $sources' ./style.json | sponge ./style.json
            fi
          )
        done
        rm -rf .basemaps
      fi
    )
    (
      cd ./protomaps-themes
      npm ci
      ./build.js
    )
    (
      for f in */*/*/style.json; do
        fonts="https://maps.black/fonts/{fontstack}/{range}.pbf"
        jq --arg fonts "$fonts" '.glyphs = $fonts' "$f" | sponge "$f"
        gl-style-format "$f" | sponge "$f"
        gl-style-migrate "$f" | sponge "$f"
        gl-style-validate "$f"
      done
    )

    # Fix font names:
    find ./{openmaptiles,protomaps,shortbread} -type f -exec sed -i 's/Klokantech Noto Sans Bold/Noto Sans Bold/g' {} \;
    find ./{openmaptiles,protomaps,shortbread} -type f -exec sed -i 's/Klokantech Noto Sans Regular/Noto Sans Regular/g' {} \;
    find ./{openmaptiles,protomaps,shortbread} -type f -exec sed -i 's/noto_sans_bold/Noto Sans Bold/g' {} \;
    find ./{openmaptiles,protomaps,shortbread} -type f -exec sed -i 's/noto_sans_regular/Noto Sans Regular/g' {} \;
    find ./{openmaptiles,protomaps,shortbread} -type f -exec sed -i 's/Open Sans Semibold Italic/Open Sans Semi Bold Italic/g' {} \;

    # Optimize sprites
    shopt -s globstar
    # pngquant exits with code 98 if a output is not smaller than input, so ignore exit status. This could be handled better
    pngquant --ext .png --force --skip-if-larger --speed 1 --strip --quality=80-90 */**/*.png || true
    oxipng -r -q --zopfli -o max --fast --strip safe --alpha ./
  fi
}

build() {
  if [ ! -f ./styles.squashfs ]; then
    (
      set -xeuo pipefail
      shopt -s globstar

      for f in */*/*/style*.json; do
        gl-style-format "$f" | sponge "$f"
        gl-style-migrate "$f" | sponge "$f"
        gl-style-validate "$f"
      done

      rm -rf styles
      mkdir -p styles
      cp -r {openstreetmap-openmaptiles,openstreetmap-protomaps,openstreetmap-shortbread,naturalearth-openmaptiles,naturalearth-protomaps,naturalearth-shortbread,raster} ./styles/

      for f in styles/**/*; do
        if [ ! -f "$f" ] || [[ $f == *".png" ]]; then
          continue
        fi
        if [[ $f == *".json" ]]; then
          jq -cr tostring "$f" | sponge "$f"
        fi
        gzip -9kf "$f"
        brotli -Zkf "$f"
      done

      find ./styles -type d -exec chmod 777 {} \;
      mksquashfs ./styles ./.styles.squashfs -exit-on-error -quiet -noD -comp zstd -Xcompression-level 6 -fstime 0 -all-time 0 -no-xattrs -all-root -no-progress -no-exports &&
        mv -f ./.styles.squashfs ./styles.squashfs
      rm -rf styles
    )
  fi
}

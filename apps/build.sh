#!/usr/bin/env bash
set -xeuo pipefail
. ../utils.sh

build() {
  set -xeuo pipefail
  if [ ! -f ./mb-util ]; then
    (
      git clone --quiet https://github.com/mapbox/mbutil.git mbutil_upstream
      cd mbutil_upstream
      git reset ${mbutilVersion} --hard
    )
    ln -fs mbutil_upstream/mb-util mb-util
  fi

  if [ ! -f ./pmtiles ]; then
    (
      mkdir -p ./pmtiles_upstream
      cd ./pmtiles_upstream
      download_with_check_noproxy https://github.com/protomaps/go-pmtiles/releases/download/v${pmtilesVersion}/go-pmtiles_${pmtilesVersion}_Linux_x86_64.tar.gz
      tar xzvf go-pmtiles_${pmtilesVersion}_Linux_x86_64.tar.gz
      cp ./pmtiles ../pmtiles
    )
    rm -rf pmtiles_upstream
  fi

  if [ ! -f tippecanoe ]; then
    git clone --quiet https://github.com/felt/tippecanoe.git tippecanoe_upstream
    (
      cd tippecanoe_upstream
      git reset --hard "${tippecanoeVersion}"
      make -j
      cp ./tippecanoe ../tippecanoe
      cp ./tippecanoe-decode ../tippecanoe-decode
      cp ./tile-join ../tile-join
    )
  fi

  if [ ! -f ./martin ]; then
    (
      mkdir -p martin_upstream
      cd martin_upstream
      download_with_check_noproxy https://github.com/maplibre/martin/releases/download/v${martinVersion}/martin-x86_64-unknown-linux-gnu.tar.gz
      tar xzvf martin-x86_64-unknown-linux-gnu.tar.gz
      cp ./martin ../martin
      cp ./mbtiles ../mbtiles
      cp ./martin-cp ../martin-cp
    )
    rm -rf martin_upstream
  fi

  if [ ! -f ./font-maker ]; then
    (
      git clone --quiet --recursive https://github.com/maplibre/font-maker.git font-maker_upstream
      cd font-maker_upstream
      git reset ${fontMakerVersion} --hard
      cmake . && make
      cp ./font-maker ../font-maker
    )
    rm -rf font-maker_upstream
  fi

  if [ ! -f ./spreet ]; then
    (
      mkdir -p spreet_upstream
      cd spreet_upstream
      download_with_check_noproxy https://github.com/flother/spreet/releases/download/v${spreetVersion}/spreet-x86_64-unknown-linux-musl.tar.gz
      tar xzvf spreet-x86_64-unknown-linux-musl.tar.gz
      mv ./spreet ../spreet
    )
    rm -rf spreet_upstream
  fi

  if [ ! -d ./maputnik ]; then
    (
      mkdir -p maputnik
      cd maputnik
      download_with_check_noproxy https://github.com/maplibre/maputnik/releases/download/v${maputnikVersion}/dist.zip
      unzip dist.zip
    )
  fi

  if [ ! -d ./maputnik-desktop ]; then
    (
      mkdir -p maputnik-desktop
      cd maputnik-desktop
      download_with_check_noproxy https://github.com/maplibre/maputnik/releases/download/v${maputnikVersion}/desktop.zip
      unzip desktop.zip
    )
  fi

  if [ ! -d ./java_upstream ]; then
    (
      # TODO: Version-check
      curl -LO https://download.java.net/java/GA/jdk23.0.1/c28985cbf10d4e648e4004050f8781aa/11/GPL/openjdk-23.0.1_linux-x64_bin.tar.gz
      mkdir -p java_upstream && tar --directory java_upstream --strip-components 1 -xzvf openjdk-23.0.1_linux-x64_bin.tar.gz && rm -f openjdk-23.0.1_linux-x64_bin.tar.gz
    )
  fi

  if [ ! -f ./java ]; then
    ln -fs java_upstream/bin/java java
  fi

  if [ ! -d ./maven_upstream ]; then
    (
      # TODO: Version-check
      curl -LO https://dlcdn.apache.org/maven/maven-3/3.9.11/binaries/apache-maven-3.9.11-bin.tar.gz
      mkdir -p maven_upstream && tar --directory maven_upstream --strip-components 1 -xzvf apache-maven-3.9.11-bin.tar.gz && rm -f apache-maven-3.9.11-bin.tar.gz
    )
  fi

  if [ ! -f ./mvn ]; then
    ln -fs maven_upstream/bin/mvn mvn
  fi

  if [ ! -f ./planetiler.jar ]; then
    (
      download_with_check_noproxy https://github.com/onthegomap/planetiler/releases/download/v${planetilerVersion}/planetiler.jar
    )
  fi

  if [ ! -f ./planetiler-openmaptiles.jar ]; then
    rm -rf planetiler-openmaptiles
    (
      # Fork to add more languages
      git clone --recurse-submodules --quiet https://github.com/maps-black/planetiler-openmaptiles.git planetiler-openmaptiles
      cd planetiler-openmaptiles
      git checkout add-languages
      mvn -DskipTests=true clean package
      java -cp target/*-with-deps.jar org.openmaptiles.Generate -tag="add-languages" -base-url="https://raw.githubusercontent.com/maps-black/openmaptiles/refs/heads/"
      cp ./target/planetiler-openmaptiles-*-SNAPSHOT-with-deps.jar ../planetiler-openmaptiles.jar
    )
    rm -rf planetiler-openmaptiles
  fi

  if [ ! -f ./spritegen ] || [ ! -f ./planetiler-protomaps.jar ]; then
    if [ ! -d ./protomaps-basemaps ]; then
      (
        # Fork to limit zoom level to 14, add languages
        git clone --recurse-submodules --quiet https://github.com/maps-black/basemaps.git protomaps-basemaps
        cd protomaps-basemaps
        git checkout add-languages
      )
    fi
    (
      cd protomaps-basemaps/sprites
      cargo build --release
      mv ./target/release/spritegen $appdir/spritegen
    )
    (
      cd protomaps-basemaps/tiles
      mvn -DskipTests=true clean package
      mv ./target/protomaps-basemap-HEAD-with-deps.jar $appdir/planetiler-protomaps.jar
    )
  fi

  rm -rf ./protomaps-basemaps

  if [ ! -d ./npm-packages/node_modules ]; then
    (
      mkdir -p npm-packages
      cd npm-packages
      npm i "@maplibre/maplibre-gl-style-spec@${styleSpecVersion}"
      npm i "@maplibre/maplibre-gl-style-spec@${styleSpecVersion}"
    )
    ln -fs npm-packages/node_modules/.bin/gl-style-format gl-style-format
    ln -fs npm-packages/node_modules/.bin/gl-style-migrate gl-style-migrate
    ln -fs npm-packages/node_modules/.bin/gl-style-validate gl-style-validate
  fi

  if [ ! -d rio-mbtiles ]; then
    mkdir -p rio-mbtiles
    cd rio-mbtiles
    python3 -m venv .
    source ./bin/activate
    # TODO: Version-check
    pip install rio-mbtiles==1.6.0
  fi
}

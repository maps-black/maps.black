#!/usr/bin/env bash
set -xeuo pipefail
export LOCAL_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

. $LOCAL_SCRIPT_DIR/../utils.sh

build() {
  set -xeuo pipefail
  download_with_check http://planet.openstreetmap.org/pbf/planet-latest.osm.pbf

  # These are infrequently updated, so we skip checking them every run
  if [ ! -f lake_centerline.shp.zip ]; then
    download_with_check http://github.com/acalcutt/osm-lakelines/releases/download/v${lakelinesVersion}/lake_centerline.shp.zip
  fi

  if [ ! -f water-polygons-split-3857.zip ]; then
    download_with_check http://osmdata.openstreetmap.de/download/water-polygons-split-3857.zip
  fi

  if [ ! -f natural_earth_vector.sqlite.zip ]; then
    download_with_check http://naciscdn.org/naturalearth/packages/natural_earth_vector.sqlite.zip
  fi

  if [ ! -f planetilershortbread.zip ]; then
    download_with_check http://github.com/maps-black/naturalearthtiles-vector/releases/latest/download/planetilershortbread.zip
  fi

  if [ ! -f top_osm_tiles.tsv.gz ]; then
    download_with_check http://raw.githubusercontent.com/onthegomap/planetiler/main/layerstats/top_osm_tiles.tsv.gz
  fi

  if [ ! -f ./openstreetmap-shortbread.mbtiles ] || [[ ./planet-latest.osm.pbf -nt ./openstreetmap-shortbread.mbtiles ]]; then
    rm -f ./.openstreetmap-shortbread.mbtiles
    rm -rf data && mkdir -p data/sources
    # TODO: This requires internet access since it downloads wikidata, figure out how to proxy it
    java -Xmx60g \
      -Dcasc.yaml.max.aliases="1000" \
      -jar $appdir/planetiler.jar \
      generate-custom \
      --schema=$LOCAL_SCRIPT_DIR/shortbread.yml \
      --osm-path=./planet-latest.osm.pbf \
      --admin-points-path="./planetilershortbread.zip" \
      --lake-centerlines-path="./lake_centerline.shp.zip" \
      --ocean-path="./water-polygons-split-3857.zip" \
      --natural-earth-path="./natural_earth_vector.sqlite.zip" \
      --area=planet \
      --bounds=world \
      --download \
      --download-threads=10 \
      --download-chunk-size-mb=1000 \
      --fetch-wikidata \
      --output=./.openstreetmap-shortbread.mbtiles \
      --nodemap-type=array \
      --nodemap-storage=mmap
      mv -f ./.openstreetmap-shortbread.mbtiles ./openstreetmap-shortbread.mbtiles
      rm -rf data
  fi
  if [ ! -f ./openstreetmap-shortbread.pmtiles ] || [[ ./openstreetmap-shortbread.mbtiles -nt ./openstreetmap-shortbread.pmtiles ]]; then
    pmtiles convert ./openstreetmap-shortbread.mbtiles ./.openstreetmap-shortbread.pmtiles &&
      mv -f ./.openstreetmap-shortbread.pmtiles ./openstreetmap-shortbread.pmtiles
  fi

  if [ ! -f ./openstreetmap-openmaptiles.mbtiles ] || [[ ./planet-latest.osm.pbf -nt ./openstreetmap-openmaptiles.mbtiles ]]; then
    rm -f ./.openstreetmap-openmaptiles.mbtiles
    rm -rf data && mkdir -p data/sources
    java -Xmx60g \
      -jar $appdir/planetiler-openmaptiles.jar \
      --osm-path=./planet-latest.osm.pbf \
      --admin-points-path="./planetilershortbread.zip" \
      --lake-centerlines-path="./lake_centerline.shp.zip" \
      --water-polygons-path="./water-polygons-split-3857.zip" \
      --natural-earth-path="./natural_earth_vector.sqlite.zip" \
      --area=planet \
      --bounds=world \
      --download \
      --download-threads=10 \
      --download-chunk-size-mb=1000 \
      --fetch-wikidata \
      --output=./.openstreetmap-openmaptiles.mbtiles \
      --nodemap-type=array \
      --nodemap-storage=mmap
      mv -f ./.openstreetmap-openmaptiles.mbtiles ./openstreetmap-openmaptiles.mbtiles
      rm -rf data
  fi
  if [ ! -f ./openstreetmap-openmaptiles.pmtiles ] || [[ ./openstreetmap-openmaptiles.mbtiles -nt ./openstreetmap-openmaptiles.pmtiles ]]; then
    pmtiles convert ./openstreetmap-openmaptiles.mbtiles ./.openstreetmap-openmaptiles.pmtiles &&
      mv -f ./.openstreetmap-openmaptiles.pmtiles ./openstreetmap-openmaptiles.pmtiles
  fi

  if [ ! -f ./openstreetmap-protomaps.mbtiles ] || [[ ./planet-latest.osm.pbf -nt ./openstreetmap-protomaps.mbtiles ]]; then
    rm -f ./.openstreetmap-protomaps.mbtiles
    rm -rf data && mkdir -p data/sources
    java -Xmx60g \
      -jar $appdir/planetiler-protomaps.jar \
      --osm-path=./planet-latest.osm.pbf \
      --admin-points-path="./planetilershortbread.zip" \
      --lake-centerlines-path="./lake_centerline.shp.zip" \
      --water-polygons-path="./water-polygons-split-3857.zip" \
      --natural-earth-path="./natural_earth_vector.sqlite.zip" \
      --bounds=world \
      --download \
      --download-threads=10 \
      --download-chunk-size-mb=1000 \
      --fetch-wikidata \
      --output=./.openstreetmap-protomaps.mbtiles \
      --nodemap-type=array \
      --nodemap-storage=mmap
      mv -f ./.openstreetmap-protomaps.mbtiles ./openstreetmap-protomaps.mbtiles
      rm -rf data
  fi
  if [ ! -f ./openstreetmap-protomaps.pmtiles ] || [[ ./openstreetmap-protomaps.mbtiles -nt ./openstreetmap-protomaps.pmtiles ]]; then
    pmtiles convert ./openstreetmap-protomaps.mbtiles ./.openstreetmap-protomaps.pmtiles &&
      mv -f ./.openstreetmap-protomaps.pmtiles ./openstreetmap-protomaps.pmtiles
  fi
}

#!/usr/bin/env bash
set -xeuo pipefail
export SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

. $SCRIPT_DIR/../utils.sh

build_extracts() {
  pmtiles extract ../osm-vector/openstreetmap-openmaptiles.pmtiles openstreetmap-openmaptiles.pmtiles --bbox=8.508911,46.276733,10.681458,47.927386
  pmtiles extract ../osm-vector/openstreetmap-shortbread.pmtiles openstreetmap-shortbread.pmtiles --bbox=8.508911,46.276733,10.681458,47.927386
  pmtiles extract ../osm-vector/openstreetmap-protomaps.pmtiles openstreetmap-protomaps.pmtiles --bbox=8.508911,46.276733,10.681458,47.927386
  pmtiles extract ../s2maps/s2maps-sentinel2-2016.pmtiles s2maps-sentinel2-2016.pmtiles --bbox=8.508911,46.276733,10.681458,47.927386
  pmtiles extract ../s2maps/s2maps-sentinel2-2023.pmtiles s2maps-sentinel2-2023.pmtiles --bbox=8.508911,46.276733,10.681458,47.927386
  pmtiles extract ../terrarium/terrarium-z0-z10.pmtiles terrarium-z0-z10.pmtiles --bbox=8.508911,46.276733,10.681458,47.927386
}

build() {
  set -xeuo pipefail
  download_with_check_noproxy \
    https://github.com/maps-black/naturalearthtiles-vector/releases/latest/download/naturalearth-shortbread.pmtiles \
    https://github.com/maps-black/naturalearthtiles-vector/releases/latest/download/naturalearth-protomaps.pmtiles \
    https://github.com/maps-black/naturalearthtiles-vector/releases/latest/download/naturalearth-openmaptiles.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-GRAY_HR_DARK_OB_DR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-GRAY_HR_DARK_W_DR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-GRAY_HR_DARK-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-GRAY_HR_DARK_W-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-GRAY_HR_LIGHT_OB_DR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-GRAY_HR_LIGHT_W_DR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-GRAY_HR_LIGHT-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-GRAY_HR_LIGHT_W-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-HYP_HR_SR_OB_DR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-HYP_HR_SR_OB-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-HYP_HR_SR_W_DR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-HYP_HR_SR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-HYP_HR_SR_W-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-HYP_HR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-LC_HR_HD-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-NE1_HR_SR_OB_DR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-NE1_HR_SR_OB-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-NE1_HR_SR_W_DR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-NE1_HR_SR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-NE1_HR_SR_W-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-NE1_HR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-NE2_HR_SR_OB_DR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-NE2_HR_SR_OB-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-NE2_HR_SR_W_DR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-NE2_HR_SR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-NE2_HR_SR_W-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-NE2_HR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-OB_HR_DARK-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-OB_HR_LIGHT-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth6-SR_HR_UD-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth-GRAY_HR_SR_OB_DR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth-GRAY_HR_SR_OB-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth-GRAY_HR_SR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth-GRAY_HR_SR_W-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth-HYP_HR_SR_OB_DR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth-HYP_HR_SR_W_DR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth-HYP_HR_SR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth-HYP_HR_SR_W-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth-HYP_HR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth-NE1_HR_LC_SR_W_DR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth-NE1_HR_LC_SR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth-NE1_HR_LC_SR_W-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth-NE1_HR_LC-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth-NE2_HR_LC_SR_W_DR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth-NE2_HR_LC_SR-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth-NE2_HR_LC_SR_W-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth-NE2_HR_LC-WEBP.pmtiles \
    https://github.com/maps-black/naturalearthtiles-raster/releases/latest/download/naturalearth-SR_HR-WEBP.pmtiles \
    https://github.com/maps-black/resourcetiles/releases/latest/download/resourcetiles-minimal.pmtiles \
    https://github.com/maps-black/demo-extracts/releases/latest/download/openstreetmap-openmaptiles.pmtiles \
    https://github.com/maps-black/demo-extracts/releases/latest/download/openstreetmap-shortbread.pmtiles \
    https://github.com/maps-black/demo-extracts/releases/latest/download/openstreetmap-protomaps.pmtiles \
    https://github.com/maps-black/demo-extracts/releases/latest/download/s2maps-sentinel2-2016.pmtiles \
    https://github.com/maps-black/demo-extracts/releases/latest/download/s2maps-sentinel2-2023.pmtiles \
    https://github.com/maps-black/demo-extracts/releases/latest/download/terrarium-z0-z10.pmtiles
  (cd ../client && mkdir -p client && npm ci && npm run build)
  cp ../client/client/{index.html,maps.black-background.png,maps.black.js,maps.black.js.map,maps.black-component.js,maps.black-component.js.map} ./
  cp -r ../client/demo_images ./
  sed -i 's/<maps-black/<maps-black loader="pmtiles"/g' index.html
  rm -f ./build.sh
}

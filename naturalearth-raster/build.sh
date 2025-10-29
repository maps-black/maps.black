#!/usr/bin/env bash
set -xeuo pipefail
export SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

. $SCRIPT_DIR/../utils.sh

build() {
  if [ ! -d .process-naturalearth ]; then
    mkdir -p .process-naturalearth
  fi

  (
    set -xeuo pipefail
    mkdir -p upstream-naturalearth
    cd upstream-naturalearth &&
      download_with_check \
        https://naciscdn.org/naturalearth/10m/raster/HYP_HR.zip \
        https://naciscdn.org/naturalearth/10m/raster/HYP_HR_SR.zip \
        https://naciscdn.org/naturalearth/10m/raster/HYP_HR_SR_W.zip \
        https://naciscdn.org/naturalearth/10m/raster/HYP_HR_SR_W_DR.zip \
        https://naciscdn.org/naturalearth/10m/raster/HYP_HR_SR_OB_DR.zip \
        https://naciscdn.org/naturalearth/10m/raster/NE1_HR_LC.zip \
        https://naciscdn.org/naturalearth/10m/raster/NE1_HR_LC_SR.zip \
        https://naciscdn.org/naturalearth/10m/raster/NE1_HR_LC_SR_W.zip \
        https://naciscdn.org/naturalearth/10m/raster/NE1_HR_LC_SR_W_DR.zip \
        https://naciscdn.org/naturalearth/10m/raster/NE2_HR_LC.zip \
        https://naciscdn.org/naturalearth/10m/raster/NE2_HR_LC_SR.zip \
        https://naciscdn.org/naturalearth/10m/raster/NE2_HR_LC_SR_W.zip \
        https://naciscdn.org/naturalearth/10m/raster/NE2_HR_LC_SR_W_DR.zip \
        https://naciscdn.org/naturalearth/10m/raster/SR_HR.zip \
        https://naciscdn.org/naturalearth/10m/raster/GRAY_HR_SR.zip \
        https://naciscdn.org/naturalearth/10m/raster/GRAY_HR_SR_W.zip \
        https://naciscdn.org/naturalearth/10m/raster/GRAY_HR_SR_OB.zip \
        https://naciscdn.org/naturalearth/10m/raster/GRAY_HR_SR_OB_DR.zip
  )
  (
    set -xeuo pipefail
    mkdir -p upstream-naturalearth6
    cd upstream-naturalearth6 &&
      download_with_check \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/SR_HR_UD.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/NE1_HR_SR.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/NE1_HR_SR_W.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/NE1_HR_SR_W_DR.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/NE1_HR_SR_OB.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/NE1_HR_SR_OB_DR.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/NE2_HR_SR.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/NE2_HR_SR_W.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/NE2_HR_SR_W_DR.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/NE2_HR_SR_OB.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/NE2_HR_SR_OB_DR.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/HYP_HR.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/HYP_HR_SR.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/HYP_HR_SR_W.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/HYP_HR_SR_W_DR.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/HYP_HR_SR_OB.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/HYP_HR_SR_OB_DR.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/GRAY_HR_LIGHT.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/GRAY_HR_LIGHT_W.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/GRAY_HR_LIGHT_W_DR.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/GRAY_HR_LIGHT_OB_DR.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/GRAY_HR_DARK.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/GRAY_HR_DARK_W.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/GRAY_HR_DARK_W_DR.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/GRAY_HR_DARK_OB_DR.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/LC_HR_HD.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/OB_HR_LIGHT.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/OB_HR_DARK.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/NE2_HR.zip \
        https://naciscdn.org/naturalearth/6.0.0-pre3/10m/raster/NE1_HR.zip
  )

  (
    set -xeuo pipefail
    cd upstream-naturalearth
    for f in *.zip; do
      filename="${f##*/}"
      name="${filename/.zip/}"
      _newname="${name/Light/LIGHT}"
      newname="${_newname/Dark/DARK}"
      if [ -f "../naturalearth-$newname-WEBP.pmtiles" ]; then
        continue
      fi
      echo "Will build $f"
      unzip -q "$f" '*.tif'
    done
    mv ./*/*.tif ./ || true
    for f in *.tif; do
      if [ ! -f "$f" ]; then
        continue
      fi
      filename="${f##*/}"
      _newname="${filename/Light/LIGHT}"
      newname="${_newname/Dark/DARK}"
      mv "$f" "naturalearth-$newname"
    done
    mv -f *.tif ../.process-naturalearth/ || true
    find . -not -iname '*.zip' -delete
    find . -empty -delete
  )

  (
    set -xeuo pipefail
    cd upstream-naturalearth6
    for f in *.zip; do
      filename="${f##*/}"
      name="${filename/.zip/}"
      _newname="${name/Light/LIGHT}"
      newname="${_newname/Dark/DARK}"
      if [ -f "../naturalearth6-$newname-WEBP.pmtiles" ]; then
        continue
      fi
      echo "Will build $f"
      unzip -q "$f" '*.tif'
    done
    mv ./*/*.tif ./ || true
    for f in *.tif; do
      if [ ! -f "$f" ]; then
        continue
      fi
      filename="${f##*/}"
      _newname="${filename/Light/LIGHT}"
      newname="${_newname/Dark/DARK}"
      mv "$f" "naturalearth6-$newname"
    done
    mv -f *.tif ../.process-naturalearth/ || true
    find . -not -iname '*.zip' -delete
    find . -empty -delete
  )

  # Function to be used in parallel execution to optimize png
  png_pngquant() {
    f="$1"
    (pngquant --force --skip-if-larger --speed 1 --strip --quality=80-90 --output "$f" "$f" || true) >/dev/null
  }
  export -f png_pngquant

  # Function to be used in parallel execution to convert to webp
  convert_to_webp() {
    set -xeuo pipefail
    f="$1"
    newpath="${f/.png/}.webp"
    cwebp -m 6 -quiet -q 90 "$f" -o "$newpath"
    rm -rf "$f"
  }
  export -f convert_to_webp

  (
    set -xeuo pipefail
    cd .process-naturalearth
    for f in ./*.tif; do
      if [ ! -f "$f" ]; then
        continue
      fi
      source $appdir/rio-mbtiles/bin/activate
      filename="${f##*/}"
      name="${filename/.tif/}"
      GDAL_CACHEMAX=4096 rio --quiet mbtiles "$f" --resampling q1 --tile-size 512 -f PNG --co ZLEVEL=1 -o "./$name.mbtiles" --zoom-levels 0..6
      rm -rf "$f"
      mb-util --silent "./$name.mbtiles" "./$name-PNG" --image_format="png"
      rm -rf "./$name.mbtiles"
      cp -r "./$name-PNG" "./$name-WEBP"
      jq --arg description "$name" '.description = $description' ./$name-PNG/metadata.json | sponge ./$name-PNG/metadata.json
      parallel -j 16 --ungroup --no-notice png_pngquant {} ::: ./$name-PNG/*/*/*.png
      oxipng -r -q --zopfli -o max --fast --strip safe --alpha ./$name-PNG/
      mb-util --silent "./$name-PNG" "./$name-PNG.mbtiles" --image_format="png"
      rm -rf "./$name-PNG"
      pmtiles convert "./$name-PNG.mbtiles" "./$name-PNG.pmtiles"
      mv -f "./$name-PNG.mbtiles" "../$name-PNG.mbtiles"
      mv -f "./$name-PNG.pmtiles" "../$name-PNG.pmtiles"
      jq --arg format "webp" '.format = $format' ./$name-WEBP/metadata.json | sponge ./$name-WEBP/metadata.json
      parallel -j 16 --ungroup --no-notice convert_to_webp {} ::: ./$name-WEBP/*/*/*.png
      mb-util --silent "./$name-WEBP" "./$name-WEBP.mbtiles" --image_format="webp"
      rm -rf "./$name-WEBP"
      pmtiles convert "./$name-WEBP.mbtiles" "./$name-WEBP.pmtiles"
      mv -f "./$name-WEBP.mbtiles" "../$name-WEBP.mbtiles"
      mv -f "./$name-WEBP.pmtiles" "../$name-WEBP.pmtiles"
      link_all
    done
  )
}

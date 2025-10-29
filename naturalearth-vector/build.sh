#! /usr/bin/env bash
set -xeuo pipefail
export LOCAL_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

. $LOCAL_SCRIPT_DIR/../utils.sh

build() {
  set -xeuo pipefail
  maxZoom="${maxZoom:-8}"

  # TODO: Check how this check should work
  if [[ ./build.sh -nt "./naturalearth-protomaps.pmtiles" ]]; then
    return 0
  fi

  if [ ! -d natural_earth_vector ]; then
    curl --unix-socket $SCRIPT_DIR/../../runtime/nginx-forward.sock -LO https://naciscdn.org/naturalearth/packages/natural_earth_vector.zip
    mkdir -p natural_earth_vector
    unzip natural_earth_vector.zip -d natural_earth_vector
    rm -rf natural_earth_vector.zip
  fi

  if [ ! -d World-Base-Map-Shapefiles ]; then
    curl --unix-socket $SCRIPT_DIR/../../runtime/nginx-forward.sock -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:133.0) Gecko/20100101 Firefox/133.0' -LO https://www.shadedrelief.com/ne-draft/World-Base-Map-Shapefiles.zip
    mkdir -p World-Base-Map-Shapefiles
    unzip World-Base-Map-Shapefiles.zip -d World-Base-Map-Shapefiles
    rm -rf World-Base-Map-Shapefiles.zip
  fi

  mkdir -p geojson-ne
  for shapefile in ./natural_earth_vector/*/*.shp; do
    pathExtLess="${shapefile/.shp/}"
    filename="${shapefile##*/}"
    dirpath="$(dirname "$shapefile")"
    name="${filename/.shp/}"
    if [ -f $pathExtLess.prj ] && [ ! -f ./geojson-ne/$name.json ]; then
      ogr2ogr -f GeoJSON -s_srs $pathExtLess.prj -t_srs EPSG:4326 ./geojson-ne/$name.json $pathExtLess.shp
    fi
  done

  mkdir -p geojson-ne6
  for shapefile in ./World-Base-Map-Shapefiles/World-Base-Map-Shapefiles/*.shp ./World-Base-Map-Shapefiles/World-Base-Map-Shapefiles/*/*.shp; do
    pathExtLess="${shapefile/.shp/}"
    filename="${shapefile##*/}"
    dirpath="$(dirname "$shapefile")"
    name="${filename/.shp/}"
    if [ -f $pathExtLess.prj ] && [ ! -f ./geojson-ne6/$name.json ]; then
      ogr2ogr -f GeoJSON -s_srs $pathExtLess.prj -t_srs EPSG:4326 ./geojson-ne6/$name.json $pathExtLess.shp
    fi
  done

  if [ ! -f wikidata.json ]; then
    $LOCAL_SCRIPT_DIR/download_wikidata_translations.js
  fi

  if [ ! -f ne6.mbtiles ]; then
    tippecanoe --no-progress-indicator -zg --coalesce-densest-as-needed --extend-zooms-if-still-dropping -o ne6.mbtiles --drop-densest-as-needed ./geojson-ne6/*.json
  fi
  if [ ! -f ne_10m.mbtiles ]; then
    tippecanoe --no-progress-indicator -zg --coalesce-densest-as-needed --extend-zooms-if-still-dropping -o ne_10m.mbtiles --drop-densest-as-needed ./geojson-ne/ne_10m_*.json
  fi
  if [ ! -f ne_50m.mbtiles ]; then
    tippecanoe --no-progress-indicator -zg --coalesce-densest-as-needed --extend-zooms-if-still-dropping -o ne_50m.mbtiles --drop-densest-as-needed ./geojson-ne/ne_50m_*.json
  fi
  if [ ! -f ne_110m.mbtiles ]; then
    tippecanoe --no-progress-indicator -zg --coalesce-densest-as-needed --extend-zooms-if-still-dropping -o ne_110m.mbtiles --drop-densest-as-needed ./geojson-ne/ne_110m_*.json
  fi

  keepFieldsshortbread="
wikidataid
ne_id
name
name_en
name_de
population
kind
rail
maritime
admin_level
way_area
iata
disputed
historic
"

  keepFieldsprotomaps="
wikidataid
ne_id
name
sort_rank
min_zoom
kind
kind_detail
brk_a3
disputed
kind
capital
population
population_rank
wikidata
iata
alkaline
intermittent
"

  keepFieldsopenmaptiles="
wikidataid
ne_id
name
name_en
name_de
iata
iso_a2
adm0_r
adm0_l
class
subclass
disputed
disputed_name
claimed_by
rank
admin_level
"

  keepFieldsplanetilershortbread="
admin_level
way_area
"

  wikidatalanguages="
name:ang
name:arc
name:arq
name:ary
name:as
name:ast
name:av
name:avk
name:awa
name:ay
name:azb
name:ba
name:ban
name:bcl
name:be-tarask
name:bho
name:bi
name:bjn
name:blk
name:bm
name:bn
name:bo
name:bpy
name:brh
name:bs
name:bxr
name:cdo
name:ce
name:ceb
name:chr
name:chy
name:ckb
name:crh
name:crh-latn
name:csb
name:cu
name:cv
name:dag
name:din
name:diq
name:dsb
name:dty
name:dz
name:et
name:ext
name:ff
name:fi
name:fit
name:fj
name:fo
name:frr
name:fur
name:gag
name:gan
name:gcr
name:gd
name:glk
name:gn
name:gom
name:got
name:gu
name:guw
name:ha
name:hak
name:haw
name:hsb
name:ht
name:ig
name:ik
name:ilo
name:inh
name:iu
name:jam
name:jbo
name:kaa
name:kab
name:kbd
name:kbp
name:kcg
name:kg
name:ki
name:kk
name:kl
name:km
name:kn
name:ko-kp
name:koi
name:krc
name:ks
name:ksh
name:ku
name:kv
name:kw
name:ky
name:lad
name:lez
name:lg
name:lld
name:lrc
name:ltg
name:lzh
name:mai
name:mdf
name:mhr
name:mi
name:ml
name:mn
name:mni
name:mnw
name:mrj
name:ms-arab
name:mt
name:mwl
name:my
name:myv
name:mzn
name:na
name:nan
name:ne
name:new
name:nov
name:nqo
name:nso
name:nv
name:olo
name:om
name:or
name:os
name:pa
name:pag
name:pam
name:pcd
name:pdc
name:pih
name:pms
name:pnb
name:pnt
name:ps
name:rmy
name:rn
name:roa-tara
name:rue
name:rw
name:sa
name:sah
name:sat
name:sc
name:scn
name:sco
name:sd
name:se
name:sg
name:sgs
name:shi
name:shn
name:skr
name:sm
name:smn
name:sms
name:so
name:srn
name:ss
name:st
name:stq
name:szl
name:szy
name:ta
name:tcy
name:te
name:tet
name:tg
name:th
name:ti
name:tk
name:tl
name:tn
name:to
name:tok
name:tpi
name:ts
name:tt
name:tt-cyrl
name:tt-latn
name:tum
name:tw
name:ty
name:tyv
name:udm
name:ug
name:ur
name:uz
name:ve
name:vep
name:vi
name:vo
name:vro
name:wa
name:war
name:wo
name:wuu
name:eu
name:gsw
name:hr
name:id
name:io
name:is
name:lb
name:mg
name:min
name:ms
name:nds
name:pl
name:sr-el
name:sw
name:tr
name:el
name:eo
name:la
name:lt
name:sr-ec
name:ab
name:ace
name:ady
name:aeb-arab
name:am
name:ami
name:an
name:atj
name:az
name:bgn
name:cbk-zam
name:ch
name:co
name:cr
name:dv
name:ee
name:eml
name:ga
name:gl
name:gom-deva
name:gom-latn
name:gor
name:hi
name:hif
name:hy
name:hyw
name:jv
name:kea
name:ko
name:krj
name:lbe
name:lfn
name:lmo
name:ln
name:lo
name:lv
name:mad
name:map-bms
name:mk
name:mr
name:nah
name:nap
name:nds-nl
name:pi
name:pt
name:pt-br
name:qu
name:rup
name:ro
name:es
name:he
name:ar
name:en-ca
name:da
name:nb
name:nn
name:sh
name:sv
name:hu
name:zh-hant
name:be
name:oc
name:zh
name:af
name:aln
name:alt
name:arz
name:bar
name:bg
name:br
name:bug
name:cs
name:cy
name:de-at
name:de-ch
name:shy
name:shy-latn
name:si
name:smj
name:sn
name:sq
name:su
name:tay
name:tg-cyrl
name:trv
name:vec
name:xal
name:yi
name:yo
name:yue
name:za
name:zea
name:zh-cn
name:zh-hans
name:zh-hk
name:zh-mo
name:zh-my
name:zh-sg
name:zh-tw
name:zu
name:kr
name:sdc
name:en-us
name:anp
name:gpe
name:mos
name:syl
name:tly
name:xh
name:nod
name:bbc
name:zgh
name:dtp
name:gv
name:grc
name:bew
name:btm
name:kge
name:iba
name:fon
name:crh-ro
name:ja
name:nl
name:ca
name:fa
name:en
name:de
name:it
name:fr
name:ru
name:en-gb
name:frp
name:fy
name:ia
name:ie
name:ka
name:ku-latn
name:li
name:lij
name:mh
name:mo
name:nia
name:nrm
name:ny
name:pap
name:pcm
name:pfl
name:pwn
name:rm
name:sk
name:sl
name:sr
name:xmf
name:guc
name:sma
name:fat
name:dga
name:ann
name:nr
name:uk
name:vls
name:mul
name:frc
name:hil
name:liv
name:wls
name:ryu
name:rki
name:igl
name:bdr
name:tdd
name:sje
name:sju
name:sjd
name:qug
name:rmc
name:rmf
name:sh-cyrl
name:kk-cyrl
name:tg-latn
name:kk-latn
name:ii
name:isv-latn
name:prg
name:crh-cyrl
name:es-419
name:ku-arab
name:ike-latn
name:kjp
name:apc
name:gur
name:pdt
name:ug-arab
name:ug-latn
name:ng
name:rgn
name:pap-aw
name:vmf
name:cps
name:mag
name:nan-hani
name:cop
name:kus
name:aa
name:aeb-latn
name:rsk
name:gaa
name:ak
name:arn
name:cho
name:hif-latn
name:ho
name:hz
name:kj
name:kk-tr
name:loz
name:lus
name:lzz
name:mus
name:rif
name:ruq-latn
name:sei
name:shi-latn
name:kk-arab
name:kk-cn
name:kk-kz
name:sli
name:tru
name:vot
name:ban-bali
name:tzm
name:ota
name:uz-cyrl
name:aeb
name:cnh
name:ks-arab
name:nan-hant
name:nan-latn-pehoeji
name:nan-latn-tailo
name:khw
name:gan-hans
name:gan-hant
name:mnc
name:tig
name:jut
name:kri
name:ruq
name:bto
name:simple
name:krl
name:als
name:no
name:nys
name:egl
name:hrx
name:niu
name:fkv
name:bbc-latn
name:wuu-hans
name:uz-latn
name:lua
name:yue-hant
name:sdh
name:wuu-hant
name:wal
name:ibb
name:bci
name:ike-cans
name:es-formal
name:xsy
name:rut
"

  maplanguages="
name
name_de
name_en
name_ar
name_bn
name_es
name_fr
name_el
name_hi
name_hu
name_id
name_it
name_ja
name_ko
name_nl
name_pl
name_pt
name_ru
name_sv
name_tr
name_vi
name_zh
name_fa
name_he
name_uk
name_ur
name_zht
"

  includeFlags() {
    set -xeuo pipefail
    schema="${1}"
    if [ "$schema" = "shortbread" ]; then
      for keepField in $keepFieldsshortbread; do
        printf -- '--include=%s ' "$keepField"
      done
    fi

    if [ "$schema" = "protomaps" ]; then
      for keepField in $keepFieldsprotomaps; do
        printf -- '--include=%s ' "$keepField"
      done
    fi

    if [ "$schema" = "openmaptiles" ]; then
      for keepField in $keepFieldsopenmaptiles; do
        printf -- '--include=%s ' "$keepField"
      done
    fi

    if [ "$schema" = "planetilershortbread" ]; then
      for keepField in $keepFieldsplanetilershortbread; do
        printf -- '--include=%s ' "$keepField"
      done
    fi

    for languageField in $maplanguages; do
      printf -- '--include=%s ' "${languageField/_/:}"
    done

    for languageField in $wikidatalanguages; do
      printf -- '--include=%s ' "$languageField"
    done
  }

  prepGeoJson() {
    set -xeuo pipefail
    schema="${1}"
    source="${2}"
    mkdir -p $schema-geojsonprep
    if [ ! -f $schema-geojsonprep/$source.json ]; then
      # TODO: Move all of these steps into the node process. Should be quicker and since you require node now anyway it's easier
      cp -r ./geojson-ne/$source.json $schema-geojsonprep/$source.json
      for fixfield in $maplanguages $keepFieldsshortbread $keepFieldsprotomaps $keepFieldsopenmaptiles $keepFieldsplanetilershortbread; do
        upper="$(tr '[:lower:]' '[:upper:]' <<<$fixfield)"
        jq -r '.features = (.features | map(.properties."'$fixfield'" = (.properties.'$upper' // .properties.'$fixfield')))' $schema-geojsonprep/$source.json | sponge $schema-geojsonprep/$source.json
      done

      # Remap naturalearth names to english before adding other languages
      jq -r '.features = (.features | map(.properties.name_en = (.properties.name_en // .properties.name)))' $schema-geojsonprep/$source.json | sponge $schema-geojsonprep/$source.json

      for languageField in $maplanguages; do
        jq -r '.features = (.features | map(.properties."'${languageField/_/:}'" = .properties.'$languageField'))' $schema-geojsonprep/$source.json | sponge $schema-geojsonprep/$source.json
      done

      jq -r '.features = (.features | map(.properties.wikidata = .properties.wikidataid))' $schema-geojsonprep/$source.json | sponge $schema-geojsonprep/$source.json

      if [[ "$source" == *"populated_places"* ]]; then
        jq -r '.features = (.features | map(.properties.population = ((.properties.POP_MAX // 0)|tonumber|floor)))' $schema-geojsonprep/$source.json | sponge $schema-geojsonprep/$source.json
      fi
      if [[ "$source" == *"admin"* ]]; then
        jq -r '.features = (.features | map(.properties.population = ((.properties.POP_EST // 0)|tonumber|floor)))' $schema-geojsonprep/$source.json | sponge $schema-geojsonprep/$source.json
        jq -r '.features = (.features | map(.properties.adm0_r = .properties.ADM0_RIGHT))' $schema-geojsonprep/$source.json | sponge $schema-geojsonprep/$source.json
        jq -r '.features = (.features | map(.properties.adm0_l = .properties.ADM0_LEFT))' $schema-geojsonprep/$source.json | sponge $schema-geojsonprep/$source.json
      fi
      if [[ "$source" == *"airport"* ]]; then
        jq -r '.features = (.features | map(.properties.iata = .properties.iata_code))' $schema-geojsonprep/$source.json | sponge $schema-geojsonprep/$source.json
      fi

      $LOCAL_SCRIPT_DIR/add_way_area.js $schema-geojsonprep/$source.json
      $LOCAL_SCRIPT_DIR/add_wikidata_languages.js $schema-geojsonprep/$source.json
    fi
  }

  filter_prop_larger() {
    set -xeuo pipefail
    schema="${1}"
    source="${2}"
    name="${3}"
    key="${4}"
    value="${5}"
    if [ ! -f $schema-geojsonprep/$name.json ]; then
      if [ ! -f $schema-geojsonprep/$source.json ]; then
        prepGeoJson $schema $source
      fi
      jq --arg KEY "$key" -r '.features = [(.features[] | select(.properties[$KEY] > '$value'))]' $schema-geojsonprep/$source.json | sponge $schema-geojsonprep/$name.json
    fi
  }

  filter_prop_not_larger() {
    set -xeuo pipefail
    schema="${1}"
    source="${2}"
    name="${3}"
    key="${4}"
    value="${5}"
    if [ ! -f $schema-geojsonprep/$name.json ]; then
      if [ ! -f $schema-geojsonprep/$source.json ]; then
        prepGeoJson $schema $source
      fi
      jq --arg KEY "$key" -r '.features = [(.features[] | select(.properties[$KEY] < '$value'))]' $schema-geojsonprep/$source.json | sponge $schema-geojsonprep/$name.json
    fi
  }

  filter_prop() {
    set -xeuo pipefail
    schema="${1}"
    source="${2}"
    name="${3}"
    key="${4}"
    value="${5}"
    if [ ! -f $schema-geojsonprep/$name.json ]; then
      if [ ! -f $schema-geojsonprep/$source.json ]; then
        prepGeoJson $schema $source
      fi
      jq --arg KEY "$key" --arg VALUE "$value" -r '.features = [(.features[] | select(.properties[$KEY] == $VALUE))]' $schema-geojsonprep/$source.json | sponge $schema-geojsonprep/$name.json
    fi
  }

  filter_not_prop() {
    set -xeuo pipefail
    schema="${1}"
    source="${2}"
    name="${3}"
    key="${4}"
    value="${5}"
    if [ ! -f $schema-geojsonprep/$name.json ]; then
      if [ ! -f $schema-geojsonprep/$source.json ]; then
        prepGeoJson $schema $source
      fi
      jq --arg KEY "$key" --arg VALUE "$value" -r '.features = [(.features[] | select(.properties[$KEY] != $VALUE))]' $schema-geojsonprep/$source.json | sponge $schema-geojsonprep/$name.json
    fi
  }

  mapped_layer() {
    set -xeuo pipefail
    schema="${1}"
    name="${2}"
    source="${3}"
    zoomFrom="${4:-0}"
    zoomTo="${5:-$maxZoom}"
    additionalAttributes="${6:-{}}"
    prepGeoJson $schema $source
    mkdir -p $schema-layers
    # Check that the mbtiles does not exist and that we have features to map
    if [ ! -f "$schema-layers/$name-$source-$zoomFrom-$zoomTo.mbtiles" ] && jq -e '.features[0]' "$schema-geojsonprep/$source.json" >/dev/null; then
      tippecanoe -r1 --no-progress-indicator -Z$zoomFrom -z$zoomTo --coalesce-densest-as-needed --extend-zooms-if-still-dropping -o "$schema-layers/$name-$source-$zoomFrom-$zoomTo.mbtiles" --drop-densest-as-needed $(includeFlags $schema) -l "$name" --set-attribute="$additionalAttributes" "$schema-geojsonprep/$source.json"
    fi
  }

  mapped_layer_to_point() {
    set -xeuo pipefail
    schema="${1}"
    name="${2}"
    source="${3}"
    zoomFrom="${4:-0}"
    zoomTo="${5:-$maxZoom}"
    additionalAttributes="${6:-{}}"
    prepGeoJson $schema $source
    mkdir -p $schema-layers
    # Check that the mbtiles does not exist and that we have features to map
    if [ ! -f "$schema-layers/$name-$source-$zoomFrom-$zoomTo.mbtiles" ] && jq -e '.features[0]' "$schema-geojsonprep/$source.json" >/dev/null; then
      tippecanoe -r1 --no-progress-indicator -Z$zoomFrom -z$zoomTo --coalesce-densest-as-needed --extend-zooms-if-still-dropping -o "$schema-layers/$name-$source-$zoomFrom-$zoomTo.mbtiles" --convert-polygons-to-label-points --drop-densest-as-needed $(includeFlags $schema) -l "$name" --set-attribute="$additionalAttributes" "$schema-geojsonprep/$source.json"
    fi
  }

  bundle_all() {
    set -xeuo pipefail
    schema="${1}"
    if [ ! -f "./naturalearth-$schema.mbtiles" ]; then
      tile-join -pk -o ./naturalearth-$schema.mbtiles $schema-layers/*.mbtiles
    fi
  }

  # Start shortbread
  mapped_layer shortbread ocean ne_110m_ocean 0 2
  mapped_layer shortbread ocean ne_50m_ocean 3 4
  mapped_layer shortbread ocean ne_10m_ocean 5

  mapped_layer shortbread land ne_10m_parks_and_protected_lands_area 8 $maxZoom '{"kind": "park"}'

  mapped_layer shortbread water_polygons ne_110m_lakes 4 5
  mapped_layer shortbread water_polygons ne_50m_lakes 6 7
  mapped_layer shortbread water_polygons ne_10m_lakes 8
  mapped_layer shortbread water_polygons ne_10m_lakes_australia 8
  mapped_layer shortbread water_polygons ne_10m_lakes_europe 8
  mapped_layer shortbread water_polygons ne_10m_lakes_north_america 8

  mapped_layer_to_point shortbread water_polygons_labels ne_110m_lakes 4 5
  mapped_layer_to_point shortbread water_polygons_labels ne_50m_lakes 6 7
  mapped_layer_to_point shortbread water_polygons_labels ne_10m_lakes 8
  mapped_layer_to_point shortbread water_polygons_labels ne_10m_lakes_australia 8
  mapped_layer_to_point shortbread water_polygons_labels ne_10m_lakes_europe 8
  mapped_layer_to_point shortbread water_polygons_labels ne_10m_lakes_north_america 8

  mapped_layer shortbread water_lines ne_50m_rivers_lake_centerlines 3 4
  mapped_layer shortbread water_lines ne_10m_rivers_lake_centerlines 5
  mapped_layer shortbread water_lines ne_10m_rivers_lake_centerlines_scale_rank 5
  mapped_layer shortbread water_lines ne_10m_rivers_australia 5
  mapped_layer shortbread water_lines ne_10m_rivers_europe 5
  mapped_layer shortbread water_lines ne_10m_rivers_north_america 5

  filter_prop shortbread ne_50m_admin_0_boundary_lines_land filtered_ne_50m_admin_0_boundary_lines_land_disputed FEATURECLA 'Disputed (please verify)'
  filter_not_prop shortbread ne_50m_admin_0_boundary_lines_land filtered_ne_50m_admin_0_boundary_lines_land_not_disputed FEATURECLA 'Disputed (please verify)'

  filter_prop shortbread ne_50m_admin_0_boundary_lines_maritime_indicator filtered_ne_50m_admin_0_boundary_lines_maritime_indicator_disputed FEATURECLA 'Marine Indicator Disputed'
  filter_not_prop shortbread ne_50m_admin_0_boundary_lines_maritime_indicator filtered_ne_50m_admin_0_boundary_lines_maritime_indicator_not_disputed FEATURECLA 'Marine Indicator Disputed'

  filter_prop shortbread ne_10m_admin_0_boundary_lines_land filtered_ne_10m_admin_0_boundary_lines_land_disputed FEATURECLA 'Disputed (please verify)'
  filter_not_prop shortbread ne_10m_admin_0_boundary_lines_land filtered_ne_10m_admin_0_boundary_lines_land_not_disputed FEATURECLA 'Disputed (please verify)'

  filter_prop shortbread ne_10m_admin_0_boundary_lines_maritime_indicator filtered_ne_10m_admin_0_boundary_lines_maritime_indicator_disputed FEATURECLA 'Marine Indicator Disputed'
  filter_not_prop shortbread ne_10m_admin_0_boundary_lines_maritime_indicator filtered_ne_10m_admin_0_boundary_lines_maritime_indicator_not_disputed FEATURECLA 'Marine Indicator Disputed'

  mapped_layer shortbread boundaries filtered_ne_50m_admin_0_boundary_lines_land_disputed 3 4 '{"admin_level": 2, "disputed": true}'
  mapped_layer shortbread boundaries filtered_ne_50m_admin_0_boundary_lines_land_not_disputed 3 4 '{"admin_level": 2, "disputed": false}'

  mapped_layer shortbread boundaries filtered_ne_50m_admin_0_boundary_lines_maritime_indicator_disputed 3 4 '{"maritime": true, "admin_level": 2, "disputed": true}'
  mapped_layer shortbread boundaries filtered_ne_50m_admin_0_boundary_lines_maritime_indicator_not_disputed 3 4 '{"maritime": true, "admin_level": 2, "disputed": false}'

  mapped_layer shortbread boundaries filtered_ne_10m_admin_0_boundary_lines_land_disputed 5 $maxZoom '{"admin_level": 2, "disputed": true}'
  mapped_layer shortbread boundaries filtered_ne_10m_admin_0_boundary_lines_land_not_disputed 5 $maxZoom '{"admin_level": 2, "disputed": false}'

  mapped_layer shortbread boundaries filtered_ne_10m_admin_0_boundary_lines_maritime_indicator_disputed 5 $maxZoom '{"maritime": true, "admin_level": 2, "disputed": true}'
  mapped_layer shortbread boundaries filtered_ne_10m_admin_0_boundary_lines_maritime_indicator_not_disputed 5 $maxZoom '{"maritime": true, "admin_level": 2, "disputed": false}'

  mapped_layer shortbread boundaries ne_10m_admin_1_states_provinces_lines 5 $maxZoom '{"admin_level": 4}'
  mapped_layer shortbread boundaries ne_10m_admin_2_counties_lines 8 $maxZoom '{"admin_level": 6}'

  mapped_layer_to_point shortbread boundary_labels ne_10m_admin_0_countries 3 6 '{"admin_level": 2}'
  mapped_layer_to_point shortbread boundary_labels ne_10m_admin_1_states_provinces 5 $maxZoom '{"admin_level": 4}'
  mapped_layer_to_point shortbread boundary_labels ne_10m_admin_2_counties 8 $maxZoom '{"admin_level": 6}'

  # FEATURECLA value:
  # "Admin-0 capital": z4, kind=capital
  # "Admin-1 region capital": z4, kind=state_capital

  # For non-capitals: POP_MAX value:
  # 100,000+: z6, kind=city
  # 5000+: z7, kind=town
  # 100+: z10, kind=village
  # 50+: z10, kind=hamlet
  # 0: z10, kind=locality

  filter_prop shortbread ne_10m_populated_places filtered_ne_10m_populated_places_capital0 FEATURECLA 'Admin-0 capital'
  filter_not_prop shortbread ne_10m_populated_places filtered_ne_10m_populated_places_no_capital0 FEATURECLA 'Admin-0 capital'

  filter_prop shortbread filtered_ne_10m_populated_places_no_capital0 filtered_ne_10m_populated_places_capital0_alt FEATURECLA 'Admin-0 capital alt'
  filter_not_prop shortbread filtered_ne_10m_populated_places_no_capital0 filtered_ne_10m_populated_places_no_capital0_alt FEATURECLA 'Admin-0 capital alt'

  filter_prop shortbread filtered_ne_10m_populated_places_no_capital0_alt filtered_ne_10m_populated_places_regioncapital0 FEATURECLA 'Admin-0 region capital'
  filter_not_prop shortbread filtered_ne_10m_populated_places_no_capital0_alt filtered_ne_10m_populated_places_no_reigoncapital0 FEATURECLA 'Admin-0 region capital'

  filter_prop shortbread filtered_ne_10m_populated_places_no_reigoncapital0 filtered_ne_10m_populated_places_capital1 FEATURECLA 'Admin-1 capital'
  filter_not_prop shortbread filtered_ne_10m_populated_places_no_reigoncapital0 filtered_ne_10m_populated_places_no_capital1 FEATURECLA 'Admin-1 capital'

  filter_prop shortbread filtered_ne_10m_populated_places_no_capital1 filtered_ne_10m_populated_places_regioncapital1 FEATURECLA 'Admin-1 region capital'
  filter_not_prop shortbread filtered_ne_10m_populated_places_no_capital1 filtered_ne_10m_populated_places_no_capital FEATURECLA 'Admin-1 region capital'

  filter_prop_larger shortbread filtered_ne_10m_populated_places_no_capital filtered_ne_10m_populated_places_no_capital_100000 POP_MAX 100000
  filter_prop_not_larger shortbread filtered_ne_10m_populated_places_no_capital filtered_ne_10m_populated_places_no_capital_no_100000 POP_MAX 100000

  filter_prop_larger shortbread filtered_ne_10m_populated_places_no_capital_no_100000 filtered_ne_10m_populated_places_no_capital_5000 POP_MAX 5000
  filter_prop_not_larger shortbread filtered_ne_10m_populated_places_no_capital_no_100000 filtered_ne_10m_populated_places_no_capital_no_5000 POP_MAX 5000

  filter_prop_larger shortbread filtered_ne_10m_populated_places_no_capital_no_5000 filtered_ne_10m_populated_places_no_capital_100 POP_MAX 100
  filter_prop_not_larger shortbread filtered_ne_10m_populated_places_no_capital_no_5000 filtered_ne_10m_populated_places_no_capital_no_100 POP_MAX 100

  filter_prop_larger shortbread filtered_ne_10m_populated_places_no_capital_no_100 filtered_ne_10m_populated_places_no_capital_50 POP_MAX 50
  filter_prop_not_larger shortbread filtered_ne_10m_populated_places_no_capital_no_100 filtered_ne_10m_populated_places_no_capital_no_50 POP_MAX 50

  mapped_layer shortbread place_labels filtered_ne_10m_populated_places_capital0 4 $maxZoom '{"kind": "capital"}'
  mapped_layer shortbread place_labels filtered_ne_10m_populated_places_capital0_alt 4 $maxZoom '{"kind": "capital"}'
  mapped_layer shortbread place_labels filtered_ne_10m_populated_places_regioncapital0 4 $maxZoom '{"kind": "capital"}'
  mapped_layer shortbread place_labels filtered_ne_10m_populated_places_capital1 6 $maxZoom '{"kind": "state_capital"}'
  mapped_layer shortbread place_labels filtered_ne_10m_populated_places_regioncapital1 6 $maxZoom '{"kind": "state_capital"}'
  mapped_layer shortbread place_labels filtered_ne_10m_populated_places_no_capital_100000 6 $maxZoom '{"kind": "city"}'
  mapped_layer shortbread place_labels filtered_ne_10m_populated_places_no_capital_5000 7 $maxZoom '{"kind": "town"}'
  mapped_layer shortbread place_labels filtered_ne_10m_populated_places_no_capital_100 8 $maxZoom '{"kind": "village"}'    # Z10?
  mapped_layer shortbread place_labels filtered_ne_10m_populated_places_no_capital_50 8 $maxZoom '{"kind": "hamlet"}'      # Z10?
  mapped_layer shortbread place_labels filtered_ne_10m_populated_places_no_capital_no_50 8 $maxZoom '{"kind": "locality"}' # Z10?

  # "Major Highway": motorway
  # "Secondary Highway": trunk
  # "Road": road
  # "Unknown": road
  filter_prop shortbread ne_10m_roads filtered_ne_10m_roads_ferries featurecla Ferry
  filter_not_prop shortbread ne_10m_roads filtered_ne_10m_roads_land_nofeature_ferry featurecla Ferry
  filter_prop shortbread filtered_ne_10m_roads_land_nofeature_ferry filtered_ne_10m_roads_type_ferry type 'Ferry Route'
  filter_not_prop shortbread filtered_ne_10m_roads_land_nofeature_ferry filtered_ne_10m_roads_land type 'Ferry Route'

  filter_prop shortbread filtered_ne_10m_roads_land filtered_ne_10m_roads_primary type 'Major Highway'
  filter_not_prop shortbread filtered_ne_10m_roads_land filtered_ne_10m_roads_no_primary type 'Major Highway'

  filter_prop shortbread filtered_ne_10m_roads_no_primary filtered_ne_10m_roads_secondary type 'Secondary Highway'
  filter_not_prop shortbread filtered_ne_10m_roads_no_primary filtered_ne_10m_roads_no_secondary type 'Secondary Highway'

  # TODO: Maybe use ne_10m_roads_north_america for north america
  mapped_layer shortbread streets filtered_ne_10m_roads_primary 6 $maxZoom '{"kind": "motorway"}'
  mapped_layer shortbread streets filtered_ne_10m_roads_secondary 8 $maxZoom '{"kind": "trunk"}'
  mapped_layer shortbread streets filtered_ne_10m_roads_no_secondary 8 $maxZoom '{"kind": "road"}' # Z10?
  # TODO: Maybe use ne_10m_railroads_north_america for north america
  filter_not_prop shortbread ne_10m_railroads filtered_ne_10m_railroads_land featurecla 'Railroad ferry'
  mapped_layer shortbread streets filtered_ne_10m_railroads_land 8 $maxZoom '{"kind": "rail", "rail": true}'

  mapped_layer shortbread ferries filtered_ne_10m_roads_ferries 8 $maxZoom '{"kind": "ferry"}'
  mapped_layer shortbread ferries filtered_ne_10m_roads_type_ferry 8 $maxZoom '{"kind": "ferry"}'
  filter_prop shortbread ne_10m_railroads filtered_ne_10m_rail_ferries featurecla 'Railroad ferry'
  mapped_layer shortbread ferries filtered_ne_10m_rail_ferries 8 $maxZoom '{"kind": "ferry"}'

  mapped_layer shortbread public_transport ne_10m_airports 8 $maxZoom '{"kind": "aerodrome"}'   # Z10?
  mapped_layer shortbread public_transport ne_10m_ports 8 $maxZoom '{"kind": "ferry_terminal"}' # Z10?

  # Mapped POIs from ne_10m_parks_and_protected_lands_point
  # "National Monument" -> historic=monument
  # "National Monument and Historic Shrine" -> historic=monument
  # "National Battlefield Site" -> historic=battlefield
  # "National Battlefield Park" -> historic=battlefield
  # "National Battlefield" -> historic=battlefield
  # "National Memorial" -> historic=memorial
  # "Memorial Parkway" -> historic=memorial
  # "Memorial" -> historic=memorial

  # Unmapped POIs from ne_10m_parks_and_protected_lands_point
  # "National Park"
  # "National Historical Park"
  # "National Preserve"
  # "National Historic Site"
  # "National Historical Park and Ecological Preserve"
  # "National Recreation Area"
  # "Park"
  # "National Historical Park and Preserve"
  # "National Military Park"
  # "Ecological and Historic Preserve"
  # "International Historic Site"
  # "National Historical Reserve"
  # "National Seashore"
  # "National Reserve"
  # "National Lakeshore"
  # "Scenic and Recreational River"
  # "National Scenic Trail"

  # historic=monument
  filter_prop shortbread ne_10m_parks_and_protected_lands_point filtered_ne_10m_parks_and_protected_lands_point_national_monument unit_type 'National Monument'
  mapped_layer shortbread pois filtered_ne_10m_parks_and_protected_lands_point_national_monument 8 $maxZoom '{"historic": "monument"}' # Z10?
  filter_prop shortbread ne_10m_parks_and_protected_lands_point filtered_ne_10m_parks_and_protected_lands_point_national_monument_shrine unit_type 'National Monument and Historic Shrine'
  mapped_layer shortbread pois filtered_ne_10m_parks_and_protected_lands_point_national_monument_shrine 8 $maxZoom '{"historic": "monument"}' # Z10?

  # historic=battlefield
  filter_prop shortbread ne_10m_parks_and_protected_lands_point filtered_ne_10m_parks_and_protected_lands_point_national_battlefield unit_type 'National Battlefield'
  mapped_layer shortbread pois filtered_ne_10m_parks_and_protected_lands_point_national_battlefield 8 $maxZoom '{"historic": "battlefield"}' # Z10?
  filter_prop shortbread ne_10m_parks_and_protected_lands_point filtered_ne_10m_parks_and_protected_lands_point_national_battlefield_park unit_type 'National Battlefield Park'
  mapped_layer shortbread pois filtered_ne_10m_parks_and_protected_lands_point_national_battlefield_park 8 $maxZoom '{"historic": "battlefield"}' # Z10?
  filter_prop shortbread ne_10m_parks_and_protected_lands_point filtered_ne_10m_parks_and_protected_lands_point_national_battlefield_site unit_type 'National Battlefield Site'
  mapped_layer shortbread pois filtered_ne_10m_parks_and_protected_lands_point_national_battlefield_site 8 $maxZoom '{"historic": "battlefield"}' # Z10?

  # historic=memorial
  filter_prop shortbread ne_10m_parks_and_protected_lands_point filtered_ne_10m_parks_and_protected_lands_point_memorial unit_type 'Memorial'
  mapped_layer shortbread pois filtered_ne_10m_parks_and_protected_lands_point_memorial 8 $maxZoom '{"historic": "memorial"}' # Z10?
  filter_prop shortbread ne_10m_parks_and_protected_lands_point filtered_ne_10m_parks_and_protected_lands_point_national_memorial unit_type 'National Memorial'
  mapped_layer shortbread pois filtered_ne_10m_parks_and_protected_lands_point_national_memorial 8 $maxZoom '{"historic": "memorial"}' # Z10?
  filter_prop shortbread ne_10m_parks_and_protected_lands_point filtered_ne_10m_parks_and_protected_lands_point_memorial_parkway unit_type 'Memorial Parkway'
  mapped_layer shortbread pois filtered_ne_10m_parks_and_protected_lands_point_memorial_parkway 8 $maxZoom '{"historic": "memorial"}' # Z10?

  bundle_all shortbread
  # End shortbread

  # Start protomaps
  filter_prop protomaps ne_50m_admin_0_boundary_lines_land filtered_ne_50m_admin_0_boundary_lines_land_disputed FEATURECLA 'Disputed (please verify)'
  filter_not_prop protomaps ne_50m_admin_0_boundary_lines_land filtered_ne_50m_admin_0_boundary_lines_land_not_disputed FEATURECLA 'Disputed (please verify)'

  filter_prop protomaps ne_10m_admin_0_boundary_lines_land filtered_ne_10m_admin_0_boundary_lines_land_disputed FEATURECLA 'Disputed (please verify)'
  filter_not_prop protomaps ne_10m_admin_0_boundary_lines_land filtered_ne_10m_admin_0_boundary_lines_land_not_disputed FEATURECLA 'Disputed (please verify)'

  mapped_layer protomaps boundaries filtered_ne_50m_admin_0_boundary_lines_land_disputed 3 4 '{"kind": "country", "disputed": true}'
  mapped_layer protomaps boundaries filtered_ne_50m_admin_0_boundary_lines_land_not_disputed 3 4 '{"kind": "country", "disputed": false}'

  mapped_layer protomaps boundaries filtered_ne_10m_admin_0_boundary_lines_land_disputed 5 $maxZoom '{"kind": "country", "disputed": true}'
  mapped_layer protomaps boundaries filtered_ne_10m_admin_0_boundary_lines_land_not_disputed 5 $maxZoom '{"kind": "country", "disputed": false}'

  mapped_layer protomaps boundaries ne_10m_admin_1_states_provinces_lines 5 $maxZoom '{"kind": "region"}'
  mapped_layer protomaps boundaries ne_10m_admin_2_counties_lines 8 $maxZoom '{"kind": "county"}'

  mapped_layer protomaps earth ne_110m_land 0 2 '{"kind": "earth"}'
  mapped_layer protomaps earth ne_50m_land 3 4 '{"kind": "earth"}'
  mapped_layer protomaps earth ne_10m_land 5 $maxZoom '{"kind": "earth"}'

  mapped_layer protomaps landcover ne_10m_parks_and_protected_lands_area 8 $maxZoom '{"kind": "park"}'

  filter_prop protomaps ne_10m_populated_places filtered_ne_10m_populated_places_capital0 FEATURECLA 'Admin-0 capital'
  filter_not_prop protomaps ne_10m_populated_places filtered_ne_10m_populated_places_no_capital0 FEATURECLA 'Admin-0 capital'

  filter_prop protomaps filtered_ne_10m_populated_places_no_capital0 filtered_ne_10m_populated_places_capital0_alt FEATURECLA 'Admin-0 capital alt'
  filter_not_prop protomaps filtered_ne_10m_populated_places_no_capital0 filtered_ne_10m_populated_places_no_capital0_alt FEATURECLA 'Admin-0 capital alt'

  filter_prop protomaps filtered_ne_10m_populated_places_no_capital0_alt filtered_ne_10m_populated_places_regioncapital0 FEATURECLA 'Admin-0 region capital'
  filter_not_prop protomaps filtered_ne_10m_populated_places_no_capital0_alt filtered_ne_10m_populated_places_no_reigoncapital0 FEATURECLA 'Admin-0 region capital'

  filter_prop protomaps filtered_ne_10m_populated_places_no_reigoncapital0 filtered_ne_10m_populated_places_capital1 FEATURECLA 'Admin-1 capital'
  filter_not_prop protomaps filtered_ne_10m_populated_places_no_reigoncapital0 filtered_ne_10m_populated_places_no_capital1 FEATURECLA 'Admin-1 capital'

  filter_prop protomaps filtered_ne_10m_populated_places_no_capital1 filtered_ne_10m_populated_places_regioncapital1 FEATURECLA 'Admin-1 region capital'
  filter_not_prop protomaps filtered_ne_10m_populated_places_no_capital1 filtered_ne_10m_populated_places_no_capital FEATURECLA 'Admin-1 region capital'

  filter_prop_larger protomaps filtered_ne_10m_populated_places_no_capital filtered_ne_10m_populated_places_no_capital_100000 POP_MAX 100000
  filter_prop_not_larger protomaps filtered_ne_10m_populated_places_no_capital filtered_ne_10m_populated_places_no_capital_no_100000 POP_MAX 100000

  filter_prop_larger protomaps filtered_ne_10m_populated_places_no_capital_no_100000 filtered_ne_10m_populated_places_no_capital_5000 POP_MAX 5000
  filter_prop_not_larger protomaps filtered_ne_10m_populated_places_no_capital_no_100000 filtered_ne_10m_populated_places_no_capital_no_5000 POP_MAX 5000

  filter_prop_larger protomaps filtered_ne_10m_populated_places_no_capital_no_5000 filtered_ne_10m_populated_places_no_capital_100 POP_MAX 100
  filter_prop_not_larger protomaps filtered_ne_10m_populated_places_no_capital_no_5000 filtered_ne_10m_populated_places_no_capital_no_100 POP_MAX 100

  filter_prop_larger protomaps filtered_ne_10m_populated_places_no_capital_no_100 filtered_ne_10m_populated_places_no_capital_50 POP_MAX 50
  filter_prop_not_larger protomaps filtered_ne_10m_populated_places_no_capital_no_100 filtered_ne_10m_populated_places_no_capital_no_50 POP_MAX 50

  mapped_layer protomaps places filtered_ne_10m_populated_places_capital0 4 $maxZoom '{"kind": "locality", "capital": "yes", "kind_detail": "city"}'
  mapped_layer protomaps places filtered_ne_10m_populated_places_capital0_alt 4 $maxZoom '{"kind": "locality", "capital": "yes", "kind_detail": "city"}'
  mapped_layer protomaps places filtered_ne_10m_populated_places_regioncapital0 4 $maxZoom '{"kind": "locality", "capital": "4", "kind_detail": "city"}'
  mapped_layer protomaps places filtered_ne_10m_populated_places_capital1 6 $maxZoom '{"kind": "locality", "capital": "4", "kind_detail": "city"}'
  mapped_layer protomaps places filtered_ne_10m_populated_places_regioncapital1 6 $maxZoom '{"kind": "locality", "capital": "4", "kind_detail": "city"}'

  mapped_layer protomaps places filtered_ne_10m_populated_places_no_capital_100000 6 $maxZoom '{"kind": "locality", "kind_detail": "city"}'
  mapped_layer protomaps places filtered_ne_10m_populated_places_no_capital_5000 7 $maxZoom '{"kind": "locality", "kind_detail": "town"}'
  mapped_layer protomaps places filtered_ne_10m_populated_places_no_capital_100 8 $maxZoom '{"kind": "locality", "kind_detail": "village"}'    # Z10?
  mapped_layer protomaps places filtered_ne_10m_populated_places_no_capital_50 8 $maxZoom '{"kind": "locality", "kind_detail": "hamlet"}'      # Z10?
  mapped_layer protomaps places filtered_ne_10m_populated_places_no_capital_no_50 8 $maxZoom '{"kind": "locality", "kind_detail": "locality"}' # Z10?

  mapped_layer_to_point protomaps places ne_10m_admin_0_countries 3 6 '{"kind": "country", "kind_detail": "country"}'
  mapped_layer_to_point protomaps places ne_10m_admin_1_states_provinces 5 $maxZoom '{"kind": "region", "kind_detail": "state"}'
  mapped_layer_to_point protomaps places ne_10m_admin_2_counties 8 $maxZoom '{"kind": "region", "kind_detail": "county"}'

  # Mapped POIs from ne_10m_parks_and_protected_lands_point
  # "National Monument" -> historic=monument
  # "National Monument and Historic Shrine" -> historic=monument
  # "National Battlefield Site" -> historic=battlefield
  # "National Battlefield Park" -> historic=battlefield
  # "National Battlefield" -> historic=battlefield
  # "National Memorial" -> historic=memorial
  # "Memorial Parkway" -> historic=memorial
  # "Memorial" -> historic=memorial

  # Unmapped POIs from ne_10m_parks_and_protected_lands_point
  # "National Park"
  # "National Historical Park"
  # "National Preserve"
  # "National Historic Site"
  # "National Historical Park and Ecological Preserve"
  # "National Recreation Area"
  # "Park"
  # "National Historical Park and Preserve"
  # "National Military Park"
  # "Ecological and Historic Preserve"
  # "International Historic Site"
  # "National Historical Reserve"
  # "National Seashore"
  # "National Reserve"
  # "National Lakeshore"
  # "Scenic and Recreational River"
  # "National Scenic Trail"

  # historic=monument
  filter_prop protomaps ne_10m_parks_and_protected_lands_point filtered_ne_10m_parks_and_protected_lands_point_national_monument unit_type 'National Monument'
  mapped_layer protomaps pois filtered_ne_10m_parks_and_protected_lands_point_national_monument 8 $maxZoom '{"kind": "monument"}' # Z10?
  filter_prop protomaps ne_10m_parks_and_protected_lands_point filtered_ne_10m_parks_and_protected_lands_point_national_monument_shrine unit_type 'National Monument and Historic Shrine'
  mapped_layer protomaps pois filtered_ne_10m_parks_and_protected_lands_point_national_monument_shrine 8 $maxZoom '{"kind": "monument"}' # Z10?

  # historic=battlefield
  filter_prop protomaps ne_10m_parks_and_protected_lands_point filtered_ne_10m_parks_and_protected_lands_point_national_battlefield unit_type 'National Battlefield'
  mapped_layer protomaps pois filtered_ne_10m_parks_and_protected_lands_point_national_battlefield 8 $maxZoom '{"kind": "battlefield"}' # Z10?
  filter_prop protomaps ne_10m_parks_and_protected_lands_point filtered_ne_10m_parks_and_protected_lands_point_national_battlefield_park unit_type 'National Battlefield Park'
  mapped_layer protomaps pois filtered_ne_10m_parks_and_protected_lands_point_national_battlefield_park 8 $maxZoom '{"kind": "battlefield"}' # Z10?
  filter_prop protomaps ne_10m_parks_and_protected_lands_point filtered_ne_10m_parks_and_protected_lands_point_national_battlefield_site unit_type 'National Battlefield Site'
  mapped_layer protomaps pois filtered_ne_10m_parks_and_protected_lands_point_national_battlefield_site 8 $maxZoom '{"kind": "battlefield"}' # Z10?

  # historic=memorial
  filter_prop protomaps ne_10m_parks_and_protected_lands_point filtered_ne_10m_parks_and_protected_lands_point_memorial unit_type 'Memorial'
  mapped_layer protomaps pois filtered_ne_10m_parks_and_protected_lands_point_memorial 8 $maxZoom '{"kind": "memorial"}' # Z10?
  filter_prop protomaps ne_10m_parks_and_protected_lands_point filtered_ne_10m_parks_and_protected_lands_point_national_memorial unit_type 'National Memorial'
  mapped_layer protomaps pois filtered_ne_10m_parks_and_protected_lands_point_national_memorial 8 $maxZoom '{"kind": "memorial"}' # Z10?
  filter_prop protomaps ne_10m_parks_and_protected_lands_point filtered_ne_10m_parks_and_protected_lands_point_memorial_parkway unit_type 'Memorial Parkway'
  mapped_layer protomaps pois filtered_ne_10m_parks_and_protected_lands_point_memorial_parkway 8 $maxZoom '{"kind": "memorial"}' # Z10?

  mapped_layer protomaps pois ne_10m_airports 8 $maxZoom '{"kind": "aerodrome"}' # Z10?
  mapped_layer protomaps pois ne_10m_ports 8 $maxZoom '{"kind": "marina"}'       # Z10?

  # "Major Highway": motorway
  # "Secondary Highway": trunk
  # "Road": road
  # "Unknown": road
  filter_prop protomaps ne_10m_roads filtered_ne_10m_roads_ferries featurecla Ferry
  filter_not_prop protomaps ne_10m_roads filtered_ne_10m_roads_land_nofeature_ferry featurecla Ferry
  filter_prop protomaps filtered_ne_10m_roads_land_nofeature_ferry filtered_ne_10m_roads_type_ferry type 'Ferry Route'
  filter_not_prop protomaps filtered_ne_10m_roads_land_nofeature_ferry filtered_ne_10m_roads_land type 'Ferry Route'

  filter_prop protomaps filtered_ne_10m_roads_land filtered_ne_10m_roads_primary type 'Major Highway'
  filter_not_prop protomaps filtered_ne_10m_roads_land filtered_ne_10m_roads_no_primary type 'Major Highway'

  filter_prop protomaps filtered_ne_10m_roads_no_primary filtered_ne_10m_roads_secondary type 'Secondary Highway'
  filter_not_prop protomaps filtered_ne_10m_roads_no_primary filtered_ne_10m_roads_no_secondary type 'Secondary Highway'

  # TODO: Maybe use ne_10m_roads_north_america for north america
  mapped_layer protomaps roads filtered_ne_10m_roads_primary 6 $maxZoom '{"kind": "highway"}'
  mapped_layer protomaps roads filtered_ne_10m_roads_secondary 8 $maxZoom '{"kind": "major_road"}'
  mapped_layer protomaps roads filtered_ne_10m_roads_no_secondary 8 $maxZoom '{"kind": "minor_road"}' # Z10?
  # TODO: Maybe use ne_10m_railroads_north_america for north america
  filter_not_prop protomaps ne_10m_railroads filtered_ne_10m_railroads_land featurecla 'Railroad ferry'
  mapped_layer protomaps roads filtered_ne_10m_railroads_land 8 $maxZoom '{"kind": "rail"}'

  mapped_layer protomaps roads filtered_ne_10m_roads_ferries 8 $maxZoom '{"kind": "ferry"}'
  mapped_layer protomaps roads filtered_ne_10m_roads_type_ferry 8 $maxZoom '{"kind": "ferry"}'
  filter_prop protomaps ne_10m_railroads filtered_ne_10m_rail_ferries featurecla 'Railroad ferry'
  mapped_layer protomaps roads filtered_ne_10m_rail_ferries 8 $maxZoom '{"kind": "ferry"}'

  mapped_layer protomaps water ne_110m_ocean 0 2 '{"kind": "ocean"}'
  mapped_layer protomaps water ne_50m_ocean 3 4 '{"kind": "ocean"}'
  mapped_layer protomaps water ne_10m_ocean 5 $maxZoom '{"kind": "ocean"}'

  mapped_layer protomaps landuse ne_10m_parks_and_protected_lands_area 8 $maxZoom '{"kind": "national_park"}'

  mapped_layer protomaps water ne_110m_lakes 4 5 '{"kind": "lake"}'
  mapped_layer protomaps water ne_50m_lakes 6 7 '{"kind": "lake"}'
  mapped_layer protomaps water ne_10m_lakes 8 $maxZoom '{"kind": "lake"}'
  mapped_layer protomaps water ne_10m_lakes_australia 8 $maxZoom '{"kind": "lake"}'
  mapped_layer protomaps water ne_10m_lakes_europe 8 $maxZoom '{"kind": "lake"}'
  mapped_layer protomaps water ne_10m_lakes_north_america 8 $maxZoom '{"kind": "lake"}'

  mapped_layer protomaps water ne_10m_playas 8 $maxZoom '{"kind": "playa"}'

  # TODO: Filter out alkaline, intermittent, reservoir to be able to set those flags

  mapped_layer protomaps water ne_50m_rivers_lake_centerlines 3 4 '{"kind": "water", "kind_detail": "river"}'
  mapped_layer protomaps water ne_10m_rivers_lake_centerlines 5 $maxZoom '{"kind": "water", "kind_detail": "river"}'
  mapped_layer protomaps water ne_10m_rivers_lake_centerlines_scale_rank 5 $maxZoom '{"kind": "water", "kind_detail": "river"}'
  mapped_layer protomaps water ne_10m_rivers_australia 5 $maxZoom '{"kind": "water", "kind_detail": "river"}'
  mapped_layer protomaps water ne_10m_rivers_europe 5 $maxZoom '{"kind": "water", "kind_detail": "river"}'
  mapped_layer protomaps water ne_10m_rivers_north_america 5 $maxZoom '{"kind": "water", "kind_detail": "river"}'

  # TODO: Protomaps questions:
  # No maritime boundaries?
  # No ports in landuse/pois?
  # No places kind value for county, but there is one for boundaries
  # Places capital value seems mixed between "yes" and stringified integers
  # Reason for including both earth and ocean

  bundle_all protomaps
  # End protomaps

  # Start openmaptiles
  mapped_layer openmaptiles water ne_110m_ocean 0 2 '{"class": "ocean"}'
  mapped_layer openmaptiles water ne_50m_ocean 3 4 '{"class": "ocean"}'
  mapped_layer openmaptiles water ne_10m_ocean 5 $maxZoom '{"class": "ocean"}'

  # TODO: class=[lowercase and replace space with underscore]
  mapped_layer openmaptiles park ne_10m_parks_and_protected_lands_area 8 $maxZoom '{"kind": "park"}'

  mapped_layer openmaptiles water ne_110m_lakes 4 5 '{"class": "lake"}'
  mapped_layer openmaptiles water ne_50m_lakes 6 7 '{"class": "lake"}'
  mapped_layer openmaptiles water ne_10m_lakes 8 $maxZoom '{"class": "lake"}'
  mapped_layer openmaptiles water ne_10m_lakes_australia 8 $maxZoom '{"class": "lake"}'
  mapped_layer openmaptiles water ne_10m_lakes_europe 8 $maxZoom '{"class": "lake"}'
  mapped_layer openmaptiles water ne_10m_lakes_north_america 8 $maxZoom '{"class": "lake"}'

  mapped_layer_to_point openmaptiles water_name ne_110m_lakes 4 5 '{"class": "lake"}'
  mapped_layer_to_point openmaptiles water_name ne_50m_lakes 6 7 '{"class": "lake"}'
  mapped_layer_to_point openmaptiles water_name ne_10m_lakes 8 $maxZoom '{"class": "lake"}'
  mapped_layer_to_point openmaptiles water_name ne_10m_lakes_australia 8 $maxZoom '{"class": "lake"}'
  mapped_layer_to_point openmaptiles water_name ne_10m_lakes_europe 8 $maxZoom '{"class": "lake"}'
  mapped_layer_to_point openmaptiles water_name ne_10m_lakes_north_america 8 $maxZoom '{"class": "lake"}'

  mapped_layer openmaptiles waterway ne_50m_rivers_lake_centerlines 3 4 '{"class": "river"}'
  mapped_layer openmaptiles waterway ne_10m_rivers_lake_centerlines 5 $maxZoom '{"class": "river"}'
  mapped_layer openmaptiles waterway ne_10m_rivers_lake_centerlines_scale_rank 5 $maxZoom '{"class": "river"}'
  mapped_layer openmaptiles waterway ne_10m_rivers_australia 5 $maxZoom '{"class": "river"}'
  mapped_layer openmaptiles waterway ne_10m_rivers_europe 5 $maxZoom '{"class": "river"}'
  mapped_layer openmaptiles waterway ne_10m_rivers_north_america 5 $maxZoom '{"class": "river"}'

  filter_prop openmaptiles ne_50m_admin_0_boundary_lines_land filtered_ne_50m_admin_0_boundary_lines_land_disputed FEATURECLA 'Disputed (please verify)'
  filter_not_prop openmaptiles ne_50m_admin_0_boundary_lines_land filtered_ne_50m_admin_0_boundary_lines_land_not_disputed FEATURECLA 'Disputed (please verify)'

  filter_prop openmaptiles ne_50m_admin_0_boundary_lines_maritime_indicator filtered_ne_50m_admin_0_boundary_lines_maritime_indicator_disputed FEATURECLA 'Marine Indicator Disputed'
  filter_not_prop openmaptiles ne_50m_admin_0_boundary_lines_maritime_indicator filtered_ne_50m_admin_0_boundary_lines_maritime_indicator_not_disputed FEATURECLA 'Marine Indicator Disputed'

  filter_prop openmaptiles ne_10m_admin_0_boundary_lines_land filtered_ne_10m_admin_0_boundary_lines_land_disputed FEATURECLA 'Disputed (please verify)'
  filter_not_prop openmaptiles ne_10m_admin_0_boundary_lines_land filtered_ne_10m_admin_0_boundary_lines_land_not_disputed FEATURECLA 'Disputed (please verify)'

  filter_prop openmaptiles ne_10m_admin_0_boundary_lines_maritime_indicator filtered_ne_10m_admin_0_boundary_lines_maritime_indicator_disputed FEATURECLA 'Marine Indicator Disputed'
  filter_not_prop openmaptiles ne_10m_admin_0_boundary_lines_maritime_indicator filtered_ne_10m_admin_0_boundary_lines_maritime_indicator_not_disputed FEATURECLA 'Marine Indicator Disputed'

  mapped_layer openmaptiles boundary filtered_ne_50m_admin_0_boundary_lines_land_disputed 3 4 '{"admin_level": 2, "disputed": 1}'
  mapped_layer openmaptiles boundary filtered_ne_50m_admin_0_boundary_lines_land_not_disputed 3 4 '{"admin_level": 2, "disputed": 0}'

  mapped_layer openmaptiles boundary filtered_ne_50m_admin_0_boundary_lines_maritime_indicator_disputed 3 4 '{"maritime": 1, "admin_level": 2, "disputed": 1}'
  mapped_layer openmaptiles boundary filtered_ne_50m_admin_0_boundary_lines_maritime_indicator_not_disputed 3 4 '{"maritime": 1, "admin_level": 2, "disputed": 0}'

  mapped_layer openmaptiles boundary filtered_ne_10m_admin_0_boundary_lines_land_disputed 5 $maxZoom '{"admin_level": 2, "disputed": 1}'
  mapped_layer openmaptiles boundary filtered_ne_10m_admin_0_boundary_lines_land_not_disputed 5 $maxZoom '{"admin_level": 2, "disputed": 0}'

  mapped_layer openmaptiles boundary filtered_ne_10m_admin_0_boundary_lines_maritime_indicator_disputed 5 $maxZoom '{"maritime": 1, "admin_level": 2, "disputed": 1}'
  mapped_layer openmaptiles boundary filtered_ne_10m_admin_0_boundary_lines_maritime_indicator_not_disputed 5 $maxZoom '{"maritime": 1, "admin_level": 2, "disputed": 0}'

  mapped_layer openmaptiles boundary ne_10m_admin_1_states_provinces_lines 5 $maxZoom '{"admin_level": 4}'
  mapped_layer openmaptiles boundary ne_10m_admin_2_counties_lines 8 $maxZoom '{"admin_level": 6}'

  filter_prop_larger openmaptiles ne_10m_admin_0_countries filtered_ne_10m_admin_0_countries_rank1 way_area 300000000000
  filter_prop_not_larger openmaptiles ne_10m_admin_0_countries filtered_ne_10m_admin_0_countries_under_rank1 way_area 300000000000

  filter_prop_larger openmaptiles filtered_ne_10m_admin_0_countries_under_rank1 filtered_ne_10m_admin_0_countries_rank2 way_area 160000000000
  filter_prop_not_larger openmaptiles filtered_ne_10m_admin_0_countries_under_rank1 filtered_ne_10m_admin_0_countries_under_rank2 way_area 160000000000

  filter_prop_larger openmaptiles filtered_ne_10m_admin_0_countries_under_rank2 filtered_ne_10m_admin_0_countries_rank3 way_area 4000000000
  filter_prop_not_larger openmaptiles filtered_ne_10m_admin_0_countries_under_rank2 filtered_ne_10m_admin_0_countries_under_rank3 way_area 4000000000

  filter_prop_larger openmaptiles filtered_ne_10m_admin_0_countries_under_rank3 filtered_ne_10m_admin_0_countries_rank4 way_area 1500000000
  filter_prop_not_larger openmaptiles filtered_ne_10m_admin_0_countries_under_rank3 filtered_ne_10m_admin_0_countries_under_rank4 way_area 1500000000

  filter_prop_larger openmaptiles filtered_ne_10m_admin_0_countries_under_rank4 filtered_ne_10m_admin_0_countries_rank5 way_area 100000000
  filter_prop_not_larger openmaptiles filtered_ne_10m_admin_0_countries_under_rank4 filtered_ne_10m_admin_0_countries_under_rank5 way_area 100000000

  mapped_layer_to_point openmaptiles place filtered_ne_10m_admin_0_countries_rank1 0 $maxZoom '{"admin_level": 2, "class": "country", "rank": 1}'
  mapped_layer_to_point openmaptiles place filtered_ne_10m_admin_0_countries_rank2 0 $maxZoom '{"admin_level": 2, "class": "country", "rank": 2}'
  mapped_layer_to_point openmaptiles place filtered_ne_10m_admin_0_countries_rank3 0 $maxZoom '{"admin_level": 2, "class": "country", "rank": 3}'
  mapped_layer_to_point openmaptiles place filtered_ne_10m_admin_0_countries_rank4 0 $maxZoom '{"admin_level": 2, "class": "country", "rank": 4}'
  mapped_layer_to_point openmaptiles place filtered_ne_10m_admin_0_countries_rank5 0 $maxZoom '{"admin_level": 2, "class": "country", "rank": 5}'
  mapped_layer_to_point openmaptiles place filtered_ne_10m_admin_0_countries_under_rank5 0 $maxZoom '{"admin_level": 2, "class": "country", "rank": 6}'

  mapped_layer_to_point openmaptiles place ne_10m_admin_1_states_provinces 5 $maxZoom '{"admin_level": 4, "class": "state", "rank": 2}'
  mapped_layer_to_point openmaptiles place ne_10m_admin_2_counties 8 $maxZoom '{"admin_level": 6, "class": "province", "rank": 3}'

  # FEATURECLA value:
  # "Admin-0 capital": z4, kind=capital
  # "Admin-1 region capital": z4, kind=state_capital

  # For non-capitals: POP_MAX value:
  # 100,000+: z6, kind=city
  # 5000+: z7, kind=town
  # 100+: z10, kind=village
  # 50+: z10, kind=hamlet
  # 0: z10, kind=locality

  # TODO: Add iso_a2 and rank to these and the ne_10m_admin_0 points above
  filter_prop openmaptiles ne_10m_populated_places filtered_ne_10m_populated_places_capital0 FEATURECLA 'Admin-0 capital'
  filter_not_prop openmaptiles ne_10m_populated_places filtered_ne_10m_populated_places_no_capital0 FEATURECLA 'Admin-0 capital'

  filter_prop openmaptiles filtered_ne_10m_populated_places_no_capital0 filtered_ne_10m_populated_places_capital0_alt FEATURECLA 'Admin-0 capital alt'
  filter_not_prop openmaptiles filtered_ne_10m_populated_places_no_capital0 filtered_ne_10m_populated_places_no_capital0_alt FEATURECLA 'Admin-0 capital alt'

  filter_prop openmaptiles filtered_ne_10m_populated_places_no_capital0_alt filtered_ne_10m_populated_places_regioncapital0 FEATURECLA 'Admin-0 region capital'
  filter_not_prop openmaptiles filtered_ne_10m_populated_places_no_capital0_alt filtered_ne_10m_populated_places_no_reigoncapital0 FEATURECLA 'Admin-0 region capital'

  filter_prop openmaptiles filtered_ne_10m_populated_places_no_reigoncapital0 filtered_ne_10m_populated_places_capital1 FEATURECLA 'Admin-1 capital'
  filter_not_prop openmaptiles filtered_ne_10m_populated_places_no_reigoncapital0 filtered_ne_10m_populated_places_no_capital1 FEATURECLA 'Admin-1 capital'

  filter_prop openmaptiles filtered_ne_10m_populated_places_no_capital1 filtered_ne_10m_populated_places_regioncapital1 FEATURECLA 'Admin-1 region capital'
  filter_not_prop openmaptiles filtered_ne_10m_populated_places_no_capital1 filtered_ne_10m_populated_places_no_capital FEATURECLA 'Admin-1 region capital'

  filter_prop_larger openmaptiles filtered_ne_10m_populated_places_no_capital filtered_ne_10m_populated_places_no_capital_100000 POP_MAX 100000
  filter_prop_not_larger openmaptiles filtered_ne_10m_populated_places_no_capital filtered_ne_10m_populated_places_no_capital_no_100000 POP_MAX 100000

  filter_prop_larger openmaptiles filtered_ne_10m_populated_places_no_capital_no_100000 filtered_ne_10m_populated_places_no_capital_5000 POP_MAX 5000
  filter_prop_not_larger openmaptiles filtered_ne_10m_populated_places_no_capital_no_100000 filtered_ne_10m_populated_places_no_capital_no_5000 POP_MAX 5000

  filter_prop_larger openmaptiles filtered_ne_10m_populated_places_no_capital_no_5000 filtered_ne_10m_populated_places_no_capital_100 POP_MAX 100
  filter_prop_not_larger openmaptiles filtered_ne_10m_populated_places_no_capital_no_5000 filtered_ne_10m_populated_places_no_capital_no_100 POP_MAX 100

  filter_prop_larger openmaptiles filtered_ne_10m_populated_places_no_capital_no_100 filtered_ne_10m_populated_places_no_capital_50 POP_MAX 50
  filter_prop_not_larger openmaptiles filtered_ne_10m_populated_places_no_capital_no_100 filtered_ne_10m_populated_places_no_capital_no_50 POP_MAX 50

  mapped_layer openmaptiles place filtered_ne_10m_populated_places_capital0 4 $maxZoom '{"class": "city", "capital": 2}'
  mapped_layer openmaptiles place filtered_ne_10m_populated_places_capital0_alt 4 $maxZoom '{"class": "city", "capital": 2}'
  mapped_layer openmaptiles place filtered_ne_10m_populated_places_regioncapital0 4 $maxZoom '{"class": "city", "capital": 2}'
  mapped_layer openmaptiles place filtered_ne_10m_populated_places_capital1 6 $maxZoom '{"class": "city", "capital": 4}'
  mapped_layer openmaptiles place filtered_ne_10m_populated_places_regioncapital1 6 $maxZoom '{"class": "city", "capital": 4}'
  mapped_layer openmaptiles place filtered_ne_10m_populated_places_no_capital_100000 6 $maxZoom '{"class": "city"}'
  mapped_layer openmaptiles place filtered_ne_10m_populated_places_no_capital_5000 7 $maxZoom '{"class": "town"}'
  mapped_layer openmaptiles place filtered_ne_10m_populated_places_no_capital_100 8 $maxZoom '{"class": "village"}'    # Z10?
  mapped_layer openmaptiles place filtered_ne_10m_populated_places_no_capital_50 8 $maxZoom '{"class": "hamlet"}'      # Z10?
  mapped_layer openmaptiles place filtered_ne_10m_populated_places_no_capital_no_50 8 $maxZoom '{"class": "locality"}' # Z10?

  # "Major Highway": motorway
  # "Secondary Highway": trunk
  # "Road": road
  # "Unknown": road
  filter_prop openmaptiles ne_10m_roads filtered_ne_10m_roads_ferries featurecla Ferry
  filter_not_prop openmaptiles ne_10m_roads filtered_ne_10m_roads_land_nofeature_ferry featurecla Ferry
  filter_prop openmaptiles filtered_ne_10m_roads_land_nofeature_ferry filtered_ne_10m_roads_type_ferry type 'Ferry Route'
  filter_not_prop openmaptiles filtered_ne_10m_roads_land_nofeature_ferry filtered_ne_10m_roads_land type 'Ferry Route'

  filter_prop openmaptiles filtered_ne_10m_roads_land filtered_ne_10m_roads_primary type 'Major Highway'
  filter_not_prop openmaptiles filtered_ne_10m_roads_land filtered_ne_10m_roads_no_primary type 'Major Highway'

  filter_prop openmaptiles filtered_ne_10m_roads_no_primary filtered_ne_10m_roads_secondary type 'Secondary Highway'
  filter_not_prop openmaptiles filtered_ne_10m_roads_no_primary filtered_ne_10m_roads_no_secondary type 'Secondary Highway'

  # TODO: Maybe use ne_10m_roads_north_america for north america
  mapped_layer openmaptiles transportation filtered_ne_10m_roads_primary 6 $maxZoom '{"class": "motorway"}'
  mapped_layer openmaptiles transportation filtered_ne_10m_roads_secondary 8 $maxZoom '{"class": "trunk"}'
  mapped_layer openmaptiles transportation filtered_ne_10m_roads_no_secondary 8 $maxZoom '{"class": "primary"}' # Z10?
  # TODO: Maybe use ne_10m_railroads_north_america for north america
  filter_not_prop openmaptiles ne_10m_railroads filtered_ne_10m_railroads_land featurecla 'Railroad ferry'
  mapped_layer openmaptiles transportation filtered_ne_10m_railroads_land 8 $maxZoom '{"class": "rail"}'

  mapped_layer openmaptiles transportation filtered_ne_10m_roads_ferries 8 $maxZoom '{"class": "ferry"}'
  mapped_layer openmaptiles transportation filtered_ne_10m_roads_type_ferry 8 $maxZoom '{"class": "ferry"}'
  filter_prop openmaptiles ne_10m_railroads filtered_ne_10m_rail_ferries featurecla 'Railroad ferry'
  mapped_layer openmaptiles transportation filtered_ne_10m_rail_ferries 8 $maxZoom '{"class": "ferry"}'

  mapped_layer openmaptiles aerodrome_label ne_10m_airports 8 $maxZoom        # Z10?
  mapped_layer openmaptiles poi ne_10m_ports 8 $maxZoom '{"class": "harbor"}' # Z10?

  bundle_all openmaptiles
  # End openmaptiles

  # Start planetilershortbread
  mapped_layer_to_point_geojson() {
    set -xeuo pipefail
    schema="${1}"
    name="${2}"
    source="${3}"
    additionalAttributes="${4:-{}}"
    prepGeoJson $schema $source
    mkdir -p $schema-points
    # Check that the mbtiles does not exist and that we have features to map
    if [ ! -f "$schema-points/$name-$source.json" ] && jq -e '.features[0]' "$schema-geojsonprep/$source.json" >/dev/null; then
      tippecanoe -r1 --no-progress-indicator -Z5 -z5 -o "$schema-points/$name-$source.mbtiles" --convert-polygons-to-label-points $(includeFlags $schema) -l "$name" --set-attribute="$additionalAttributes" "$schema-geojsonprep/$source.json"
      tippecanoe-decode -c "$schema-points/$name-$source.mbtiles" | jq -s >"$schema-points/$name-$source.json"
      $LOCAL_SCRIPT_DIR/snakecase.js "$schema-points/$name-$source"
    fi
  }

  mapped_layer_to_point_geojson planetilershortbread boundary_labels ne_10m_admin_0_countries '{"admin_level": 2}'
  mapped_layer_to_point_geojson planetilershortbread boundary_labels ne_10m_admin_1_states_provinces '{"admin_level": 4}'
  mapped_layer_to_point_geojson planetilershortbread boundary_labels ne_10m_admin_2_counties '{"admin_level": 6}'

  if [ ! -f planetilershortbread.zip ]; then
    rm -f planetilershortbread-geojsonprep/planetilershortbread.json
    jq '{"type": "FeatureCollection", "features": [.[] | .features[]]}' --slurp planetilershortbread-points/*.json >planetilershortbread-geojsonprep/planetilershortbread.json
    mkdir -p planetilershortbread
    ogr2ogr -F "ESRI Shapefile" -lco ENCODING=UTF-8 planetilershortbread/planetilershortbread.shp planetilershortbread-geojsonprep/planetilershortbread.json
    zip planetilershortbread.zip planetilershortbread/*
  fi
  # End planetilershortbread

  # Package into pmtiles
  for mbtiles in *.mbtiles; do
    pathExtLess="${mbtiles/.mbtiles/}"
    if [ ! -f $pathExtLess.pmtiles ]; then
      pmtiles convert $pathExtLess.mbtiles $pathExtLess.pmtiles
    fi
    link_all
  done

  # TODO: not all languages included? Stockholm has 348 in openmaptiles, shortbread has 268
  # TODO: Validate naturalearth & openstreetmap side-by-side
  # TODO: add git committed single-tile extracts in geojson to be able to diff builds
  # TODO: Set the time of all artifacts to the source, and check that. check and commit wikidata based on time
}

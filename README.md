# maps.black

See <https://maps.black/> or <https://maps-black.github.io/> for info

## Licensing

- Apps:
  - mb-util: BSD 3-Clause: <https://github.com/mapbox/mbutil/blob/master/LICENSE.md>
  - mksquashfs: GPL-2: <https://github.com/plougher/squashfs-tools/blob/master/COPYING>
  - tippecanoe: BSD 2-Clause: <https://github.com/felt/tippecanoe/blob/main/LICENSE.md>
  - planetiler: Apache-2: <https://github.com/onthegomap/planetiler/blob/main/LICENSE>
  - spreet: MIT: <https://github.com/flother/spreet/blob/master/LICENCE>
  - font-maker: BSD 3-Clause: <https://github.com/maplibre/font-maker/blob/main/LICENSE.txt>
  - esbuild: MIT: <https://github.com/evanw/esbuild/blob/main/LICENSE.md>
  - oxipng: MIT: <https://github.com/shssoichiro/oxipng/blob/master/LICENSE>
  - pngquant: GPL-3: <https://github.com/kornelski/pngquant/blob/main/COPYRIGHT>
  - gzip: GPL-3: <https://www.gnu.org/software/gzip/>
  - zstd: BSD 3-Clause: <https://github.com/facebook/zstd/blob/dev/LICENSE>

  - pmtiles: BSD 3-Clause: <https://github.com/protomaps/go-pmtiles/blob/main/LICENSE>
  - maplibre-gl: BSD 3-Clause: <https://github.com/maplibre/maplibre-gl-js/blob/main/LICENSE.txt>
  - mapbox-gl-rtl-text: BSD 2-Clause, MIT: <https://github.com/mapbox/mapbox-gl-rtl-text/blob/main/LICENSE.md>
  - maplibre-gl-compare: ISC: <https://github.com/maplibre/maplibre-gl-compare/blob/main/LICENCE>
  - maplibre-gl-inspect: BSD 3-Clause: <https://github.com/maplibre/maplibre-gl-inspect/blob/main/LICENSE>
  - fflate: MIT: <https://github.com/101arrowz/fflate/blob/master/LICENSE>
  - mapbox-gl-infobox: GPL-3: <https://github.com/el/infobox-control/blob/master/LICENSE>
  - maplibre-contour: BSD 3-Clause: <https://github.com/onthegomap/maplibre-contour/blob/main/LICENSE>
  - sql.js-httpvfs: Apache-2: <https://github.com/phiresky/sql.js-httpvfs/blob/master/LICENSE>
  - protomaps-leaflet: BSD 3-Clause: <https://github.com/protomaps/protomaps-leaflet/blob/main/LICENSE>
  - leaflet: BSD 2-Clause: <https://github.com/Leaflet/Leaflet/blob/main/LICENSE>

For datasets the licenses are included in the datasets.

## TODOs

- [ ] Docs:
  - [ ] terrarium split & overlays
  - [ ] changes to upstream tile builds:
    - [ ] openmaptiles: Added more languages
    - [ ] protomaps: reduced zoom level to 14 (but included all features on that zoom), add more languages
    - [ ] shortbread: Added more langauges, added some poi types (harbor?)?
      - [ ] Add the tags from <https://github.com/shortbread-tiles/shortbread-tilemaker/blob/a92a462bc83dc7dc4910c90da4c236fee23b1b27/process.lua#L937>, that seems to be more up to date
      - [ ] Fix boundary labels being empty
- [ ] Styles
  - [ ] Add <https://gitlab.com/trailstash/openstyle> with the additional data as a separate vector source
  - [ ] Add ferry_terminal icons to at least shortbread, add at least harbor to shortbread spec and versatiles <https://github.com/versatiles-org/versatiles-style/blob/main/icons/transport/harbor.svg>
- [ ] Fonts
  - [ ] Handle fonts with duplicate names when <https://github.com/google/fonts/issues/8776> is answered
- [ ] NE vector
  - [ ] Cleanup scripts
  - [ ] Move into a planetiler build instead of hacky bash scripts
  - [ ] use ne_10m_roads_north_america
  - [ ] use ne_10m_railroads_north_america
- [ ] mbtiles client option (started in client/mbtiles.js)
- [ ] Perf comparison between different serving modes and servers
- [ ] Add <https://github.com/wipfli/foursquare-os-places-pmtiles> as a POI dataset
- [ ] Reverse geocoding (by parsing exisiting vector tiles, started in TMP-remove-experimentreverse-geocode-via-tiles.js)
- [ ] Better attribution free maps by adding more wikidata
- [ ] Landcover tiles
- [ ] Mapzen tiles & styles (compare with protomaps)
- [ ] Geocoding
- [ ] Routing
- [ ] Add maplibre-geoman-free with realtime capabilities (via webrtc datachannels)
- [ ] Add CSP guidance
- [ ] Create torrents for all the large datasets
- [ ] Build steps for <https://shortbread.geofabrik.de/shapefiles/admin-points-4326.zip>: <https://github.com/shortbread-tiles/shortbread-tilemaker/blob/main/boundary_labels_shape_file.md>

## Issues

- <https://github.com/shortbread-tiles/shortbread-docs>
  - No admin levels past 4 (6 for counties)
  - language tag separator: <https://github.com/shortbread-tiles/shortbread-docs/issues/72>
  - pois/sites harbour=yes
  - sites leisure=park
  - sites leisure=nature_reserve
  - sites boundary=national_park
- <https://github.com/protomaps/basemaps>
  - No maritime boundaries?
  - pois harbour
  - no places kind=county, but there is boundaries kind=county
  - places capital=yes¡2|4|6? Why mix string and bool
  - Reason for including both earth and ocean
- <https://github.com/openmaptiles/openmaptiles>
  - Licensing, interpertation of CC-BY <https://github.com/openmaptiles/openmaptiles/issues/1318>
    - CC-BY cannot include requirements of where to display the attributions: <https://creativecommons.org/faq/#can-i-insist-on-the-exact-placement-of-the-attribution-credit> but openmaptiles does

## Fonts excluded due to missing licenses

```txt
Kumar One Outline
M PLUS Rounded 1c
M PLUS Rounded 1c Black
M PLUS Rounded 1c Bold
M PLUS Rounded 1c Extra Bold
M PLUS Rounded 1c Light
M PLUS Rounded 1c Medium
M PLUS Rounded 1c Thin
js Math-cmbx10
js Math-cmex10
js Math-cmmi10
js Math-cmr10
js Math-cmsy10
js Math-cmti10
```

## Build full dataset from scratch

WARNING: This will use about 5TB and take 14-20 days

Running the whole build from scratch requires a somewhat beefy machine (64-128GB RM, good CPU) and around 14-20 days.

To run use `./build.sh build_image` to build an image with all the tools to build the files. Prep to run with `mkdir -p /usr/local/lib/kxnu/sites/maps.black/` and run the image with `portablectl attach --profile trusted --enable --now --no-block ./maps.black.raw`. You can view progress with `journalctl -fu maps.black-*`.

These steps do not build terrarium/s2maps since they are merely a packaged version of what is available from their upstreams. If you want to package them yourself I'm guessing you know how to download with curl and package into mbtils/pmtiles from the examples in the repo.

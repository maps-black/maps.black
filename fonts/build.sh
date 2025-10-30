#!/usr/bin/env bash
set -xeuo pipefail
. ../utils.sh

notoVariants="Noto Znamenny Musical Notation
Noto Fangsong KSSVertical
Noto Fangsong KSSRotated
Noto Traditional Nushu
Noto Nastaliq Urdu
Noto Naskh Arabic
Noto Rashi Hebrew
Noto Kufi Arabic
Noto Music
Noto Serif
Noto Sans"

notoVariantStyles="Extra Condensed Extra Light Italic
Semi Condensed Extra Light Italic
Extra Condensed Extra Bold Italic
Semi Condensed Extra Bold Italic
Extra Condensed Semi Bold Italic
Semi Condensed Semi Bold Italic
Extra Condensed Medium Italic
Semi Condensed Medium Italic
Extra Condensed Light Italic
Extra Condensed Black Italic
Condensed Extra Light Italic
Semi Condensed Light Italic
Semi Condensed Black Italic
Extra Condensed Thin Italic
Extra Condensed Extra Light
Extra Condensed Bold Italic
Condensed Extra Bold Italic
Semi Condensed Thin Italic
Semi Condensed Extra Light
Semi Condensed Bold Italic
Extra Condensed Extra Bold
Condensed Semi Bold Italic
Semi Condensed Extra Bold
Extra Condensed Semi Bold
Semi Condensed Semi Bold
Condensed Medium Italic
Extra Condensed Medium
Extra Condensed Italic
Condensed Light Italic
Condensed Black Italic
Semi Condensed Medium
Semi Condensed Italic
Extra Condensed Light
Extra Condensed Black
Condensed Thin Italic
Condensed Extra Light
Condensed Bold Italic
Semi Condensed Light
Semi Condensed Black
Extra Condensed Thin
Extra Condensed Bold
Condensed Extra Bold
Semi Condensed Thin
Semi Condensed Bold
Condensed Semi Bold
Extra Light Italic
Extra Bold Italic
Semi Bold Italic
Condensed Medium
Condensed Italic
Extra Condensed
Condensed Light
Condensed Black
Semi Condensed
Condensed Thin
Condensed Bold
Medium Italic
Light Italic
Black Italic
Thin Italic
Extra Light
Bold Italic
Extra Bold
Semi Bold
Condensed
Regular
Medium
Italic
Light
Black
Thin
Bold"

build() {
  set -xeuo pipefail
  convert_font() {
    set -xeuo pipefail
    dir="$1"
    cd "$dir"
    rm -rf "./processed"
    font-maker --name "$dir" "./processed" *.ttf >/dev/null
    mv ./processed/*/* ./
    rm -rf processed *.ttf
  }
  export -f convert_font

  compress_font() {
    set -xeuo pipefail
    cd "$1"
    for f in ./*; do
      if [ ! -f "$f" ] || [[ $f == *".txt" ]]; then
        continue
      fi
      gzip -f9 "$f"
      mv -f "$f".gz "$f"
    done
  }
  export -f compress_font

  if [ ! -f ./fonts-full.squashfs ]; then
    (
      set -xeuo pipefail
      if [ -d fonts-full ]; then
        umount ./fonts-full || true
        rm -rf ./fonts-full
      fi
      if [ -d fonts-core ]; then
        umount ./fonts-core || true
        rm -rf ./fonts-core
      fi
      if [ -d fonts-minimal ]; then
        umount ./fonts-minimal || true
        rm -rf ./fonts-minimal
      fi
      mkdir -p fonts-full
      cd fonts-full
      git clone --quiet https://github.com/vernnobile/NunitoFont.git
      (cd NunitoFont && git reset ${nunitoFontVersion} --hard)
      cp NunitoFont/version-2.0/*.ttf ./
      git clone --quiet https://github.com/googlefonts/NunitoSans.git
      (cd NunitoSans && git reset ${nunitoSansFontVersion} --hard)
      cp NunitoSans/fonts/ttf/*.ttf ./
      git clone --quiet https://github.com/dw5/Metropolis.git
      (cd Metropolis && git reset ${metropolisFontVersion} --hard)
      cp Metropolis/Fonts/TrueType/*.ttf ./
      git clone --quiet https://github.com/googlefonts/opensans.git
      (cd opensans && git reset ${openSansFontVersion} --hard)
      cp opensans/fonts/ttf/*.ttf ./
      git clone --quiet https://github.com/googlefonts/roboto-2.git
      (cd roboto-2 && git reset ${robotoFontVersion} --hard)
      cp roboto-2/src/hinted/*.ttf ./
      git clone --quiet https://github.com/googlefonts/robotoslab.git
      (cd robotoslab && git reset ${robotoSlabFontVersion} --hard)
      cp robotoslab/fonts/ttf/*.ttf ./
      git clone --quiet https://github.com/googlefonts/josefinsans.git
      (cd josefinsans && git reset ${josefinSansFontVersion} --hard)
      cp josefinsans/fonts/ttf/*.ttf ./
      git clone --quiet https://github.com/indestructible-type/Jost.git
      (cd Jost && git reset ${jostFontVersion} --hard)
      cp Jost/fonts/ttf/*.ttf ./
      git clone --quiet https://github.com/JulietaUla/Montserrat.git
      (cd Montserrat && git reset ${montserratFontVersion} --hard)
      cp Montserrat/fonts/ttf/*.ttf ./
      git clone --quiet https://github.com/itfoundry/Poppins.git
      (cd Poppins && git reset ${poppinsFontVersion} --hard)
      (
        cd Poppins/products/Poppins-4.003-GoogleFonts-TTF
        ttx *
      )
      cp Poppins/products/Poppins-4.003-GoogleFonts-TTF/*.ttf ./

      find . -maxdepth 1 -name "*[0-9]*" -type f -exec sh -c 'mv "{}" "$(echo "{}" | sed -E "s/[0-9]+-?//g")"' \;
      find . -maxdepth 1 -name "*[a-z][A-Z]*" -type f -exec sh -c 'mv "{}" "$(echo "{}" | sed -E "s/([a-z])([A-Z])/\1 \2/g")"' \;
      find . -maxdepth 1 -name "*[a-z][A-Z]*" -type f -exec sh -c 'mv "{}" "$(echo "{}" | sed -E "s/([a-z])([A-Z])/\1 \2/g")"' \;
      find . -maxdepth 1 -name "*[a-z][A-Z]*" -type f -exec sh -c 'mv "{}" "$(echo "{}" | sed -E "s/([a-z])([A-Z])/\1 \2/g")"' \;
      find . -maxdepth 1 -name "*-*" -type f -exec sh -c 'mv "{}" "$(echo "{}" | sed -E "s/-/ /g")"' \;
      for f in ./*.ttf; do
        filename="${f##*/}"
        name="${filename/.ttf/}"
        mkdir -p "$name"
        mv "$filename" "$name"/
      done
      for dir in Nunito*; do cp NunitoFont/OFL.txt "$dir/LICENSE.txt"; done
      for dir in Metropolis*; do cp Metropolis/UNLICENSE "$dir/LICENSE.txt"; done
      for dir in Open\ Sans*; do cp opensans/OFL.txt "$dir/LICENSE.txt"; done
      for dir in Roboto*; do cp roboto-2/LICENSE "$dir/LICENSE.txt"; done
      for dir in Josefin*; do cp josefinsans/OFL.txt "$dir/LICENSE.txt"; done
      for dir in Jost*; do cp Jost/OFL.txt "$dir/LICENSE.txt"; done
      for dir in Montserrat*; do cp Montserrat/OFL.txt "$dir/LICENSE.txt"; done
      for dir in Poppins*; do cp Poppins/OFL.txt "$dir/LICENSE.txt"; done
      rm -rf NunitoFont NunitoSans Metropolis opensans roboto-2 robotoslab josefinsans Jost Montserrat Poppins
      git clone --quiet https://github.com/notofonts/notofonts.github.io.git
      cp -f notofonts.github.io/fonts/*/hinted/ttf/*.ttf ./
      cp -f notofonts.github.io/fonts/*/unhinted/ttf/*.ttf ./
      find . -maxdepth 1 -name "*Semibold*" -type f -exec sh -c 'mv "{}" "$(echo "{}" | sed -E "s/Semibold/SemiBold/g")"' \;
      find . -maxdepth 1 -name "*[a-z][A-Z]*" -type f -exec sh -c 'mv "{}" "$(echo "{}" | sed -E "s/([a-z])([A-Z])/\1 \2/g")"' \;
      find . -maxdepth 1 -name "*-*" -type f -exec sh -c 'mv "{}" "$(echo "{}" | sed -E "s/-/ /g")"' \;
      # Prefer UI/Display variants
      find . -maxdepth 1 -name "* UI *" -type f -exec sh -c 'mv -f "{}" "$(echo "{}" | sed -E "s/ UI / /g")"' \;
      find . -maxdepth 1 -name "* Display *" -type f -exec sh -c 'mv -f "{}" "$(echo "{}" | sed -E "s/ Display / /g")"' \;
      while IFS= read -r variant; do
        while IFS= read -r style; do
          if ls "$variant"*"$style.ttf" 1>/dev/null 2>&1; then
            mkdir -p "$variant $style"
            mv "$variant"*"$style.ttf" "$variant $style"/
          fi
        done <<<"$notoVariantStyles"
      done <<<"$notoVariants"
      for dir in Noto*; do cp notofonts.github.io/LICENSE "$dir/LICENSE.txt"; done
      rm -rf notofonts.github.io

      (
        set -xeuo pipefail
        cd ../
        rm -rf fonts-core
        cp -r fonts-full fonts-core
        cd fonts-core
        parallel --halt soon,fail=1 --no-notice convert_font {} ::: *
        parallel --halt soon,fail=1 --no-notice compress_font {} ::: *
      )

      (
        set -xeuo pipefail
        cd ../
        rm -rf fonts-minimal
        mkdir -p fonts-minimal
        # These should always be the list of the fonts directly required by the styles
        cp -r \
          fonts-core/Josefin\ Sans\ Bold \
          fonts-core/Josefin\ Sans\ Bold\ Italic \
          fonts-core/Josefin\ Sans\ Light\ Italic \
          fonts-core/Josefin\ Sans\ Regular \
          fonts-core/Jost\ Bold \
          fonts-core/Jost\ Medium \
          fonts-core/Jost\ Medium\ Italic \
          fonts-core/Metropolis\ Light \
          fonts-core/Metropolis\ Light\ Italic \
          fonts-core/Metropolis\ Medium\ Italic \
          fonts-core/Metropolis\ Regular \
          fonts-core/Noto\ Sans\ Bold \
          fonts-core/Noto\ Sans\ Bold\ Italic \
          fonts-core/Noto\ Sans\ Condensed \
          fonts-core/Noto\ Sans\ Extra\ Bold \
          fonts-core/Noto\ Sans\ Italic \
          fonts-core/Noto\ Sans\ Light\ Italic \
          fonts-core/Noto\ Sans\ Medium \
          fonts-core/Noto\ Sans\ Regular \
          fonts-core/Noto\ Sans\ Semi\ Bold \
          fonts-core/Noto\ Sans\ Semi\ Bold\ Italic \
          fonts-core/Nunito\ Bold \
          fonts-core/Nunito\ Extra\ Bold \
          fonts-core/Nunito\ Regular \
          fonts-core/Nunito\ Semi\ Bold \
          fonts-core/Open\ Sans\ Italic \
          fonts-core/Open\ Sans\ Regular \
          fonts-core/Open\ Sans\ Semi\ Bold\ Italic \
          fonts-core/Poppins\ Italic \
          fonts-core/Poppins\ Medium \
          fonts-core/Poppins\ Regular \
          fonts-core/Roboto\ Condensed\ Italic \
          fonts-core/Roboto\ Medium \
          fonts-core/Roboto\ Regular \
          fonts-core/Montserrat\ Regular \
          fonts-core/Montserrat\ Medium \
          fonts-core/Montserrat\ Italic \
          fonts-core/Montserrat\ Medium\ Italic \
          fonts-minimal/
      )

      rm -rf google-fonts
      git clone --quiet https://github.com/google/fonts.git google-fonts
      (cd google-fonts && git reset ${googleFontsVersion} --hard)

      # These are handled separately above
      rm -rf google-fonts/*/noto* google-fonts/*/nunito* google-fonts/*/roboto* google-fonts/*/opensans* google-fonts/*/poppins* google-fonts/*/jost* google-fonts/*/josefinsans* google-fonts/*/montserrat*

      # Function to be used in parallel execution to prepare fonts
      process_font() {
        set -xeuo pipefail
        f="$1"
        dirpath="$(dirname "$f")"
        sed -z 's/\n  //g' <"$f" | grep -Eo 'fonts \{[^\}]*filename: "([^"]*)"[^\}]*full_name: "([^"]*)"[^\}]*' | while read -r FONT; do
          FILENAME="$(grep -Po 'filename: "\K([^"]*)' <<<"$FONT")"
          FONTNAME="$(grep -Po 'full_name: "\K([^"]*)' <<<"$FONT")"
          FONTPATH="$dirpath/$FILENAME"
          mkdir -p "$FONTNAME"
          mv -f "$FONTPATH" "$FONTNAME/source.ttf"

          if [ -f "$dirpath/LICENCE.txt" ]; then
            cp -f "$dirpath/LICENCE.txt" "./$FONTNAME/LICENSE.txt"
          fi
          if [ -f "$dirpath/LICENSE.txt" ]; then
            cp -f "$dirpath/LICENSE.txt" "./$FONTNAME/LICENSE.txt"
          fi
          if [ -f "$dirpath/OFL.txt" ]; then
            cp -f "$dirpath/OFL.txt" "./$FONTNAME/LICENSE.txt"
          fi
        done
      }
      export -f process_font
      parallel --halt soon,fail=1 --no-notice process_font {} ::: ./google-fonts/*/*/METADATA.pb

      rm -rf ./google-fonts

      find . -maxdepth 1 -name "*Semibold*" -type d -exec sh -c 'mv "{}" "$(echo "{}" | sed -E "s/Semibold/SemiBold/g")"' \;
      find . -maxdepth 1 -name "*[a-z][A-Z]*" -type d -exec sh -c 'mv "{}" "$(echo "{}" | sed -E "s/([a-z])([A-Z])/\1 \2/g")"' \;

      for f in ./*; do
        if [ ! -f "$f/LICENSE.txt" ]; then
          echo "$f is missing LICENSE.txt, removing"
          rm -rf "$f"
        fi
      done

      parallel --halt soon,fail=1 --no-notice convert_font {} ::: *
      parallel --halt soon,fail=1 --no-notice compress_font {} ::: *
    )

    for sizeVariant in '-minimal' '-core' '-full'; do
      find ./fonts$sizeVariant -type d -exec chmod 777 {} \;
      mksquashfs ./fonts$sizeVariant ./.fonts$sizeVariant.squashfs -exit-on-error -quiet -noD -comp zstd -Xcompression-level 6 -fstime 0 -all-time 0 -no-xattrs -all-root -no-progress &&
        mv -f ./.fonts$sizeVariant.squashfs ./fonts$sizeVariant.squashfs
      rm -rf ./fonts$sizeVariant
    done
  fi

  for sizeVariant in '-minimal' '-core' '-full'; do
    if [ ! -f ./fontsprep$sizeVariant.squashfs ] || [[ "./fonts$sizeVariant.squashfs" -nt "./fontsprep$sizeVariant.squashfs" ]]; then
      if [ -d fonts$sizeVariant ]; then
        umount ./fonts$sizeVariant || true
        rm -rf ./fonts$sizeVariant
      fi
      mkdir -p fonts$sizeVariant
      mount ./fonts$sizeVariant.squashfs fonts$sizeVariant
      rm -rf fontsprep$sizeVariant
      mkdir -p fontsprep$sizeVariant/0/0/
      echo '{"files": [], "fonts": []}' >fontsprep$sizeVariant/0/0/0.json
      i=0
      for _fontName in ./fonts$sizeVariant/*; do
        mkdir -p fontsprep$sizeVariant/21/$i fontsprep$sizeVariant/20/$i
        fontName="${_fontName##*/}"
        jq --arg fontName "$fontName" -c -r '.fonts |= .+ [$fontName]' fontsprep$sizeVariant/0/0/0.json | sponge fontsprep$sizeVariant/0/0/0.json
        for _fileName in "./fonts$sizeVariant/$fontName/"*.pbf; do
          pathExtLess="${_fileName/.pbf/}"
          fileName="${_fileName##*/}"
          name="${fileName/.pbf/}"
          startpoint="${name%%-*}"
          cp "./$_fileName" "./fontsprep$sizeVariant/21/$i/$startpoint.pbf"
        done
        if [ -f "./fonts$sizeVariant/$fontName/LICENSE.txt" ]; then
          cp "./fonts$sizeVariant/$fontName/LICENSE.txt" "./fontsprep$sizeVariant/20/$i/0.pbf"
          gzip -f9 "./fontsprep$sizeVariant/20/$i/0.pbf"
          mv -f "./fontsprep$sizeVariant/20/$i/0.pbf.gz" "./fontsprep$sizeVariant/20/$i/0.pbf"
        fi
        i=$((i + 1))
      done
      umount ./fonts$sizeVariant || true
      rm -rf ./fonts$sizeVariant
      find ./fontsprep$sizeVariant -type d -exec chmod 777 {} \;
      mksquashfs ./fontsprep$sizeVariant ./.fontsprep$sizeVariant.squashfs -exit-on-error -quiet -noD -comp zstd -Xcompression-level 6 -fstime 0 -all-time 0 -no-xattrs -all-root -no-progress &&
        mv -f ./.fontsprep$sizeVariant.squashfs ./fontsprep$sizeVariant.squashfs
      rm -rf ./fontsprep$sizeVariant
    fi
  done
}

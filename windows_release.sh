#!/bin/bash -eu

# This script assumes you already have built the executable

rm -rf release
mkdir -p release

cp principia.exe release/

WINE=${MSYSTEM:+}
WINE=${WINE:-wine}

if [[ -z "${MSYSTEM-}" ]]; then
	$WINE $MINGW_PREFIX/bin/gdk-pixbuf-query-loaders.exe --update-cache
fi

cd release
# collect up GTK3 junk to make it work
PIXBUF_DIR="lib/gdk-pixbuf-2.0/2.10.0"
mkdir -p $PIXBUF_DIR/loaders/
cp $MINGW_PREFIX/$PIXBUF_DIR/loaders.cache $PIXBUF_DIR/
cp $MINGW_PREFIX/$PIXBUF_DIR/loaders/libpixbufloader-{jpeg,png}.dll $PIXBUF_DIR/loaders/

SCHEMAS_DIR="share/glib-2.0/schemas"
mkdir -p $SCHEMAS_DIR
cp $MINGW_PREFIX/$SCHEMAS_DIR/{gschema.dtd,gschemas.compiled} $SCHEMAS_DIR/

if [[ -z "${MSYSTEM-}" ]]; then
	list=$($WINE $MINGW_PREFIX/bin/ntldd.exe --search-dir $MINGW_PREFIX/bin -R principia.exe | awk '$3 ~ /^Z:\\/ {gsub(/^Z:/, "", $3); gsub(/\\/, "/", $3); print $3}')
else
	list=$(ldd principia.exe | grep $MINGW_PREFIX | sed 's/.* => //' | sed 's/ \(.*\)//')
fi

for dll in $list; do
	cp -v $dll .
done

cd ..

cp ../packaging/principia_install.nsi .
cp -r ../packaging/installer/ .

$WINE $MINGW_PREFIX/bin/makensis.exe principia_install

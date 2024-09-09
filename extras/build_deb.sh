#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
NODE_RED_DIR=$(realpath $SCRIPT_DIR/..)


rm -rf node_modules
export CC=riscv64-unknown-linux-musl-gcc
export CXX=riscv64-unknown-linux-musl-g++

NODE_ENV=production yarn install --arch=riscv64

PACKAGE_NAME=$(jq -r '.name' package.json)
VERSION=$(jq -r '.version' package.json)
ARCH="riscv64"
DESCRIPTION="Node-RED packages and node_modules"

WORK_DIR=$(mktemp -d)
BUILD_DIR="$WORK_DIR/$PACKAGE_NAME"
DEBIAN_DIR="$BUILD_DIR/DEBIAN"

mkdir -p "$DEBIAN_DIR"
mkdir -p "$BUILD_DIR/usr/lib/node-red"

cp -r $NODE_RED_DIR/packages $BUILD_DIR/usr/lib/node-red/
cp -r $NODE_RED_DIR/node_modules $BUILD_DIR/usr/lib/node-red/
cp -r $NODE_RED_DIR/extras/files/* $BUILD_DIR/

cp -r $NODE_RED_DIR/extras/control/* $DEBIAN_DIR/

cat <<EOL > "$DEBIAN_DIR/control"
Package: $PACKAGE_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: Seeed Studio
Description: $DESCRIPTION
EOL

chmod -R 755 "$DEBIAN_DIR"
chmod 644 "$DEBIAN_DIR/control"

dpkg-deb -Zgzip --root-owner-group --build "$BUILD_DIR/"

mkdir -p "./.dist"
mv "$BUILD_DIR.deb" "./.dist/$PACKAGE_NAME-$VERSION-$ARCH.deb"
rm -rf "$WORK_DIR"

echo "Deb package $PACKAGE_NAME-$VERSION-$ARCH.deb created successfully!"

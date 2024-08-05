#!/bin/bash

sudo dnf install yarn

PKG_VERSION=$(rpmspec -q --queryformat="%{VERSION}" *.spec --srpm)
PKG_URL=$(cat *.spec |grep '^Source0:' | sed -e "s/Source0:[ ]*//g;s/%{version}/$PKG_VERSION/g")
PKG_TARBALL=$(basename $PKG_URL)
PKG_NAME=$(rpmspec -q --queryformat="%{NAME}" *.spec --srpm | sed 's/^python-//')
PKG_SRCDIR="${PKG_NAME}-${PKG_VERSION}"
PKG_DIR="$PWD"
PKG_TMPDIR=$(mktemp --tmpdir -d ${PKG_NAME}-XXXXXXXX)
PKG_PATH="$PKG_TMPDIR/$PKG_SRCDIR/"

echo "URL:     $PKG_URL"
echo "TARBALL: $PKG_TARBALL"
echo "NAME:    $PKG_NAME"
echo "VERSION: $PKG_VERSION"
echo "PATH:    $PKG_PATH"

cleanup_tmpdir() {
    popd 2>/dev/null
    rm -rf $PKG_TMPDIR
    rm -rf /tmp/yarn--*
}
trap cleanup_tmpdir SIGINT

cleanup_and_exit() {
    cleanup_tmpdir
    if test "$1" = 0 -o -z "$1" ; then
        exit 0
    else
        exit $1
    fi
}

if [ ! -w "$PKG_TARBALL" ]; then
    wget "$PKG_URL"
fi


mkdir -p $PKG_TMPDIR
tar -xf $PKG_TARBALL -C $PKG_TMPDIR

cd $PKG_PATH

export YARN_CACHE_FOLDER="$PWD/.package-cache"
echo ">>>>>> Install npm modules"
rm package-lock.json
yarn install
if [ $? -ne 0 ]; then
    echo "ERROR: yarn install failed"
    cleanup_and_exit 1
fi

echo ">>>>>> Cleanup object dirs"
find node_modules/ -type d -name "*.o.d" -execdir rm {} +
find node_modules/ -type d -name "__pycache__" -execdir rm {} +

echo ">>>>>> Cleanup object files"
find node_modules/ -name "*.node" -execdir rm {} +

find node_modules/ -name "*.dll" | grep -Fv signal-client | xargs rm -f
find node_modules/ -name "*.dylib" -delete
find node_modules/ -name "*.so" -delete
find node_modules/ -name "*.o" -delete
find node_modules/ -name "*.a" -delete
find node_modules/ -name "*.snyk-*.flag" -delete

echo ">>>>>> Cleanup build info"
find node_modules/ -name "builderror.log" -delete
find node_modules/ -name "yarn-error.log" -delete
find node_modules/ -name "yarn.lock" -delete
find node_modules/ -name ".deps" -type d -execdir rm {} +
find node_modules/ -name "Makefile" -delete
find node_modules/ -name "*.target.mk" -delete
find node_modules/ -name "config.gypi" -delete
find node_modules/ -name "package.json" -exec sed -i "s#$PKG_PATH#/tmp#g" {} \;

echo ">>>>>> Cleanup yarn tarballs"
find node_modules/ -name ".yarn-tarball.tgz" -delete

echo ">>>>>> Cleanup source maps"
find node_modules/ -name "*.js.map" -delete
find node_modules/ -name "*.ts.map" -delete
find node_modules/ -name "*.mjs.map" -delete
find node_modules/ -name "*.cjs.map" -delete
find node_modules/ -name "*.css.map" -delete
find node_modules/ -name "*.min.map" -delete

echo ">>>>>> Package vendor files"
rm -f $PKG_DIR/${PKG_NAME}-${PKG_VERSION}-vendor.tar.xz
XZ_OPT="-9e -T$(nproc)" tar cJf $PKG_DIR/${PKG_NAME}-${PKG_VERSION}-vendor.tar.xz .package-cache
if [ $? -ne 0 ]; then
    cleanup_and_exit 1
fi

yarn add license-checker
yarn license-checker --summary | sed "s#$PKG_PATH#/tmp#g" > $PKG_DIR/${PKG_NAME}-${PKG_VERSION}-vendor-licenses.txt

cd -

rm -rf .package-cache
cleanup_and_exit 0

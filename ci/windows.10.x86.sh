set -x
echo "CI: Windows 10 x86"

# FIXME: workaround for calling 32bit builds directly instead of environment detection
# determine build version
git describe --tags --exact-match 2> /dev/null
if [ $? -eq 0 ]; then
	BUILD_VERSION=`git describe --tags --exact-match`
else
	BUILD_BRANCH=`git rev-parse --abbrev-ref HEAD`
	BUILD_COMMIT=`git rev-parse --short HEAD`
	BUILD_VERSION="$BUILD_BRANCH-$BUILD_COMMIT"
fi
export BUILD_VERSION

echo "CI: Building static release..."
./build.sh
if [ $? -ne 0 ]; then
	echo "CI: Build failed with error code: $?"
	exit 1
fi

echo "CI: Building deployable binary..."
cd build
make deploy
if [ $? -ne 0 ]; then
	echo "CI: Build failed with error code: $?"
	exit 1
fi
cd ..

echo "CI: Creating release archive..."
RELEASE_NAME="intensecoin-gui-win-32bit-$BUILD_VERSION"
cd build/release/bin/
mkdir $RELEASE_NAME
ls -alR
#cp XYZ $RELEASE_NAME/
cp ../../../ci/package-artifacts/CHANGELOG.txt $RELEASE_NAME/
cp ../../../ci/package-artifacts/README.txt $RELEASE_NAME/
zip -rv $RELEASE_NAME.zip $RELEASE_NAME
sha256sum $RELEASE_NAME.zip > $RELEASE_NAME.zip.sha256.txt

#!/usr/bin/env bash

echo "==> Downloading XCActionBar..."
mkdir -p /var/tmp/XCActionBarInstall && cd /var/tmp/XCActionBarInstall
git clone https://github.com/pdcgomes/XCActionBar.git /var/tmp/XCActionBarInstall > /dev/null

echo ""
echo "==> Installing XCActionBar..."

xcodebuild clean > /dev/null
xcodebuild > /dev/null

cd ~
rm -rf /var/tmp/XCActionBarInstall

echo "==> Installation completed!"
echo "==> Please restart Xcode and enjoy XCActionBar!"

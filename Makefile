.PHONY: plugin
plugin:
	xcodebuild ARCHS=x86_64 VALID_ARCHS=x86_64 ONLY_ACTIVE_ARCH=NO -configuration Release
	command -v postbuild-codesign >/dev/null 2>&1 && postbuild-codesign
	command -v postbuild-notarize >/dev/null 2>&1 && postbuild-notarize
	cp -r build/Release/*.glyphsPlugin .

.PHONY: clean
clean:
	rm -rf build
	rm -rf *.glyphsPlugin

archive: clean plugin
	CURRENT_DIR=$$(pwd); \
	PROJECT_NAME=$$(basename "$${CURRENT_DIR}"); \
	git archive -o "build/Release/$${PROJECT_NAME}-$$(git rev-parse --short HEAD).zip" HEAD

dist: clean plugin archive

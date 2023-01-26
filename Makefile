PROJECT_NAME := $(shell xcodebuild -list | grep -i 'information about project' | sed 's/^.*"\(.*\)":/\1/g')
TARGET       := $(shell xcodebuild -list | grep -A2 -E '\s+Targets:' | grep -v 'Targets:' | sed 's/^ *//g' | sort -r | head -1)

.PHONY: plugin
plugin:
	xcodebuild -target $(TARGET)
	command -v postbuild-codesign >/dev/null 2>&1 && postbuild-codesign
	command -v postbuild-notarize >/dev/null 2>&1 && postbuild-notarize
	cp -r build/Release/*.glyphsPlugin .

.PHONY: clean
clean:
	rm -rf build
	rm -rf *.glyphsPlugin

archive: clean plugin
	git archive -o "build/Release/$(PROJECT_NAME)-$$(git rev-parse --short HEAD).zip" HEAD

dist: clean plugin archive

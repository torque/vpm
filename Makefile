.PHONY: all debug release clean

all: debug

debug:
	xctool -reporter pretty -project vpm.xcodeproj -scheme vpm -configuration Debug
#	xcodebuild -project vpm.xcodeproj -target vpm -configuration Debug

release:
	xctool -project vpm.xcodeproj -scheme vpm -configuration Release
#	xcodebuild -project vpm.xcodeproj -target vpm -configuration Release

clean:
	rm -rf build

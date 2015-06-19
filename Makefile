.PHONY: all debug release clean

all: debug

debug:
	xctool -project vpm.xcodeproj -scheme vpm -configuration Debug build OBJROOT="build" SYMROOT="build"
	# xcodebuild -project vpm.xcodeproj -target vpm -configuration Debug build OBJROOT="build" SYMROOT="build"

release:
	xctool -project vpm.xcodeproj -scheme vpm -configuration Release build OBJROOT="build" SYMROOT="build"
	# xcodebuild -project vpm.xcodeproj -target vpm -configuration Release build OBJROOT="build" SYMROOT="build"

clean:
	rm -rf build

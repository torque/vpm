PREFIX := build/deps
BASE := .

# stop talloc from dumping debug strings everywhere.
MPVCFLAGS := -DTA_NO_WRAPPERS=1 -I$(realpath $(PREFIX))/include
MPVLDFLAGS := -L$(realpath $(PREFIX))/lib

VIDEO_INTERFACE_DEPS := src/web-ui/scripts/fullscreenButton.coffee
VIDEO_INTERFACE_DEPS += src/web-ui/scripts/globals.coffee
VIDEO_INTERFACE_DEPS += src/web-ui/scripts/hoverTime.coffee
VIDEO_INTERFACE_DEPS += src/web-ui/scripts/playButton.coffee
VIDEO_INTERFACE_DEPS += src/web-ui/scripts/playTime.coffee
VIDEO_INTERFACE_DEPS += src/web-ui/scripts/seekBar.coffee
VIDEO_INTERFACE_DEPS += src/web-ui/scripts/volumeWidget.coffee

VIDEO_INTERFACE_DEPS += src/web-ui/styles/bottomBar.styl
VIDEO_INTERFACE_DEPS += src/web-ui/styles/fullscreenButton.styl
VIDEO_INTERFACE_DEPS += src/web-ui/styles/hoverTime.styl
VIDEO_INTERFACE_DEPS += src/web-ui/styles/main.styl
VIDEO_INTERFACE_DEPS += src/web-ui/styles/mixins.styl
VIDEO_INTERFACE_DEPS += src/web-ui/styles/playButton.styl
VIDEO_INTERFACE_DEPS += src/web-ui/styles/playTime.styl
VIDEO_INTERFACE_DEPS += src/web-ui/styles/seekBar.styl
VIDEO_INTERFACE_DEPS += src/web-ui/styles/volumeWidget.styl

.PHONY: all libmpv ffmpeg video-interface debug release clean

all: debug

debug:
	@xctool -reporter pretty -project vpm.xcodeproj -scheme vpm -configuration Debug
# @xcodebuild -project vpm.xcodeproj -target vpm -configuration Debug

release: MPVCFLAGS += -DNDEBUG
release:
	@xctool -project vpm.xcodeproj -scheme vpm -configuration Release
#	@xcodebuild -project vpm.xcodeproj -target vpm -configuration Release

clean:
	rm -rf build

video-interface: $(BASE)/src/web-ui/video.html

$(BASE)/src/web-ui/video.html: $(BASE)/src/web-ui/video.jade $(VIDEO_INTERFACE_DEPS)
	@jade -P $<

libmpv: $(PREFIX)/lib/libmpv.dylib

$(PREFIX)/lib/libmpv.dylib: $(BASE)/deps/mpv/build/config.h
	@echo waf build
	@cd $(BASE)/deps/mpv && ./waf build
	@echo waf install
	@cd $(BASE)/deps/mpv && ./waf install

# This is kind of a mediocre dependency chain both in terms of rebuilding mpv as
# well as determining when to reconfigure mpv, but I'd rather have it not run in
# every case it should than run in cases it shouldn't. The xcode script handles
# the awkward case of switching between debug and release prefixes.
$(BASE)/deps/mpv/build/config.h: $(PREFIX)/lib/libavcodec.dylib $(BASE)/deps/mpv/waf | $(PREFIX)
	@echo waf configure
	@cd $(BASE)/deps/mpv && CFLAGS="$(MPVCFLAGS)" LINKFLAGS="$(MPVLDFLAGS)" ./waf configure --lua=luajit --disable-cplayer --enable-libmpv-shared --disable-encoding "--prefix=$(realpath $(PREFIX))" >/dev/null 2>&1
	@# clear out personal filesystem details from the configuration header, since
	@# they get baked into the binary.
	@sed -e "s:$(realpath $(PREFIX))::g" -i .bak $@

$(BASE)/deps/mpv/waf:
	@cd $(BASE)/deps/mpv && ./bootstrap.py

ffmpeg: $(PREFIX)/lib/libavcodec.dylib

$(PREFIX)/lib/libavcodec.dylib: $(BASE)/deps/FFmpeg/config.h
	@echo ffmpeg build
	@$(MAKE) -C $(BASE)/deps/FFmpeg install

$(BASE)/deps/FFmpeg/config.h: | $(PREFIX)
	@cd $(BASE)/deps/FFmpeg && ./configure --disable-static --enable-shared --enable-gpl --enable-version3 --enable-nonfree --enable-videotoolbox --disable-programs --disable-encoders --disable-decoders --disable-muxers --enable-lto --enable-hardcoded-tables "--prefix=$(realpath $(PREFIX))"
	@sed -e "s:$(realpath $(PREFIX))::g" -i .bak $@

$(PREFIX):
	@mkdir -p "$@"

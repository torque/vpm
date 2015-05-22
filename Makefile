TARGET  := vpm
CC      := clang
CFLAGS  := -Wall -std=c99
LDFLAGS := -lmpv -framework Cocoa -framework WebKit -framework JavaScriptCore -framework OpenGL -pagezero_size 10000 -image_base 100000000
# DEFS    := -D_XOPEN_SOURCE=600

SOURCE_DIRS := src
OC_SOURCES  := $(foreach dir, $(SOURCE_DIRS), $(wildcard $(dir)/*.m))
C_SOURCES   := $(foreach dir, $(SOURCE_DIRS), $(wildcard $(dir)/*.c))
OBJECTS     := $(OC_SOURCES:.m=.o) $(C_SOURCES:.c=.o)

.PHONY: all debug clean

all: debug

production: DEFS += -DPRODUCTION -DNDEBUG
production: CFLAGS += -O2
production: $(TARGET)

debug: CFLAGS += -O0 -g
debug: $(TARGET)

$(TARGET): $(OBJECTS)
	@echo LINK $@
	@$(CC) $^ $(LDFLAGS) -o $@

%.o: %.m
	@echo OBJC $@
	@$(CC) $(DEFS) $(CFLAGS) -c $< -o $@

%.o: %.c
	@echo CC $@
	@$(CC) $(DEFS) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(TARGET)
	@echo "Cleanup complete!"

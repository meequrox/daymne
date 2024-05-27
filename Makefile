TARGET = daymne
SRC_DIR = src
BUILD_DIR = build

SRC_FILES = $(shell find $(SRC_DIR) -name '*.v')

V = v
VFLAGS = -stats

.PHONY: all clean test build run
all: build

format: $(SRC_FILES)
	$(V) fmt -w $(SRC_FILES)

$(BUILD_DIR)/$(TARGET): $(SRC_FILES)
	@mkdir -p $(BUILD_DIR)
	$(V) $(VFLAGS) -o $(BUILD_DIR)/$(TARGET) $(SRC_DIR)
	@echo -e "\nBuild done: $(BUILD_DIR)/$(TARGET)"

build: $(BUILD_DIR)/$(TARGET)

run: $(BUILD_DIR)/$(TARGET)
	@$(BUILD_DIR)/$(TARGET)

test: $(SRC_FILES)
	$(V) test $(SRC_DIR)

clean:
	@rm -rf $(BUILD_DIR)

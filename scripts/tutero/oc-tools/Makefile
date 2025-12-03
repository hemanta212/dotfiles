.PHONY: all build clean install

BIN_DIR = bin
INSTALL_DIR = $(HOME)/.local/bin
CMDS = db-oracle big-brain session-hunter local-librarian web-search

all: build

build:
	@mkdir -p $(BIN_DIR)
	@for cmd in $(CMDS); do \
		echo "Building $$cmd..."; \
		go build -o $(BIN_DIR)/$$cmd ./cmd/$$cmd; \
	done
	@echo "Done! Binaries in $(BIN_DIR)/"

install: build
	@mkdir -p $(INSTALL_DIR)
	@for cmd in $(CMDS); do \
		echo "Symlinking $$cmd to $(INSTALL_DIR)/$$cmd"; \
		rm -f $(INSTALL_DIR)/$$cmd; \
		ln -s $(CURDIR)/$(BIN_DIR)/$$cmd $(INSTALL_DIR)/$$cmd; \
	done
	@echo "Done! Symlinked to $(INSTALL_DIR)/"

clean:
	rm -rf $(BIN_DIR)

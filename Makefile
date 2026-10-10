# Craft apps — one Makefile for every project.
#
#   make build     PROJECT=gridcraft
#   make install   PROJECT=gridcraft PREFIX=$HOME/.local
#   make update    PROJECT=gridcraft PREFIX=$HOME/.local
#   make install-all PREFIX=$HOME/.local
#   make help
#
# PROJECT is the directory name of the app repo (default cadcraft). PROJECTS lists every repo
# for the -all targets. Installing into a system prefix (/usr/local) needs root, but `git pull`
# must not run as root, so pass sudo to the install step only:
#
#   make update PROJECT=gridcraft SUDO=sudo
#
# Everything is overridable, e.g. `make install PROJECT=gridcraft PREFIX=$HOME/.local`.

ROOT     := $(CURDIR)
PROJECT  ?= cadcraft
PROJECTS ?= cadcraft deckcraft designcraft effectcraft filmcraft gridcraft lightcraft \
            pdfcraft photocraft soundcraft vectorcraft wordcraft

# ---- configuration --------------------------------------------------------------------------
PREFIX  ?= /usr/local
BINDIR  ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share
APPDIR  ?= $(DATADIR)/applications
ICONDIR ?= $(DATADIR)/icons
MIMEDIR ?= $(DATADIR)/mime
METADIR ?= $(DATADIR)/metainfo
DOCDIR  ?= $(DATADIR)/doc/$(PROJECT)
DESTDIR ?=
CARGO   ?= cargo
SUDO    ?=

PROJ_DIR := $(ROOT)/$(PROJECT)
APP_ID   := ai.storyteller.$(PROJECT)
# Cargo writes release artifacts to $CARGO_TARGET_DIR/release; default it the same way cargo does.
export CARGO_TARGET_DIR := $(PROJ_DIR)/target
TARGET_DIR := $(CARGO_TARGET_DIR)/release

# The version lives in exactly one place: [workspace.package] version in the project's Cargo.toml.
VERSION := $(shell grep -A5 '^\[workspace\.package\]' $(PROJ_DIR)/Cargo.toml 2>/dev/null \
  | sed -n 's/^version *= *"\(.*\)"/\1/p' | head -1)
DATE    := $(shell date -u +%Y-%m-%d)
UNAME_S := $(shell uname -s)

# The sample/demo flag each app takes, for `make run`. Blank = open the empty document.
RUNFLAGS_cadcraft    := --sample
RUNFLAGS_deckcraft   := --sample
RUNFLAGS_designcraft := --sample
RUNFLAGS_effectcraft := --demo
RUNFLAGS_filmcraft   := --demo
RUNFLAGS_gridcraft   := --sample sales
RUNFLAGS_soundcraft  := --demo
RUNFLAGS_wordcraft   := --sample
RUNFLAGS := $(RUNFLAGS_$(PROJECT))

.DEFAULT_GOAL := build

# ---- build ----------------------------------------------------------------------------------
.PHONY: build
build: ## Build PROJECT and PROJECT-cli in release mode
	cd "$(PROJ_DIR)" && $(CARGO) build --release --locked -p $(PROJECT) -p $(PROJECT)-cli

# ---- install --------------------------------------------------------------------------------
# Linux also gets the freedesktop entry, MIME type, AppStream metadata and the icon theme,
# matching what the .deb/.rpm install. Other platforms get the two binaries on PATH.
.PHONY: install install-desktop
install: build ## Install PROJECT (binaries, and on Linux the desktop integration)
	@echo "Installing $(PROJECT) $(VERSION) into $(DESTDIR)$(PREFIX)"
	$(SUDO) install -d "$(DESTDIR)$(BINDIR)" "$(DESTDIR)$(DOCDIR)"
	$(SUDO) install -m755 "$(TARGET_DIR)/$(PROJECT)" "$(DESTDIR)$(BINDIR)/$(PROJECT)"
	$(SUDO) install -m755 "$(TARGET_DIR)/$(PROJECT)-cli" "$(DESTDIR)$(BINDIR)/$(PROJECT)-cli"
	@# The same licence/readme set the packages carry (packaging/env.sh copy_docs).
	@for f in README.md LICENSE LICENSE-MIT LICENSE-APACHE COPYRIGHT; do \
	  [ -f "$(PROJ_DIR)/$$f" ] && $(SUDO) install -m644 "$(PROJ_DIR)/$$f" "$(DESTDIR)$(DOCDIR)/" || true; \
	done

ifeq ($(UNAME_S),Linux)
install: install-desktop
endif

# Staged exactly as packaging/linux/package.sh stages it, so a `make install` looks to the
# desktop, the file managers and the software centre like a package-manager install.
install-desktop:
	@echo "Installing desktop entry, icons and metadata"
	$(SUDO) install -d "$(DESTDIR)$(APPDIR)" "$(DESTDIR)$(MIMEDIR)/packages" "$(DESTDIR)$(METADIR)" "$(DESTDIR)$(ICONDIR)"
	install -d "$(TARGET_DIR)"
	@# Absolute Exec/TryExec, because a launcher runs with the session PATH, which may not
	@# contain this BINDIR (a ~/.local install in particular). The packaged file keeps the
	@# bare name for /usr/bin, which every session has.
	sed -e 's#^Exec=$(PROJECT)#Exec=$(BINDIR)/$(PROJECT)#' \
	  -e 's#^TryExec=$(PROJECT)#TryExec=$(BINDIR)/$(PROJECT)#' \
	  "$(PROJ_DIR)/packaging/linux/$(APP_ID).desktop" > "$(TARGET_DIR)/$(APP_ID).desktop"
	$(SUDO) install -m644 "$(TARGET_DIR)/$(APP_ID).desktop" "$(DESTDIR)$(APPDIR)/$(APP_ID).desktop"
	$(SUDO) install -m644 "$(PROJ_DIR)/packaging/linux/$(APP_ID).mime.xml" "$(DESTDIR)$(MIMEDIR)/packages/$(APP_ID).xml"
	sed -e 's/@VERSION@/$(VERSION)/g' -e 's/@DATE@/$(DATE)/g' \
	  "$(PROJ_DIR)/packaging/linux/$(APP_ID).metainfo.xml.in" > "$(TARGET_DIR)/$(APP_ID).metainfo.xml"
	$(SUDO) install -m644 "$(TARGET_DIR)/$(APP_ID).metainfo.xml" "$(DESTDIR)$(METADIR)/$(APP_ID).metainfo.xml"
	$(SUDO) cp -R "$(PROJ_DIR)/assets/app-icon/hicolor" "$(DESTDIR)$(ICONDIR)/"
	@# Refresh the caches, the way packaging/linux/postinst.sh does. Only for a real install,
	@# and only when the tool exists.
	@if [ -z "$(DESTDIR)" ]; then \
	  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$(APPDIR)" || true; \
	  command -v update-mime-database    >/dev/null 2>&1 && update-mime-database "$(MIMEDIR)"    || true; \
	  command -v gtk-update-icon-cache   >/dev/null 2>&1 && gtk-update-icon-cache -q -t -f "$(ICONDIR)/hicolor" || true; \
	fi

# ---- update ---------------------------------------------------------------------------------
.PHONY: update
update: ## git pull PROJECT, then build and install
	@echo "Pulling latest changes into $(PROJ_DIR)"
	git -C "$(PROJ_DIR)" pull --ff-only
	$(MAKE) install PROJECT=$(PROJECT)

.PHONY: install-all
install-all: ## Install every project in PROJECTS (builds each in turn)
	@for p in $(PROJECTS); do \
	  echo "== $$p =="; \
	  $(MAKE) --no-print-directory install PROJECT=$$p || exit 1; \
	done

.PHONY: update-all
update-all: ## git pull, build and install every project in PROJECTS
	@for p in $(PROJECTS); do \
	  echo "== $$p =="; \
	  $(MAKE) --no-print-directory update PROJECT=$$p || exit 1; \
	done

# ---- uninstall ------------------------------------------------------------------------------
.PHONY: uninstall
uninstall: ## Remove the installed PROJECT files
	$(SUDO) rm -f "$(DESTDIR)$(BINDIR)/$(PROJECT)" "$(DESTDIR)$(BINDIR)/$(PROJECT)-cli"
	$(SUDO) rm -rf "$(DESTDIR)$(DOCDIR)"
ifeq ($(UNAME_S),Linux)
	$(SUDO) rm -f "$(DESTDIR)$(APPDIR)/$(APP_ID).desktop" \
	  "$(DESTDIR)$(MIMEDIR)/packages/$(APP_ID).xml" \
	  "$(DESTDIR)$(METADIR)/$(APP_ID).metainfo.xml"
	$(SUDO) rm -f "$(DESTDIR)$(ICONDIR)"/hicolor/*/apps/$(APP_ID).png
	$(SUDO) rm -f "$(DESTDIR)$(ICONDIR)"/hicolor/scalable/apps/$(APP_ID).svg
endif

# ---- development helpers --------------------------------------------------------------------
.PHONY: run test check ci clean help
run: ## Run PROJECT from source (with its sample/demo if it has one)
	cd "$(PROJ_DIR)" && $(CARGO) run --release -p $(PROJECT) $(if $(RUNFLAGS),-- $(RUNFLAGS))

test: ## Run PROJECT's workspace tests
	cd "$(PROJ_DIR)" && $(CARGO) test --locked --workspace

check: ## Type-check PROJECT's workspace without building artifacts
	cd "$(PROJ_DIR)" && $(CARGO) check --locked --workspace

ci: ## Run PROJECT's full quality gate (fmt, clippy, tests, assets, layers, wasm)
	cd "$(PROJ_DIR)" && $(CARGO) xtask ci

clean: ## Remove PROJECT's build artifacts and dist/
	cd "$(PROJ_DIR)" && $(CARGO) clean
	rm -rf "$(PROJ_DIR)/dist"

help: ## Show this help
	@echo "Craft apps — make targets (PROJECT=$(PROJECT), $(VERSION)):"
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
	  | sort \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

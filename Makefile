# Craft apps — one Makefile for every project.
#
#   make                           show the help (the default goal)
#   make install                   install every application
#   make install PROJECT=gridcraft install one application
#   make build                     build every application, without install
#   make update                    git pull, build and install every application
#
# PROJECT selects one application by its submodule name. If you do not set PROJECT, the target
# runs for every application in PROJECTS. `make install` thus installs all of them.
#
# The default PREFIX is $HOME/.local, so a normal user needs no root. For a system install, set
# PREFIX and pass sudo to the install step only (`git pull` must not run as root):
#
#   make install PREFIX=/usr/local SUDO=sudo
#
# Everything is overridable, e.g. `make PROJECT=gridcraft PREFIX=$HOME/.local`.

ROOT     := $(CURDIR)
PROJECTS ?= cadcraft deckcraft designcraft effectcraft filmcraft gridcraft lightcraft \
            pdfcraft photocraft soundcraft vectorcraft wordcraft

# PROJECT selects one application (a submodule name). Leave it unset to act on all of them.
ifeq ($(origin PROJECT),undefined)
ALL := 1
else
ALL :=
endif

# ---- configuration --------------------------------------------------------------------------
# A user install (the default) needs no root. Set PREFIX=/usr/local and SUDO=sudo for a system
# install.
PREFIX  ?= $(HOME)/.local
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

.DEFAULT_GOAL := help

# Run the current target ($@) for every project by re-entering make once per project.
define all_projects
@for p in $(PROJECTS); do \
  echo "== $$p =="; \
  $(MAKE) --no-print-directory $@ PROJECT=$$p || exit 1; \
done
endef

# ---- build ----------------------------------------------------------------------------------
.PHONY: build
build: ## Build PROJECT, or every application when PROJECT is unset
ifeq ($(ALL),1)
	$(all_projects)
else
	cd "$(PROJ_DIR)" && $(CARGO) build --release --locked -p $(PROJECT) -p $(PROJECT)-cli
endif

# ---- install --------------------------------------------------------------------------------
# Linux also gets the freedesktop entry, MIME type, AppStream metadata and the icon theme,
# matching what the .deb/.rpm install. Other platforms get the two binaries on PATH.
.PHONY: install
ifeq ($(ALL),1)
install: ## Install PROJECT, or every application when PROJECT is unset
	$(all_projects)
else
install: build
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
endif

# Staged exactly as packaging/linux/package.sh stages it, so a `make install` looks to the
# desktop, the file managers and the software centre like a package-manager install.
.PHONY: install-desktop
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
update: ## git pull PROJECT, or every application, then build and install
ifeq ($(ALL),1)
	$(all_projects)
else
	@echo "Pulling latest changes into $(PROJ_DIR)"
	git -C "$(PROJ_DIR)" pull --ff-only
	$(MAKE) install PROJECT=$(PROJECT)
endif

# ---- uninstall ------------------------------------------------------------------------------
.PHONY: uninstall
uninstall: ## Remove the installed PROJECT files, or every application
ifeq ($(ALL),1)
	$(all_projects)
else
	$(SUDO) rm -f "$(DESTDIR)$(BINDIR)/$(PROJECT)" "$(DESTDIR)$(BINDIR)/$(PROJECT)-cli"
	$(SUDO) rm -rf "$(DESTDIR)$(DOCDIR)"
ifeq ($(UNAME_S),Linux)
	$(SUDO) rm -f "$(DESTDIR)$(APPDIR)/$(APP_ID).desktop" \
	  "$(DESTDIR)$(MIMEDIR)/packages/$(APP_ID).xml" \
	  "$(DESTDIR)$(METADIR)/$(APP_ID).metainfo.xml"
	$(SUDO) rm -f "$(DESTDIR)$(ICONDIR)"/hicolor/*/apps/$(APP_ID).png
	$(SUDO) rm -f "$(DESTDIR)$(ICONDIR)"/hicolor/scalable/apps/$(APP_ID).svg
endif
endif

# ---- development helpers --------------------------------------------------------------------
.PHONY: run
run: ## Run PROJECT from source, or every application
ifeq ($(ALL),1)
	$(all_projects)
else
	cd "$(PROJ_DIR)" && $(CARGO) run --release -p $(PROJECT) $(if $(RUNFLAGS),-- $(RUNFLAGS))
endif

.PHONY: test
test: ## Run PROJECT's tests, or every application's
ifeq ($(ALL),1)
	$(all_projects)
else
	cd "$(PROJ_DIR)" && $(CARGO) test --locked --workspace
endif

.PHONY: check
check: ## Type-check PROJECT, or every application
ifeq ($(ALL),1)
	$(all_projects)
else
	cd "$(PROJ_DIR)" && $(CARGO) check --locked --workspace
endif

.PHONY: ci
ci: ## Run PROJECT's quality gate, or every application's
ifeq ($(ALL),1)
	$(all_projects)
else
	cd "$(PROJ_DIR)" && $(CARGO) xtask ci
endif

.PHONY: clean
clean: ## Remove PROJECT's build output, or every application's
ifeq ($(ALL),1)
	$(all_projects)
else
	cd "$(PROJ_DIR)" && $(CARGO) clean
	rm -rf "$(PROJ_DIR)/dist"
endif

# ---- help -----------------------------------------------------------------------------------
.PHONY: help
help: ## Show this help
	@echo "Craft apps — make targets:"
	@echo ""
	@echo "  make                             Show this help (the default goal)"
	@echo "  make install    [PROJECT=name]   Build and install every application"
	@echo "  make build      [PROJECT=name]   Build the release binaries only"
	@echo "  make update     [PROJECT=name]   git pull, then build and install"
	@echo "  make uninstall  [PROJECT=name]   Remove the installed files"
	@echo "  make run        [PROJECT=name]   Start an application from source"
	@echo "  make test       [PROJECT=name]   Run the tests"
	@echo "  make check      [PROJECT=name]   Type-check the workspace"
	@echo "  make ci         [PROJECT=name]   Run the full quality gate"
	@echo "  make clean      [PROJECT=name]   Remove the build output"
	@echo ""
	@echo "If PROJECT is unset, the target runs for every application:"
	@echo "  $(PROJECTS)"
	@echo ""
	@echo "Variables: PROJECT, PROJECTS, PREFIX (default \$$HOME/.local), DESTDIR, SUDO, CARGO."
	@echo ""
	@echo "Examples:"
	@echo "  make install                             # install all into \$$HOME/.local"
	@echo "  make install PROJECT=gridcraft           # install one application"
	@echo "  make install PREFIX=/usr/local SUDO=sudo # system install"
	@echo ""
	@echo "Or pick another target: build, update, uninstall, run, test, check, ci, clean."

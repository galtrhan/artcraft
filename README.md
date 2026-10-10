# Craft Apps

This repository collects the Craft applications in one place. Each application is a separate
Git repository. This repository holds the twelve repositories as Git submodules. One Makefile
builds, installs and updates them.

## Applications

| Submodule | Application | Function |
| --- | --- | --- |
| cadcraft | CADCraft | Draft, dimension and plot 2D drawings. Open DXF and DWG files. |
| deckcraft | DeckCraft | Create and present slide decks. |
| designcraft | DesignCraft | Lay out magazines, books and print documents. |
| effectcraft | EffectCraft | Make motion graphics and visual effects. |
| filmcraft | FilmCraft | Edit video, color and sound. |
| gridcraft | GridCraft | Calculate, analyze and chart data in workbooks. |
| lightcraft | LightCraft | Organize photos and develop raw files. Keep the source files safe. |
| pdfcraft | PdfCraft | Read, organize, combine, split and protect PDF files. |
| photocraft | PhotoCraft | Edit photos and layered PSD documents. |
| soundcraft | SoundCraft | Record, edit and mix audio and MIDI. |
| vectorcraft | VectorCraft | Draw and edit vector illustrations, SVG and PDF. |
| wordcraft | WordCraft | Write and design documents. Open and save Word files. |

Each application is a Rust workspace. The application code stays in the submodule. The parent
repository holds the submodule links and the Makefile only.

## Install

Install all twelve applications with three commands.

```sh
git clone --recurse-submodules https://github.com/galtrhan/artcraft.git
cd artcraft
make install
```

The third line is a make target. Use the target you need. `make` alone shows the help.

`make install` builds every application and installs it into `$HOME/.local`. A user install
needs no root. It writes the two binaries, and on Linux the desktop entry, the file types, the
AppStream metadata and the icons. The applications then appear in your launcher.

Set `PROJECT` to a submodule name to act on one application.

```sh
make install PROJECT=gridcraft
```

A system install uses `/usr/local` and root. Do not run `git pull` as root. Give the privilege
command to the install step only.

```sh
make install PREFIX=/usr/local SUDO=sudo
```

If you already have the repository, get the submodules and install later.

```sh
git submodule update --init --recursive
```

## Common targets

```sh
make                # show the help
make install        # build and install every application
make build          # build every application, without install
make update         # git pull, then build and install every application
make uninstall      # remove the installed files
make run            # start an application from source
```

## Targets

| Target | Function |
| --- | --- |
| `build` | Build the application and its command-line tool. |
| `install` | Build and install. Add the desktop entry, icons and file types on Linux. |
| `update` | Pull the latest changes, then build and install. |
| `uninstall` | Remove the installed files. |
| `run` | Start the application from source. |
| `test` | Run the tests. |
| `check` | Type-check the workspace. |
| `ci` | Run the full quality check. |
| `clean` | Remove the build output. |
| `help` | List the targets. |

Each target acts on one application when you set `PROJECT`, and on every application when you
do not set it.

## Variables

| Variable | Function |
| --- | --- |
| `PROJECT` | The application to act on. Use the submodule name. Leave it unset to act on all. |
| `PROJECTS` | The applications for the "all" behavior. Defaults to the twelve submodules. |
| `PREFIX` | The install directory. Default `$HOME/.local`. |
| `DESTDIR` | Stage the install into a package root. |
| `SUDO` | The privilege command, for example `sudo`. |
| `CARGO` | The cargo command. |

## Desktop entry on Linux

On Linux, `make install` also writes the desktop entry, the MIME type, the AppStream metadata
and the icons. The desktop entry makes the application appear in the launcher. The Makefile
writes the full path of the binary into the desktop entry. A launcher starts with the session
PATH. That PATH can omit `$HOME/.local/bin`. The full path removes this problem.

## Work in a submodule

Each application has its own repository. Commit your changes in the submodule. The parent
repository records one commit for each submodule. When you change a submodule, commit the new
link in the parent repository too.

```sh
cd gridcraft
git add .
git commit -m "describe the change"
git push
cd ..
git add gridcraft
git commit -m "Update the gridcraft submodule"
```

## Licenses

Each application has its own license. Read the license files in the submodule.

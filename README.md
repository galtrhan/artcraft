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

## Get the source

Clone the parent repository and all submodules in one command.

```sh
git clone --recurse-submodules <parent-repo-url>
cd <parent-dir>
```

If you already have the parent repository, get the submodules now.

```sh
git submodule update --init --recursive
```

## Build, install and update

A bare `make` shows the help. Set `PROJECT` to the submodule name to act on one application.

```sh
make                                      # show the help
make build   PROJECT=gridcraft            # build the binaries
make run     PROJECT=gridcraft            # start from source
make install PROJECT=gridcraft            # install (needs root for /usr/local)
make update  PROJECT=gridcraft            # git pull, then build and install
```

If you do not set `PROJECT`, the target runs for **every** application. For example, this
command installs all twelve applications:

```sh
make install PREFIX=$HOME/.local
```

A user install needs no root. Set `PREFIX` to your home directory.

```sh
make install PROJECT=gridcraft PREFIX=$HOME/.local
make update  PROJECT=gridcraft PREFIX=$HOME/.local
```

A system install needs root for the install step. Do not run `git pull` as root. Give the
privilege command to the install step only.

```sh
make update PROJECT=gridcraft SUDO=sudo
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
| `PREFIX` | The install directory. Default `/usr/local`. |
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

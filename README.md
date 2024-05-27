# daymne

Command line **extension updater** for Visual Studio Code text editor without unnecessary connections and telemetry,
with support for several marketplaces (extension galleries).

Features:

- Count installed extensions
- List of installed extensions indicating their version
- Check for updates to installed extensions
- Update installed extensions (automatically download and install a newer version)

## Screenshots

![Upgrade](https://i.imgur.com/L1XKgzj.png)

## Why daymne?

Unlike Visual Studio Code's built-in extension manager, `daymne`:

- Collects **zero** telemetry and doesn't make unnecessary connections.
- Can search for new versions in multiple sources ([Visual Studio](https://marketplace.visualstudio.com) and
  [Open VSX](https://open-vsx.org/) marketplaces) and pick the latest one.
- Supports proprietary builds of *Visual Studio Code*, as well as debloated *Code - OSS* versions.
- Works even with extremely hardened builds such as [Uncoded](https://gitlab.com/megastallman/uncoded/),
  which don't have the ability to check and perform extension updates out of the box.

## Why not daymne?

It's not exactly an extension **manager** because it cannot search for and install new extensions and
doesn't manage dependencies.

Reasons why I didn't implement this:

1. It's just easier to search and read descriptions using a web browser.
1. I just don't want to deal with the semi-public stupid MS API again.

But it's still better to use `daymne` than to manually check for updates for each of the 10, 50, 100... extensions.

## Installation

This project is written in [V language](https://vlang.io/),
so you will need to [install vlang](https://github.com/vlang/v/blob/master/README.md#installing-v-from-source) first.

```bash
git clone https://github.com/meequrox/daymne.git

cd daymne

make
```

The compiled file will be located in the `build/` directory.

## Usage

Download and install your favorite extensions manually using the [Open VSX](https://open-vsx.org/) or
[Visual Studio](https://marketplace.visualstudio.com) marketplaces and from now on you will be able
to update them with `daymne`.

```bash
# Print help message
./daymne -h
```

#### Using with OSS build

```bash
# Check extensions for updates
./daymne update

# Upgrade only specified extensions
./daymne upgrade golang.go rust-lang.rust-analyzer

# Upgrade all extensions
./daymne upgrade
```

#### Using with proprietary build

`-p` is an alias to `--proprietary` and can be placed anywhere:

```bash
# Check extensions for updates
./daymne update --proprietary

# List installed extensions
./daymne list -p

# Upgrade all extensions
./daymne -p upgrade
```

After running the `daymne upgrade` command, go to the **Extensions** tab in the sidebar and restart
the upgraded extensions with one click.

## Examples

#### Print information related to VSCode installation

```bash
$ daymne info

Config directory: /home/user/.vscode-oss/extensions (exists: true)
Config file: /home/user/.vscode-oss/extensions/extensions.json (exists: true)
Extensions: 4
Platform: linux-x64
```

#### Print installed extensions

```bash
$ daymne list

alefragnani.bookmarks 13.5.0
ecmel.vscode-html-css 2.0.9
golang.go 0.41.4
haskell.haskell 2.5.3
```

#### Check for updates

```bash
$ daymne update
Failed to request haskell.haskell: https://open-vsx.org/vscode/gallery/extensionquery => code 503 (attempt 1)

All extensions are up-to-date
```

Marketplaces are not entirely stable, as they randomly produce 5xx errors,
so the program will repeat the request and everything will be fine.

#### Upgrade extensions

```bash
$ daymne upgrade
All extensions are up-to-date
```

If there are extensions to upgrade, the following process will be performed:

1. Download vsix package for the current OS and architecture.
1. Unpack the package into the extension installation directory.
1. Modify the configuration file to tell VSCode about the new version of the extension.

## Troubleshooting

Encountered a bug or want to request new functionality? Please open a new issue on Github.

# daymne

Simple command line extension updater for "Code - OSS" text editor without unnecessary connections and telemetry,
with support for multiple marketplaces (extension galleries).

Features:

- Count installed extensions
- List of installed extensions indicating their version
- Check for updates to installed extensions
- Update installed extensions (automatically download and install a newer version)
- Select the latest version among the [Visual Studio](https://marketplace.visualstudio.com) and [Open VSX](https://open-vsx.org/) marketplaces

## Screenshots

![Upgrade](https://i.imgur.com/L1XKgzj.png)

## Why

Instead of a built-in Visual Studio Code extension manager, `daymne` does not send unnecessary Internet requests and can
search for new versions between several sources.

There is also a hardened build of VSCode called [Uncoded](https://gitlab.com/megastallman/uncoded/) which
does not have ability to track and perform extension updates. For ease of use this build,
I decided to develop this application.

Do not consider it an extension **manager** as it can't search for and install new extensions and
does not currently manage dependencies.
It's not very hard to implement, but I just don't want to deal with the semi-public stupid MS API again.

## Installation

This project is written in [V language](https://vlang.io/),
so you will need to [install it](https://github.com/vlang/v/blob/master/README.md#installing-v-from-source) first.

```bash
git clone https://github.com/meequrox/daymne.git

cd daymne

make
```

The compiled file will be located in the `build/` directory.

## Usage

Since you need to search and then read the description of the extension anyway, you should do this using
the [Open VSX](https://open-vsx.org/) or [Visual Studio](https://marketplace.visualstudio.com) marketplaces.

Download and install the extension manually and from now on you will be able to update it with `daymne`.

```bash
# Print help message
./daymne -h

# Check extensions for updates
./daymne update

# Upgrade only specified extensions
./daymne upgrade golang.go rust-lang.rust-analyzer

# Upgrade all extensions
./daymne upgrade
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

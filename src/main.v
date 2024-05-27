module main

import src.handler
import os
import cli

fn build_subcommands() []cli.Command {
	return [
		cli.Command{
			name: 'info'
			description: 'Print information related to Visual Studio Code configuration'
			execute: fn (cmd cli.Command) ! {
				use_proprierary := cmd.flags.get_bool('proprietary') or { false }
				handler.info(use_proprierary)
				return
			}
			posix_mode: true
			sort_flags: true
			defaults: struct {
				help: cli.CommandFlag{
					command: false
				}
				man: false
				version: false
			}
		},
		cli.Command{
			name: 'list'
			description: 'Print installed extensions'
			execute: fn (cmd cli.Command) ! {
				use_proprierary := cmd.flags.get_bool('proprietary') or { false }
				handler.list(use_proprierary)
				return
			}
			posix_mode: true
			sort_flags: true
			defaults: struct {
				help: cli.CommandFlag{
					command: false
				}
				man: false
				version: false
			}
		},
		cli.Command{
			name: 'update'
			description: 'Print extensions that can be updated to a newer version'
			execute: fn (cmd cli.Command) ! {
				use_proprierary := cmd.flags.get_bool('proprietary') or { false }
				handler.update(use_proprierary)
				return
			}
			posix_mode: true
			sort_flags: true
			defaults: struct {
				help: cli.CommandFlag{
					command: false
				}
				man: false
				version: false
			}
		},
		cli.Command{
			name: 'upgrade'
			description: 'Download and install a newer version of the extension(s)'
			execute: fn (cmd cli.Command) ! {
				use_proprierary := cmd.flags.get_bool('proprietary') or { false }
				handler.upgrade(cmd.args, use_proprierary)
				return
			}
			posix_mode: true
			sort_flags: true
			defaults: struct {
				help: cli.CommandFlag{
					command: false
				}
				man: false
				version: false
			}
		},
	]
}

fn main() {
	mut app := cli.Command{
		name: 'daymne'
		description: 'Command line extension updater for Visual Studio Code text editor'
		version: '1.1.0'
		execute: fn (cmd cli.Command) ! {
			handler.main(cmd.help_message())
			return
		}
		commands: build_subcommands()
		posix_mode: true
		sort_flags: true
		flags: [
			cli.Flag{
				flag: cli.FlagType.bool
				name: 'proprietary'
				abbrev: 'p'
				description: 'Use proprietary build configuration (.vscode) instead of OSS one (.vscode-oss)'
				global: true
				required: false
			},
		]
		defaults: struct {
			help: cli.CommandFlag{
				command: false
			}
			man: false
			version: cli.CommandFlag{
				command: false
			}
		}
	}

	app.setup()
	app.parse(os.args)
}

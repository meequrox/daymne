module main

import os
import cli

fn build_subcommands() []cli.Command {
	return [
		cli.Command{
			name: 'info'
			description: 'Print information related to "Code - OSS"'
			execute: fn (cmd cli.Command) ! {
				info_handler()
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
				list_handler()
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
				update_handler()
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
			// TODO: parse positional args
			name: 'upgrade'
			description: 'Download and install a newer version of the extension(s)'
			execute: fn (cmd cli.Command) ! {
				upgrade_handler(cmd.args)
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
		description: 'Command line extension updater for "Code - OSS" text editor'
		version: '0.5.2'
		execute: fn (cmd cli.Command) ! {
			main_handler(cmd.help_message())
			return
		}
		commands: build_subcommands()
		posix_mode: true
		sort_flags: true
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

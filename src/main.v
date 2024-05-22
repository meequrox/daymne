module main

import os
import cli

fn build_subcommands() []cli.Command {
	return [
		cli.Command{
			name: 'info'
			// TODO: add description
			description: ''
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
			// TODO: add description
			description: ''
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
			// TODO: add description
			description: ''
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
			// TODO: add description
			description: ''
			execute: fn (cmd cli.Command) ! {
				upgrade_handler()
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
		// TODO: add description
		description: ''
		// TODO: bump version
		version: '0.3.0'
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

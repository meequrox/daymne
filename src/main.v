module main

import src.handler
import os
import cli

fn build_subcommands() []cli.Command {
	return [
		cli.Command{
			name: 'info'
			description: 'Print information related to "Code - OSS"'
			execute: fn (cmd cli.Command) ! {
				handler.info()
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
				handler.list()
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
				handler.update()
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
				handler.upgrade(cmd.args)
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
		version: '1.0.2'
		execute: fn (cmd cli.Command) ! {
			handler.main(cmd.help_message())
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

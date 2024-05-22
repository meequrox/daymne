module main

import os
import cli
import extension
import semver
import utils

fn print_info() {
	println('Platform: ${utils.get_current_platform()}')
	println('Root path: ${utils.get_root_path()}')
	println('Config path: ${utils.get_root_config_path()}')
	println('Extensions count: ${extension.get_local_extensions().len}')
}

fn check_extensions_updates() {
	mut count := 0

	for local_ext in extension.get_local_extensions() {
		remote_ext := extension.get_remote(local_ext.identifier.id)

		local_version := semver.from(local_ext.version) or { panic(err) }
		remote_version := semver.from(remote_ext.version) or { panic(err) }

		if remote_version > local_version {
			println('${local_ext.identifier.id} ${local_ext.version} -> ${remote_ext.version}')
			count++
		}
	}

	if count > 0 {
		println('\n${count} extensions can be upgraded using `${os.args[0]} upgrade`')
	} else {
		println('All extensions are up-to-date!')
	}
}

// TODO: Move functions to packages

fn main() {
	info_cmd := cli.Command{
		name: 'info'
		description: 'TODO: Description'
		posix_mode: true
		execute: fn (cmd cli.Command) ! {
			print_info()
			return
		}
		defaults: struct {
			help: cli.CommandFlag{
				command: false
			}
			man: false
			version: false
		}
	}

	list_cmd := cli.Command{
		name: 'list'
		description: 'TODO: Description'
		posix_mode: true
		execute: fn (cmd cli.Command) ! {
			print_local_extensions()
			return
		}
		defaults: struct {
			help: cli.CommandFlag{
				command: false
			}
			man: false
			version: false
		}
	}

	update_cmd := cli.Command{
		name: 'update'
		description: 'TODO: Description'
		posix_mode: true
		execute: fn (cmd cli.Command) ! {
			check_extensions_updates()
			return
		}
		defaults: struct {
			help: cli.CommandFlag{
				command: false
			}
			man: false
			version: false
		}
	}

	upgrade_cmd := cli.Command{
		name: 'upgrade'
		description: 'TODO: Description'
		posix_mode: true
		execute: fn (cmd cli.Command) ! {
			// TODO: Upgrade (all) command
			check_extensions_updates()
			return
		}
		defaults: struct {
			help: cli.CommandFlag{
				command: false
			}
			man: false
			version: false
		}
	}

	mut app := cli.Command{
		name: 'daymne'
		description: 'TODO: Description'
		version: '0.3.0'
		posix_mode: true
		execute: fn (cmd cli.Command) ! {
			cmd.execute_help()
			return
		}
		commands: [
			info_cmd,
			list_cmd,
			update_cmd,
			upgrade_cmd,
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

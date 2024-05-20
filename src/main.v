module main

import os
import json
import cli

struct Extension {
	version           string @[required]
	relative_location string @[json: 'relativeLocation'; required]

	identifier struct {
		id string @[required]
	} @[required]

	location struct {
		mid    int    @[json: '\$mid'; required]
		path   string @[required]
		scheme string @[required]
	} @[required]

	metadata struct {
		installed_timestamp i64    @[json: 'installedTimestamp'; required]
		source              string @[required]
	} @[required]
}

fn get_root_path() string {
	return os.join_path(os.home_dir(), '.vscode-oss', 'extensions')
}

fn get_root_config_path() string {
	return os.join_path_single(get_root_path(), 'extensions.json')
}

fn get_extensions_list() []Extension {
	config_str := os.read_file(get_root_config_path()) or { panic(err) }
	list := json.decode([]Extension, config_str) or { panic(err) }

	return list.sorted(a.identifier.id < b.identifier.id)
}

fn print_extensions() {
	for extension in get_extensions_list() {
		println('${extension.identifier.id} ${extension.version}')
	}
}

fn print_info() {
	println('Root path: ${get_root_path()}')
	println('Config path: ${get_root_config_path()}')
	println('Extensions count: ${get_extensions_list().len}')
}

fn main() {
	default_cmd := fn (cmd cli.Command) ! {
		cmd.execute_help()
		return
	}

	info_cmd := cli.Command{
		name: 'info'
		execute: fn (cmd cli.Command) ! {
			print_info()
			return
		}
	}

	list_cmd := cli.Command{
		name: 'list'
		execute: fn (cmd cli.Command) ! {
			print_extensions()
			return
		}
	}

	mut app := cli.Command{
		name: 'daymne'
		description: 'TODO: Description'
		version: '0.3.0'
		posix_mode: true
		execute: default_cmd
		commands: [
			info_cmd,
			list_cmd,
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

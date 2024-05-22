module main

import extension
import utils
import semver
import os

fn main_handler(help_msg string) {
	println(help_msg)
}

fn info_handler() {
	println('Platform: ${utils.get_current_platform()}')
	println('Root path: ${utils.get_root_path()}')
	println('Config path: ${utils.get_root_config_path()}')
	println('Extensions: ${extension.get_local_extensions().len}')
}

fn list_handler() {
	extension.print_local_extensions()
}

fn update_handler() {
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

fn upgrade_handler() {
	// TODO: Implement upgrade (all) command
	update_handler()
}

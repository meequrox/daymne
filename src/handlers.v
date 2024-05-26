module main

import extension
import utils
import os
import arrays

fn main_handler(help_msg string) {
	println(help_msg)
}

fn info_handler() {
	config := utils.get_config()

	println(config)
	println('Extensions: ${extension.get_local().len}')
	println('Platform: ${utils.get_current_platform()}')
}

fn list_handler() {
	arrays.each(extension.get_local(), fn (ex extension.LocalExtension) {
		println(ex)
	})
}

fn update_handler() {
	count := arrays.fold(extension.get_local(), 0, fn (acc int, ex extension.LocalExtension) int {
		local_version := ex.get_version()
		remote_version := extension.get_remote(ex.get_id()).get_version()

		if remote_version > local_version {
			println('${ex.get_id()} ${local_version} -> ${remote_version}')
			return acc + 1
		}

		return acc
	})

	if count > 0 {
		println('\n${count} extensions can be upgraded using `${os.args[0]} upgrade`')
	} else {
		println('All extensions are up-to-date')
	}
}

fn upgrade_handler(args []string) {
	// TODO: Implement upgrade (all) command
	mut installed := extension.get_local()

	mut candidates := map[string]int{}
	mut candidates_ref := &candidates

	if args.len > 0 {
		arrays.each(args, fn [installed, mut candidates_ref] (candidate_id string) {
			if candidate_id.len > 0 && candidate_id[0] != `-` && candidate_id.count('.') == 1 {
				// Find candidate in list of installed extensions
				idx := arrays.index_of_first(installed, fn [candidate_id] (_ int, ex extension.LocalExtension) bool {
					return ex.get_id() == candidate_id
				})

				if idx > -1 {
					(*candidates_ref)[candidate_id] = idx
				}
			}
		})
	} else {
		arrays.each_indexed(installed, fn [mut candidates_ref] (idx int, ex extension.LocalExtension) {
			(*candidates_ref)[ex.get_id()] = idx
		})
	}

	for k, v in candidates {
		println('${k} at ${v}')
	}

	mut count := 0

	for candidate_id, installed_idx in candidates {
		remote_ext := extension.get_remote(candidate_id)

		local_version := installed[installed_idx].get_version()
		remote_version := remote_ext.get_version()

		if remote_version > local_version {
			tmp_path := extension.download_package(remote_ext)

			// TODO: Unpack and copy to config root
			// TODO: Update config file
			dst_path := os.join_path(os.home_dir(), 'Desktop', '${candidate_id}-${remote_version}.vsix')
			os.cp(tmp_path, dst_path) or { panic(err) }

			println('${candidate_id} ${local_version} -> ${remote_version} (moved from ${tmp_path} to ${dst_path})')
			count++
		}
	}

	if count > 0 {
		println('\n${count} extensions was upgraded')
	}
}

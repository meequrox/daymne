module handler

import src.extension
import os

pub fn update(use_proprierary bool) {
	mut count := 0

	for ex in extension.get_local(use_proprierary) {
		local_ver := ex.get_version()
		remote_ver := extension.get_remote(ex.get_id()).get_version()

		println('Processing ${ex.get_id()}...')

		if remote_ver > local_ver {
			println('${ex.get_id()} ${local_ver} -> ${remote_ver}')
			count++
		}
	}

	if count > 0 {
		println('\n${count} extensions can be upgraded using `${os.args[0]} upgrade`')
	} else {
		println('\nAll extensions are up-to-date')
	}
}

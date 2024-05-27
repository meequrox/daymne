module handler

import src.extension
import os

pub fn update() {
	mut count := 0

	for ex in extension.get_local() {
		local_ver := ex.get_version()
		remote_ver := extension.get_remote(ex.get_id()).get_version()

		if remote_ver > local_ver {
			println('${ex.get_id()} ${local_ver} -> ${remote_ver}')
			count++
		}
	}

	if count > 0 {
		println('\n${count} extensions can be upgraded using `${os.args[0]} upgrade`')
	} else {
		println('All extensions are up-to-date')
	}
}

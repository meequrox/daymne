module handler

import src.extension
import src.utils

pub fn info(use_proprierary bool) {
	config := utils.get_config(use_proprierary)

	println(config)

	if config.file.exists {
		println('Extensions: ${extension.get_local(use_proprierary).len}')
	}

	println('Platform: ${utils.get_current_platform()}')
}

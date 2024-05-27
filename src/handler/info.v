module handler

import src.extension
import src.utils

pub fn info() {
	config := utils.get_config()

	println(config)

	if config.file.exists {
		println('Extensions: ${extension.get_local().len}')
	}

	println('Platform: ${utils.get_current_platform()}')
}

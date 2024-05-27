module handler

import extension
import utils
// ^^ local

pub fn info() {
	config := utils.get_config()

	println(config)
	println('Extensions: ${extension.get_local().len}')
	println('Platform: ${utils.get_current_platform()}')
}

module handler

import src.extension

pub fn list() {
	for ex in extension.get_local() {
		println(ex)
	}
}

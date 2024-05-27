module handler

import extension
// ^^ local

pub fn list() {
	for ex in extension.get_local() {
		println(ex)
	}
}

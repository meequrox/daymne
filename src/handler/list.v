module handler

import src.extension

pub fn list(use_proprierary bool) {
	for ex in extension.get_local(use_proprierary) {
		println(ex)
	}
}

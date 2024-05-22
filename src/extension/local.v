module extension

import os
import json
import utils

// TODO: remove pub

pub struct LocalExtension {
pub:
	version           string @[required]
	relative_location string @[json: 'relativeLocation'; required]

	identifier LocalExtensionIdentifier @[required]

	location LocalExtensionLocation @[required]

	metadata LocalExtensionMetadata @[required]
}

// ? pub struct
struct LocalExtensionIdentifier {
pub:
	id string @[required]
}

// ? pub struct
struct LocalExtensionLocation {
pub:
	mid    int    @[json: '\$mid'; required]
	path   string @[required]
	scheme string @[required]
}

// ? pub struct
struct LocalExtensionMetadata {
pub:
	installed_timestamp i64    @[json: 'installedTimestamp'; required]
	source              string @[required]
}

pub fn get_local_extensions() []LocalExtension {
	config_str := os.read_file(utils.get_root_config_path()) or { panic(err) }
	list := json.decode([]LocalExtension, config_str) or { panic(err) }

	return list.sorted(a.identifier.id < b.identifier.id)
}

pub fn print_local_extensions() {
	for extension in get_local_extensions() {
		println('${extension.identifier.id} ${extension.version}')
	}
}

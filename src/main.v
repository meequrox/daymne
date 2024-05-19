module main

import os
import json

struct Extension {
	version           string @[required]
	relative_location string @[json: relativeLocation; required]

	identifier struct {
		id string @[required]
	} @[required]

	location struct {
		// ! BUG: Cannot decode and encode $mid key
		mid    int    @[json: mid]
		path   string @[required]
		scheme string @[required]
	} @[required]

	metadata struct {
		installed_timestamp i64    @[json: installedTimestamp; required]
		source              string @[required]
	} @[required]
}

fn get_root_path() string {
	return os.join_path(os.home_dir(), '.vscode-oss', 'extensions')
}

fn get_root_config_path() string {
	return os.join_path_single(get_root_path(), 'extensions.json')
}

fn main() {
	config_str := os.read_file(get_root_config_path())!
	extensions := json.decode([]Extension, config_str)!.sorted(a.identifier.id < b.identifier.id)

	for extension in extensions {
		println('${extension.identifier.id} ${extension.version}')
	}
}

module extension

import json
import utils
import semver
import os

pub struct LocalExtension {
pub:
	identifier        LocalExtensionIdentifier @[required]
	location          LocalExtensionLocation   @[required]
	relative_location string                   @[json: 'relativeLocation'; required]
	version           string                   @[required]
	metadata          LocalExtensionMetadata
}

pub struct LocalExtensionIdentifier {
pub:
	id string @[required]
}

pub struct LocalExtensionLocation {
pub:
	mid    int    @[json: '\$mid'; required]
	path   string @[required]
	scheme string @[required]
}

pub struct LocalExtensionMetadata {
pub:
	installed_timestamp i64    @[json: 'installedTimestamp'; required]
	source              string @[required]
}

pub fn (ex LocalExtension) get_id() string {
	return ex.identifier.id
}

pub fn (ex LocalExtension) get_path() string {
	return ex.location.path
}

pub fn (ex LocalExtension) get_version() semver.Version {
	return semver.from(ex.version) or {
		println('Failed to parse ${ex.get_id()} local version: ${err}')
		semver.build(0, 0, 0)
	}
}

pub fn (ex LocalExtension) str() string {
	return '${ex.get_id()} ${ex.get_version()}'
}

pub fn get_local() []LocalExtension {
	config_path := utils.get_config().file.path

	if !os.exists(config_path) {
		println('Config file does not exist: ${config_path}')
		exit(0)
	}

	config_str := os.read_file(config_path) or {
		println('Failed to read config file: ${err}')
		exit(-1)
	}

	list := json.decode([]LocalExtension, config_str) or {
		println('Failed to parse config file: ${err}')
		exit(-1)
	}

	return list.sorted(a.identifier.id < b.identifier.id)
}

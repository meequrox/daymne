module main

import os
import json
import cli
import net.http
import time

struct LocalExtensionMetadata {
	installed_timestamp i64    @[json: 'installedTimestamp'; required]
	source              string @[required]
}

struct LocalExtensionLocation {
	mid    int    @[json: '\$mid'; required]
	path   string @[required]
	scheme string @[required]
}

struct LocalExtensionIdentifier {
	id string @[required]
}

struct LocalExtension {
	version           string @[required]
	relative_location string @[json: 'relativeLocation'; required]

	identifier LocalExtensionIdentifier @[required]

	location LocalExtensionLocation @[required]

	metadata LocalExtensionMetadata @[required]
}

struct RemoteAsset {
	asset_type string @[json: 'assetType']
	source     string
}

struct RemoteVersion {
	version         string
	target_platform string        @[json: 'targetPlatform']
	files           []RemoteAsset
}

struct RemoteResultMetadataItems {
	count int
	name  string
}

struct RemoteResultMetadata {
	metadata_items []RemoteResultMetadataItems @[json: 'metadataItems']
	metadata_type  string                      @[json: 'metadataType']
}

struct RemoteResultExtension {
	versions []RemoteVersion
}

struct RemoteResult {
	extensions      []RemoteResultExtension
	result_metadata []RemoteResultMetadata  @[json: 'resultMetadata']
}

struct RemoteExtensions {
	results []RemoteResult
}

struct RemoteExtension {
mut:
	version     string
	package_url string
}

fn get_root_path() string {
	return os.join_path(os.home_dir(), '.vscode-oss', 'extensions')
}

fn get_root_config_path() string {
	return os.join_path_single(get_root_path(), 'extensions.json')
}

fn get_local_extensions_list() []LocalExtension {
	config_str := os.read_file(get_root_config_path()) or { panic(err) }
	list := json.decode([]LocalExtension, config_str) or { panic(err) }

	return list.sorted(a.identifier.id < b.identifier.id)
}

fn print_local_extensions() {
	for extension in get_local_extensions_list() {
		println('${extension.identifier.id} ${extension.version}')
	}
}

fn print_info() {
	println('Root path: ${get_root_path()}')
	println('Config path: ${get_root_config_path()}')
	println('Extensions count: ${get_local_extensions_list().len}')
}

enum RemoteQueryFlag {
	include_versions             = 0x1
	include_files                = 0x2
	include_category_and_tags    = 0x4
	include_shared_accounts      = 0x8
	include_version_properties   = 0x10
	exclude_non_validated        = 0x20
	include_installation_targets = 0x40
	include_asset_uri            = 0x80
	include_statistics           = 0x100
	include_latest_version_only  = 0x200
	unpublished                  = 0x1000
	include_name_conflict_info   = 0x8000
}

fn find_package_url(assets []RemoteAsset) string {
	for asset in assets {
		if asset.asset_type == 'Microsoft.VisualStudio.Services.VSIXPackage' {
			return asset.source
		}
	}

	return ''
}

fn match_remote_extension(exts RemoteExtensions) RemoteExtension {
	if exts.results.len > 0 && exts.results[0].result_metadata[0].metadata_items[0].count > 0 {
		versions := exts.results[0].extensions[0].versions

		mut ext := RemoteExtension{
			version: ''
			package_url: ''
		}

		platform := 'linux-x64' // TODO: get current platform in runtime

		for version in versions {
			if version.target_platform == '' || version.target_platform == platform {
				ext.version = version.version
				ext.package_url = find_package_url(version.files)
				break
			}
		}

		return ext
	}

	return RemoteExtension{}
}

fn request_extension_from_remote(id string) RemoteExtension {
	query_flags := int(RemoteQueryFlag.include_files) | int(RemoteQueryFlag.include_installation_targets) | int(RemoteQueryFlag.include_latest_version_only)
	filter_type := 7

	url := 'https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery'
	body := '{"filters":[{"criteria":[{"filterType":${filter_type},"value":"${id}"}]}],"flags":${query_flags}}'

	resp := http.post_json(url, body) or { panic(err) }
	time.sleep(100_000_000) // 100 ms

	if resp.status() == http.Status.ok {
		exts := json.decode(RemoteExtensions, resp.body) or { panic(err) }
		return match_remote_extension(exts)
	} else {
		// TODO: remove in release
		println('Request extension from remote: code ${resp.status_code}; body ${resp.body}')
	}

	return RemoteExtension{}
}

fn check_extensions_updates() {
	for local_ext in get_local_extensions_list() {
		remote_ext := request_extension_from_remote(local_ext.identifier.id)

		if local_ext.version != remote_ext.version {
			println('${local_ext.identifier.id} ${local_ext.version} -> ${remote_ext.version}')
		}

		break
	}
}

fn main() {
	default_cmd := fn (cmd cli.Command) ! {
		cmd.execute_help()
		return
	}

	info_cmd := cli.Command{
		name: 'info'
		execute: fn (cmd cli.Command) ! {
			print_info()
			return
		}
	}

	list_cmd := cli.Command{
		name: 'list'
		execute: fn (cmd cli.Command) ! {
			print_local_extensions()
			return
		}
	}

	check_cmd := cli.Command{
		name: 'check'
		execute: fn (cmd cli.Command) ! {
			check_extensions_updates()
			return
		}
	}

	mut app := cli.Command{
		name: 'daymne'
		description: 'TODO: Description'
		version: '0.3.0'
		posix_mode: true
		execute: default_cmd
		commands: [
			info_cmd,
			list_cmd,
			check_cmd,
		]
		defaults: struct {
			help: cli.CommandFlag{
				command: false
			}
			man: false
			version: cli.CommandFlag{
				command: false
			}
		}
	}

	app.setup()
	app.parse(os.args)
}

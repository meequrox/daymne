module main

import os
import json
import cli
import net.http
import time
import v.pref
import extension
import semver
import arrays

fn get_root_path() string {
	return os.join_path(os.home_dir(), '.vscode-oss', 'extensions')
}

fn get_root_config_path() string {
	return os.join_path_single(get_root_path(), 'extensions.json')
}

fn get_local_extensions_list() []extension.LocalExtension {
	config_str := os.read_file(get_root_config_path()) or { panic(err) }
	list := json.decode([]extension.LocalExtension, config_str) or { panic(err) }

	return list.sorted(a.identifier.id < b.identifier.id)
}

fn print_local_extensions() {
	for extension in get_local_extensions_list() {
		println('${extension.identifier.id} ${extension.version}')
	}
}

fn print_info() {
	println('Platform: ${get_current_platform()}')
	println('Root path: ${get_root_path()}')
	println('Config path: ${get_root_config_path()}')
	println('Extensions count: ${get_local_extensions_list().len}')
}

fn find_package_url(assets []extension.RemoteAsset) string {
	find_fun := fn (asset extension.RemoteAsset) bool {
		return asset.asset_type == 'Microsoft.VisualStudio.Services.VSIXPackage'
	}

	package_asset := arrays.find_first(assets, find_fun) or { extension.RemoteAsset{} }
	return package_asset.source
}

fn get_current_os() string {
	mut host_os := pref.get_host_os().str()

	match host_os {
		'Windows' { host_os = 'win32' }
		'Linux' { host_os = 'linux' }
		'MacOS' { host_os = 'darwin' }
		else { host_os = host_os.to_lower() }
	}

	return host_os
}

fn get_current_arch() string {
	mut arch := pref.get_host_arch().str()

	match arch {
		'i386' { arch = 'ia32' }
		'amd64' { arch = 'x64' }
		else { arch = arch.to_lower() }
	}

	return arch
}

fn get_current_platform() string {
	return get_current_os() + '-' + get_current_arch()
}

fn match_remote_extension(exts extension.RemoteExtensions) extension.RemoteExtension {
	find_fun := fn (version extension.RemoteVersion) bool {
		return version.target_platform == '' || version.target_platform == get_current_platform()
	}

	mut ext := extension.RemoteExtension{}

	if exts.results.len > 0 && exts.results[0].extensions.len > 0 {
		versions := exts.results[0].extensions[0].versions
		compatible_version := arrays.find_first(versions, find_fun) or { extension.RemoteVersion{} }

		ext.version = compatible_version.version
		ext.package_url = find_package_url(compatible_version.files)
	}

	return ext
}

pub struct RemoteQueryConfig {
pub:
	filters []RemoteQueryConfigFilter
	flags   int
}

struct RemoteQueryConfigFilter {
	criteria []RemoteQueryConfigCriteria
}

struct RemoteQueryConfigCriteria {
	filter_type int    @[json: 'filterType']
	value       string
}

fn request_extension_from_remote(url string, id string) extension.RemoteExtension {
	query_flags := int(extension.RemoteQueryFlag.include_files) | int(extension.RemoteQueryFlag.include_installation_targets) | int(extension.RemoteQueryFlag.include_latest_version_only)

	query_config := RemoteQueryConfig{
		filters: [
			RemoteQueryConfigFilter{
				criteria: [
					RemoteQueryConfigCriteria{
						filter_type: 7
						value: id
					},
				]
			},
		]
		flags: query_flags
	}

	mut req := http.new_request(http.Method.post, url, json.encode(query_config))
	req.add_header(http.CommonHeader.content_type, 'application/json')
	req.add_header(http.CommonHeader.accept, 'application/json;api-version=3.0-preview.1')
	req.add_header(http.CommonHeader.user_agent, 'VSCode 1.91.1')

	req.read_timeout = 5 * time.second
	req.write_timeout = req.read_timeout

	println('========== ${id} ==========')
	println('${time.now()}: REQUEST ${id} from ${url}')
	resp := req.do() or { panic(err) }
	println('${time.now()}: RECEIVED ${id} from ${url}')
	time.sleep(100 * time.millisecond)

	if resp.status() == http.Status.ok {
		exts := json.decode(extension.RemoteExtensions, resp.body) or { panic(err) }
		return match_remote_extension(exts)
	} else {
		// TODO: remove
		println('Request extension from remote: code ${resp.status_code}; body ${resp.body}')
	}

	println('========== ${id} ==========\n')

	return extension.RemoteExtension{}
}

fn request_extension_from_marketplace(id string) extension.RemoteExtension {
	url := 'https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery'
	return request_extension_from_remote(url, id)
}

fn request_extension_from_openvsx(id string) extension.RemoteExtension {
	url := 'https://open-vsx.org/vscode/gallery/extensionquery'
	return request_extension_from_remote(url, id)
}

fn get_remote_extension(id string) extension.RemoteExtension {
	openvsx_ext := request_extension_from_openvsx(id)
	marketplace_ext := request_extension_from_marketplace(id)

	if openvsx_ext.version.len > 0 && marketplace_ext.version.len == 0 {
		return openvsx_ext
	} else if openvsx_ext.version.len == 0 && marketplace_ext.version.len > 0 {
		return marketplace_ext
	} else if marketplace_ext.version.len == 0 && openvsx_ext.version.len == 0 {
		return extension.RemoteExtension{
			version: '0.0.0'
		}
	}

	openvsx_semver := semver.from(openvsx_ext.version) or { panic(err) }
	marketplace_semver := semver.from(marketplace_ext.version) or { panic(err) }

	return if openvsx_semver > marketplace_semver { openvsx_ext } else { marketplace_ext }
}

fn check_extensions_updates() {
	mut count := 0

	for local_ext in get_local_extensions_list() {
		remote_ext := get_remote_extension(local_ext.identifier.id)

		local_version := semver.from(local_ext.version) or { panic(err) }
		remote_version := semver.from(remote_ext.version) or { panic(err) }

		if remote_version > local_version {
			println('${local_ext.identifier.id} ${local_ext.version} -> ${remote_ext.version}')
			count++
		}
	}

	if count > 0 {
		println('\n${count} extensions can be upgraded using `${os.args[0]} upgrade`')
	} else {
		println('All extensions are up-to-date!')
	}
}

// TODO: Move functions to packages

fn main() {
	info_cmd := cli.Command{
		name: 'info'
		description: 'TODO: Description'
		posix_mode: true
		execute: fn (cmd cli.Command) ! {
			print_info()
			return
		}
		defaults: struct {
			help: cli.CommandFlag{
				command: false
			}
			man: false
			version: false
		}
	}

	list_cmd := cli.Command{
		name: 'list'
		description: 'TODO: Description'
		posix_mode: true
		execute: fn (cmd cli.Command) ! {
			print_local_extensions()
			return
		}
		defaults: struct {
			help: cli.CommandFlag{
				command: false
			}
			man: false
			version: false
		}
	}

	update_cmd := cli.Command{
		name: 'update'
		description: 'TODO: Description'
		posix_mode: true
		execute: fn (cmd cli.Command) ! {
			check_extensions_updates()
			return
		}
		defaults: struct {
			help: cli.CommandFlag{
				command: false
			}
			man: false
			version: false
		}
	}

	upgrade_cmd := cli.Command{
		name: 'upgrade'
		description: 'TODO: Description'
		posix_mode: true
		execute: fn (cmd cli.Command) ! {
			// TODO: Upgrade (all) command
			check_extensions_updates()
			return
		}
		defaults: struct {
			help: cli.CommandFlag{
				command: false
			}
			man: false
			version: false
		}
	}

	mut app := cli.Command{
		name: 'daymne'
		description: 'TODO: Description'
		version: '0.3.0'
		posix_mode: true
		execute: fn (cmd cli.Command) ! {
			cmd.execute_help()
			return
		}
		commands: [
			info_cmd,
			list_cmd,
			update_cmd,
			upgrade_cmd,
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

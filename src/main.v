module main

import os
import json
import cli
import net.http
import time
import v.pref
import extension
import semver

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
	println('Root path: ${get_root_path()}')
	println('Config path: ${get_root_config_path()}')
	println('Extensions count: ${get_local_extensions_list().len}')
}

fn find_package_url(assets []extension.RemoteAsset) string {
	for asset in assets {
		if asset.asset_type == 'Microsoft.VisualStudio.Services.VSIXPackage' {
			return asset.source
		}
	}

	return ''
}

fn get_current_platform() string {
	host_os := pref.get_host_os().str()
	host_arch := pref.get_host_arch().str()

	mut platform := 'unknown'
	mut arch := 'unknown'

	match host_os {
		'Windows' { platform = 'win32' }
		'Linux' { platform = 'linux' }
		'MacOS' { platform = 'darwin' }
		else { platform = host_os.to_lower() }
	}

	match host_arch {
		'i386' { arch = 'ia32' }
		'amd64' { arch = 'x64' }
		else { arch = host_arch }
	}

	return '${platform}-${arch}'
}

fn match_remote_extension(exts extension.RemoteExtensions) extension.RemoteExtension {
	if exts.results.len > 0 && exts.results[0].result_metadata[0].metadata_items[0].count > 0 {
		versions := exts.results[0].extensions[0].versions

		mut ext := extension.RemoteExtension{
			version: ''
			package_url: ''
		}

		platform := get_current_platform()

		for version in versions {
			if version.target_platform == '' || version.target_platform == platform {
				ext.version = version.version
				ext.package_url = find_package_url(version.files)
				break
			}
		}

		return ext
	}

	return extension.RemoteExtension{}
}

fn request_extension_from_remote(id string) extension.RemoteExtension {
	query_flags := int(extension.RemoteQueryFlag.include_files) | int(extension.RemoteQueryFlag.include_installation_targets) | int(extension.RemoteQueryFlag.include_latest_version_only)

	url := 'https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery'
	body := '{"filters":[{"criteria":[{"filterType":7,"value":"${id}"}]}],"flags":${query_flags}}'
	ua := 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) UpNote/9.3.0 Chrome/122.0.6261.156 Electron/29.3.1 Safari/537.36'

	mut req := http.new_request(http.Method.post, url, body)
	req.add_header(http.CommonHeader.content_type, 'application/json')
	req.add_header(http.CommonHeader.accept, 'application/json;api-version=3.0-preview.1')
	req.add_header(http.CommonHeader.user_agent, ua)

	req.read_timeout = 5 * time.second
	req.write_timeout = req.read_timeout

	println('${time.now()}: do req for ${id}')
	resp := req.do() or { panic(err) }
	time.sleep(100 * time.millisecond)
	println('${time.now()}: end req for ${id}')

	if resp.status() == http.Status.ok {
		exts := json.decode(extension.RemoteExtensions, resp.body) or { panic(err) }
		return match_remote_extension(exts)
	} else {
		// TODO: remove in release
		println('Request extension from remote: code ${resp.status_code}; body ${resp.body}')
	}

	return extension.RemoteExtension{}
}

fn check_extensions_updates() {
	for local_ext in get_local_extensions_list() {
		remote_ext := request_extension_from_remote(local_ext.identifier.id)

		local_version := semver.from(local_ext.version) or { panic(err) }
		remote_version := semver.from(remote_ext.version) or { panic(err) }

		if remote_version > local_version {
			println('${local_ext.identifier.id} ${local_ext.version} -> ${remote_ext.version}')
		}
	}
}

// TODO: Move functions to packages
// TODO: Install command
// TODO: Upgrade (all) command
// ? Pipe upgrade through install?

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

module extension

import net.http
import time
import json
import semver
import arrays
import utils

// TODO: remove pub

pub enum RemoteQueryFlag {
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

pub enum RemoteGallery {
	visualstudio = 0
	openvsx
}

pub struct RemoteExtension {
pub mut:
	version     string
	package_url string
}

pub struct RemoteExtensions {
pub:
	results []RemoteResult
}

pub struct RemoteAsset {
pub:
	asset_type string @[json: 'assetType']
	source     string
}

pub struct RemoteVersion {
pub:
	version         string
	target_platform string        @[json: 'targetPlatform']
	files           []RemoteAsset
}

// ? pub struct
struct RemoteResultMetadataItems {
pub:
	count int
	name  string
}

// ? pub struct
struct RemoteResultMetadata {
pub:
	metadata_items []RemoteResultMetadataItems @[json: 'metadataItems']
	metadata_type  string                      @[json: 'metadataType']
}

// ? pub struct
struct RemoteResultExtension {
pub:
	versions []RemoteVersion
}

// ? pub struct
struct RemoteResult {
pub:
	extensions      []RemoteResultExtension
	result_metadata []RemoteResultMetadata  @[json: 'resultMetadata']
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

// TODO: replace by str()
fn get_gallery_url(gallery RemoteGallery) string {
	url := match gallery {
		.visualstudio { 'https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery' }
		.openvsx { 'https://open-vsx.org/vscode/gallery/extensionquery' }
	}

	return url
}

fn find_package_url(assets []RemoteAsset) string {
	find_fun := fn (asset RemoteAsset) bool {
		return asset.asset_type == 'Microsoft.VisualStudio.Services.VSIXPackage'
	}

	package_asset := arrays.find_first(assets, find_fun) or { RemoteAsset{} }
	return package_asset.source
}

fn match_remote_extension(exts RemoteExtensions) RemoteExtension {
	find_fun := fn (version RemoteVersion) bool {
		return version.target_platform == ''
			|| version.target_platform == utils.get_current_platform()
	}

	mut ext := RemoteExtension{}

	if exts.results.len > 0 && exts.results[0].extensions.len > 0 {
		versions := exts.results[0].extensions[0].versions
		compatible_version := arrays.find_first(versions, find_fun) or { RemoteVersion{} }

		ext.version = compatible_version.version
		ext.package_url = find_package_url(compatible_version.files)
	}

	return ext
}

fn request_remote(url string, id string) RemoteExtension {
	query_flags := int(RemoteQueryFlag.include_files) | int(RemoteQueryFlag.include_installation_targets) | int(RemoteQueryFlag.include_latest_version_only)

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

	// TODO: build_request()
	mut req := http.new_request(http.Method.post, url, json.encode(query_config))
	req.add_header(http.CommonHeader.content_type, 'application/json')
	req.add_header(http.CommonHeader.accept, 'application/json;api-version=3.0-preview.1')
	req.add_header(http.CommonHeader.user_agent, 'VSCode 1.91.1')

	// ? SSL not implemented
	req.read_timeout = 5 * time.second
	req.write_timeout = req.read_timeout

	// TODO: remove prints

	println('========== ${id} ==========')
	println('${time.now()}: REQUEST ${id} from ${url}')
	resp := req.do() or { panic(err) }
	println('${time.now()}: RECEIVED ${id} from ${url}')
	time.sleep(100 * time.millisecond)

	if resp.status() == http.Status.ok {
		exts := json.decode(RemoteExtensions, resp.body) or { panic(err) }
		return match_remote_extension(exts)
	} else {
		println('Request extension from remote: code ${resp.status_code}; body ${resp.body}')
	}

	println('========== ${id} ==========\n')

	return RemoteExtension{}
}

pub fn get_remote(id string) RemoteExtension {
	openvsx_ext := request_remote(get_gallery_url(.openvsx), id)
	visualstudio_ext := request_remote(get_gallery_url(.visualstudio), id)

	// TODO(90): remove
	if openvsx_ext.version.len > 0 && visualstudio_ext.version.len == 0 {
		return openvsx_ext
	} else if openvsx_ext.version.len == 0 && visualstudio_ext.version.len > 0 {
		return visualstudio_ext
	} else if visualstudio_ext.version.len == 0 && openvsx_ext.version.len == 0 {
		return RemoteExtension{
			version: '0.0.0'
		}
	}

	// TODO(90): set to 0.0.0 if !
	openvsx_semver := semver.from(openvsx_ext.version) or { panic(err) }
	visualstudio_semver := semver.from(visualstudio_ext.version) or { panic(err) }

	return if openvsx_semver > visualstudio_semver { openvsx_ext } else { visualstudio_ext }
}

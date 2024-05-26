module extension

import net.http
import time
import json
import semver
import arrays
import utils
import io.util

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
	vs      = 0
	openvsx
}

pub struct RemoteExtension {
pub mut:
	id          string
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

pub fn (ex RemoteExtension) get_version() semver.Version {
	return semver.from(ex.version) or { semver.build(0, 0, 0) }
}

fn (g RemoteGallery) str() string {
	url := match g {
		.vs { 'https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery' }
		.openvsx { 'https://open-vsx.org/vscode/gallery/extensionquery' }
	}

	return url
}

pub fn get_remote(id string) RemoteExtension {
	openvsx_ext := request_remote_info(RemoteGallery.openvsx.str(), id)
	vs_ext := request_remote_info(RemoteGallery.vs.str(), id)

	return if openvsx_ext.get_version() >= vs_ext.get_version() { openvsx_ext } else { vs_ext }
}

pub fn download_package(ex RemoteExtension) string {
	_, tmp_path := util.temp_file(util.TempFileOptions{ pattern: 'daymne_*_package' }) or {
		panic(err)
	}

	http.download_file(ex.package_url, tmp_path) or { panic(err) }

	return tmp_path
}

fn find_package_url(assets []RemoteAsset) string {
	package_asset := arrays.find_first(assets, fn (asset RemoteAsset) bool {
		return asset.asset_type == 'Microsoft.VisualStudio.Services.VSIXPackage'
	}) or { RemoteAsset{} }

	return package_asset.source
}

fn match_remote_extension(exts RemoteExtensions, id string) RemoteExtension {
	mut ext := RemoteExtension{}

	if exts.results.len > 0 && exts.results[0].extensions.len > 0 {
		versions := exts.results[0].extensions[0].versions
		compatible_version := arrays.find_first(versions, fn (version RemoteVersion) bool {
			return version.target_platform == ''
				|| version.target_platform == utils.get_current_platform()
		}) or { RemoteVersion{} }

		ext.id = id
		ext.version = compatible_version.version
		ext.package_url = find_package_url(compatible_version.files)
	}

	return ext
}

fn build_info_request(url string, id string) http.Request {
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

	mut req := http.new_request(http.Method.post, url, json.encode(query_config))
	req.add_header(http.CommonHeader.content_type, 'application/json')
	req.add_header(http.CommonHeader.accept, 'application/json;api-version=3.0-preview.1')
	req.add_header(http.CommonHeader.user_agent, 'VSCode 1.91.1')

	// TODO: SSL not implemented
	req.read_timeout = 5 * time.second
	req.write_timeout = req.read_timeout

	return req
}

fn request_remote_info(url string, id string) RemoteExtension {
	resp := build_info_request(url, id).do() or { panic(err) }
	time.sleep(100 * time.millisecond)

	if resp.status() == http.Status.ok {
		exts := json.decode(RemoteExtensions, resp.body) or { RemoteExtensions{} }
		return match_remote_extension(exts, id)
	} else {
		println('Request extension from remote: code ${resp.status_code}; body ${resp.body}')
	}

	return RemoteExtension{}
}

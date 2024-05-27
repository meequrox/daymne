module extension

import net.http
import time
import json
import semver
import utils
import io.util

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

pub struct RemoteExtension {
pub mut:
	id          string
	version     string
	package_url string
}

struct RemoteQueryConfig {
	filters []RemoteQueryConfigFilter
	flags   int
}

enum RemoteGallery {
	vs      = 0
	openvsx
}

struct RemoteExtensions {
	results []RemoteResult
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

pub fn (g RemoteGallery) str() string {
	url := match g {
		.vs { 'https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery' }
		.openvsx { 'https://open-vsx.org/vscode/gallery/extensionquery' }
	}

	return url
}

pub fn combine_query_flags(flags []RemoteQueryFlag) int {
	mut res := 0

	for flag in flags {
		res |= int(flag)
	}

	return res
}

pub fn get_remote(id string) RemoteExtension {
	galleries := [RemoteGallery.openvsx, RemoteGallery.vs]
	mut ext := RemoteExtension{}

	// Pick extension with newest version
	for gallery in galleries {
		candidate := request_remote_info(gallery.str(), id) or {
			println('Cannot fetch ${id} from ${gallery}')
			RemoteExtension{}
		}

		if candidate.get_version() > ext.get_version() {
			ext = candidate
		}
	}

	return ext
}

pub fn download_package(ex RemoteExtension) ?string {
	return download_package_impl(ex, 0)
}

fn download_package_impl(ex RemoteExtension, attempt int) ?string {
	tmp_opts := util.TempFileOptions{
		pattern: 'daymne_*_${ex.id}-${ex.version}.vsix'
	}

	_, path := util.temp_file(tmp_opts) or {
		println('Failed to create temporary file for ${ex.id}: ${err}')
		return none
	}

	http.download_file(ex.package_url, path) or {
		println('Failed to download ${ex.id}: ${err}')
		return if attempt < 2 { download_package_impl(ex, attempt + 1) } else { none }
	}

	return path
}

fn find_package_url(assets []RemoteAsset) ?string {
	for asset in assets {
		if asset.asset_type == 'Microsoft.VisualStudio.Services.VSIXPackage' {
			return asset.source
		}
	}

	return none
}

fn find_compatible_version(versions []RemoteVersion) ?RemoteVersion {
	platform := utils.get_current_platform()

	for ver in versions {
		if ver.target_platform.len == 0 || ver.target_platform == platform {
			return ver
		}
	}

	return none
}

fn match_remote_extension(exts RemoteExtensions, id string) RemoteExtension {
	mut ext := RemoteExtension{}

	if exts.results.len > 0 && exts.results[0].extensions.len > 0 {
		compatible_version := find_compatible_version(exts.results[0].extensions[0].versions) or {
			println('Cannot find compatible version of ${id}')
			RemoteVersion{}
		}

		ext.id = id
		ext.version = compatible_version.version

		ext.package_url = find_package_url(compatible_version.files) or {
			println('Cannot find download URL for ${id}')
			''
		}
	}

	return ext
}

fn build_info_request(url string, id string) http.Request {
	query_flags := combine_query_flags([.include_files, .include_installation_targets,
		.include_latest_version_only])

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

	req.read_timeout = 4 * time.second
	req.write_timeout = 4 * time.second

	return req
}

fn request_remote_info(url string, id string) ?RemoteExtension {
	return request_remote_info_impl(url, id, 0)
}

fn request_remote_info_impl(url string, id string, attempt int) ?RemoteExtension {
	resp := build_info_request(url, id).do() or {
		println('Failed to request remote ${url} for ${id}: ${err}')
		return none
	}

	time.sleep(100 * time.millisecond)

	if resp.status() == http.Status.ok {
		exts := json.decode(RemoteExtensions, resp.body) or {
			println('Failed to parse response for ${id} from ${url}: ${err}')
			RemoteExtensions{}
		}

		return match_remote_extension(exts, id)
	} else {
		println('Failed to request ${id}: ${url} => code ${resp.status_code} (attempt ${attempt + 1})')
	}

	return if attempt < 2 { request_remote_info_impl(url, id, attempt + 1) } else { none }
}

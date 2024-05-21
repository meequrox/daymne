module extension

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

struct RemoteVersion {
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

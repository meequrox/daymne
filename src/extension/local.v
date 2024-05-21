module extension

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

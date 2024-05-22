module utils

import os

pub fn get_root_path() string {
	return os.join_path(os.home_dir(), '.vscode-oss', 'extensions')
}

pub fn get_root_config_path() string {
	return os.join_path_single(get_root_path(), 'extensions.json')
}

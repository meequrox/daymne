module utils

import os

pub struct Config {
pub:
	dir  ConfigDir
	file ConfigFile
}

pub struct ConfigDir {
pub:
	path   string
	exists bool
}

pub struct ConfigFile {
pub:
	path   string
	exists bool
}

pub fn (c Config) str() string {
	return '${c.dir}\n${c.file}'
}

pub fn (cd ConfigDir) str() string {
	return 'Config directory: ${cd.path} (exists: ${cd.exists})'
}

pub fn (cf ConfigFile) str() string {
	return 'Config file: ${cf.path} (exists: ${cf.exists})'
}

pub fn get_config() Config {
	dir_path := os.join_path(os.home_dir(), '.vscode-oss', 'extensions')
	file_path := os.join_path_single(dir_path, 'extensions.json')

	return Config{
		dir: ConfigDir{
			path: dir_path
			exists: os.exists(dir_path)
		}
		file: ConfigFile{
			path: file_path
			exists: os.exists(file_path)
		}
	}
}

pub fn rewrite_config_file(content string) {
	os.write_file(get_config().file.path, content) or {
		eprintln('Failed to rewrite config file: ${err}')
		exit(-1)
	}
}

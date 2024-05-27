module handler

import src.extension
import src.utils
import os
import compress.szip
import json
import time
import arrays

struct UpgradePaths {
	install  InstallDir
	temp     TempDir
	manifest ManifestPath
}

struct InstallDir {
	old string
	new string
}

struct TempDir {
	unpack    string
	extension string
}

struct ManifestPath {
	old string
	new string
}

struct UpgradeCandidate {
	id   string
	path string
	pos  int // Entry position in original config file
}

pub fn upgrade(args []string) {
	mut installed, candidates := get_upgrade_candidates(args)
	mut count := 0

	for c in candidates {
		remote_ext := extension.get_remote(c.id)

		local_ver := installed[c.pos].get_version()
		remote_ver := remote_ext.get_version()

		if remote_ver > local_ver {
			tmp_file := extension.download_package(remote_ext) or { continue }
			paths := create_upgrade_paths(c, local_ver.str(), remote_ver.str(), tmp_file)

			szip.extract_zip_to_dir(tmp_file, paths.temp.unpack) or {
				println('Failed to extract archive of ${c.id}: ${err}')
				continue
			}

			for src, dest in {
				paths.manifest.old:   paths.manifest.new
				paths.temp.extension: paths.install.new
			} {
				os.mv(src, dest, os.MvParams{ overwrite: true }) or {
					println('Failed to install extension files for ${c.id}: ${err}')
					continue
				}
			}

			os.rm(tmp_file) or { println('Failed to remove temp .vsix package of ${c.id}: ${err}') }

			for path in [paths.temp.unpack, paths.install.old] {
				if os.exists(path) {
					os.rmdir_all(paths.install.old) or {
						println('Failed to remove directory ${path}: ${err}')
					}
				}
			}

			// Update config file entry
			installed[c.pos] = extension.LocalExtension{
				identifier: extension.LocalExtensionIdentifier{
					id: c.id
				}
				location: extension.LocalExtensionLocation{
					mid: installed[c.pos].location.mid
					path: paths.install.new
					scheme: installed[c.pos].location.scheme
				}
				relative_location: '${c.id}-${remote_ver}'
				version: remote_ver.str()
				metadata: extension.LocalExtensionMetadata{
					installed_timestamp: time.now().unix_milli()
					source: installed[c.pos].metadata.source
				}
			}

			utils.rewrite_config_file(json.encode_pretty(installed))

			println('${c.id} ${local_ver} -> ${remote_ver}')
			count++
		}
	}

	if count > 0 {
		println('\n${count} extensions were upgraded')
	} else {
		println('All extensions are up-to-date')
	}
}

fn get_upgrade_candidates(args []string) ([]extension.LocalExtension, []UpgradeCandidate) {
	installed := extension.get_local()
	mut candidates := []UpgradeCandidate{}

	if args.len > 0 {
		for cid in arrays.uniq(args) {
			if cid[0] != `-` && cid.count('.') == 1 {
				// Find candidate in list of installed extensions
				idx := arrays.index_of_first(installed, fn [cid] (_ int, ex extension.LocalExtension) bool {
					return ex.get_id() == cid
				})

				if idx > -1 {
					candidates << UpgradeCandidate{
						id: cid
						path: installed[idx].get_path()
						pos: idx
					}
				}
			}
		}
	} else {
		// Upgrade all
		for idx, ex in installed {
			candidates << UpgradeCandidate{
				id: ex.get_id()
				path: ex.get_path()
				pos: idx
			}
		}
	}

	return installed, candidates
}

fn create_upgrade_paths(candidate UpgradeCandidate, local_ver string, remote_ver string, downloaded_file string) UpgradePaths {
	config := utils.get_config()

	paths := UpgradePaths{
		install: InstallDir{
			old: candidate.path
			new: os.join_path_single(config.dir.path, '${candidate.id}-${remote_ver}')
		}
		temp: TempDir{
			unpack: downloaded_file + '_unpacked'
			extension: os.join_path_single(downloaded_file + '_unpacked', 'extension')
		}
		manifest: ManifestPath{
			old: os.join_path_single(downloaded_file + '_unpacked', 'extension.vsixmanifest')
			new: os.join_path(downloaded_file + '_unpacked', 'extension', '.vsixmanifest')
		}
	}

	for path in [config.dir.path, paths.temp.unpack] {
		os.mkdir_all(path, os.MkdirParams{ mode: 0o755 }) or {
			println('Failed to create path ${path}: ${err}')
			continue
		}
	}

	return paths
}

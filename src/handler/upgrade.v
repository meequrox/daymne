module handler

import extension
import utils
// ^^ local
import os
import compress.szip
import json
import time
import arrays

pub fn upgrade(args []string) {
	// TODO: refactor
	// TODO: delete by relative directory
	mut installed, candidates := get_upgrade_candidates(args)
	mut count := 0

	for cid, installed_idx in candidates {
		remote_ext := extension.get_remote(cid)

		local_ver := installed[installed_idx].get_version()
		remote_ver := remote_ext.get_version()

		if remote_ver > local_ver {
			tmp_file := extension.download_package(remote_ext) or { continue }

			old_dir, tmp_unpack_dir, tmp_ext_dir, new_dir := create_upgrade_paths(cid,
				local_ver.str(), remote_ver.str(), tmp_file)

			szip.extract_zip_to_dir(tmp_file, tmp_unpack_dir) or {
				utils.rewrite_config_file(json.encode_pretty(installed))
				panic(err)
			}

			if os.exists(tmp_ext_dir) {
				os.mv(os.join_path_single(tmp_unpack_dir, 'extension.vsixmanifest'), os.join_path_single(tmp_ext_dir,
					'.vsixmanifest'), os.MvParams{}) or {
					utils.rewrite_config_file(json.encode_pretty(installed))
					panic(err)
				}

				os.cp_all(tmp_ext_dir, new_dir, false) or {
					utils.rewrite_config_file(json.encode_pretty(installed))
					panic(err)
				}

				os.rmdir_all(old_dir) or {
					utils.rewrite_config_file(json.encode_pretty(installed))
					panic(err)
				}

				// Update config file entry
				installed[installed_idx] = extension.LocalExtension{
					identifier: extension.LocalExtensionIdentifier{
						id: cid
					}
					location: extension.LocalExtensionLocation{
						mid: installed[installed_idx].location.mid
						path: new_dir
						scheme: installed[installed_idx].location.scheme
					}
					relative_location: '${cid}-${remote_ver}'
					version: remote_ver.str()
					metadata: extension.LocalExtensionMetadata{
						installed_timestamp: time.now().unix_milli()
						source: installed[installed_idx].metadata.source
					}
				}

				println('${cid} ${local_ver} -> ${remote_ver}')
				count++
			}
		}
	}

	if count > 0 {
		utils.rewrite_config_file(json.encode_pretty(installed))
		println('\n${count} extensions were upgraded')
	}
}

fn get_upgrade_candidates(args []string) ([]extension.LocalExtension, map[string]int) {
	installed := extension.get_local()
	mut candidates := map[string]int{}

	if args.len > 0 {
		for cid in arrays.uniq(args) {
			if cid.len > 0 && cid[0] != `-` && cid.count('.') == 1 {
				// Find candidate in list of installed extensions
				idx := arrays.index_of_first(installed, fn [cid] (_ int, ex extension.LocalExtension) bool {
					return ex.get_id() == cid
				})

				if idx > -1 {
					candidates[cid] = idx
				}
			}
		}
	} else {
		// Upgrade all
		for idx, ex in installed {
			candidates[ex.get_id()] = idx
		}
	}

	return installed, candidates
}

fn create_upgrade_paths(id string, local_ver string, remote_ver string, downloaded_file string) (string, string, string, string) {
	// TODO: refactor
	config := utils.get_config()

	old_dir := os.join_path_single(config.dir.path, '${id}-${local_ver}')
	tmp_unpack_dir := downloaded_file + '_unpacked'
	tmp_ext_dir := os.join_path_single(tmp_unpack_dir, 'extension')
	new_dir := os.join_path_single(config.dir.path, '${id}-${remote_ver}')

	if !config.dir.exists {
		os.mkdir_all(config.dir.path, os.MkdirParams{ mode: 0o755 }) or { panic(err) }
	}

	if !os.exists(tmp_unpack_dir) {
		os.mkdir(tmp_unpack_dir, os.MkdirParams{ mode: 0o755 }) or { panic(err) }
	}

	return old_dir, tmp_unpack_dir, tmp_ext_dir, new_dir
}

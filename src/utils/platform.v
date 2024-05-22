module utils

import v.pref

fn get_current_os() string {
	mut host_os := pref.get_host_os().str()

	match host_os {
		'Windows' { host_os = 'win32' }
		'Linux' { host_os = 'linux' }
		'MacOS' { host_os = 'darwin' }
		else { host_os = host_os.to_lower() }
	}

	return host_os
}

fn get_current_arch() string {
	mut arch := pref.get_host_arch().str()

	match arch {
		'i386' { arch = 'ia32' }
		'amd64' { arch = 'x64' }
		else { arch = arch.to_lower() }
	}

	return arch
}

pub fn get_current_platform() string {
	return get_current_os() + '-' + get_current_arch()
}

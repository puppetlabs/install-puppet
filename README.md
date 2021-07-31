# install-puppet

One-shot shell script that can be used to install puppet-agent on a supported
POSIX platform.

## Description

This repository contains a Ruby script (`install.rb`), which when executed will
generate an `install.sh` file to be used for installing puppet-agent on
supported FOSS POSIX platforms.

The script leverages Bolt tasks from the
[puppet_agent](https://forge.puppet.com/modules/puppetlabs/puppet_agent) and
[facts](https://forge.puppet.com/modules/puppetlabs/facts) modules, and
attempts to change as few things as possible in order to create a working shell
script which can be used with little to no external dependencies

## Getting Started

### Dependencies

* A non-Windows platform for which Puppet provides official packages (see the full list [here](https://puppet.com/docs/puppet/latest/system_requirements.html#supported_operating_systems-packaged-platforms))
* One of wget/curl/fetch/perl-LWP-Simple in order to download packages
* `bash` (probably at least version 3)
* Ability to run the script as `root`

### Usage

### Install with curl
```sh
curl -sSL https://raw.githubusercontent.com/puppetlabs/install-puppet/main/install.sh | bash
```

### Install with wget
```sh
wget -qO - https://raw.githubusercontent.com/puppetlabs/install-puppet/main/install.sh | bash
```

Piping to `bash` is a controversial practice, so you are encouraged to inspect
the [contents of the
script](https://github.com/puppetlabs/install-puppet/blob/main/install.sh)
before executing it.


### Script arguments

If run with no arguments, the script will install the latest stable version of puppet-agent. 

You can install a specific version using:
```sh
curl -sSL https://raw.githubusercontent.com/puppetlabs/install-puppet/main/install.sh | bash -s -- -v 6.24.0
```

Below is the full list of configurable options:

* `-v`/`--version` - install a specific puppet-agent version
* `-c`/`--collection` - install a specific puppet-agent collection (e.g. puppet7)
* `-n`/`--noop` - do a dry run, do not change any files
* `--cleanup` - remove the puppetlabs repository after installation finishes

## Development

The Ruby script uses parts of the `bash.sh` task from the
[facts](https://forge.puppet.com/modules/puppetlabs/facts) module, and the
`install_shell.sh` task from the
[puppet_agent](https://forge.puppet.com/modules/puppetlabs/puppet_agent) module
to generate the `install.sh` file. The modules are vendored as git submodules;
in order to initialize them, run `git submodule update --init` after cloning
this repository.

After making your changes, run the following command to regenerate the shell script:
```sh
ruby install.rb
```

You can also run shellcheck on the resulting script, it will skip the vendored
task parts and only warn on code specific to this repository.

```sh
shellcheck install.sh
```

## License

This project is licensed under the Apache 2.0 License - see the LICENSE file for details

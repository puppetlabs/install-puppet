# This script generates an install.sh file which can be used to install
# puppet-agent on supported FOSS POSIX platforms.
#
# The script leverages tasks from the puppet_agent and facts modules, and
# attempts to change as few things as possible.

# we just need the variables from here
facts_script = `sed '/munge_name "$family"/q' < modules/facts/tasks/bash.sh`
install_script = File.read('modules/puppet_agent/tasks/install_shell.sh')
  .sub('[ -f "$PT__installdir/facts/tasks/bash.sh" ]', 'true')
  .sub('$(bash $PT__installdir/facts/tasks/bash.sh "platform")', '$ID')
  .sub('$(bash $PT__installdir/facts/tasks/bash.sh "release")', '$full')

File.write('install.sh', <<-SH)
#!/usr/bin/env bash

beginswith() { case $2 in "$1"*) true;; *) false;; esac; }
 
function usage()
{
   cat << HEREDOC

   Usage: install.sh [--version VERSION] [--collection COLLECTION] [--cleanup] [--noop]

   optional arguments:
     -h, --help                   show this help message and exit
     -v, --version VERSION        install a specific puppet-agent version
     -c, --collection COLLECTION  install a specific puppet-agent collection (e.g. puppet7)
     -n, --noop                   do a dry run, do not change any files 
     --cleanup                    remove the puppetlabs repository after installation finishes

HEREDOC
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
      -v|--version) PT_version="$2"; shift ;
         if beginswith "6." "$PT_version"; then
           PT_collection="puppet6"
         elif beginswith "7." "$PT_version"; then
           PT_collection="puppet7"
         else
           PT_collection="puppet"
         fi ;;
      -c|--collection) PT_collection="$2"; shift ;;
      --cleanup) PT_cleanup=true; shift ;;
      -n|--noop) PT__noop=true; shift ;;
      -h|--help) usage; exit ;;
      *) echo "Unknown parameter passed: $1"; usage; exit 1 ;;
  esac
  shift
done

# shellcheck disable=SC1000-SC9999
{
#{facts_script}
#{install_script}
}

if [[ $PT__noop != true ]]; then
  if [[ $PT_cleanup == true ]]; then
    info "Cleanup requested, removing ${collection}-release repository..."
    case $platform in
      SLES|el|Amzn|"Amazon Linux"|Fedora)
        rpm -e --allmatches ${collection}-release
        ;;
      Debian|LinuxMint|Linuxmint|Ubuntu)
        apt-get purge ${collection}-release -y
        ;;
    esac
  fi
fi
SH

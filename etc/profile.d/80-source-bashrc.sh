# If running bash, make sure we always run /etc/bash.bashrc
[ -z "$BASH_VERSION" ] && return

# only if not read yet, obviously
[ ! -z "$ETC_PROFILE_SOURCED" ] && return

. /etc/bash.bashrc

[ ! -z "$DEBUG" ] && echo "$BASH_SOURCE sourced"
# EOF


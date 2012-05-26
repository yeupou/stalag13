# /etc/profile (interactive login shell) by default does
# not source /etc/bash.bashrc (interactive non login shell)
# make sure it does

# obviously only if running bash
[ -z "$BASH_VERSION" -o -z "$PS1" ] && return
# and only if not done already
[ -z "$BASH_PROFILE_ALREADY_SOURCED" ] && return

# setup stuff that /etc/bash.bashrc skipped
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# actually do the job
. /etc/profile
BASH_PROFILE_ALREADY_SOURCED=1

# EOF


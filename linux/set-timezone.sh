#!/usr/bin/env bash
set -euo pipefail

validate_only=0
if [[ ${1-} == --validate ]]; then validate_only=1; shift; fi
if (( $# > 1 )); then
    echo 'Usage: set-timezone.sh [auto|keep|Area/City]' >&2
    exit 2
fi
zone=${1-auto}

known_timezone() {
    # Reject multiple lines before passing the value to grep as a literal pattern.
    [[ $1 =~ ^[A-Za-z][A-Za-z0-9_+/-]*$ ]] &&
        timedatectl list-timezones | grep -Fx -- "$1" >/dev/null
}

if [[ $zone != auto && $zone != keep ]] && ! known_timezone "$zone"; then
    printf 'Unknown timezone: %s. See timedatectl list-timezones.\n' "$zone" >&2
    exit 2
fi
if (( validate_only )); then exit 0; fi
if [[ $zone == keep ]]; then
    echo 'Keeping the system timezone.'
    exit 0
fi

current=$(timedatectl show --property=Timezone --value)
if [[ $zone == auto ]]; then
    # Calamares uses the public KDE GeoIP service. Trust only zones known to this system.
    if ! zone=$(curl -qfsS --proto '=https' --connect-timeout 3 --max-time 8 --max-filesize 65536 \
        https://geoip.kde.org/v1/calamares | jq -er '.time_zone | strings') || ! known_timezone "$zone"; then
        printf 'Could not detect the timezone. Keeping %s.\n' "${current:-the system default}" >&2
        exit 0
    fi
fi
if [[ $zone != "$current" ]]; then
    sudo timedatectl set-timezone "$zone"
fi
printf 'Timezone: %s\n' "$zone"

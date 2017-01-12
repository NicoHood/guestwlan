#!/bin/bash -e

PROGNAME=$(basename "$0")
ARGS=( "$@" )

usage() {
    echo "Usage: ${PROGNAME} [options]"
    echo
    echo "Generates new WLAN passphrase and QR codes."
    echo
    echo "Options:"
    echo "  -h, --help              Show this help"
    echo "  -c,--config <cfg_file>  Load configs from cfg_file"
    echo "                          Default: etc/guestwlan/guestwlan.cfg"
    echo "  -a,--apconfig <ap_conf> Load configs from ap_conf"
    echo "                          Default: /etc/create_guest_ap.conf"
    echo "  -l,--length <chars>     Generate a password of a special length"
    echo "                          Range: 8-63, Default: 63)"
    echo "  -d,--dict <dict>        Only use characters of a special dict."
    echo "                          See 'man tr'. Default: 'alnum'"
    echo "  -u,--umask <umask>      Use special umask for the QR codes."
    echo "                          Default: 0077"
    echo "  -o,--output <path>      Save QR codes at path."
    echo "                          Default: /var/lib/guestwlan"
    echo
    echo "Useful informations:"
    echo "  * Options are parsed in the priority: params -> config -> default"
    echo "    This means you can overwrite a config file with input parameters."
    echo "  * Using a dict with slashes will cause problems."
    echo
    echo "Examples:"
    echo "  ${PROGNAME} -d digit -l 16"
    echo "  ${PROGNAME} -c ~/guestwlan.cfg -a /etc/create_ap.conf"
    echo "  ${PROGNAME} -o /var/lib/kodi/ -u 0000"
}

# Make sure only root can run the script
if [[ ${EUID} -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Set default values in config array
typeset -A ap_config
typeset -A config
config=(
    [CONFIG]="/etc/guestwlan.cfg"
    [AP_CONFIG]="/etc/create_guest_ap.conf"
    [PASSPHRASE_LENGTH]="63"
    [DICT]="alnum"
    [UMASK]="0077"
    [QRCODE_PATH]="/var/lib/guestwlan"
)

# Preprocessing for --config before option-parsing starts
for ((i=0; i<$#; i++)); do
    if [[ "${ARGS[i]}" = "--config" || "${ARGS[i]}" = "-c" ]]; then
        config[CONFIG]="${ARGS[i+1]}"
        break
    fi
done

# Check if config file exists
if [ ! -f "${config[CONFIG]}" ]; then
    echo "Error: No config file found at given location" 1>&2
    exit 1
fi

# Read guestwlan.cfg
while read -r line
do
    if echo "${line}" | grep -F = &>/dev/null
    then
        varname=$(echo "${line}" | cut -d '=' -f 1)
        config[${varname}]=$(echo "${line}" | cut -d '=' -f 2-)
    fi
done < "${config[CONFIG]}"

# Parse input params an ovrwrite possible default or config loaded options
GETOPT_ARGS=$(getopt -o "hd:c:a:l:d:u:o:" \
            -l "help,config:,apconfig:,length:,dict:,umask:,output:"\
            -n "$PROGNAME" -- "$@")
eval set -- "$GETOPT_ARGS"

# Handle all params
while true ; do
    case "$1" in
        --)
            # No more options left.
            shift
            break
           ;;
        -h|--help)
            usage
            exit 0
            ;;
        -c|--config)
            # Config already parsed above
            shift
            ;;
        -a|--apconfig)
            config[AP_CONFIG]="$2"
            shift
            ;;
        -l|--length)
            config[PASSPHRASE_LENGTH]="$2"
            shift
            ;;
        -d|--dict)
            config[DICT]="$2"
            shift
            ;;
        -u|--umask)
            config[UMASK]="$2"
            shift
            ;;
        -o|--output)
            config[QRCODE_PATH]="$2"
            shift
            ;;
        *)
            echo "Internal error!" 1>&2
            exit 1
            ;;
    esac

    shift
done

# Check if AP config file exists
if [ ! -f "${config[AP_CONFIG]}" ]; then
    echo "Error: No AP config file found at given location" 1>&2
    exit 1
fi

# Check keylength
if [[ "${config[PASSPHRASE_LENGTH]}" -lt 8 || "${config[PASSPHRASE_LENGTH]}" -gt 63 ]]; then
    echo "Error: Invalid passphrase length (8-63 allowed)" 1>&2
    exit 1
fi

# Check if QR code path exists
if [ ! -d "${config[QRCODE_PATH]}" ]; then
    echo "Error: QR code output path does not exist" 1>&2
    exit 1
fi

# Read create_guest_ap.conf
while read -r line
do
    if echo "${line}" | grep -F = &>/dev/null
    then
        varname=$(echo "${line}" | cut -d '=' -f 1)
        ap_config[${varname}]=$(echo "${line}" | cut -d '=' -f 2-)
    fi
done < "${config[AP_CONFIG]}"

# All new files and directories must be readable only by root.
# In special cases we must use chmod to give any other permissions.
umask "${config[UMASK]}"

# Generate new wlan password and safe it.
# Do not use special chars as they are a) hard to read and b) cause problems with sed
# TODO fix "tr: write error: Broken pipe" (Not essentially a problem)
WLANPSK=$(</dev/random tr -dc "[:${config[DICT]}:]" | head -c "${config[PASSPHRASE_LENGTH]}")
sed -i "s/PASSPHRASE=.*/PASSPHRASE=${WLANPSK}/" "${config[AP_CONFIG]}"

# Convert hidden setting into string
if [ "${ap_config[HIDDEN]}" == "1" ]
then
    HIDDENSSID="true"
else
    HIDDENSSID="false"
fi

# Generate QR code pictures for Android and Windows.
# IOS does not support any WIFI QR code.
# Use the copy to clipboard function for the password and manually connect instead.
qrencode -t PNG -o "${config[QRCODE_PATH]}/AndroidWlan.png" -s 4 "WIFI:T:WPA;S:${ap_config[SSID]};P:${WLANPSK};H:${HIDDENSSID};"
qrencode -t PNG -o "${config[QRCODE_PATH]}/WindowsWlan.png" -s 4 "WIFI;T:WPA;S:${ap_config[SSID]};P:${WLANPSK};H:${HIDDENSSID};"
qrencode -t PNG -o "${config[QRCODE_PATH]}/iOSWlan.png" -s 4 "${WLANPSK}"

echo "New WLAN password generated and QR codes saved successfully to ${config[QRCODE_PATH]}."

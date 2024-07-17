#!/bin/bash

umask 077

CLIENT_IP="$1"
PUBLIC_IP="$2"
CLIENT_NAME="$3"
DNS="$4" # optional

[[ -n "$DNS" ]] || DNS="1.1.1.1,1.0.0.1" # defaults to OpenDNS

CONFIG_DIR="/etc/wireguard"
SERVER_CONF="${CONFIG_DIR}/wg0.conf"

CLIENT_CONF="${CONFIG_DIR}/${CLIENT_NAME}.conf"
CLIENT_PRIVATE_KEY="${CONFIG_DIR}/${CLIENT_NAME}.key"
CLIENT_PUBLIC_KEY="${CONFIG_DIR}/${CLIENT_NAME}.pub"
CLIENT_PRESHARED_KEY="${CONFIG_DIR}/${CLIENT_NAME}.psk"

wg genkey | tee "$CLIENT_PRIVATE_KEY" | wg pubkey > "$CLIENT_PUBLIC_KEY"
wg genpsk > "$CLIENT_PRESHARED_KEY"

# Add new Peer on wireguard server config
cat << EOF >> "$SERVER_CONF"
# ${CLIENT_NAME}
[Peer]
PublicKey = $(cat "$CLIENT_PUBLIC_KEY")
PresharedKey = $(cat "$CLIENT_PRESHARED_KEY")
AllowedIPs = ${CLIENT_IP}/32

EOF

# Create a client config
cat << EOF > "$CLIENT_CONF"
[Interface]
Address = ${CLIENT_IP}/32
DNS = ${DNS}
PrivateKey = $(cat "$CLIENT_PRIVATE_KEY")

[Peer]
PublicKey = $(cat ${CONFIG_DIR}/server.pub)
PresharedKey = $(cat "$CLIENT_PRESHARED_KEY")
Endpoint = ${PUBLIC_IP}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25

EOF

# Print QR code scanable by the Wireguard mobile app on screen
qrencode -t ansiutf8 < "${CLIENT_NAME}.conf"

wg syncconf wg0 <(wg-quick strip wg0)

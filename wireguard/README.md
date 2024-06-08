# Add new client for WireGuard

Run the script like:

```bash
chmod +x /path/to/add-wg-client.sh
sudo -i
mkdir "/etc/wireguard" # Run this, if directory don't exist

/path/to/add-wg-client.sh "10.0.0.2" "insert_server_public_ip:47111" "macbook-laptop"
/path/to/add-wg-client.sh "10.0.0.3" "insert_server_public_ip:47111" "iphone15"

exit
```

to generate clients:

- `macbook-laptop` with address `10.0.0.2`
- `iphone15` with address `10.0.0.3`

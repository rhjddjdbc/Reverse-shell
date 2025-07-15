# Reverse SSH Tunnel Script

This script sets up a secure reverse SSH tunnel using encrypted configuration data hosted remotely. It is suitable for both capture-the-flag (CTF) challenges and authorized production environments where stealth and automation are important.

## Features

- Randomized sleep delay to reduce predictability
- Rotating User-Agent strings for download obfuscation
- Resilient payload retrieval via `curl`, `wget`, or Python
- RSA decryption of remote host and port information
- In-memory execution without leaving residual files
- Automatic cleanup of sensitive environment variables
- Signal handling for graceful termination

## Intended Use

This script may be used in the following scenarios:

- CTF competitions or security training
- Home lab automation and experimentation
- Production deployments in trusted and authorized environments

## Disclaimer

This tool is intended for responsible use only. It must not be deployed against systems without explicit permission. The author disclaims any liability for misuse or unauthorized access facilitated by this script.

## License

This project is licensed under the MIT License. You are free to use, modify, and distribute the code, including for commercial or productive purposes, as long as the terms of the MIT License are respected.

See the `LICENSE` file in this repository for full details.

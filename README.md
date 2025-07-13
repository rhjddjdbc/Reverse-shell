# Reverse SSH Tunnel Script

This script establishes a reverse SSH tunnel using an AES-encrypted IP:PORT string fetched from a GitHub repository. It is designed to securely connect to a remote server while obfuscating the connection details.

## Features

- **AES Encryption**: The IP and port are stored in an encrypted format for security.
- **Random Delay**: Introduces a random delay before execution to avoid detection.
- **Base64 Encoding**: The SSH command is encoded in Base64 to further obfuscate the connection details.

## Prerequisites

Before using this script, ensure you have the following installed:

- `curl`: For fetching the encrypted connection data.
- `openssl`: For decrypting the AES-encrypted string.
- `bash`: The script is written in Bash and requires a compatible shell.

## Configuration

1. **GitHub URL**: Update the `GITHUB_URL` variable with the URL of your encrypted IP:PORT string.
   ```bash
   GITHUB_URL="https://raw.githubusercontent.com/username/repo-name/main/encrypted.txt"
   ```

2. **Encryption Key**: Set the `KEY` variable to your secret passphrase used for encryption.
   ```bash
   KEY="yourSecretPassphrase"
   ```

## Usage

1. **Clone the Repository**: Clone this repository to your local machine.
2. **Make the Script Executable**: Run the following command to make the script executable:
   ```bash
   chmod +x reverse_ssh_tunnel.sh
   ```
3. **Run the Script**: Execute the script:
   ```bash
   ./reverse_ssh_tunnel.sh
   ```

## How It Works

1. The script waits for a random duration between 60 to 240 seconds.
2. It fetches the encrypted IP:PORT string from the specified GitHub URL.
3. The script decrypts the fetched string using the provided passphrase.
4. It extracts the IP address and port from the decrypted string.
5. The script constructs the SSH command for establishing a reverse tunnel.
6. The SSH command is encoded in Base64 and then executed.

## Security Considerations

- Ensure that the encryption key is kept secret and not hard-coded in the script.
- Regularly update the encrypted IP:PORT string in the GitHub repository to maintain security.
- Use secure practices when managing SSH keys and user credentials.

## License

This project is licensed under the GPL v3 License. See the LICENSE file for more details.

## Disclaimer

Use this script responsibly and ensure you have permission to establish a reverse SSH tunnel to the target server. Misuse of this script may lead to legal consequences.

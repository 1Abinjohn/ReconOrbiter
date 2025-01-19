# ReconOrbiter
**ReconOrbiter** is a comprehensive bug bounty reconnaissance script that automates subdomain enumeration, port scanning, web crawling, and vulnerability detection. It integrates multiple tools to streamline the reconnaissance process for bug bounty hunters and penetration testers.

---

## Features

- **Dependency Check**: Verifies the presence of required tools before execution.
- **Anonymity with Tor**: Uses Tor for anonymous scans and rotates identities to avoid detection.
- **Subdomain Enumeration**: Discovers subdomains using Subfinder and Assetfinder.
- **Alive Subdomains**: Identifies responsive subdomains with `httprobe`.
- **Port Scanning**: Scans open ports using Naabu.
- **Archived URLs**: Fetches archived URLs from the Wayback Machine using WaybackURLs.
- **Web Crawling**: Crawls application endpoints with Katana.
- **XSS Detection**: Scans for XSS vulnerabilities using Dalfox and XSStrike.
- **DNS Validation**: Validates discovered subdomains with DNSx.
- **HTTP Status Codes**: Logs HTTP status codes of discovered subdomains using Httpx.
- **Screenshots**: Captures visual snapshots of live subdomains with Gowitness.
- **Dynamic User-Agent**: Randomizes User-Agent strings for every request to bypass filtering.

---

## Requirements

Ensure the following tools are installed on your system:
- `subfinder`
- `assetfinder`
- `httprobe`
- `gowitness`
- `naabu`
- `waybackurls`
- `dnsx`
- `httpx`
- `katana`
- `dalfox`
- `xsstrike`
- `tor`
- `nc`

You can install these tools using the respective package managers or binary downloads.

---

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/<your-username>/ReconOrbiter.git
   cd ReconOrbiter
   ```

2. Make the script executable:
   ```bash
   chmod +x ReconOrbiter.sh
   ```

---

## Usage

Run the script by providing a domain as an argument:

```bash
./ReconOrbiter.sh <domain>
```

### Example:
```bash
./ReconOrbiter.sh example.com
```

All output files will be saved in a structured directory named after the target domain.

---

## Directory Structure

The script organizes output files in the following structure:

```
<domain>/
├── subdomains/
│   ├── subdomain.txt         # List of discovered subdomains
│   ├── alive_all.txt         # Consolidated list of live subdomains
│   ├── alive_https.txt       # Live subdomains with HTTPS
│   ├── alive_http.txt        # Live subdomains with HTTP
├── screenshots/
│   └── (Captured screenshots of live subdomains)
├── scans/
│   ├── scan-result.txt       # Results of port scanning
│   ├── dalfox_results.txt    # Findings from XSS vulnerability scans
│   ├── xsstrike_results.txt  # Detailed XSS scanning results
├── wayback/
│   └── waybackurls.txt       # Archived URLs retrieved for analysis
├── dns_resolution/
│   └── valid_subdomains.txt  # Subdomains with valid DNS resolution
├── http_status/
│   └── status_codes.txt      # HTTP status codes of live subdomains
├── katana_output/
│   └── crawl_output.jsonl    # Crawled endpoints for further exploration
```

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Contributing

Contributions are welcome! If you find a bug or have suggestions, feel free to open an issue or submit a pull request.

---

## Disclaimer

**ReconOrbiter** is designed for legal penetration testing and bug bounty activities. Ensure you have explicit permission to test any target before running the script. Misuse of this tool is strictly prohibited.

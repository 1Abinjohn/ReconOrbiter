#!/bin/bash

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "\033[1;31m[!] $1 is not installed. Please install it first.\033[0m"
        exit 1
    fi
}

# Check dependencies
dependencies=(subfinder assetfinder httprobe gowitness naabu waybackurls dnsx httpx katana dalfox xsstrike tor nc)
for dep in "${dependencies[@]}"; do
    check_command "$dep"
done

# Validate input
domain=$1
if [ -z "$domain" ]; then
    echo -e "\033[1;31m[!] Usage: $0 <domain>\033[0m"
    exit 1
fi

# Directories
RED="\033[1;31m"
RESET="\033[0m"
subdomain_path="$domain/subdomains"
screenshot_path="$domain/screenshots"
scan_path="$domain/scans"
wayback_path="$domain/wayback"
dns_path="$domain/dns_resolution"
http_status_path="$domain/http_status"
katana_output_path="$domain/katana_output"

# User-Agent List
USER_AGENTS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.5481.177 Safari/537.36"
    "Mozilla/5.0 (iPhone; CPU iPhone OS 14_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.2 Mobile/15E148 Safari/604.1"
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.5615.121 Safari/537.36"
)

# Start Tor service
echo -e "${RED} [+] Starting Tor service....${RESET}"
sudo service tor start

# Function to rotate Tor identity
rotate_tor() {
    echo -e "${RED} [+] Rotating Tor identity....${RESET}"
    echo -e 'AUTHENTICATE ""\r\nSIGNAL NEWNYM\r\nQUIT' | nc 127.0.0.1 9051
    sleep 5
}

# Create directories
echo -e "${RED} [+] Setting up directories....${RESET}"
for path in "$domain" "$subdomain_path" "$screenshot_path" "$scan_path" "$wayback_path" "$dns_path" "$http_status_path" "$katana_output_path"; do
    mkdir -p "$path"
done

# Subdomain enumeration
if [ -s "$subdomain_path/subdomain.txt" ]; then
    echo -e "${RED} [+] Subdomain enumeration results found, skipping....${RESET}"
else
    echo -e "${RED} [+] Running subfinder....${RESET}"
    subfinder -d "$domain" > "$subdomain_path/subdomain.txt"
    rotate_tor

    echo -e "${RED} [+] Running assetfinder....${RESET}"
    assetfinder "$domain" | grep "$domain" >> "$subdomain_path/subdomain.txt"
    rotate_tor
fi

# Finding alive subdomains
if [ -s "$subdomain_path/alive_all.txt" ]; then
    echo -e "${RED} [+] Alive subdomains already found, skipping....${RESET}"
else
    echo -e "${RED} [+] Finding alive subdomains....${RESET}"
    cat "$subdomain_path/subdomain.txt" | sort -u | httprobe |
        tee >(grep '^https://' | sed 's|https://||' > "$subdomain_path/alive_https.txt") \
            >(grep '^http://' | sed 's|http://||' > "$subdomain_path/alive_http.txt")
    cat "$subdomain_path/alive_https.txt" "$subdomain_path/alive_http.txt" > "$subdomain_path/alive_all.txt"
fi

# Screenshots
if [ "$(ls -A $screenshot_path 2>/dev/null)" ]; then
    echo -e "${RED} [+] Screenshots already taken, skipping....${RESET}"
else
    echo -e "${RED} [+] Taking screenshots of alive subdomains....${RESET}"
    gowitness file -f "$subdomain_path/alive_all.txt" -P "$screenshot_path/" --no-http
fi

# Port scanning with Naabu
if [ -s "$scan_path/scan-result.txt" ]; then
    echo -e "${RED} [+] Port scanning results found, skipping....${RESET}"
else
    echo -e "${RED} [+] Scanning with Naabu....${RESET}"
    naabu -list "$subdomain_path/alive_all.txt" -rate 100 -exclude-ports 80,443 -o "$scan_path/scan-result.txt"
fi

# Wayback URLs
if [ -s "$wayback_path/waybackurls.txt" ]; then
    echo -e "${RED} [+] Wayback URLs already retrieved, skipping....${RESET}"
else
    echo -e "${RED} [+] Retrieving Wayback URLs....${RESET}"
    cat "$subdomain_path/alive_all.txt" | waybackurls > "$wayback_path/waybackurls.txt"
    rotate_tor
fi

# Scanning with Dalfox for XSS
if [ -s "$scan_path/dalfox_results.txt" ]; then
    echo -e "${RED} [+] Dalfox results already exist, skipping....${RESET}"
else
    echo -e "${RED} [+] Scanning for XSS vulnerabilities using Dalfox....${RESET}"
    RANDOM_USER_AGENT="${USER_AGENTS[$RANDOM % ${#USER_AGENTS[@]}]}"
    cat "$wayback_path/waybackurls.txt" | dalfox pipe --proxy socks5://127.0.0.1:9050 --delay 500 -H "User-Agent: $RANDOM_USER_AGENT" --output "$scan_path/dalfox_results.txt"
    rotate_tor
fi

# Web crawling with Katana
if [ -s "$katana_output_path/crawl_output.jsonl" ]; then
    echo -e "${RED} [+] Katana crawl results found, skipping....${RESET}"
else
    echo -e "${RED} [+] Launching Katana crawler on alive subdomains....${RESET}"
    RANDOM_USER_AGENT="${USER_AGENTS[$RANDOM % ${#USER_AGENTS[@]}]}"
    katana -u "$subdomain_path/alive_all.txt" --proxy socks5://127.0.0.1:9050 -H "User-Agent: $RANDOM_USER_AGENT" -o "$katana_output_path/crawl_output.jsonl"
    rotate_tor
fi

# Export Tor proxy for XSStrike
echo -e "${RED} [+] Configuring Tor proxy for XSStrike....${RESET}"
export HTTP_PROXY="socks5://127.0.0.1:9050"
export HTTPS_PROXY="socks5://127.0.0.1:9050"

# Scanning with XSStrike for XSS
if [ -s "$scan_path/xsstrike_results.txt" ]; then
    echo -e "${RED} [+] XSStrike results already exist, skipping....${RESET}"
else
    echo -e "${RED} [+] Scanning with XSStrike for potential XSS vulnerabilities....${RESET}"
    cat "$katana_output_path/crawl_output.jsonl" | grep -Eo 'https?://[^"]+' | while read -r url; do
        RANDOM_USER_AGENT="${USER_AGENTS[$RANDOM % ${#USER_AGENTS[@]}]}"
        xsstrike -u "$url" --crawl --blind --headers "User-Agent: $RANDOM_USER_AGENT"
        sleep $((RANDOM % 2 + 1))  # Random delay between XSStrike requests
        rotate_tor
    done | tee "$scan_path/xsstrike_results.txt"
fi

# DNS resolution
if [ -s "$dns_path/valid_subdomains.txt" ]; then
    echo -e "${RED} [+] DNS resolution results found, skipping....${RESET}"
else
    echo -e "${RED} [+] Validating DNS for discovered subdomains....${RESET}"
    cat "$subdomain_path/subdomain.txt" | sort -u | dnsx -silent -o "$dns_path/valid_subdomains.txt"
fi

# HTTP status codes
if [ -s "$http_status_path/status_codes.txt" ]; then
    echo -e "${RED} [+] HTTP status codes already checked, skipping....${RESET}"
else
    echo -e "${RED} [+] Checking HTTP status codes....${RESET}"
    RANDOM_USER_AGENT="${USER_AGENTS[$RANDOM % ${#USER_AGENTS[@]}]}"
    httpx -l "$subdomain_path/alive_all.txt" -rate-limit 50 -H "User-Agent: $RANDOM_USER_AGENT" --proxy socks5://127.0.0.1:9050 -status-code -o "$http_status_path/status_codes.txt"
fi

echo -e "${RED} [+] Script execution completed! Outputs saved in $domain directory.${RESET}"

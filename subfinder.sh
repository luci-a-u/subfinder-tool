#!/bin/bash

# Simple but Effective Subdomain Enumeration Script
# Usage: ./subfinder.sh example.com

# Check if domain is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

domain=$1
timestamp=$(date +%F_%H-%M-%S)
outdir="${domain}_enum_${timestamp}"

mkdir -p "$outdir"

echo "[*] Enumerating subdomains for: $domain"
echo "[*] All results will be stored in: $outdir/"
echo

# Run subfinder (fastest, good coverage)
if command -v subfinder >/dev/null 2>&1; then
    echo "[-] Running subfinder..."
    subfinder -d "$domain" -silent 2>/dev/null | sort -u > "$outdir/subfinder.txt"
    echo "[+] subfinder found $(wc -l < "$outdir/subfinder.txt") subdomains"
else
    echo "[!] subfinder not found, skipping..."
    touch "$outdir/subfinder.txt"
fi

# Certificate Transparency (often the best source)
echo "[-] Querying Certificate Transparency logs..."
timeout 60 curl -s "https://crt.sh/?q=%25.$domain&output=json" |
  jq -r '.[].name_value' 2>/dev/null |
  sed 's/\*\.//g' |
  sort -u > "$outdir/crtsh.txt"
echo "[+] crt.sh found $(wc -l < "$outdir/crtsh.txt") subdomains"

# Skip amass (removed per user request)

# Run assetfinder (good additional coverage)
if command -v assetfinder >/dev/null 2>&1; then
    echo "[-] Running assetfinder..."
    timeout 120 assetfinder --subs-only "$domain" 2>/dev/null | sort -u > "$outdir/assetfinder.txt"
    echo "[+] assetfinder found $(wc -l < "$outdir/assetfinder.txt") subdomains"
else
    echo "[!] assetfinder not found, skipping..."
    touch "$outdir/assetfinder.txt"
fi

# Additional quick sources
echo "[-] Checking additional sources..."

# Virus Total (no API key needed for basic queries)
timeout 30 curl -s "https://www.virustotal.com/vtapi/v2/domain/report?apikey=&domain=$domain" |
  jq -r '.subdomains[]?' 2>/dev/null | sort -u > "$outdir/virustotal.txt"

# DNSdumpster (web scraping - be respectful)
timeout 30 curl -s "https://dnsdumpster.com/" -d "targetip=$domain" |
  grep -oE "[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.${domain//./\\.}" |
  sort -u > "$outdir/dnsdumpster.txt" 2>/dev/null

echo "[+] Additional sources found $(cat "$outdir/virustotal.txt" "$outdir/dnsdumpster.txt" 2>/dev/null | sort -u | wc -l) subdomains"

# Merge and clean results
echo "[-] Merging and cleaning results..."
cat "$outdir"/*.txt 2>/dev/null | 
grep -E '^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\..*$' |
grep -v '^\s*$' |
sort -u > "$outdir/all.txt"

echo
echo "[+] Total unique subdomains: $(wc -l < "$outdir/all.txt")"
echo "[+] Merged results saved in: $outdir/all.txt"

# Show results summary
echo
echo "[*] Results Summary:"
for file in subfinder crtsh assetfinder virustotal dnsdumpster; do
    if [ -f "$outdir/${file}.txt" ]; then
        printf "  %-15s: %d subdomains\n" "$file" "$(wc -l < "$outdir/${file}.txt")"
    fi
done

# Check for live subdomains
if command -v httpx >/dev/null 2>&1; then
    echo
    echo "[-] Checking which subdomains are alive..."
    grep -E '^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\..*\.[a-zA-Z]{2,}$' "$outdir/all.txt" |
    timeout 180 httpx -silent -nc -threads 50 > "$outdir/alive.txt"
    echo "[+] Live subdomains: $(wc -l < "$outdir/alive.txt")"
    echo "[+] Alive results saved in: $outdir/alive.txt"
fi

echo
echo "[*] Enumeration complete! Check the $outdir/ directory for results."

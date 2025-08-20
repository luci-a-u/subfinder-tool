#!/bin/bash

# Enhanced Subdomain Enumeration Script with GitHub Integration
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

# Load GitHub tokens
TOKENSFILE="TOKENSFILE"
if [ -f "$TOKENSFILE" ]; then
    mapfile -t GITHUB_TOKENS < <(grep -v '^[[:space:]]*$' "$TOKENSFILE" | grep -v '^#')
    
    if [ ${#GITHUB_TOKENS[@]} -gt 0 ]; then
        RANDOM_INDEX=$((RANDOM % ${#GITHUB_TOKENS[@]}))
        export GITHUB_TOKEN="${GITHUB_TOKENS[$RANDOM_INDEX]}"
        echo "[+] Loaded ${#GITHUB_TOKENS[@]} GitHub tokens from $TOKENSFILE"
        echo "[+] Using token #$((RANDOM_INDEX + 1)) for this session"
    else
        echo "[!] Warning: $TOKENSFILE exists but contains no valid tokens"
        export GITHUB_TOKEN=""
    fi
else
    echo "[!] Warning: $TOKENSFILE not found in current directory"
    export GITHUB_TOKEN=""
fi

# Run subfinder
if command -v subfinder >/dev/null 2>&1; then
    echo "[-] Running subfinder..."
    subfinder -d "$domain" -silent 2>/dev/null | sort -u > "$outdir/subfinder.txt"
    echo "[+] subfinder found $(wc -l < "$outdir/subfinder.txt") subdomains"
fi

# GitHub subdomain search with enhanced patterns and rate limiting
echo "[-] Searching GitHub repositories..."
if [ -n "$GITHUB_TOKEN" ]; then
    # Function to check rate limit
    check_rate_limit() {
        local remaining=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                               -H "Accept: application/vnd.github.v3+json" \
                               "https://api.github.com/rate_limit" | 
                               jq -r '.resources.search.remaining' 2>/dev/null)
        
        if [ "$remaining" != "null" ] && [ "$remaining" -lt 5 ]; then
            echo "[!] Rate limit low ($remaining remaining), waiting 60 seconds..."
            sleep 60
        fi
    }
    
    # Enhanced subdomain search function
    github_search_subdomain() {
        local query="$1"
        local output_file="$2"
        
        check_rate_limit
        
        # Search with multiple query variations for better coverage
        for search_query in "$query" "\"$query\"" "site:$query" "*.$query"; do
            echo "  [*] Searching for: $search_query"
            
            curl -s -H "Authorization: token $GITHUB_TOKEN" \
                 -H "Accept: application/vnd.github.v3+json" \
                 "https://api.github.com/search/code?q=${search_query// /%20}+in:file&per_page=100" |
            jq -r '.items[]?.html_url' 2>/dev/null |
            head -20 |  # Limit to prevent excessive API calls
            while read -r url; do
                if [ -n "$url" ]; then
                    echo "    [*] Processing: $(basename "$url")"
                    # Get raw content of the file
                    raw_url=$(echo "$url" | sed 's/github.com/raw.githubusercontent.com/' | sed 's/blob\///')
                    
                    # Add timeout and better error handling
                    timeout 30 curl -s -H "Authorization: token $GITHUB_TOKEN" "$raw_url" 2>/dev/null |
                    grep -oiE "[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.${domain//./\\.}" |
                    tr '[:upper:]' '[:lower:]' |  # Convert to lowercase
                    sort -u >> "$output_file" 2>/dev/null
                    
                    # Small delay to be respectful
                    sleep 0.5
                fi
            done
            
            # Delay between different search queries
            sleep 2
        done
    }
    
    # Search patterns
    echo "  [*] Searching for ${domain} mentions in GitHub code..."
    github_search_subdomain "$domain" "$outdir/github_temp.txt"
    
    # Clean and deduplicate results
    if [ -f "$outdir/github_temp.txt" ] && [ -s "$outdir/github_temp.txt" ]; then
        # Remove duplicates and invalid entries
        cat "$outdir/github_temp.txt" | 
        grep -v "^$domain$" |  # Remove root domain
        grep -E "^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.${domain//./\\.}$" |
        sort -u > "$outdir/github.txt"
        rm -f "$outdir/github_temp.txt"
        echo "[+] GitHub API search found $(wc -l < "$outdir/github.txt") subdomains"
    else
        touch "$outdir/github.txt"
        echo "[+] GitHub API search found 0 subdomains"
    fi
else
    echo "[!] No GitHub token available, skipping GitHub search"
    touch "$outdir/github.txt"
fi

# Run github-subdomains if available
if command -v github-subdomains >/dev/null 2>&1 && [ -n "$GITHUB_TOKEN" ]; then
    echo "[-] Running github-subdomains tool..."
    timeout 300 github-subdomains -d "$domain" -t "$GITHUB_TOKEN" 2>/dev/null | 
    sort -u > "$outdir/github_subdomains.txt"
    echo "[+] github-subdomains found $(wc -l < "$outdir/github_subdomains.txt") subdomains"
fi

# Pull from crt.sh
echo "[-] Querying crt.sh..."
timeout 60 curl -s "https://crt.sh/?q=%25.$domain&output=json" |
  jq -r '.[].name_value' 2>/dev/null |
  sed 's/\*\.//g' |
  sort -u > "$outdir/crtsh.txt"
echo "[+] crt.sh found $(wc -l < "$outdir/crtsh.txt") subdomains"

# Run amass (passive mode)
if command -v amass >/dev/null 2>&1; then
    echo "[-] Running amass..."
    timeout 600 amass enum -passive -d "$domain" 2>/dev/null | sort -u > "$outdir/amass.txt"
    echo "[+] amass found $(wc -l < "$outdir/amass.txt") subdomains"
fi

# Run assetfinder
if command -v assetfinder >/dev/null 2>&1; then
    echo "[-] Running assetfinder..."
    timeout 120 assetfinder --subs-only "$domain" 2>/dev/null | sort -u > "$outdir/assetfinder.txt"
    echo "[+] assetfinder found $(wc -l < "$outdir/assetfinder.txt") subdomains"
fi

# Merge results
cat "$outdir"/*.txt 2>/dev/null | sort -u > "$outdir/all.txt"
echo
echo "[+] Total unique subdomains: $(wc -l < "$outdir/all.txt")"
echo "[+] Merged results saved in: $outdir/all.txt"

# Show top level summary
echo
echo "[*] Results Summary:"
for file in "$outdir"/*.txt; do
    if [ -f "$file" ] && [ "$(basename "$file")" != "all.txt" ] && [ "$(basename "$file")" != "alive.txt" ]; then
        printf "  %-20s: %d subdomains\n" "$(basename "$file" .txt)" "$(wc -l < "$file")"
    fi
done

# Optional: Check for live subdomains
if command -v httpx >/dev/null 2>&1; then
    echo
    echo "[-] Checking which subdomains are alive (httpx)..."
    grep -E '^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\..*$' "$outdir/all.txt" | 
    grep -v '^\.' > "$outdir/cleaned.txt"
    cat "$outdir/all.txt" | timeout 300 httpx -silent -nc -threads 50 > "$outdir/alive.txt"
    echo "[+] Live subdomains saved in: $outdir/alive.txt ($(wc -l < "$outdir/alive.txt") alive)"

# SubFinder-Tool

A **fast and efficient Bash-based subdomain enumeration tool** that discovers subdomains from multiple passive sources.  
Automatically organizes results with **timestamped directories**, **deduplication**, and **live domain validation**.

---

## Features

- **Multi-source subdomain enumeration** from:
  - [subfinder](https://github.com/projectdiscovery/subfinder) → Fast passive subdomain discovery
  - [assetfinder](https://github.com/tomnomnom/assetfinder) → Asset & subdomain enumeration
  - **crt.sh** → Certificate Transparency logs (often the most productive source)
  - **Additional sources** → Alternative Certificate Transparency and passive reconnaissance 
- **Live domain validation** using [httpx](https://github.com/projectdiscovery/httpx)
- **Timestamped output directories** for organized results
- **Automatic deduplication** and intelligent merging
- **Clean result organization** with per-source files and combined results
- **Fast execution** - optimized for speed and reliability

---

<img width="1059" height="808" alt="Screenshot From 2025-08-20 10-43-19" src="https://github.com/user-attachments/assets/a6339738-f8cd-40c1-841e-d3fb43520b35" />


## Installation & Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/luci-a-u/subfinder-tool.git
   cd subfinder-tool
   ```

2. **Make the script executable**
   ```bash
   chmod +x subfinder.sh
   ```

3. **Install required tools** (install the ones available on your system):
   ```bash
   # Install subfinder (recommended)
   go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

   # Install assetfinder (recommended)
   go install github.com/tomnomnom/assetfinder@latest

   # Install httpx for domain validation (recommended)
   go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
   ```

   **Note:** Make sure your `~/go/bin` is in your `$PATH` for Go tools.

4. **Install dependencies**
   ```bash
   # Required for parsing JSON responses
   sudo apt install jq curl
   ```

---

## Usage

Run the script with a target domain:

```bash
./subfinder.sh <domain>
```

**Example:**
```bash
./subfinder.sh example.com
```

**Output:** Creates a timestamped directory with organized results:
```
example.com_enum_2025-08-20_15-22-10/
├── subfinder.txt      # Subfinder results
├── assetfinder.txt    # Assetfinder results  
├── crtsh.txt          # Certificate transparency results
├── additional.txt     # Additional sources results
├── all.txt            # Merged & deduplicated results
└── alive.txt          # Live domains (httpx validated)
```

---

## Example Run

```bash
$ ./subfinder.sh tesla.com
[*] Enumerating subdomains for: tesla.com
[*] All results will be stored in: tesla.com_enum_2025-08-20_15-22-10/

[-] Running subfinder...
[+] subfinder found 127 subdomains
[-] Querying Certificate Transparency logs...
[+] crt.sh found 89 subdomains
[-] Running assetfinder...
[+] assetfinder found 156 subdomains
[-] Checking additional sources...
[+] Additional sources found 23 subdomains
[-] Merging and cleaning results...

[+] Total unique subdomains: 312
[+] Merged results saved in: tesla.com_enum_2025-08-20_15-22-10/all.txt

[*] Results Summary:
  subfinder      : 127 subdomains
  crtsh          : 89 subdomains
  assetfinder    : 156 subdomains
  additional     : 23 subdomains

[-] Checking which subdomains are alive...
[+] Live subdomains: 87
[+] Alive results saved in: tesla.com_enum_2025-08-20_15-22-10/alive.txt

[*] Enumeration complete! Check the tesla.com_enum_2025-08-20_15-22-10/ directory for results.
```

---

## Tool Details

| Tool/Source | Purpose | Speed | Output File |
|-------------|---------|--------|-------------|
| **subfinder** | Fast passive subdomain discovery | Fast | `subfinder.txt` |
| **crt.sh** | Certificate Transparency logs | Fast | `crtsh.txt` |
| **assetfinder** | Multiple passive sources aggregated | Medium | `assetfinder.txt` |
| **Additional sources** | Alternative CT and passive DNS data | Fast | `additional.txt` |
| **httpx** | HTTP probe for live domain validation | Medium | `alive.txt` |

---

## Output Structure

Each execution creates a timestamped directory with organized results:

```
domain_enum_YYYY-MM-DD_HH-MM-SS/
├── subfinder.txt      # Subfinder passive discovery results
├── crtsh.txt          # Certificate transparency results  
├── assetfinder.txt    # Assetfinder enumeration results
├── additional.txt     # Additional sources results
├── all.txt            # Merged & deduplicated master list
└── alive.txt          # Live domains validated by httpx
```

---

## System Requirements

- **Bash** shell environment (Linux/macOS/WSL)
- **Go** 1.19+ (for installing Go-based tools)
- **Internet connection** for API queries and tool execution
- **Dependencies**: `jq`, `curl` (usually pre-installed)

---

## Removed Features

This version has been **optimized for speed and reliability** by removing:
- **GitHub API integration** (minimal results, complex token management)
- **Amass integration** (slow, verbose output format issues)

Focus is on **fast, reliable sources** that provide the most comprehensive results.

---

## Performance

**Typical Results:**
- **Small domains** (startups): 50-200 subdomains
- **Medium domains** (companies): 200-1000 subdomains  
- **Large domains** (enterprises): 1000+ subdomains

**Execution Time:**
- **Fast execution**: Usually completes in 1-3 minutes
- **Optimized timeouts** prevent hanging on slow sources
- **Concurrent processing** where possible

---

## Disclaimer

This tool is intended for **educational purposes** and **authorized security testing only**.  
**Always ensure you have explicit permission** before scanning any target domain.

**Responsible Usage:**
- Only scan domains you own or have permission to test
- Respect rate limits and be considerate of target infrastructure
- Use results responsibly and ethically

---

## License

This project is licensed under the **MIT License**. See [LICENSE](LICENSE) file for details.

---

## Contributing

Contributions are welcome! Please feel free to:
- Submit **bug reports** via issues
- Suggest **new features** or improvements  
- Submit **pull requests** for fixes and enhancements
- Improve **documentation**

# SubFinder-Tool

A Bash-based **enhanced subdomain enumeration tool** with **GitHub API integration**.  
It automates the process of discovering and validating subdomains from multiple sources, saving results in a clean and organized way.

---

## Features

- **Multi-tool subdomain enumeration** from:
  - [subfinder](https://github.com/projectdiscovery/subfinder) → Subdomain discovery
  - [assetfinder](https://github.com/tomnomnom/assetfinder) → Asset & subdomain enumeration
  - [amass](https://github.com/OWASP/Amass) → Advanced subdomain enumeration & OSINT
  - [github-subdomains](https://github.com/gwen001/github-search) → GitHub repository scanning
- **GitHub API integration** with rotating API tokens to avoid rate limits
- **Live domain validation** using [httpx](https://github.com/projectdiscovery/httpx)
- **Timestamped output directories** for organized results
- **Automatic deduplication** and merging into master lists
- **Clean result organization** per tool plus combined files

---

## Installation

Install the required tools using Go:

```bash
# Core enumeration tools
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/tomnomnom/assetfinder@latest
go install -v github.com/owasp-amass/amass/v3/...@master
go install -v github.com/gwen001/github-search@latest

# Domain validation
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
```

Ensure all tools are in your `$PATH`.

---

## Usage

```bash
./subfinder.sh <domain>
```

**Example:**
```bash
./subfinder.sh example.com
```

Output will be stored in:
```
example.com_enum_2025-08-20_12-45-01/
```

---

## GitHub Token Configuration

To avoid GitHub API rate limiting, create a `TOKENSFILE` in the repository root:

```bash
# TOKENSFILE - One token per line
ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ghp_yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
ghp_zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz
```

**Security Note:** Add `TOKENSFILE` to `.gitignore` to prevent committing tokens to the repository.

---

## Output Structure

Each execution creates a timestamped directory:

```
domain_enum_YYYY-MM-DD_HH-MM-SS/
├── subfinder.txt      # Subfinder results
├── assetfinder.txt    # Assetfinder results
├── amass.txt          # Amass results
├── github.txt         # GitHub API results
├── resolved.txt       # Live domains (httpx validated)
└── final.txt          # Merged & deduplicated results
```

---

## Example Run

```bash
$ ./subfinder.sh tesla.com
[*] Enumerating subdomains for: tesla.com
[*] All results will be stored in: tesla.com_enum_2025-08-20_15-22-10/

[+] Loaded 3 GitHub tokens from TOKENSFILE
[+] Using token #2 for this session

[+] Running subfinder...
[+] Running assetfinder...
[+] Running amass...
[+] Querying GitHub API...
[+] Validating domains with httpx...

[✔] Results saved in tesla.com_enum_2025-08-20_15-22-10/
```

---

## Tool Details

| Tool | Purpose | Output File |
|------|---------|-------------|
| **subfinder** | Fast subdomain discovery using passive sources | `subfinder.txt` |
| **assetfinder** | Asset and subdomain enumeration | `assetfinder.txt` |
| **amass** | Advanced OSINT-based subdomain enumeration | `amass.txt` |
| **github-subdomains** | Subdomain discovery from GitHub repositories | `github.txt` |
| **httpx** | HTTP probe to validate live domains | `resolved.txt` |
| **curl** | Fetch GitHub API results | (integrated) |
| **grep/sort/uniq** | Filter and deduplicate results | `final.txt` |

---

## Requirements

- **Bash** shell environment
- **Go** 1.19+ for tool installation
- **Internet connection** for API queries and tool execution
- **GitHub Personal Access Tokens** (recommended for best results)

---

## Disclaimer

This tool is intended for **educational purposes** and **authorized security testing only**.  
**Do not use on targets without explicit permission.**

---

## License

This project is licensed under the MIT License. See LICENSE file for details.

---

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for improvements and bug fixes.

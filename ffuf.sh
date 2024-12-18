#!/bin/bash

# Function to handle errors
handle_error() {
    echo "Error: $1"
    exit 1
}

# Check if domain is provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <domain> <wordlist>"
    exit 1
fi

domain=$1
wordlist=$2

# Validate inputs
[ -z "$domain" ] && handle_error "Domain cannot be empty"
[ ! -f "$wordlist" ] && handle_error "Wordlist file not found: $wordlist"

# Create directory for the domain (first step)
domain_folder=$(echo "$domain" | tr '.' '_')
mkdir -p "$domain_folder" || handle_error "Could not create directory for $domain"

log() {
    echo "[*] $1"
}

# Subdomain enumeration
log "Running Subfinder..."
subfinder -d "$domain" -silent > "$domain_folder/subfinder.txt" || handle_error "Subfinder failed"

log "Fetching results from crt.sh..."
curl -s -m 10 "https://crt.sh/?q=%25.$domain&output=json" | \
    jq -r '.[].name_value' | sed 's/\*\.//g' > "$domain_folder/crtsh.txt" || \
    handle_error "crt.sh retrieval failed"

log "Fetching subdomains from RapidDNS..."
output_file="$domain_folder/rapid.txt"
> "$output_file"

# Improved RapidDNS scraping
max_pages=10
for ((page=1; page<=max_pages; page++)); do
    log "Fetching page $page of RapidDNS..."
    curl -s -m 5 "https://rapiddns.io/subdomain/$domain?page=$page" | \
    grep -oP '(?<=<td>)[^<]+(?=</td>)' | \
    grep -E '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' >> "$output_file"
    sleep 1
done

# Combine and deduplicate subdomains
log "Consolidating subdomains..."
cat "$domain_folder"/*.txt | sort -u > "$domain_folder/all_subdomains.txt"

# Verify if subdomains were found
if [ ! -s "$domain_folder/all_subdomains.txt" ]; then
    log "No subdomains found for $domain"
    exit 1
fi

# Logging number of discovered subdomains
subdomain_count=$(wc -l < "$domain_folder/all_subdomains.txt")
log "Discovered $subdomain_count unique subdomains"


# Consolidated FFUF results
consolidated_ffuf="$domain_folder/all_ffuf_results.json"
> "$consolidated_ffuf"

# Run FFUF on discovered subdomains
log "Running FFUF on discovered subdomains..."
while IFS= read -r subdomain; do
    log "Scanning $subdomain..."
    ffuf -u "https://$subdomain/FUZZ" \
         -w "$wordlist" \
         -o "$domain_folder/ffuf_results_$subdomain.json" \
         -json \
         -timeout 3 \
         -rate 50 \
         -recursion \
         -recursion-depth 2

    # Append to consolidated results
    cat "$domain_folder/ffuf_results_$subdomain.json" >> "$consolidated_ffuf"
done < "$domain_folder/all_subdomains.txt"

log "FFUF scan completed. Consolidated results in $consolidated_ffuf"

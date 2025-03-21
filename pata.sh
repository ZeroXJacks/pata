#!/bin/bash
echo -e "\033[1;35m" 
echo "    ██████╗   █████╗ ████████╗ █████╗   "
echo -e "  \033[1;36m  ██╔══██╗ ██╔══██╗╚══██╔══╝██╔══██╗  "
echo "    ██████╔╝ ███████║   ██║   ███████║  "
echo -e "  \033[1;32m  ██╔═══╝  ██╔══██║   ██║   ██╔══██║  "
echo "    ██║      ██║  ██║   ██║   ██║  ██║  "
echo -e "  \033[1;32m  ╚═╝      ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝  "
echo "   Data Extractor v1.2 by @ZeroXJacks "
echo -e "\033[0m"

echo -e "\033[1;34mEnter the target URL:\033[0m" 
read -p "→ " URL
OUTPUT_FILE="extracted_data.txt"

if [ -z "$URL" ]; then
    echo -e "\033[1;31mError: URL cannot be empty. Please enter a valid URL.\033[0m"
    exit 1
fi

echo "[DEBUG] Target URL set to: $URL"

extract_data() {
    echo -e "\033[1;33mExtracting API endpoints, emails, and sensitive data...\033[0m"
    curl --retry 2 --connect-timeout 8 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" -s "$URL" |
    grep -E -o '((?<=/)[a-zA-Z0-9\-_\/.:]+(?=/)|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|(passw(or)?d|key|secret|token|api[_-]?key|access[_-]?token)\s*[:=]\s*["'\''][^"'\'']+["'\''])' |
    sort -u
    echo "[DEBUG] Data extraction complete."
}
extract_js_links() {
    echo -e "\033[1;34mExtracting JavaScript files...\033[0m"
    curl -s --max-time 8 "$URL" | grep -oE 'src=["'\''](.*?\.js)["'\'']' | cut -d'"' -f2 | sort -u | while read -r js_file; do
        [[ $js_file != http* ]] && js_file="$URL$js_file"
        echo "Checking: $js_file"
        curl -s --max-time 8 "$js_file" | grep -E -o '(api|token|key|json\.txt)' && echo "[!] Possible API key in: $js_file"
    done
    echo "[DEBUG] JavaScript file extraction complete."
}

search_archive_org() {
    echo -e "\033[1;36mSearching archive.org for old API endpoints...\033[0m"
    archive_url="https://web.archive.org/cdx/search/cdx?url=$URL/*&output=text&fl=original"
    echo "[DEBUG] Archive.org search URL: $archive_url"
    curl -s --max-time 8 "$archive_url" | grep -E '(api|token|json\.txt)' | sort -u
    echo "[DEBUG] Archive.org search complete."
}
echo -e "\033[1;34mProcessing data...\033[0m"
extract_data > "$OUTPUT_FILE" &
extract_js_links >> "$OUTPUT_FILE" &
search_archive_org >> "$OUTPUT_FILE" &
wait
echo -e "\033[1;32mResults saved to: $OUTPUT_FILE\033[0m"
echo -e "\033[1;36mNumber of items extracted: $(wc -l < "$OUTPUT_FILE")\033[0m"
echo "[DEBUG] Script execution completed successfully."

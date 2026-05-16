# tools
General purpose tools for day-to-day usage

# pdf-tools
python merge_pdfs.py <output-file-name> <input-files>
Example:  python pdfmerger.py merged.pdf $(ls *.pdf | xargs)

# sync-tools - identify file duplication
./rsync-diff.sh <path>
Example: ./rsync-diff.sh root/Files/

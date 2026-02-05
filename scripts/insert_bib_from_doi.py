#!/usr/bin/env python3
import requests
import bibtexparser
from bibtexparser.bwriter import BibTexWriter
from urllib.parse import urlparse

def insert_bibtex_from_doi():
    # Get DOI from clipboard (requires pyperclip)
    import pyperclip
    doi = pyperclip.paste().strip().rstrip(',')

    # Clean DOI
    if not doi.startswith('https://doi.org/'):
        doi = f'https://doi.org/{doi}'

    # Fetch BibTeX
    headers = {'Accept': 'application/x-bibtex'}
    response = requests.get(doi, headers=headers)
    bibtex = response.text

    # Parse and clean
    bib_database = bibtexparser.loads(bibtex)
    if not bib_database.entries:
        print("No entries found")
        return

    entry = bib_database.entries[0]

    # Write to your .bib file (modify path)
    with open('~/path/to/your/library.bib', 'a') as bibfile:
        writer = BibTexWriter()
        bibfile.write(bibtexparser.dumps(bib_database))

    print(f"Added entry: {entry.get('ID', 'unknown key')}")

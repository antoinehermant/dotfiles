#!/home/anthe/software/miniconda3/envs/generic/bin/python3
import sys
import os

def search_doi_in_bib(doi: str, bib: str = '/home/anthe/phd/bib/phd.bib'):
    """
    Search for a DOI in the specified BibTeX file.

    :param doi: The DOI to search for.
    :param bib: Path to the BibTeX file.
    :return: True if the DOI exists in the BibTeX file, False otherwise.
    """
    doi = doi.split("https://doi.org/")[-1].strip()

    if not os.path.exists(bib):
         print("False")
         return

    with open(bib, 'r') as file:
        bib_content = file.read()

    # Search for the DOI
    for line in bib_content.splitlines():
        if doi in line:
            print("True")
            return

    print("False")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python doiexistsinbib.py <doi> </path/to/bib.bib>")
        sys.exit(1)

    doi = sys.argv[1]
    bib = sys.argv[2]
    search_doi_in_bib(doi, bib)

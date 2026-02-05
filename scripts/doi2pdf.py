#!/home/anthe/software/miniconda3/envs/generic/bin/python3
import os
import sys
import requests
from urllib.parse import urlparse
import requests
from bs4 import BeautifulSoup

def doi_to_pdf_url(doi):
    """
    Convert a DOI to a PDF URL based on journal-specific patterns.
    """
    # Isolate the DOI identifier (e.g., "10.5194/tc-13-2023-2019")

    doi = doi.rstrip(",")

    if "10.5194" in doi:  # Copernicus pattern
        doi = doi.split("10.5194")[-1]
        doi = "10.5194" + doi
        doi_identifier = doi.split("/")[-1]
        # Example: 10.5194/tc-13-2023-2019
        parts = doi_identifier.split("-")
        journal = parts[0]
        volume = parts[1]   # e.g., '13'
        page = parts[2]     # e.g., '2023'
        year = parts[3]      # e.g., '2019'
        pdf_url = f"https://{journal}.copernicus.org/articles/{volume}/{page}/{year}/{journal}-{volume}-{page}-{year}.pdf"
        return pdf_url

    for prefix in ["10.3189", "10.1017"]:
        if prefix in doi:
            doi = doi.split(f"{prefix}")[-1]
            doi = prefix + doi
            return get_cambridge_pdf_url(doi)

    try:
        doi_parts = doi.split('/')[-2:]
        doi = '/'.join(doi_parts)
        pdf_url = get_scihub_pdf_url(doi)
        if pdf_url:  # Check if Sci-Hub returned a valid URL
            return pdf_url
        else:
            print(f"DOI {doi} not found on Sci-Hub.")
            return None
    except Exception as e:
        print(f"Error fetching from Sci-Hub: {e}")
        return None

def get_cambridge_pdf_url(doi):
    # Resolve DOI to get final URL path
    response = requests.get(
        f"https://doi.org/{doi}",
        allow_redirects=True,
        headers={"Accept": "text/html"},
        stream=True
    )

    hash_id = response.url.split("/")[-1]

    response = requests.get(f"https://doi.org/{doi}", allow_redirects=False, headers={"Accept": "text/html"})
    doi_suffix = response.headers.get("Location").split("/")[-3]

    return f"https://www.cambridge.org/core/services/aop-cambridge-core/content/view/{hash_id}/{doi_suffix}a.pdf"

def get_scihub_pdf_url(doi, scihub_mirror='https://sci-hub.fr/'):
    # Fetch the Sci-Hub page
    scihub_url = scihub_mirror + doi
    response = requests.get(scihub_url)
    if response.status_code != 200:
        print(f"Failed to fetch the page. Status code: {response.status_code}")
        return

    # Parse the HTML
    soup = BeautifulSoup(response.text, "html.parser")

    # Find the download div
    download_div = soup.find("div", {"class": "download"})
    if not download_div:
        print("Could not find the download div.")
        return None

    # Find the <a> tag inside the download div
    download_link = download_div.find("a", href=True)
    if not download_link:
        print("Could not find the download link.")
        return None

    # Extract the href attribute
    pdf_dir = download_link["href"]
    pdf_url = f"https://sci-hub.fr/download/2024/{'/'.join(pdf_dir.split('/')[-3:])}"

    return pdf_url

def download_pdf(pdf_url, output_dir="/home/anthe/phd/bib/papers/", filename=None):
    """
    Download a PDF from a URL and save it to a directory.
    """
    # if not os.path.exists(output_dir):
    #     os.makedirs(output_dir)

    if filename is None:
        filename = os.path.basename(urlparse(pdf_url).path)

    output_path = os.path.join(output_dir, filename)
    response = requests.get(pdf_url)

    if response.status_code == 200:
        with open(output_path, "wb") as f:
            f.write(response.content)
        print(f"PDF saved to {output_path}")
        return output_path
    else:
        print(f"Failed to download PDF: {response.status_code}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python download_pdf.py <doi> <bibtex_key>")
        sys.exit(1)

    doi = sys.argv[1]
    bibtex_key = sys.argv[2]
    pdf_url = doi_to_pdf_url(doi)

    if pdf_url:
        output_path = download_pdf(pdf_url, filename=f"{bibtex_key}.pdf")
        if output_path:
            print(f"Success: PDF saved as {bibtex_key}.pdf")
        else:
            print("Failed to download PDF.")
    else:
        print("No pattern found for this DOI.")

    # elif "10.1029" in doi:  # Wiley pattern #NOT WORKING because of authentification
    #     doi = doi.split("10.1029")[-1]
    #     doi = "10.1029" + doi
    #     doi_identifier = doi.split("/")[-1]
    #     # Example: 10.5194/tc-13-2023-2019
    #     pdf_url = f"https://agupubs.onlinelibrary.wiley.com/doi/pdf/{doi}"
    #     return pdf_url

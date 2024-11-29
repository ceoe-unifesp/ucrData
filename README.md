
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ucrData

<!-- badges: start -->
<!-- badges: end -->

# `ucrData` R Package

## Overview

The `ucrData` package is designed to facilitate the download,
extraction, and parsing of Supplementary Homicide Reports (SHR) data
from the FBI’s Uniform Crime Reporting (UCR) program. This package
streamlines the process of working with SHR datasets, offering functions
to retrieve specific years of data, manage file downloads, and load
fixed-width files into a tidy data format.

## Installation

To install the `ucrData` package, use the following command:

``` r
pak::pak("ceoe-unifesp/ucrData")
```

## Usage

### Main Functions

#### 1. Retrieve Available Years

The `shr_years()` function fetches the range of years for which SHR data
is available.

``` r
available_years <- shr_years()
print(available_years)
```

#### 2. Fetch Links to SHR Data

Use `shr_links()` to retrieve download links for the desired years.

``` r
links <- shr_links(years = 2010:2020)
print(links)
```

#### 3. Download and Extract SHR Data

The `read_shr_online()` function automates the process of downloading,
extracting, and reading SHR data for the specified years.

``` r
shr_data <- read_shr_online(years = 2010:2020, verbose = TRUE)
head(shr_data)
```

### Custom Steps

For more control, the following lower-level functions can be used:

- **Download Files:** `shr_download(link_data, path)`  
  Downloads SHR files from a given list of links.

- **Unzip Files:** `shr_unzip(zip_file, path)`  
  Extracts and renames files within ZIP archives.

- **Read SHR Data:** `shr_read(file)`  
  Reads and parses a single SHR file into a tidy data frame.

### Specifications and Structure

The package includes predefined fixed-width format specifications
(`shr_fwf_specs()`) and column types (`shr_col_types()`), ensuring
consistent parsing of SHR data. These helpers are invoked internally by
`shr_read()`.

### Example Workflow

``` r
library(ucrData)

# Step 1: Get available years
years <- shr_years()

# Step 2: Download and parse data
shr_data <- read_shr_online(years = years[1:5], verbose = TRUE)

# Step 3: Inspect the data
print(head(shr_data))
```

## Notes

- The data is downloaded from the UCR website and may require internet
  access during the process.
- Temporary files are cleaned up after data processing, unless specified
  otherwise.

## Contributions

Contributions are welcome! Feel free to submit issues or pull requests
for enhancements or bug fixes.

## License

This package is open-source and distributed under the MIT License.

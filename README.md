
# RSorcery

<!-- badges: start -->
<!-- badges: end -->

The goal of RSorcery is to help lazy R programmers who don't want to write
functions just define them and magically generate the code.

## Installation

You can install the development version of RSorcery like so:

``` r
require(devtools)
install_git("kriskumar/RSorcerey")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r

library(RSorcery)
## basic example code
require(openai)
#let us set the openai_key just in case.
#Sys.setenv("OPENAI_API_KEY"="sk-")

source("utils.r")
# Example usage
file_path <- "defined_function.r"
dosorcery(file_path)
```


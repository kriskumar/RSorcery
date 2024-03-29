
# RSorcery

<!-- badges: start -->
[![R-CMD-check](https://github.com/kriskumar/RSorcery/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/kriskumar/RSorcery/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

RSorcery is for lazy R programmers that want to use LLMs to write
their code. Just define the function add a comment of what it does
and magically generate the code.

## Installation

You can install the development version of RSorcery with devtools:

``` r
require(devtools)
install_git("kriskumar/RSorcerey")
```

## Example Usage

This is a basic example which shows you how to use this.
Let us say we want to write a function to generate fibonacci sequences
and say the next prime number given a prime number.
We create a file with function definitions and comments.

@@include[defined_function.r](inst/ext-data/defined_function.r)


``` r

#calculate fibonacci numbers up to n 
fibonacci<-function(n=10)
{ 
  }

#calculate next prime given a prime
primenext<-function(m=11)
{ 
}

```

## Sorcery Magic!

Now for us to generate the actual function code we will
runsorcery on it!

``` r

library(RSorcery)
## basic example code
require(openai)
#set the openai_key if it is not in your environment
#Sys.setenv("OPENAI_API_KEY"="sk-")

```

Specify where your file is located. By default if an ouput file
is not specified it creates one in the same folder with 
'_extracted.r' appended to the name which now contains
the implemented function.

``` r

file_path <- "defined_function.r"
dosorcery(file_path)

```


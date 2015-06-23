# bulast - A simpler R package to access the Bureau of Labor Statistics (BLS) API

This package provides access to the Bureau of Labor Statistics API in an (arguably) friendlier interface than the blsAPI package, by hiding the JSON code under the hood. 

It relies on `httr` and returns the results as a data.table with a Date field set at the last day of the period.

# Installation

For now it is not on CRAN since it is likely to evolve. You will have to use the `devtools` package to install directly from Github:

```{r}
devtools::install_github("fcocquemas/bulast")
```

# Examples

A simple example with the V1 API:

```{r}
library(bulast)
r <- bulast(c('LAUCN040010000000005', 'LAUCN040010000000006'), 
            startyear = 2010, endyear = 2012)
r
```

This returns:

```
$status
[1] "REQUEST_SUCCEEDED"

$responseTime
[1] 629

$message
list()

$Results
    year period periodName value footnotes             seriesID
 1: 2012    M12   December 18281           LAUCN040010000000005
 2: 2012    M11   November 18242           LAUCN040010000000005
 3: 2012    M10    October 18619           LAUCN040010000000005
 4: 2012    M09  September 19008           LAUCN040010000000005

...

69: 2010    M04      April 23569           LAUCN040010000000006
70: 2010    M03      March 23209           LAUCN040010000000006
71: 2010    M02   February 23156           LAUCN040010000000006
72: 2010    M01    January 23374           LAUCN040010000000006
    year period periodName value footnotes             seriesID
```


A more complex example with the V2 API (requires a valid [registration key from the BLS](http://data.bls.gov/registrationEngine/)):

```{r}
r <- bulast(c('LAUCN040010000000005', 'LAUCN040010000000006'),
            startyear = 2010, endyear = 2012,
            registrationKey = "995f4e779f204473aa565256e8afe73e", calculations = TRUE)
r$Results
```

This returns:
```
    year period periodName value footnotes pct_ch_1 pct_ch_3 pct_ch_6 pct_ch_12             seriesID
 1: 2012    M12   December 18281                0.2     -3.8     -2.0      -2.3 LAUCN040010000000005
 2: 2012    M11   November 18242               -2.0     -3.9     -1.1      -2.2 LAUCN040010000000005
 3: 2012    M10    October 18619               -2.0     -1.5      2.1      -0.7 LAUCN040010000000005
 4: 2012    M09  September 19008                0.2      1.9      4.1       0.5 LAUCN040010000000005

...

69: 2010    M04      April 23569                1.6      0.8      1.9       5.5 LAUCN040010000000006
70: 2010    M03      March 23209                0.2      1.3     -1.1       5.9 LAUCN040010000000006
71: 2010    M02   February 23156               -0.9      1.1     -5.1       5.2 LAUCN040010000000006
72: 2010    M01    January 23374                2.0      1.0     -3.7       6.3 LAUCN040010000000006
    year period periodName value footnotes pct_ch_1 pct_ch_3 pct_ch_6 pct_ch_12             seriesID
```

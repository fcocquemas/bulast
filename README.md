# bulast - A simpler R package to access the Bureau of Labor Statistics (BLS) API

This package provides access to the Bureau of Labor Statistics API in an (arguably) friendlier interface than the [blsAPI package](http://www.github.com/mikeasilva/blsAPI), by hiding the JSON code under the hood and being a little more opinionated. It might not suit your use case, in which case you should definitely check out [blsAPI](http://www.github.com/mikeasilva/blsAPI).

It relies on `httr`, and returns the results as a data.table with a `date` field set at the last day of the period. That would be December 31 for both December and annual data, so a periodType field is set to either "Monthly" or "Annual".

Not yet tested with quarterly or semiannual data, and it will likely choke on them.

# Installation

For now, it has not been submitted to CRAN since it is likely to evolve. You will have to use the `devtools` package to install directly from Github:

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
[1] 89

$message
list()

$Results
                seriesID       date value periodType footnotes
 1: LAUCN040010000000005 2010-01-31 19164    Monthly          
 2: LAUCN040010000000005 2010-02-28 18996    Monthly          
 3: LAUCN040010000000005 2010-03-31 19252    Monthly          
 4: LAUCN040010000000005 2010-04-30 19834    Monthly          

...

69: LAUCN040010000000006 2012-09-30 23249    Monthly          
70: LAUCN040010000000006 2012-10-31 22888    Monthly          
71: LAUCN040010000000006 2012-11-30 22258    Monthly          
72: LAUCN040010000000006 2012-12-31 22415    Monthly          
                seriesID       date value periodType footnotes

```


A more complex example with the V2 API (requires a valid [registration key from the BLS](http://data.bls.gov/registrationEngine/)):

```{r}
r <- bulast(c('LAUCN040010000000005', 'LAUCN040010000000006'),
            startyear = 2010, endyear = 2012,
            registrationKey = "cfbcf439326c4a2faa70451d74013819", 
            calculations = TRUE, annualaverage = TRUE)
r$Results[periodType=="Annual"]
```

This returns:
```
               seriesID       date value periodType footnotes pct_ch_1 pct_ch_3 pct_ch_6 pct_ch_12
1: LAUCN040010000000005 2010-12-31 19589     Annual                2.2      0.7     -1.5       1.4
2: LAUCN040010000000005 2011-12-31 18794     Annual                0.4      0.3        0      -4.1
3: LAUCN040010000000005 2012-12-31 18499     Annual                1.2     -0.6     -2.1      -1.6
4: LAUCN040010000000006 2010-12-31 23438     Annual                3.3      1.8     -2.6       2.2
5: LAUCN040010000000006 2011-12-31 23065     Annual                0.3     -0.3     -2.6      -1.6
6: LAUCN040010000000006 2012-12-31 22878     Annual                2.1        0     -4.5      -0.8
```

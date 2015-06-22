# bulast - A simpler R package to access the Bureau of Labor Statistics (BLS) API

This package provides access to the Bureau of Labor Statistics API in an (arguably) friendlier interface than the blsAPI package, by hiding the JSON code under the hood. 

It relies on `httr` and returns the results as a data.frame, or better yet a data.table if the `data.table` package is present.

A simple example with the V1 API:

```{r}
r <- bulast(c('LAUCN040010000000005', 'LAUCN040010000000006'), startyear = 2010, endyear = 2012)
r$Results
```

A more complex example with the V2 API (require [registration key from the BLS](http://data.bls.gov/registrationEngine/)):

```{r}
r <- bulast(c('LAUCN040010000000005', 'LAUCN040010000000006'), startyear = 2010, endyear = 2012, 
            registrationKey = "995f4e779f204473aa565256e8afe73e", calculations = TRUE)
r$Results
```

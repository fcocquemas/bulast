# bulast - A simpler R package to access the Bureau of Labor Statistics (BLS) API

This package provides access to the Bureau of Labor Statistics API in an (arguably) friendlier interface than the blsAPI package, by hiding the JSON code under the hood. It relies on `httr` and returns the results as a data.frame, or better yet a data.table if the `data.table` package is present. A `date` field marking the end of the period is added if the `lubridate` package is present.

```{r}

```
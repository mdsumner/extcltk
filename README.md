# extcltk
an old tcltk app in R

# To run it

This loads the code in 'sMat.R', reads a csv, and an old MCMC binned array thing, an provides a tcltk interative app. Try playing with **Start position**. 


```R
source("extent.r")
```

This an old binned estimate of a seal location (from geolocation-light tag) compared to a satellite track. It's very old, but the performance of tcltk for an interactive "space time" image is pretty good, because we could clear the current plot and simply add the time-range for the current UI setting. 


![](Untitled.png)

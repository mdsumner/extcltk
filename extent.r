

library(MASS)
source("sMat.r")
#mat <- increMat(sMat(),c(-50,100))
d <- read.csv("track.csv")
lons <- d[,2]
lats <- d[,1]
load("Chain.Rdata")
npars <- 3
npts <- dim(ps)[2]/npars



## plotting functions

## replot - when the options change
##        - contour / image
##        - overlay points/lines/none

## regen  - when the data to display change
##        [- grid size (resolution)  - choices based on range of data]
##        - (temporal) window position - slider
##        [- (temporal) window length   - entry]
##        [- smoothing parameter        - slider ]
##        [- subsampling (for larger sets of points)]

## .maybe  - replot when slider values change?
#demo <- function() {
require(tcltk) || stop("tcltk support is absent")
require(MASS)  || stop("MASS supoort is absent")
# nn <- 100
#ix <- seq(min(lons),max(lons),length=nn)
#iy <- seq(min(lats),max(lats),length=nn)


#i <- 1
#hscl <- 2

## no buffer
bscl <- 1
bufX <- range(lons) #+ c(-diff(range(lons))/bscl,diff(range(lons))/bscl)
bufY <- range(lats) #+ c(-diff(range(lats))/bscl,diff(range(lats))/bscl)

iters <- dim(ps)[1]

overlay <- tclVar("points")
pos <- tclVar(1)
disp <- tclVar("image")
hscl <- tclVar(1.5)
nn <- tclVar(100)
rN <- tclVar(1)
chain <- tclVar("n")
palette <- tclVar("heat")
midLat <- (max(lats) - min(lats))/2
aspect <- tclVar(abs(cos(min(lats) + midLat)))
replot <- function(...) {
  dev.hold()
  plot(lons,lats,type="n",xlim=bufX,ylim=bufY,asp=as.numeric(tclObj(aspect)))
  usr <- par("usr")
  pal <- as.character(tclObj(palette))
  if (pal == "heat") {
    cols=c("red",heat.colors(12)[2:12])
    bg = "red"
  } else if (pal == "etopo") {
    cols = ETcol
    bg = ETcol[1]
  }  else if (pal == "pathfinder") {
    cols = PFcol[3:length(PFcol)]
    bg = PFcol[2]
  }  else if (pal == "seawifs") {
    cols = SWcol[-length(SWcol)]
    bg = SWcol[1]
  }
  rect(usr[1], usr[3], usr[2], usr[4], col = bg,border = "black")
  display <- as.character(tclObj(disp))
  if (display == "image") {
    #image(kde,add=T,col=c("red",heat.colors(12)[2:12]))
    image(kde,add=T,col=cols)
  } else if (display == "contour") {
    contour(kde,add=T,col="white")
  } else {
    # do nothing
  }
  ov <- as.character(tclObj(overlay))
    if (ov == "points") {
      points(lons,lats)
    } else if (ov == "lines") {
      lines(lons,lats)
    } else {
      #no overlay
    }
  ch <- as.character(tclObj(chain))
  if (ch != "n") {
    points(xx,yy,pch="x",col="blue",cex=.3)
  }
  dev.flush()
}

regen <- function(...) {
  i <- as.numeric(tclObj(pos))
  xx <<- yy <<- NULL;
  nTWI <- (min( as.numeric(tclObj(rN)),npts-i+1))
  for (n in 1:nTWI) {
  yy <<- c(yy,ps[,(i+n-2)*npars+1][seq(1,iters,length=iters/nTWI)])
  xx <<- c(xx,ps[,(i+n-2)*npars+2][seq(1,iters,length=iters/nTWI)])
}
  ## lons/lats set the overal range of plotting
  ix <- seq(min(lons),max(lons),length=as.numeric(tclObj(nn)))
  iy <- seq(min(lats),max(lats),length=as.numeric(tclObj(nn)))
  
  xlim <- range(xx)
  ylim <- range(yy)
  dimX <- length(ix[ix > min(xlim) & ix < max(xlim)])
  dimY <- length(iy[iy > min(ylim) & iy < max(ylim)])
  hx <- bandwidth.nrd(xx)/as.numeric(tclObj(hscl))
  hy <- bandwidth.nrd(yy)/as.numeric(tclObj(hscl))
  temp <- kde2d(xx,yy,h=c(hx,hy),n=min(dimX,dimY))
  temp$z[temp$z < quantile(temp$z[temp$z > 0], 0.85)] <- 0
  kde <<- temp
  
  
  replot()
}

output <- function(){
  tmp <- kde
  tmp$z <- tmp$z
  #xmlBin(tmp,binFile=paste("MCMC",format(Sys.time(), "%d%b%H%M"),".bin",sep=""))
  xmlBin(tmp)
  rm(tmp)
}


base <- tktoplevel()
tkwm.title(base, "mcmc plot")
spec.frm <- tkframe(base,borderwidth=2)
left.frm <- tkframe(spec.frm)
right.frm <- tkframe(spec.frm)

##  - set the window position (which twilight are we centred on)
frame1 <-tkframe(right.frm, relief="groove", borderwidth=2)
tkpack(tklabel (frame1, text="Start position"))
tkpack(tkscale(frame1,command=regen, from=1, to=npts,
                   showvalue=T, variable=pos,
                   resolution=1, orient="horiz"))


##  - set the display "image" or "contour"
frame2 <-tkframe(left.frm, relief="groove", borderwidth=2)
tkpack(tklabel(frame2, text="Type of Display"))
tkpack(tkradiobutton(frame2, command=replot, text="Image",
               value="image", variable=disp), anchor="w")
tkpack(tkradiobutton(frame2, command=replot, text="Contour",
                         value="contour", variable=disp), anchor="w")
tkpack(tkradiobutton(frame2, command=replot, text="None",
                         value="n", variable=disp), anchor="w")


##  - set the bandwidth scale factor
frame3 <-tkframe(right.frm, relief="groove", borderwidth=2)
tkpack(tklabel (frame3, text="Bandwidth scale factor"))
tkpack(tkscale(frame3,command=regen, from=.1, to=8,
                   showvalue=T, variable=hscl,
                   resolution=.1, orient="horiz"))


##  - set the overall grid size
frame4 <-tkframe(right.frm, relief="groove", borderwidth=2)
tkpack(tklabel (frame4, text="Grid size"))
tkpack(tkscale(frame4,command=regen, from=10, to=1000,
                   showvalue=T, variable=nn,
                   resolution=10, orient="horiz"))



## - set the overlays
frame5 <-tkframe(left.frm, relief="groove", borderwidth=2)
tkpack(tklabel(frame5, text="Overlay Track"))
tkpack(tkradiobutton(frame5, command=replot, text="Track lines",
                         value="lines", variable=overlay), anchor="w")
tkpack(tkradiobutton(frame5, command=replot, text="Track points",
                         value="points", variable=overlay), anchor="w")
tkpack(tkradiobutton(frame5, command=replot, text="Off",
                         value="n", variable=overlay), anchor="w")


##  - set the number of twilights to smooth over
frame6 <-tkframe(right.frm, relief="groove", borderwidth=2)
tkpack(tklabel (frame6, text="Max Number of twilights\n - start is \"Window\""))
tkpack(tkscale(frame6,command=regen, from=1, to=npts,
                   showvalue=T, variable=rN,
                   resolution=1, orient="horiz"))

frame7 <-tkframe(left.frm, relief="groove", borderwidth=2)
tkpack(tklabel(frame7, text="Overlay MCMC"))
tkpack(tkradiobutton(frame7, command=regen, text="MCMC points",
                         value="mcmc", variable=chain), anchor="w")
tkpack(tkradiobutton(frame7, command=regen, text="MCMC off",
                         value="n", variable=chain), anchor="w")

frame8 <- tkframe(left.frm,relief="groove",borderwidth=2)
tkpack(tklabel(frame8,text="Output KDE for GIS"))
tkpack(tkbutton(frame8,text="xmlBin",command=output))

frame9 <- tkframe(right.frm,relief="groove",borderwidth=2)
tkpack(tklabel(frame9,text="Palette"))
tkpack(tkradiobutton(frame9,command=replot,text="Heat colours",
                     value="heat",variable=palette),anchor="w")
tkpack(tkradiobutton(frame9,command=replot,text="Etopo colours",
                     value="etopo",variable=palette),anchor="w")
tkpack(tkradiobutton(frame9,command=replot,text="Pathfinder colours",
                     value="pathfinder",variable=palette),anchor="w")
tkpack(tkradiobutton(frame9,command=replot,text="SeaWiFS colours",
                     value="seawifs",variable=palette),anchor="w")



##  - set the aspect ratio
frame10 <-tkframe(left.frm, relief="groove", borderwidth=2)
tkpack(tklabel (frame10, text="Aspect ratio"))
tkpack(tkscale(frame10,command=replot, from=.1, to=5,
                   showvalue=T, variable=aspect,
                   resolution=.1, orient="horiz"))


  
tkpack(frame2,frame5,frame7,frame8,fill="x")
tkpack(frame1,frame3,frame4,frame6,frame9,frame10,fill="x")
#tkpack(frame1,frame2,frame3,frame4,frame5,frame6)

tkpack(left.frm, right.frm,side="left", anchor="n")
## `Bottom frame' (on base):
q.but <- tkbutton(base,text="Quit",
                      command=function(){tkdestroy(base);dev.off()})
tkpack(spec.frm, q.but)





### this stuff was my initial concept design


#plot(lons,lats,type="n")

#i <- 1
#for(i in 1:npts) {
#  yy <- ps[,(i-1)*npars+1]
#  xx <- ps[,(i-1)*npars+2]	

#nn <- 100
#da <- kde2d(lons,lats,n=nn)
#image(da$x,da$y,matrix(0,nrow=nn,ncol=nn),col="red")
#ix <- seq(min(lons),max(lons),length=nn)
#iy <- seq(min(lats),max(lats),length=nn)
#opar <- par(bg="red")

#xlim <- range(xx)
#ylim <- range(yy)
#dimX <- length(ix[ix > min(xlim) & ix < max(xlim)])
#dimY <- length(iy[iy > min(ylim) & iy < max(ylim)])
#plot(lons,lats,type="n")

#  usr <- par("usr")

# rect(usr[1], usr[3], usr[2], usr[4], col = "red", 
#    border = "black")

  
#dam <- kde2d(xx,yy,n=min(dimX,dimY))
#image(dam,add=T,h=c(1,1)/19,col=c("red",heat.colors(12)[2:12]))
#points(lons,lats)
#}
#par(opar)

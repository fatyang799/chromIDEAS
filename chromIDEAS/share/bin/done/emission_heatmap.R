# load the environment
if (T) {
  rm(list = ls())
  options(stringAsFactors = F)
}

# get arguments
if (T) {
  args <-commandArgs(trailingOnly=TRUE)
  parafile <- args[1]
  pout <- args[2]
  fout <- args[3]
}

# test data
if (F) {
  parafile <- "ENCODE_core.para"
  pout <- "ENCODE_core.pdf"
  fout <- "ENCODE_core.tab"
}

# read para
if (T) {
  x=read.table(parafile, comment="!", header=T)
}

# format the matrix
if (T) {
  k=ncol(x)
  l=nrow(x)
  
  # num of mk
  p=(sqrt(9+8*(k-1))-3)/2
  
  # colnames
  m=as.matrix(x[,1+c(1:p)]/x[,1])
  colnames(m) = colnames(x)[1+c(1:p)]
  m = m[,order(colnames(m))]
  marks=colnames(m)
  
  # rownames
  rownames(m)=paste0(c(1:l)-1," (",round(x[,1]/sum(x[,1])*10000)/100,"%)")
}

# order row by ward.D2
if(T) {
  o <- hclust(dist(m),method="ward.D2")$order
  m <- m[o,]
}

# color setting
if (T) {
  cols=c("white", "dark blue")
  my_palette <- colorRampPalette(cols)(n=100)
  defpalette=palette(my_palette)
}

# plot heatmap
if (T) {
  pdf(pout)
  par(mar=c(4.2,0.5,0.5,6))
  
  # plot board
  plot(NA, NA, xlim=c(0,p), ylim=c(0,l), xaxt="n", yaxt="n", xlab=NA, ylab=NA, frame.plot=F)
  
  # plot x lab
  axis(1, at=1:p-0.5, labels=colnames(m), las=2, tick = F, pos = 0.1)
  
  # plot y lab
  axis(4, at=1:l-0.5, labels=rownames(m), las=2)

  # plot heatmap
  rect(rep(1:p-1,l),
       rep(1:l-1,each=p),
       rep(1:p,l),
       rep(1:l,each=p),
       col=round((t(m)-min(m))/(max(m)-min(m))*100))
  
  dev.off()
}

# output matix
if (T) {
  mat <- as.data.frame(m)
  mat$State <- paste0("S", o-1)
  mat$Percentage <- (x[,1]/sum(x[,1])*10000/100)[o]
  mat <- mat[, c(ncol(mat)-1, ncol(mat), 1:p)]
  
  write.table(mat, file = fout, quote = F, sep = "\t", col.names = T, row.names = F)
}


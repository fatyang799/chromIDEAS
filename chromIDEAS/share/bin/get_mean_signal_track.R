# load the environment
if (T) {
  rm(list = ls())
  options(stringAsFactors = F)
  args = commandArgs(trailingOnly=TRUE)
}

# get the arguments
if (T) {
  input = args[1]
  output = args[2]
}

# read the data
if (T) {
  dat <- data.table::fread(input, header=F, sep='\t', data.table=F)

  bed <- dat[, 1:3]
  ncol <- ncol(dat)

  dat <- dat[, seq(4, ncol, 4)]
  dat <- sapply(dat, as.numeric)
}

# get average signal
if (T) {
  if (ncol != 4) {
    signal <- apply(dat, 1, median)
  }
  if (ncol == 4) {
    signal <- dat
  }
}

# output
if (T) {
  bedgraph <- cbind(bed, signal)
  write.table(bedgraph, file = output, quote=F, col.names=F, row.names=F, sep='\t')
}


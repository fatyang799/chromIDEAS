# load the environment
if (T) {
  rm(list = ls())
  options(stringAsFactors = F)
  options(digits = 15)
  args = commandArgs(trailingOnly=TRUE)
}

# get the arguments
if (T) {
  input = args[1]
  output = args[2]
  
  average_method <- args[3]
  cor_method <- args[4]
  skipZeros <- args[5]
  cutoff_cor <- as.numeric(args[6])
  quiet <- args[7]
  labels <- args[8]
}

# read the data
if (T) {
  dat <- data.table::fread(input, header=F, sep='\t', data.table=F)
  
  bed <- dat[, 1:3]
  dat <- dat[, seq(4, ncol(dat), 4)]
  dat <- data.frame(sapply(dat, as.numeric))
}

# get average signal
if (T) {
  fun <- ifelse(average_method == "median", median, 
                ifelse(average_method == "mean", mean, stop))
  signal <- apply(dat, 1, fun)
}

# output
if (T) {
  bedgraph <- cbind(bed, signal)
  write.table(bedgraph, file = output, quote=F, col.names=F, row.names=F, sep='\t')
}

# quality control
if (T) {
  # format the lables
  labels <- strsplit(labels, "\\n")[[1]]
  labels <- basename(labels)
  
  if (skipZeros == "T") {
    dat <- dat[apply(dat, 1, sum)>0, ]
  }
  
  cor_mat <- data.frame(cor(dat, method = cor_method))
  colnames(cor_mat) <- labels
  cor_mat$Files <- labels
  
  write.table(cor_mat, file = paste0(output, ".cor.mat"), quote = F, sep = "\t", col.names = T, row.names = F)
  
  if (min(as.matrix(cor_mat[, -ncol(cor_mat)]))<cutoff_cor) {
    if (quiet == "F") {
      cat(paste0("WARNING: Some files failed quality control. Check ", output, ".cor.mat for detailed QC results."))
    }
  }
}
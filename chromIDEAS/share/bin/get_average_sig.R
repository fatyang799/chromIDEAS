# get mean value for a list file (exp sample, not CT)

# get arguments
if (T) {
  args = commandArgs(trailingOnly=TRUE)  
  
  file_list_file = args[1]
  output = args[2]
  set.seed(2020)
}

### read input
if (T) {
  file_list = read.table(file_list_file, header=F)  
  
  # if there are more than 50 datasets, random select 50 to do analysis
  if (nrow(file_list)>50){
    used_id_sample = sample(nrow(file_list), 50)
    file_list = file_list[used_id_sample,]
  }
}

# get average signal
if (T) {
  # get 1st file
  if (T) {
    d10 = data.table::fread(file_list[1,1], header=F, sep='\t', data.table=F)
    bed = d10[,1:3]
    sum_sig = d10[,4]
    non0mean = mean(sum_sig[sum_sig>0])
    
    if (non0mean<0.01){
      stop(paste0('1.', file_list[1,1], ': Is the data average counts data? script get_average.R'))
      sum_sig = sum_sig/non0mean
    }
  }
  
  # get other files
  if (T) {
    notused = c()
    if (nrow(file_list)>1){
      for (i in 2:nrow(file_list)){
        if (file.exists(file_list[i,1])){
          d10 = data.table::fread(file_list[i,1], header=F, sep='\t', data.table=F)[,4]
          
          if (is.na(mean(d10)) || (max(d10)==0)){
            warning(paste0(i, ".", file_list[i,1], ": !!!Something wrong with the normalization (s3/s3v2) step !!!. script get_average.R"))
            notused = c(notused, file_list[i,1])
            next
          }
          
          non0mean = mean(d10[d10>0])
          if (non0mean<0.01){
            stop(paste0(i, '.', file_list[i,1], ': Is the data average counts data? script get_average.R'))
            d10 = d10/non0mean
          }
          
          sum_sig = sum_sig + d10
        }
        if (! file.exists(file_list[i,1])){
          stop(paste0(i, ".", file_list[i,1], " not exist. script get_average.R"))
        }
      }
    }    
  }
}

# get average signal
if (T) {
  notused_n <- length(notused)
  average_sig = sum_sig / (nrow(file_list)-notused_n)
  bedgraph_dat = cbind(bed, average_sig)  
}

# output
if (T) {
  write.table(bedgraph_dat, output, col.names=F, row.names=F, quote=F, sep='\t')
  # question_files
  output <- paste0(output, ".notused.files.txt")
  write(notused, output)
}
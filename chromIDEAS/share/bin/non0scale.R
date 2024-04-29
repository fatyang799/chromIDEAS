# get arguments
if (T) {
  args = commandArgs(trailingOnly=TRUE)
  file_list_file = args[1]
  set.seed(2020)
}

# get all CT files
if (T) {
  file_list = read.table(file_list_file, header=F)[, 1]
}

# define the function for s3v2norm
if (T) {
  non0scale = function(sig, refmean, refsd){
    sig_non0 = sig[sig>0]
    sig_non0_mean = mean(sig_non0)
    sig_non0_sd = sd(sig_non0)
    
    B = refsd/sig_non0_sd
    A = refmean - sig_non0_mean/sig_non0_sd*refsd
    
    return(c(B, A))
  }
}

### get bed location
if (T) {
  d1 = data.table::fread(file_list[1], header=F, sep='\t', data.table = F)
  dbed = d1[,1:3]
}

# get random bins number
if (T) {
  bin_num = nrow(dbed)
  bin_num_used = 100000
  used_id = sample(bin_num, bin_num_used)
}

### get all CT value
if (T) {
  dat = lapply(file_list, function(x) {
    dat = data.table::fread(x, header=F, sep='\t', data.table = F)[, 4]
    if (is.na(mean(dat)) || (max(dat)==0)){
      stop('!!!Something wrong with normalize controls step!!!     non0scale.R script line45')
    }
    return(dat)
  })
  dat = do.call(cbind, dat)
  dat = as.data.frame(dat)
}

# get CT random bins value
if (T) {
  dmat_s = dat[used_id, ]
}

### get average non0 mean sd
if (T) {
  dmat_s_non0 = dmat_s[dmat_s!=0]
  average_non0mean = mean(dmat_s_non0)
  average_non0sd = sd(dmat_s_non0)
}

### non0scale for every CT
if (T) {
  out <- lapply(dat, function(dmat_sigi) {
    if (length(unique(dmat_sigi))!=1){
      norm_factors = non0scale(dmat_sigi, average_non0mean, average_non0sd)
      B = norm_factors[1]
      A = norm_factors[2]
      
      dmat_sigi_norm = dmat_sigi * B + A
      dmat_sigi_norm[dmat_sigi_norm<0] = 0
    }
    if (length(unique(dmat_sigi))==1){
      B = 1
      A = 0
      dmat_sigi_norm = dmat_sigi
    }
    
    # norm_dat
    outdat = cbind(dbed, dmat_sigi_norm)
    # norm_info
    info = data.frame(B=B,
                      A=A,
                      average_non0mean = average_non0mean,
                      average_non0sd = average_non0sd)
    return(list(outdat, info))
  })
  
  for (i in 1:length(file_list)){
    # output for norm dat
    file_tmp = basename(file_list[i])
    output_name_tmp = paste0(file_tmp, '.norm.bedgraph')
    write.table(out[[i]][[1]], output_name_tmp, row.names=F, col.names=F, quote=F, sep='\t')
    # output for norm info
    write.table(out[[i]][[2]], paste0(output_name_tmp, ".info.txt"), row.names=F, col.names=T, quote=F, sep='\t')
  }
}

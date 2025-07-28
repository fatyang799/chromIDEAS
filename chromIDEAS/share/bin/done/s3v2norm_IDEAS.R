### get parameters
if (T) {
  args = commandArgs(trailingOnly=TRUE)
  
  input_target = args[1]
  input_ref = args[2]
  output_target = args[3]
  
  threshold = as.numeric(args[4])
  local_bg_bin = as.numeric(args[5])
  
  for_ref = args[6]
  
  rank_lim = as.numeric(args[7])
  upperlim = as.numeric(args[8])
  lowerlim = as.numeric(args[9])
  
  p_method = args[10]
  
  cpk_file = args[11]
  cbg_file = args[12]
  allpk_file = args[13]
  
  uniq_mk_num = as.numeric(args[14])
}

# default setting
if (F) {
  input_target = "${cell}.${marker}.${id}.ip.idsort.bedgraph"
  input_ref = "${marker}.average_sig.bedgraph.S3.bedgraph"
  output_target = "${cell}_${id}.${marker}.S3V2.bedgraph"
  threshold = 0.1
  local_bg_bin = 5
  for_ref = "F"
  rank_lim = 0.0001
  upperlim = 1000
  lowerlim = 0
  p_method = "z"
  cpk_file = "${mk}_commonpkfdr01_z.cpk.txt"
  cbg_file = "${mk}_commonpkfdr01_z.cbg.txt"
  allpk_file = "${mk}_commonpkfdr01_z.allpk.txt"
  uniq_mk_num = "${uniq_mk_num}"
  
  input_target = "../2.bigWig2bedGraph/thp1.H3K4me2.rep3.ip.idsort.bedgraph"
  input_ref = "H3K4me2.average_sig.bedgraph.S3.bedgraph"
  output_target = "thp1_rep1.H3K4me2.S3V2.bedgraph"
  threshold = 0.1
  local_bg_bin = 5
  for_ref = "F"
  rank_lim = 0.0001
  upperlim = 1000
  lowerlim = 0
  p_method = "z"
  cpk_file = "H3K4me2_commonpkfdr01_z.cpk.txt"
  cbg_file = "H3K4me2_commonpkfdr01_z.cbg.txt"
  allpk_file = "H3K4me2_commonpkfdr01_z.allpk.txt"
  uniq_mk_num = 6
}

# define functions
if (T) {
  ### get p-value
  if (T) {
    if (uniq_mk_num > 1) {
      get_p_z = function(d, notop_p){
        d_notop = d[d<=quantile(d, notop_p)]
        # just in case
        if (T) {
          if (max(d_notop)<=1){
            d_notop = d[d<=quantile(d[d>0], notop_p)]
          }
        }
        
        dz = (d - mean(d_notop))/sd(d_notop)
        dzp = pnorm(-(dz))
        dzpfdr = p.adjust(dzp,'fdr')
        return(dzpfdr)
      }
    }
    if (uniq_mk_num == 1) {
      get_p_z = function(d, notop_p){
        d_notop = d[d<=quantile(d[d>0], notop_p)]
        # just in case
        if (T) {
          if (max(d_notop)<=1){
            d_notop = d[d<=quantile(d[d>0], notop_p)]
          }
        }
        
        dz = (d - mean(d_notop))/sd(d_notop)
        dzp = pnorm(-(dz))
        dzpfdr = p.adjust(dzp,'fdr')
        return(dzpfdr)
      }
    }
  }
  
  # calculation for normalization
  if (T) {
    # solve an equation for pk normalization: exponential regression (Norm_a = a^x), error=|b-a^x|
    getsf_pk_LM_A0 = function(a0, b0){
      # a: tar sig
      # b: ref sig
      a = ((a0[(a0>0)&(b0>0)]))
      b = ((b0[(a0>0)&(b0>0)]))
      expLM_linear <- function(x) {
        sum((b-a^x)^2)
      }
      B = optimize(expLM_linear, lower=0, upper=5)$minimum
      sf = c(B, 0.0)
      return(sf)
    }
    
    getsf_pk = function(a0, b0){
      # a: tar sig
      # b: ref sig
      a = log2(a0[(a0>0)&(b0>0)])
      b = log2(b0[(a0>0)&(b0>0)])
      B = sd(b)/sd(a)
      A = mean(b) - mean(a)/sd(a)*sd(b)
      sf = c(B, A)
      return(sf)
    }
    
    getsf_bg = function(a0, b0){
      # a0: tar cbg sig
      # b0: ref cbg sig
      a = (a0[(a0>0)])
      b = (b0[(b0>0)])
      
      B = sd(b)/sd(a)
      # A = mean(b) - mean(a)*B
      A = mean(b) - mean(a)/sd(a)*sd(b)
      
      
      sf = c(B, A)
      return(sf)
    }
  }
  
  ### get local bg signal (replace all peak as bg, and then model the bg to calculate the P value)
  if (T) {
    get_local_bg_sig_each_row = function(x, local_bg_bin, d_lim, xsig, xbinary){
      # x[1-5]: peakID of upstream 5 bins, up1-up5
      # x[6-10]: peakID of downstream 5 bins, down1-down5
      # x[11-15]: raw signal of upstream 5 bins, up1-up5
      # x[16-20]: raw signal of downstream 5 bins, down1-down5
      # x[21]: row number ID
      # d_lim: mean value of all raw bg signal
      # xsig: target bin signal value
      # xbinary: target bin peakID
      
      ### target bin is defined as pk
      if (xbinary!=0){
        sig_tmp = x[(2*local_bg_bin+1):(length(x)-1)]
        binary_tmp = x[1:(2*local_bg_bin)]
        row_n <- x[length(x)]
        
        ### all local_bg_bin are bg
        if (sum(binary_tmp)==0){
          sig_bg_tmp = max(sig_tmp)
        }
        
        ### all local_bg_bin are pk
        if (sum(binary_tmp)!=0 & prod(binary_tmp)!=0){
          sig_bg_tmp = d_lim
        }
        
        ### some local_bg_bin are pk, some local_bg_bin are bg
        if (sum(binary_tmp)!=0 & prod(binary_tmp)==0){
          sig_bg_tmp = max(sig_tmp[binary_tmp==0])
          
          if(!is.finite(sig_bg_tmp)){
            mess <- paste0("s3v2norm_IDEAS.R 1 raise warning, there are inf within local_bg_bin value.\n\tThe row number: ", row_n)
            warning(mess)
          }
        }
      }
      
      ### target bin is defined as bg
      if (xbinary==0){
        sig_bg_tmp = xsig
      }
      return(sig_bg_tmp)
    }
    get_local_bg_sig = function(local_bg_bin, d_sig_all, d_pkb, d_lim){
      # local_bg_bin: the local background bin number, default: 5
      # d_sig_all: all raw signal
      # d_pkb: all peak ID, T or F
      # d_lim: mean value of all raw bg signal
      
      ### get windows sig pkb mat
      if (T) {
        # d_exp_sig_up: the signal value of upstream 5 bins for each bin. row=bin, col=up1-5; up+1, up+2, up+3, up+4, up+5
        # d_exp_sig_up_pkb: the peakID of upstream 5 bins for each bin. row=bin, col=up1-5; up+1, up+2, up+3, up+4, up+5
        # d_exp_sig_down: the signal value of downstream 5 bins for each bin. row=bin, col=down1-5; down+1, down+2, down+3, down+4, down+5
        # d_exp_sig_down_pkb: the peakID of downstream 5 bins for each bin. row=bin, col=up1-5; down+1, down+2, down+3, down+4, down+5
        d_exp_sig_up = c()
        d_exp_sig_down = c()
        d_exp_sig_up_pkb = c()
        d_exp_sig_down_pkb = c()
        
        for (i in 1:local_bg_bin){
          d_exp_sig_down = cbind( d_exp_sig_down, c(d_sig_all[(1+i):length(d_sig_all)], rep(0,i)) )
          d_exp_sig_down_pkb = cbind( d_exp_sig_down_pkb, c(d_pkb[(1+i):length(d_pkb)], rep(0,i)) )
          
          d_exp_sig_up = cbind( d_exp_sig_up, c(rep(0,i), d_sig_all[1:(length(d_sig_all)-i)]) )
          d_exp_sig_up_pkb = cbind( d_exp_sig_up_pkb, c(rep(0,i), d_pkb[1:(length(d_pkb)-i)]) )
        }
      }
      
      ### merge pkb & sig mat
      if (T) {
        d_exp_sig = cbind(d_exp_sig_up, d_exp_sig_down)
        d_exp_pkb = cbind(d_exp_sig_up_pkb, d_exp_sig_down_pkb)
        
        # d_exp_pkb_sig:
        # col1: raw signal
        # col2: common peakID
        # col3-7: peakID of upstream 5 bins, up1-up5
        # col8-12: peakID of downstream 5 bins, down1-down5
        # col13-17: raw signal of upstream 5 bins, up1-up5
        # col18-22: raw signal of downstream 5 bins, down1-down5
        # col23: row number ID
        d_exp_pkb_sig = cbind(d_sig_all, d_pkb, d_exp_pkb, d_exp_sig, 1:length(d_sig_all))
        
        colnames(d_exp_pkb_sig)[3:ncol(d_exp_pkb_sig)] <- c(
          paste0("up_pk", 1:5),
          paste0("down_pk", 1:5),
          paste0("up_sig", 1:5),
          paste0("down_sig", 1:5), 
          "row_ID"
        )
      }
      
      ### get local bg signal
      if (T) {
        # d_exp_pkb_sig:
        # col1: raw signal
        # col2: common peakID
        # col3-7: peakID of upstream 5 bins, up1-up5
        # col8-12: peakID of downstream 5 bins, down1-down5
        # col13-17: raw signal of upstream 5 bins, up1-up5
        # col18-22: raw signal of downstream 5 bins, down1-down5
        # col23: row number ID
        
        d_exp_pkb_sig_bg_sig = apply(d_exp_pkb_sig, 1, function(x) {get_local_bg_sig_each_row(x[3:length(x)], local_bg_bin, d_lim, x[1], x[2])})
      }
      
      ### replace all pk region by global bg
      if (T) {
        d_exp_pkb_sig_bg_sig[is.infinite(d_exp_pkb_sig_bg_sig)] = d_lim
      }
      
      return(d_exp_pkb_sig_bg_sig)
    }
  }
}

### read signal
if (T) {
  d10 = data.table::fread(input_ref, header=F, sep='\t', data.table=F)
  d20 = data.table::fread(input_target, header=F, sep='\t', data.table=F)
  d1 = d10[,4]
  d2 = d20[,4]
}

# if values of target file are too small, scale up the signal
if (T) {
  if (cpk_file=='F'){
    d2_quantile = quantile(d2[d2>0],0.75,type=1)
    if (d2_quantile<1){
      d2 = d2/d2_quantile
      write.table(paste0(input_target, ": The Q75 value is too low (<1)"), paste0(output_target, ".low.value.txt"), sep='\t', quote=F, col.names=F, row.names=F)
    }
  }
  if (cpk_file!='F'){
    cpk_file_content = data.table::fread(cpk_file, header=F, sep='\t', data.table=F)[,1]
    cpk_id = (cpk_file_content==1)
    d2_cpk = d2[cpk_id]
    d2_cpk_non0_min = min(d2_cpk[d2_cpk>0])
    if (d2_cpk_non0_min<1){
      d2 = d2/d2_cpk_non0_min
      write.table(paste0(input_target, ": The non0 minimum value is too low (<1)"), paste0(output_target, ".low.value.txt"), sep='\t', quote=F, col.names=F, row.names=F)
    } 
  }
}

# limit signal range
if (T) {
  d1[d1>upperlim] = upperlim
  d1[d1<lowerlim] = lowerlim
  
  d2[d2>upperlim] = upperlim
  d2[d2<lowerlim] = lowerlim
}

### get FDR NB p-value vector
if (T) {
  if (p_method=='neglog10p'){
    d1s_nb_pval_out = p.adjust(10^(-d1), 'fdr')
    d2s_nb_pval_out = p.adjust(10^(-d2), 'fdr')
  }
  if (p_method=='rc') {
    d1s_nb_pval_out = get_p_r1(d1)
    d2s_nb_pval_out = get_p_r1(d2)
  }
  if (p_method=='z') {
    if (uniq_mk_num > 1) {
      d1s_nb_pval_out = get_p_z(d1, 0.999)
      d2s_nb_pval_out = get_p_z(d2, 0.999)
    }
    if (uniq_mk_num == 1) {
      d1s_nb_pval_out = get_p_z(d1, 1)
      d2s_nb_pval_out = get_p_z(d2, 1)
    }
  }
}

### get pk bg binary vec
if (T) {
  d1s_nb_pval_out_binary_pk = (d1s_nb_pval_out<threshold)
  d2s_nb_pval_out_binary_pk = (d2s_nb_pval_out<threshold)
  
  d1s_nb_pval_out_binary_bg = (d1s_nb_pval_out>=threshold)
  d2s_nb_pval_out_binary_bg = (d2s_nb_pval_out>=threshold)
}

### get mean value of all bg region for tar and ref
if (T) {
  # all bg in tar and ref files
  d12_bgb = d1s_nb_pval_out_binary_bg | d2s_nb_pval_out_binary_bg
  
  d1bg = d1[d12_bgb]
  d2bg = d2[d12_bgb]
  d1s_lim = mean(d1bg)
  d2s_lim = mean(d2bg)
}

### get all pk
if (T) {
  if (allpk_file != 'F') {
    all_pk = data.table::fread(allpk_file, header=F, sep='\t', data.table=F)[,1]
    allpk_used_id = all_pk == 1
  }
  if (allpk_file == 'F') {
    # tar file peaks
    allpk_used_id = d2s_nb_pval_out_binary_pk
  }
}

# prepare data to model the bg distribution: d1_exp_pkb_sig_bg_sig, d2_exp_pkb_sig_bg_sig, d1_sig_all, d2_sig_all
if (T) {
  # prepare ref and target sig
  if (T) {
    d1_sig_all = d1
    d2_sig_all = d2
    
    d1_pkb = d2_pkb = allpk_used_id
  }
  
  # replace the pk with bg to model the bg distribution
  if (T) {
    # the number of sig < 10w
    if (length(d1_sig_all)<100000) {
      # ref
      d1_exp_pkb_sig_bg_sig = get_local_bg_sig(local_bg_bin, d1_sig_all, allpk_used_id, d1s_lim)
      # tar
      d2_exp_pkb_sig_bg_sig = get_local_bg_sig(local_bg_bin, d2_sig_all, allpk_used_id, d2s_lim)
    }
    
    # the number of sig >= 10w: separate the dat by step=10w
    if (length(d1_sig_all)>=100000) {
      d1_exp_pkb_sig_bg_sig = rep(0, length(d1_sig_all))
      d2_exp_pkb_sig_bg_sig = rep(0, length(d2_sig_all))
      
      if (length(d1_sig_all) == length(d2_sig_all)) {
        split_range = cbind(seq(1,length(d1_sig_all), by=100000), c(seq(1,length(d1_sig_all), by=100000)[-1],length(d1_sig_all)) )
        for (i in 1:nrow(split_range)){
          used_id_i = split_range[i,1]:split_range[i,2]
          d1_exp_pkb_sig_bg_sig[used_id_i] = get_local_bg_sig(local_bg_bin, d1_sig_all[used_id_i], allpk_used_id[used_id_i], d1s_lim)
          d2_exp_pkb_sig_bg_sig[used_id_i] = get_local_bg_sig(local_bg_bin, d2_sig_all[used_id_i], allpk_used_id[used_id_i], d2s_lim)
        }
      }
      if (! length(d1_sig_all) == length(d2_sig_all)) {
        stop("s3v2norm_IDEAS.R raise error: the number of input_ref and input_target is not identical, please check line 359")
      }
    }
  }
}

# calculate normalization factors:
# normalization for pk: exponential regression;  Norm_dat = dat^B
# normalization for bg: linear regression;  Norm_dat = B*dat+A
if (T) {
  if (for_ref == 'T'){
    # pk normalization
    if (T) {
      # raw sig - bg_distribution
      d1pk_sig = d1_sig_all - d1_exp_pkb_sig_bg_sig
      d2pk_sig = d2_sig_all - d2_exp_pkb_sig_bg_sig
      d1pk_sig[d1pk_sig<0]=0
      d2pk_sig[d2pk_sig<0]=0
      
      pksf = getsf_pk(d2pk_sig, d1pk_sig)
    }
    
    # bg normalization
    if (T) {
      d1bg_sig = d1_exp_pkb_sig_bg_sig
      d2bg_sig = d2_exp_pkb_sig_bg_sig
      
      bgsf_bg = getsf_bg(d2bg_sig, d1bg_sig)  
    }
  }
  if (for_ref == 'F'){
    ### cpk: cpk_id
    if (T) {
      if (cpk_file=='F'){
        cpk_id = (d1s_nb_pval_out_binary_pk) & (d2s_nb_pval_out_binary_pk)
      }
      if (cpk_file!='F'){
        cpk_file_content = data.table::fread(cpk_file, header=F, sep='\t', data.table=F)[,1]
        cpk_id = (cpk_file_content==1)
      }  
    }
    
    ### cbg: cbg_id
    if (T) {
      if (cbg_file=='F'){
        cbg_id = (d1s_nb_pval_out_binary_bg) & (d2s_nb_pval_out_binary_bg)
      }
      if (cbg_file!='F'){
        cbg_file_content = data.table::fread(cbg_file, header=F, sep='\t', data.table=F)[,1]
        cbg_id = (cbg_file_content==1)
      }  
    }
    
    ### get pk sf = raw_sig - bg_distribution;  d1pk_sig, d2pk_sig: if >0, means it is a peak, else a bg
    if (T) {
      d1pk_sig = d1_sig_all - d1_exp_pkb_sig_bg_sig
      d2pk_sig = d2_sig_all - d2_exp_pkb_sig_bg_sig
      
      d1pk_sig[d1pk_sig<0]=0
      d2pk_sig[d2pk_sig<0]=0
    }
    
    # normalization for pk: exponential regression;  Norm_dat = dat^B
    # - pksf: c(B, 0.0)
    if (T) {
      # calculate λ for exponential regression
      if (sum(cpk_id)>(rank_lim*length(cpk_id))){
        pksf = getsf_pk_LM_A0(d2pk_sig[cpk_id], d1[cpk_id])
      }
      if (sum(cpk_id)<=(rank_lim*length(cpk_id))){
        cpk_id = (d1s_nb_pval_out_binary_pk) & (d2s_nb_pval_out_binary_pk)
        
        pksf = getsf_pk_LM_A0(d2pk_sig[cpk_id], d1[cpk_id])
      }
    }
    
    # normalization for bg: linear regression;  Norm_dat = B*dat+A
    # - bgsf_bg: c(B, A)
    if (T) {
      d2bg_sig = d2_exp_pkb_sig_bg_sig
      bgsf_bg = getsf_bg(d2bg_sig[cbg_id], d1[cbg_id])
    }
  }
}

### norm bg
if (T) {
  b <- bgsf_bg[1]
  a <- bgsf_bg[2]
  
  d2bg_sig_norm = d2bg_sig*b + a
  d2bg_sig_norm[d2bg_sig==0] = 0
}

### norm pk
if (T) {
  d2pk_sig_norm = d2pk_sig
  b <- pksf[1]
  a <- pksf[2]
  
  d2pk_sig_norm[allpk_used_id] = (d2pk_sig_norm[allpk_used_id]^b) * (2^a)
}

### norm sig = norm_pk + norm_bg
if (T) {
  d2_sig_norm = d2bg_sig_norm + d2pk_sig_norm
}

### limit signal range
if (T) {
  d2_sig_norm[d2_sig_norm>upperlim] = upperlim
  d2_sig_norm[d2_sig_norm<lowerlim] = lowerlim
}

### write output
if (T) {
  bedgraph <- cbind(d20[,1:3], d2_sig_norm)
  write.table(bedgraph, output_target, sep='\t', quote=F, col.names=F, row.names=F)
  
  info <- data.frame(
    pk_b = pksf[1],
    pk_a = pksf[2],
    bg_b = bgsf_bg[1],
    bg_a = bgsf_bg[2]
  )
  write.table(info, paste0(output_target, '.info.txt'), sep='\t', quote=F, col.names=T, row.names=F)
}
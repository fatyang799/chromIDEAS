# get parameters
if (T) {
  args = commandArgs(trailingOnly=TRUE)
  
  file_list_file = args[1]
  output_prefix = args[2]
  thresh = as.numeric(args[3])
  method = args[4]
  prob_pk = as.numeric(args[5])
  prob_bg = as.numeric(args[6])
}

# deine the function
if (T) {
  ### get z
  get_z = function(x){
    x_notop = x[x<=quantile(x[x>0], 0.95)]
    xz = (x - mean(x_notop)) / sd(x_notop)
    return(xz)
  }
  
  ### get fdr
  get_fdr = function(x){
    z = get_z(x)
    zp = pnorm(-z)
    zpfdr = p.adjust(zp)
    return(zpfdr)
  }
  
  ### get NB model
  get_true_NB_prob_size = function(x){
    m=mean(x[x>0]);
    m2=mean(x[x>0]^2);
    p0 = length(which(x==0)) / length(x);
    p = m/(m2-m^2 * (1-p0));
    s = m * (1 - p0) * p /(1-p);
    rt=c(p,s,p0);
    
    for(i in 1:100){
      op = p;
      os = s;
      p0=p^s;
      #print(p0)
      p=m/(m2-m^2*(1-p0));
      if (p<0.001){
        p = 0.001
      }
      if (p>=0.999){
        p = 0.999
      }
      s=m * (1 - p0) * p / (1-p);
      #rt=rbind(rt,c(p,s,p0));
      rt = c(p,s,p0)
      if(abs(op-p)<0.00001 & abs(os-s)<0.00001) break;
    }
    return(rt);
  }
  
  ### get p-value
  get_pval = function(N, l, sig_0_size, sig_0_prob, num_0){
    if (N != 0){
      pval_new = pnbinom(N-1, sig_0_size, sig_0_prob, lower.tail=FALSE) / pnbinom(0, sig_0_size, sig_0_prob, lower.tail=FALSE) * (l-num_0)/l
    } else {
      pval_new = 1.0
    }
    return(pval_new)
  }
  
  ### get fdr p-value vector
  get_nb_fdrp = function(d){
    ds = d
    ds_notop = ds[ds<=quantile(ds, 0.99)]
    ds_notop_probT_sizeT = get_true_NB_prob_size(ds_notop)
    ds_obs_0_num = sum(ds == 0)
    bin_num = length(ds)
    ### get NB para
    ds_p0 = ds_notop_probT_sizeT[3]
    ds_size = ds_notop_probT_sizeT[2]
    ds_prob = ds_notop_probT_sizeT[1]
    ### set limit for prob
    if (ds_prob<0.001){
      ds_prob = 0.001
    }
    if (ds_prob>=0.999){
      ds_prob = 0.999
    }
    ### get p
    ds_nb_pval = apply(cbind(ds), MARGIN=1, function(x) get_pval(x[1], bin_num, ds_size, ds_prob, ds_obs_0_num) )
    ds_nb_pval[ds_nb_pval>1] = 1
    ### get fdr
    ds_nb_pval_fdr0 = p.adjust(ds_nb_pval, 'fdr')
    return(ds_nb_pval_fdr0)
  }
}

# read input
if (T) {
  file_list = read.table(file_list_file, header=F)
  set.seed(2020)
}

# if there are more than 50 datasets, random select 50 to do analysis
if (nrow(file_list)>50){
	used_id_sample = sample(nrow(file_list), 50)
	file_list = file_list[used_id_sample,]
}

# construct the matrix
if (T) {
  # construct the 0 matrix
  if (T) {
    d00 = data.table::fread(file_list[1,1], header=F, sep='\t', data.table=F)  
    common_pk = matrix(0, nrow=nrow(d00), ncol=nrow(file_list))
  }
  
  # contruct the 0/1 matrix
  for (i in 1:nrow(file_list)){
    print(file_list[i,1])
    
    d10 = data.table::fread(file_list[i,1], header=F, sep='\t', data.table=F)
    sig_tmp = d10[,4]
    
    if (is.na(mean(sig_tmp)) || (max(sig_tmp)==0)) {
      print('!!!Something wrong with the bigWig to signal step!!!')
      stop('!!!Something wrong with the bigWig to signal step!!!')
    }
    
    # get average value
    if (method =='z'){
      sig_tmp_fdr = get_fdr(sig_tmp)
    } else if (method =='nb'){
      sig_tmp = sig_tmp/min(sig_tmp[sig_tmp>0])
      sig_tmp_fdr = get_nb_fdrp(sig_tmp)
    }
    
    # get peaks
    sig_tmp_fdr_pk = sig_tmp_fdr<thresh
    common_pk[,i] = sig_tmp_fdr_pk
  }
}


# 1 for peak, 0 for bg
if (T) {
  # transfer to numeric
  common_pk = common_pk*1
  
  # get common peak
  if (T) {
    # proportion of files as peak
    cpk_num_thresh = round(prob_pk * ncol(common_pk))
    
    common_pk_binary = apply(common_pk, 1, function(x) sum(x==1))
    common_pk_binary = as.numeric(common_pk_binary >= cpk_num_thresh)
  }
  
  # get common bg
  if (T) {
    # proportion of files as bg
    cbg_num_thresh = round(prob_bg * ncol(common_pk))
    
    common_bg_binary = apply(common_pk, 1, function(x) sum(x==0))
    common_bg_binary = as.numeric(common_bg_binary >= cbg_num_thresh)
  }
}

# output
if (T) {
  write.table(common_pk_binary, paste0(output_prefix, '.cpk.txt'), quote=F, col.names=F, row.names=F, sep='\t')
  write.table(common_bg_binary, paste0(output_prefix, '.cbg.txt'), quote=F, col.names=F, row.names=F, sep='\t')  
}

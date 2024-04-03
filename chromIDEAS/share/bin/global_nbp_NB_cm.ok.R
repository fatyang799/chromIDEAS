# get arguments
if (T) {
  args = commandArgs(trailingOnly=TRUE)  
  
  # file_list_file: ${mk}.getave_nbp.list.txt (s3v2 norm EXP vs CT)
  file_list_file = args[1]
  # average_sig_file: ${mk}.average_sig.bedgraph.S3V2.ave.bedgraph
  average_sig_file = args[2]
}

# test data
if (F) {
  rm(list = ls())
  options(stringAsFactors = F)
  average_sig_file <- "H3K4me2.average_sig.bedgraph.S3V2.ave.bedgraph"
}

# define functions
if (T) {
  ###### get NB model prob and size
  get_true_NB_prob_size = function(x, siglim){
    # filter data
    x_pass_lim = x[x>=siglim]
    
    # old m & v
    m=mean(x_pass_lim)
    v=var(x_pass_lim)
    
    passlim_num = length(x_pass_lim)
    
    for (i in 1:1){
      if (v<m){
        v=m+0.1
      }
      
      m_pre = m
      v_pre = v
      p = m/v
      s = m^2/(v-m)
      
      exp_siglim_p = dnbinom(0:siglim, s, p)
      exp_total_num = passlim_num/(1-sum(exp_siglim_p))
      
      ### get new mean
      if (T) {
        siglim_n_sum_for_m = 0
        for (j in 0:siglim){
          siglim_n_sum_for_m = siglim_n_sum_for_m + j* exp_siglim_p[j+1]*exp_total_num
        }
        m = (siglim_n_sum_for_m + m * passlim_num) / exp_total_num  
      }
      
      ### get new var
      if (T) {
        siglim_n_sum_for_v = 0
        for (j in 0:siglim){
          siglim_n_sum_for_v = siglim_n_sum_for_v + (j-m)^2 * exp_siglim_p[j+1]*exp_total_num
        }
        v = (siglim_n_sum_for_v + sum((x_pass_lim-m)^2)) / (exp_total_num-1)  
      }
      
      if (v<m){
        v=m+0.1
      }
      
      if(abs(m-m_pre)<0.001 & abs(v-v_pre)<0.00001) {
        break
      }
    }
    p = m/v
    s = m^2/(v-m)
    
    return(c(p,s))
  }
}

# calculate p value of NB bg model for average signal
if (T) {
  ######## read average signal: mk_average_sig
  if (T) {
    mk_average = data.table::fread(average_sig_file, header=F, sep='\t', data.table=F)
    bed = mk_average[,1:3]
    mk_average_sig = as.numeric(mk_average[,4])
  }
  
  # related factors: NB_thresh, scale_down
  ### get bg only signal: AVEmat_cbg
  if (T) {
    AVEmat_cbg = mk_average_sig
    AVEmat_cbg[AVEmat_cbg<1] = 0
    
    # get minimum value for NB distribution: NB_thresh
    if (T) {
      top_sigs = AVEmat_cbg[AVEmat_cbg>10]
      top_mean = mean(tail(sort(top_sigs),100))
      
      scale_down = 200/top_mean
      if (scale_down>1){
        scale_down = 1
      }
      
      NB_thresh = top_mean*scale_down*0.01
      if (NB_thresh<1){
        NB_thresh = 1
      }
    }
    
    # transfer to integer
    AVEmat_cbg = round(AVEmat_cbg)
    
    # scale down the sig
    if (T) {
      min_non0 = min(AVEmat_cbg[AVEmat_cbg>0])
      #AVEmat_cbg = (AVEmat_cbg-min_non0)*scale_down+min_non0  
      
      AVEmat_cbg0 = AVEmat_cbg
      AVEmat_cbg = (AVEmat_cbg-min_non0)*scale_down+min_non0
      AVEmat_cbg[AVEmat_cbg0==0] = 0
    }
    
    # limit the range: 0-200
    if (T) {
      AVEmat_cbg[AVEmat_cbg<0] = 0
      AVEmat_cbg[AVEmat_cbg>200] = 200
    }
    
    # Q95 cutoff as pk cutoff
    if (T) {
      top_rm_thresh = quantile(AVEmat_cbg[AVEmat_cbg>0],0.95)
      
      if (top_rm_thresh<=NB_thresh){
        top_rm_thresh = NB_thresh+1
      }
    }
    
    # remove outlier
    AVEmat_cbg = AVEmat_cbg[AVEmat_cbg<top_rm_thresh]
  }
  
  ######### get global NB bg model: NB(AVEmat_cbg_prob, AVEmat_cbg_size)
  if (T) {
    AVEmat_cbg_NBmodel = get_true_NB_prob_size(AVEmat_cbg, NB_thresh)
    
    AVEmat_cbg_prob = AVEmat_cbg_NBmodel[1]
    AVEmat_cbg_size = AVEmat_cbg_NBmodel[2]
    
    ### set limit for prob
    AVEmat_cbg_prob = ifelse(AVEmat_cbg_prob<0.001, 0.001, 
                             ifelse(AVEmat_cbg_prob>=0.999, 0.999, AVEmat_cbg_prob))
  }
  
  # for average signal
  if (T) {
    # IP_CTRL_tmp: signal & AVEmat_cbg_size
    if (T) {
      min_non0 = min(mk_average_sig[mk_average_sig>0])
      IP_CTRL_tmp = (mk_average_sig-min_non0)*scale_down + min_non0
    }
    
    # get pvalue for signal within NB distribution: IP_nb_pval
    if (T) {
      IP_nb_pval = pnbinom(IP_CTRL_tmp, AVEmat_cbg_size, AVEmat_cbg_prob, lower.tail=FALSE)
      
      # limit the range of Pvalue
      IP_nb_pval[IP_nb_pval<=1e-323] = 1e-323
      IP_nb_pval[IP_nb_pval>1] = 1.0
    }
    
    # transfer to -log10P: IP_nb_pval
    if (T) {
      IP_neglog10_nb_pval = -log10(IP_nb_pval)
      IP_neglog10_nb_pval[IP_neglog10_nb_pval<0] = 0
      neglog10_nb_pval_bedgraph = cbind(bed, IP_neglog10_nb_pval)
    }
  }
  
  ### write output
  if (T) {
    # info
    info <- data.frame(
      AVEmat_cbg_prob=AVEmat_cbg_prob,
      AVEmat_cbg_size=AVEmat_cbg_size,
      scale_down=scale_down
    )
    write.table(info, paste0(average_sig_file, '.NBP.bedgraph.info.txt'), quote=FALSE, col.names=TRUE, row.names=FALSE, sep='\t')
    
    # output
    write.table(neglog10_nb_pval_bedgraph, paste0(average_sig_file, '.NBP.bedgraph'), quote=FALSE, col.names=FALSE, row.names=FALSE, sep='\t')
  }
}

# calculate p value of NB bg model for every single file
if (T) {
  rm(list = ls()[! grepl("file_list_file|average_sig_file|scale_down|AVEmat_cbg_size|AVEmat_cbg_prob", ls())])
  
  # get all files
  if (T) {
    # ${cell}_${id}.${mk}.S3V2.bedgraph ${cell}.${mk}.${id}.ctrl.idsort.bedgraph.norm.bedgraph
    mk = unlist(strsplit(file_list_file, split='[.]'))[1]
    file_list = read.table(file_list_file, header=F)
  }
  
  for (i in 1:nrow(file_list)){
    ### get IP signal: IP_tmp
    if (T) {
      file_tmp = file_list[i,1]
      IP_tmp0 = data.table::fread(file_tmp, header=F, sep='\t', data.table=F)
      if (i==1){
        bed = IP_tmp0[,1:3]
      }
      IP_tmp = IP_tmp0[,4]
      
      min_non0 = min(IP_tmp[IP_tmp>0])
      IP_tmp = (IP_tmp-min_non0)*scale_down+min_non0
    }
    
    ### get CTRL signal: CTRL_tmp
    if (T) {
      file_tmp1 = file_list[i,2]
      CTRL_tmp = data.table::fread(file_tmp1, header=F, sep='\t', data.table=F)[,4]  
    }
    
    ### merge the signal: IP + adjusted_CT
    if (T) {
      CTRL_tmp_mean = mean(CTRL_tmp)
      CTRL_tmp_adj = (CTRL_tmp+1)/(CTRL_tmp_mean+1)*AVEmat_cbg_size
      
      IP_CTRL_tmp = cbind(IP_tmp, CTRL_tmp_adj)
    }
    
    ### get negative binomial p-value: IP_nb_pval
    if (T) {
      IP_nb_pval = pnbinom(IP_CTRL_tmp[,1], IP_CTRL_tmp[,2], AVEmat_cbg_prob, lower.tail=FALSE)
      
      # limit the range of Pvalue
      IP_nb_pval[IP_nb_pval<=1e-323] = 1e-323
      IP_nb_pval[IP_nb_pval>1] = 1.0
    }
    
    # transfer to -log10P: IP_nb_pval
    if (T) {
      IP_neglog10_nb_pval = -log10(IP_nb_pval)
      IP_neglog10_nb_pval[IP_neglog10_nb_pval<0] = 0
      neglog10_nb_pval_bedgraph = cbind(bed, IP_neglog10_nb_pval)
    }
    
    ### write output
    if (T) {
      output_file_tmp = paste0(file_list[i,1], '.NBP.bedgraph')
      write.table(neglog10_nb_pval_bedgraph, output_file_tmp, quote=FALSE, col.names=FALSE, row.names=FALSE, sep='\t')
    }
  }
}

library(pheatmap)

#IDEAS_folder = '/storage/home/gzx103/scratch/S3V2norm_compare/human_vision/'
#IDEAS_output_name = 'hg38bp0402'
#output_name='.var_mean.pdf'

#time Rscript S3V2_IDEAS_ESMP/bin/get_state_mean_var.maxnum.R '/S3V2_IDEAS_outputs_hg38/' 'S3V2_IDEAS_hg38_r2' '.m_v.pdf' '_IDEAS_output/'


args = commandArgs(trailingOnly=TRUE)
IDEAS_folder = args[1]
IDEAS_output_name = args[2]
output_name = args[3]
IDEAS_output_folder_tail = args[4]


print(IDEAS_output_folder_tail)

d = read.table(paste(IDEAS_folder, IDEAS_output_name, '.input', sep=''), header=F, sep=' ')

print(head(d))
uniq_mk = unique(apply(d,1,function(x) as.character(x[2])))
uniq_mk_num = length(uniq_mk)

ct_rep = apply(d,1,function(x) as.character(x[1]))
ct_num = table(ct_rep)
print(ct_num)
#fullset_ct = rownames(ct_num)[ct_num==uniq_mk_num]
fullset_ct = rownames(ct_num)[ct_num==max(ct_num)]



uniq_mk = d[ct_rep==fullset_ct[1],2]
print(uniq_mk)
uniq_mk_num = length(uniq_mk)

print(paste(IDEAS_folder, IDEAS_output_name, IDEAS_output_folder_tail, IDEAS_output_name, '.state', sep=''))
library(data.table)
state = as.data.frame(fread(paste(IDEAS_folder, IDEAS_output_name, IDEAS_output_folder_tail, IDEAS_output_name, '.state', sep='')))
state_tmp = state[,5]
state_num = length(unique(state_tmp))

state_var_all = matrix(0, nrow=state_num, ncol=uniq_mk_num)
state_mean_all = matrix(0, nrow=state_num, ncol=uniq_mk_num)
state_var_mean_all = matrix(0, nrow=state_num, ncol=uniq_mk_num)
state_var_mean_all_sep = matrix(0, nrow=state_num, ncol=uniq_mk_num*length(fullset_ct))

for (i in 1:length(fullset_ct)){
#for (i in 1:2){

#
### get file list
print(fullset_ct[i])
files_tmp = d[ct_rep==fullset_ct[i],3]
mk_tmp = d[ct_rep==fullset_ct[i],2]
### get signal mat
sigmat_tmp = c()
for (mk_i in uniq_mk){
print(mk_i)
sigmat_tmp_mk = scan(toString(files_tmp[mk_tmp == mk_i]))
sigmat_tmp = cbind(sigmat_tmp, sigmat_tmp_mk)
}
### get ct state
state_tmp = state[,colnames(state) == fullset_ct[i]]
print(head(state_tmp))
state_var = c()
state_mean = c()
for (j in 0:(state_num-1)){
print(j)
sigmat_tmp_j = sigmat_tmp[state_tmp==j,]
#print(dim(sigmat_tmp_j))
sigmat_tmp_j_colmean = colMeans(sigmat_tmp_j)
#print(sigmat_tmp_j_colmean)
sigmat_tmp_j_colvar = apply(sigmat_tmp_j, 2, var)
#sigmat_tmp_j_colvar = apply(sigmat_tmp_j, 2, sd)
#print(sigmat_tmp_j_colvar)
#print(sigmat_tmp_j_colvar)
#print(sigmat_tmp_j_colmean)
state_var = rbind(state_var, (sigmat_tmp_j_colvar+1))
state_mean = rbind(state_mean, (sigmat_tmp_j_colmean+1))
}
colnames(state_var) = uniq_mk
rownames(state_var) = 0:(state_num-1)
colnames(state_mean) = uniq_mk
rownames(state_mean) = 0:(state_num-1)
state_var_mean_i = state_var/state_mean
print(state_mean)
print(state_var)
print(state_var/state_mean)
state_var_all = state_var_all + state_var
state_mean_all = state_mean_all + state_mean
#state_var_mean_all = state_var_mean_all+state_var_mean_i
pdf(paste(fullset_ct[i], '.m.', output_name, sep=''))
my_colorbar=colorRampPalette(c('white', 'blue'))(n = 128)
col_breaks = c(seq(0, 2000,length=33))
pheatmap(state_mean, color=my_colorbar, cluster_cols = FALSE,cluster_rows=FALSE,show_rownames=TRUE,show_colnames=TRUE)
dev.off()
pdf(paste(fullset_ct[i], output_name, sep=''))
my_colorbar=colorRampPalette(c('white', 'blue'))(n = 128)
col_breaks = c(seq(0, 2000,length=33))
pheatmap(state_var_mean_i, color=my_colorbar, cluster_cols = FALSE,cluster_rows=FALSE,show_rownames=TRUE,show_colnames=TRUE)
dev.off()

state_var_mean_all_sep[,1:length(uniq_mk)+(i-1)*length(uniq_mk)] = state_var_mean_i
}

used_order_col = order(colnames(state_var_all))
state_var_all = state_var_all[,used_order_col]
state_mean_all = state_mean_all[,used_order_col]

state_var_mean_all = matrix(0, nrow=state_num, ncol=uniq_mk_num)
colnames(state_var_mean_all) = uniq_mk
rownames(state_var_mean_all) = 0:(state_num-1)
print(dim(state_var_mean_all))
for (i in 1:state_num){
state_num_i_mat = matrix(0, nrow=length(fullset_ct), ncol=uniq_mk_num)
state_num_i_mat_sig = state_var_mean_all_sep[i,]
for (j in 1:length(fullset_ct)){
state_num_i_mat[j,] = state_num_i_mat_sig[(1:uniq_mk_num)+(j-1)*uniq_mk_num]
}
state_var_mean_all[i,] = apply(state_num_i_mat,2,median)
}
state_var_mean_all = state_var_mean_all[,used_order_col]


write.table(state_var_mean_all, paste(IDEAS_folder, IDEAS_output_name, IDEAS_output_folder_tail, 'all', output_name, '.txt', sep=''), quote=F)
write.table(state_var_all, paste(IDEAS_folder, IDEAS_output_name, IDEAS_output_folder_tail, 'all_var', output_name, '.txt', sep=''), quote=F)
write.table(state_mean_all, paste(IDEAS_folder, IDEAS_output_name, IDEAS_output_folder_tail, 'all_mean', output_name, '.txt', sep=''), quote=F)

#state_var_mean_all = cbind(rowMeans(state_var_mean_all), rowMeans(state_var_mean_all))
pdf(paste(IDEAS_folder, IDEAS_output_name, IDEAS_output_folder_tail, 'all', output_name, sep=''))
breaksList = seq(0, 20, by = 0.01)
my_colorbar=colorRampPalette(c('white', 'blue'))(n = length(breaksList))
#state_var_mean_all[state_var_mean_all>2] = 2
pheatmap(state_var_mean_all, color=my_colorbar, breaks = breaksList, cluster_cols = FALSE,cluster_rows=FALSE,show_rownames=TRUE,show_colnames=TRUE)
dev.off()




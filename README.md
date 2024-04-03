## S3V2norm

修改

### 1. get cpk cbg allpk average_sig

对每个 `mk` 进行如下操作：

```shell
bash ${bin_root}/get_cpk_cbg_allpk_averagesig.sh ${mk} ${metadata} ${input_dir} ${zip}
```

对于 `get_cpk_cbg_allpk_averagesig.sh` 脚本进行分析

#### 1.1 get_cpk_cbg_allpk_averagesig.sh脚本

输入数据包括：

```shell
mk=$1
metadata=$2
input_dir=$3 # bedgraph文件的路径
zip=$4 # bedgraph文件是否被压缩
```

1. 根据 `${metadata}` 文件以及 `${input_dir}` 路径，制作 `${mk}.file_list.txt` 文件，记录了exp 和 ct文件地址，内容如下：

```shell
${cell}.${mk}.${id}.ip.idsort.bedgraph   ${cell}.${mk}.${id}.ctrl.idsort.bedgraph
```

2. 根据 `${mk}.file_list.txt` 文件运行脚本 `get_common_pk_p.R`，得到 `${mk}_commonpkfdr01_z.cpk.txt` 和 `${mk}_commonpkfdr01_z.cbg.txt`：

```shell
Rscript ${bin_root}/get_common_pk_p.R ${mk}.file_list.txt ${mk}_commonpkfdr01_z 0.1 z 1.0 1.0
```

3. 关于 `get_common_pk_p.R` 做的事：
   1. 对于同一种 `$mk` 的数据而言，如果超过50个，则从中随机抽取50个数据进行后续分析。
   2. 将所有数据中的信号值转为zscale（去除top5%的数据），而后计算p值，而后对p进行fdr。
   3. 定义pk：fdr<0.1
   4. 对于所有bin而言，如果所有数据在同一个bin中都为pk，则该bin为common pk
   5. 对于所有bin而言，如果所有数据在同一个bin中都为bg，则该bin为common bg
   6. 将common pk和common bg输出，文件为 `${mk}_commonpkfdr01_z.cpk.txt` 和 `${mk}_commonpkfdr01_z.cbg.txt`

4.  `${mk}_commonpkfdr01_z.allpk.txt` 文件：根据 `${mk}_commonpkfdr01_z.cbg.txt` 文件，对于只要不是 common bg 的区域，则认为是有pk的区域，即pk至少出现在1个文件中
5. 计算实验组所有样本的均值，使用 `get_average_sig.R` 脚本：

```shell
Rscript ${bin_root}/get_average_sig.R ${mk}.file_list.txt ${mk}.average_sig.bedgraph
```

6. `get_average_sig.R` 做的事：
   1. 对于同一种 `$mk` 的数据而言，如果超过50个，则从中随机抽取50个数据进行后续分析。
   2. 对 `${mk}.file_list.txt` 中记录的第一列所有文件（EXP）的第4列进行加和，并取 `mean` 值。
   3. 对于EXP文件中，如果信号值的均值是NA，或者最大值=0，则该文件不用于计算均值，且该文件名会记录在 `${mk}.average_sig.bedgraph.notused.files.txt`
   4. 结果输出为：`${mk}.average_sig.bedgraph` 和 `${mk}.average_sig.bedgraph.notused.files.txt`



### 2. S3norm average across marks

这一步根据 `mk` 种类数目而定，如果只有一种 `mk`， 则直接将第一步得到的 `${mk}.average_sig.bedgraph` 进行复制获得 `${mk}.average_sig.bedgraph.S3.bedgraph` ：

```shell
cp ${mk}.average_sig.bedgraph ${mk}.average_sig.bedgraph.S3.bedgraph
```

如果 `mk` 的种类数超过1个，则按下述方法，对每一类 `mk` 进行处理，目的是使所有 `mk` 数据的均值达到相同的水平：

```shell
bash ${bin_root}/s3norm.sh ${mk}
```

对于 `s3norm.sh` 脚本进行分析，内容如下：

```shell
python3 ${bin_root}/s3norm.py \
	-r ${bin_root}/prior/H3K27ac.average_sig.sample200k.seed2019.bedgraph \
	-t ${mk}.average_sig.bedgraph \
	-o ${mk}.average_sig.bedgraph.S3.bedgraph \
	-c T 1>${mk}.average_sig.bedgraph.log 2>&1
```

所以我们需要进一步对 `s3norm.py` 脚本进行分析。

#### 2.1 s3norm.py脚本

该脚本作用：以 `${bin_root}/prior/H3K27ac.average_sig.sample200k.seed2019.bedgraph` 作为标准，将所有数据的均值拉到与 `${bin_root}/prior/H3K27ac.average_sig.sample200k.seed2019.bedgraph` 相同的水平。

 `s3norm.py` 脚本的默认参数：

```python
Default NTmethod: -m non0mean
Default B_init: -i 2.0
Default fdr_thresh: -f 0.05
Default rank_lim: -l 0.001
Default upperlim: -a 500
Default lowerlim: -b 0
Default p_method: -p z
Default common_pk_binary: -k 0
Default common_bg_binary: -g 0
# Default cross_mark: -c F
```

 `s3norm.py` 脚本做的事：

1. 读入 `${bin_root}/prior/H3K27ac.average_sig.sample200k.seed2019.bedgraph` ，取其信号值为 `sig1`
2. 读入 `${mk}.average_sig.bedgraph` ，取其信号值为 `sig2`
3. 限制 `sig1` 和 `sig2` 中所有的信号值，取值范围在默认设置值中 【0,500】
4. 将 `sig1` 和 `sig2` 中所有的信号值转为zscale（去除top5%的数据），而后计算p值，而后对p进行fdr。
5. 根据得到的fdr值，与fdr_thresh【默认为0.05】进行比较，得到pk区域：`sig1_binary` 和 `sig2_binary`
6. 默认 `rank_lim=0.001`：
   1. 对 `sig1_binary` 和 `sig2_binary` 进行评估，如果 `pk` 的数量太少【pk数目 <= 总bin数目的0.001】，则换用其他方法寻找pk
   2. 将 `sig1` 和 `sig2` 中信号值进行排序，然后挑选信号值最高的（总bin数目的0.001）个作为pk
7. 根据上述结果，找到对应的pk与bg区域：`sig1_cpk`，`sig1_cbg`，`sig2_cpk`，`sig2_cbg`
8. 利用 `NewtonRaphsonMethod` （`NewtonRaphsonMethod(sig1_cpk, sig1_cbg, sig2_cpk, sig2_cbg, upperlim, 0.5, 2.0, NTmethod, 1e-5, 200)`）计算normalization所需的参数 A, B【`norm=a*raw^b`】：
   1. 分别计算 sig1 的 pk 和 bg 信号值中，非0数据的mean值，得到 `sig1_pk_mean` 和 `sig1_bg_mean`
   2. 默认初始 A=0.5，B=2。
   3. 默认迭代次数为：200次。
   4. 计算并返回参数【A,B】
9. 利用得到的参数【A,B】对数据进行转换：【`norm=a*raw^b`】得到 `sig2_norm`
10. 对 `sig2_norm` 进行范围限定： 【0,500】
11. 结果输出：
    1. `${mk}.average_sig.bedgraph.S3.bedgraph`：norm转化后的数据
    2. `${mk}.average_sig.bedgraph.S3.bedgraph.info.txt`：记录 `${bin_root}/prior/H3K27ac.average_sig.sample200k.seed2019.bedgraph` 和原始 `${mk}.average_sig.bedgraph` 数据mean值之比，norm转化过程中的AB值
    3. `${mk}.average_sig.bedgraph.S3.bedgraph.log`：程序运行log文件，记录各种信息，包括AB值



### 3. S3V2 across samples with same mk

对每个 `mk` 进行如下操作：

```shell
 bash ${bin_root}/s3v2norm.sh \
 	-k ${mk} \
 	-i ${input_dir} \
 	-n ${uniq_mk_num} \
 	-L ${local_bg_bin} \
 	-r 0.0001 \
 	-m ${metadata} \
 	-p ${nthreads}
```

对于 `s3v2norm.sh` 脚本进行分析。

#### 3.1 s3v2norm.sh脚本

该脚本作用有2个：

1. 以 `${mk}.average_sig.bedgraph.S3.bedgraph` 作为标准，将所有的 `${mk}` 数据的均值拉到与 `${mk}.average_sig.bedgraph.S3.bedgraph` 相同的水平：使用 `s3v2norm_sup.sh` 脚本。
2. 计算所有的 `${mk}` 数据均值：使用 `get_average_sig.R` 脚本。

该脚本的一些默认参数：

```shell
-k) mk
-i) input_dir
-m) metadata
-n) uniq_mk_num
-p) nthreads=4
-L) local_bg_bin=5
-r) rank_lim=0.001
-q) fdr_thresh=0.1
-u) upperlim=1000
-l) lowerlim=0
-P) p_method=z
```

首先先准备 `${mk}.file_list.S3V2.txt` 输入文件，其一共有4列：

- `${input_dir}/${cell}.${mk}.${id}.ip.idsort.bedgraph`：原始输入数据
- `${mk}.average_sig.bedgraph.S3.bedgraph`：第2步得到的经过normalization后的 `${mk}` 平均水平数据
- `${cell}_${id}`
- `${mk}`

而后根据 `mk` 种类数目而定，如果只有一种 `mk`，则 `allpk_binary=F` ，否则 `allpk_binary=${mk}_commonpkfdr01_z.allpk.txt`，对 `${mk}.file_list.S3V2.txt` 输入文件中的**每一行（`${line}`）**运行 `s3v2norm_sup.sh` 脚本：

```shell
bash ${bin_root}/s3v2norm_sup.sh \
	${line} \
	${bin_root} \
	${fdr_thresh} \
	${local_bg_bin} \
	${rank_lim} \
	${upperlim} \
	${lowerlim} \
	${p_method} \
	${common_pk_binary} \
	${common_bg_binary} \
	${allpk_binary} \
	${uniq_mk_num}
```

将默认值带入后，实际上运行的脚本是：

```shell
bash ${bin_root}/s3v2norm_sup.sh \
	${line} \
	${bin_root} \
	0.1 \
	5 \
	0.001 \
	1000 \
	0 \
	z \
	${mk}_commonpkfdr01_z.cpk.txt \
	${mk}_commonpkfdr01_z.cbg.txt \
	${allpk_binary} \
	${uniq_mk_num}
```

因为该脚本核心是依赖 `s3v2norm_sup.sh` 脚本，所以下面我们先对该脚本进行解析。

##### 3.1.1 s3v2norm_sup.sh脚本

该脚本承接上述脚本，并对 `${line}` 进行解析，得到：

```shell
# line = ${input_dir}/${cell}.${mk}.${id}.ip.idsort.bedgraph ${mk}.average_sig.bedgraph.S3.bedgraph ${cell}_${id} ${mk}
line=$1
script_dir=${bin_root}
fdr_thresh=0.1
local_bg_bin=5
rank_lim=0.001
upperlim=1000
lowerlim=0
p_method=z
common_pk_binary=${mk}_commonpkfdr01_z.cpk.txt
common_bg_binary=${mk}_commonpkfdr01_z.cbg.txt
allpk_binary=${mk}_commonpkfdr01_z.allpk.txt
uniq_mk_num=${12}

# parse the line
single_raw_sig=$(echo $line | cut -d " " -f1) # ${input_dir}/${cell}.${mk}.${id}.ip.idsort.bedgraph
average_sig=$(echo $line | cut -d " " -f2) # ${mk}.average_sig.bedgraph.S3.bedgraph
cell_id=$(echo $line | cut -d " " -f3) # ${cell}_${id}
mk=$(echo $line | cut -d " " -f4) # ${mk}

# setting
outfile=${cell_id}.${mk}.S3V2.bedgraph
# log file
log=${outfile}.log
```

实际上运行的脚本是：

```shell
Rscript ${script_dir}/s3v2norm_IDEAS.R \
	${single_raw_sig} \
	${average_sig} \
	${outfile} \
	${fdr_thresh} \
	${local_bg_bin} \
	F \
	${rank_lim} \
	${upperlim} \
	${lowerlim} \
	${p_method} \
	${common_pk_binary} \
	${common_bg_binary} \
	${allpk_binary} \
	${uniq_mk_num} 1>>${log} 2>>${log}
```

接下来让我们去检查 `s3v2norm_IDEAS.R` 脚本。

###### 3.1.1.1 s3v2norm_IDEAS.R

该脚本是作用是：将所有 `${cell}.${mk}.${id}.ip.idsort.bedgraph` 文件（`input_target`）的信号值拉到与 `${mk}.average_sig.bedgraph.S3.bedgraph` （`input_ref`）水平一致。

该脚本做的事如下：

1. 读入 `input_ref`（`d1`），`input_target` （`d2`）文件的信号值
2. 读入 `${common_pk_binary}` 文件，并提取 `common_pk` 区域，计算 `input_target` 文件 `common_pk` 区域中非0的最小值 `d2_cpk_non0_min`，如果 `d2_cpk_non0_min<1` 则将该文件名输出到 `${cell_id}.${mk}.S3V2.bedgraph.low.value.txt` （意味着：这个文件中记录的文件都不可用）
3. 限制 `d1` 和 `22` 中所有的信号值，取值范围在默认设置值中 【0,1000】
4. 将 `d1` 和 `d2` 中所有的信号值转为zscale（去除top0.1%的数据），而后计算p值，而后对p进行fdr。
5. 定义pk（fdr<0.1）得到：`d1s_nb_pval_out_binary_pk`，`d2s_nb_pval_out_binary_pk`，`d1s_nb_pval_out_binary_bg`，`d2s_nb_pval_out_binary_bg`
6. 找到 `d1` 和 `d2` 中所有的 bg 区域（`d1s_nb_pval_out_binary_bg | d2s_nb_pval_out_binary_bg`）的信号值，并计算均值，得到 `d1s_lim`，`d2s_lim`
7. 读入 `${mk}_commonpkfdr01_z.allpk.txt` 文件，找到 `allpk_used_id` 区域
8. 根据信号 bin 的总数，对 bg 区域进行建模。如果bin 的总数<100000则直接建模，如果bin 的总数>=100000，则将所有的 bin 分成数个100000个bin进行建模。建模过程命令为 `get_local_bg_sig(local_bg_bin, d1/d2_sig_all, allpk_used_id, d1s/d2s_lim)` ：
   1. 原理：将数据中的pk用 `d1s/d2s_lim` 替代，这样所有的bin都为bg，然后对bg进行模拟建模。这一步是将所有pk进行替换。
   2. `local_bg_bin=5`，表示将附近5个bin作为local的bg
   3. `d1/d2_sig_all`：`d1/d2` 所有的信号值
   4. `allpk_used_id`：所有 `${cell}.${mk}.${id}.ip.idsort.bedgraph` 文件共有的 `pk`
   5. `d1s/d2s_lim`：`d1/d2` 2个文件所有 bg 区域的信号均值
   6. 构建 `d_exp_pkb_sig` 数据框，该数据框每一行记录了一个bin的信息，我以第10个bin为例介绍：
      - 第1列: 第10个bin的raw signal
      - 第2列: 第10个bin的common peakID （T or F）
      - 第3-7列: 第9->5个bin的common peakID （T or F）
      - 第8-12列: 第11->15个bin的common peakID （T or F）
      - 第13-17列: 第9->5个bin的raw signal
      - 第18-22列: 第11->15个bin的raw signal
      - 第23列: bin ID，这里即10
   7. 对每一行（每一个bin）的数据 `x` 利用 `get_local_bg_sig_each_row(x[3:length(x)], local_bg_bin, d1s/d2s_lim, x[1], x[2])}` 进行计算 `bg` 信号：
      - `x[3:length(x)]`：见上
      - `local_bg_bin`：5
      - `d1s/d2s_lim`：`d1/d2` 2个文件所有 bg 区域的信号均值
      - `x[1]`：bin的raw signal
      - `x[2]`：bin的common peakID （T or F）
      - 如果这个bin是pk（`x[2]!=0`）：
        - 如果上下游5个bin的common peakID （T or F）**都是bg**，那么 `sig_bg_tmp` 就等于这10个bin的最大值
        - 如果上下游5个bin的common peakID （T or F）**都是pk**，那么 `sig_bg_tmp` 就等于 `d1s/d2s_lim`
        - 如果上下游5个bin的common peakID （T or F）中**同时有pk和bg**，那么 `sig_bg_tmp` 就等于这10个bin中**bg区域信号的最大值**
      - 如果这个bin是bg（`x[2]==0`）： `sig_bg_tmp` 就等于`x[1]`
   8. 替换pk后，分别得到了均为bg的 `d1_exp_pkb_sig_bg_sig`，`d2_exp_pkb_sig_bg_sig` 数据进行后续建模。
9. **normalization过程中原理**：
   1. **pk**区域：**指数**分布建模，公式 `Norm_dat = dat^B`
   2. **bg**区域：**线性**分布建模，公式 `Norm_dat = B*dat+A`
   3. 读入 `${mk}_commonpkfdr01_z.cpk.txt`，将common_pk区域定义为 `cpk_id`
   4. 读入 `${mk}_commonpkfdr01_z.cbg.txt`，将common_bg区域定义为 `cbg_id`
   5. 估算**pk**区域模型参数：
      1. 计算 `pk` 区域的信号值，用**原始信号值减去 `get_local_bg_sig` 得到的bg信号**，得到：`d1pk_sig`，`d2pk_sig`
      2. 如果 `cpk_id` 的pk数目 > 总bin数的0.001【rank_lim】：`getsf_pk_LM_A0(d2pk_sig[cpk_id], d1[cpk_id])`
      3. 如果 `cpk_id` 的pk数目 <= 总bin数的0.001【rank_lim】：`cpk_id` 则用 `(d1s_nb_pval_out_binary_pk) & (d2s_nb_pval_out_binary_pk)` 来定义，而后再运行 `getsf_pk_LM_A0(d2pk_sig[cpk_id], d1[cpk_id])`
      4. 关于 `getsf_pk_LM_A0` 函数干的事：
         - `d2pk_sig[cpk_id]`： `input_target` （`d2`）中cpk区域信号值（原始值减去bg信号值）
         - `d1[cpk_id]`： `input_ref`（`d1`）中cpk区域原始信号值
         - 利用上述值，根据 `Norm_dat = dat^B` 计算出B值
         - 返回 `pksf` 变量: c(B, 0.0)
   6. 估算**bg**区域模型参数：
      1. 只需要针对 `input_target` （`d2`）中 `d2_exp_pkb_sig_bg_sig` 进行计算
      2. `getsf_bg(d2bg_sig[cbg_id], d1[cbg_id])`：
         - `a=d2bg_sig[cbg_id]`： `input_target` （`d2`）中cbg区域信号值（原始值减去bg信号值）
         - `b=d1[cbg_id]`： `input_ref`（`d1`）中cpk区域原始信号值
         - 利用上述值，根据 `Norm_dat = B*dat+A` 计算出A及B值：
           - `B = sd(b)/sd(a)`
           - `A = mean(b) - mean(a)/sd(a)*sd(b)`
   7. norm bg：`d2bg_sig_norm = d2_exp_pkb_sig_bg_sig*b + a`
   8. （修改）d2bg_sig_norm[d2bg_sig<0] = 0
   9. norm pk1：`d2pk_sig_norm = d2pk_sig`
   10. norm pk2：`d2pk_sig_norm[allpk_used_id] = (d2pk_sig_norm[allpk_used_id]^b) * (2^a)`
   11. norm sig：norm_pk + norm_bg
   12. 限制 `norm sig` 中所有的信号值，取值范围在默认设置值中 【0,1000】
   13. 结果导出：
       1. normalization之后数据：`${cell_id}.${mk}.S3V2.bedgraph`
       2. normalization中的参数：`${cell_id}.${mk}.S3V2.bedgraph.info.txt`

#### 3.1.2 get_average_sig.R脚本

在使用该脚本计算mean值前，先处理得到 `${mk}.getave_nbp.list.txt` 文件，内容如下：

```shell
${cell}_${id}.${mk}.S3V2.bedgraph	${cell}.${mk}.${id}.ctrl.idsort.bedgraph.norm.bedgraph
```

而后利用 `get_average_sig.R` 脚本对 `${mk}.getave_nbp.list.txt` 文件第1列的所有文件计算mean值，脚本的输出结果有2个：

1. `${mk}.average_sig.bedgraph.S3V2.ave.bedgraph`：经过normalization后数据的均值
2. `${mk}.average_sig.bedgraph.S3V2.ave.bedgraph.notused.files.txt`：计算均值时没有使用的文件，原因是该文件的所有信号值的均值是NA，或者最大值=0



### 4. S3V2 across CT samples

根据 `${metadata}` 文件制作 `all.ctrl.list.txt`，内容如下：

```shell
${cell}.${mk}.${id}.ctrl.idsort.bedgraph
```

根据运行脚本 `non0scale.R`：

```shell
Rscript ${bin_root}/non0scale.R all.ctrl.list.txt
```

脚本 `non0scale.R` 做的事：

1. 读入所有 `all.ctrl.list.txt` 中的CT样本数据，组成一个matrix，名为 `dat` 的变量
2. 从 `dat` 中随机不放回抽样 100000 个bin用于计算，抽取的matrix为 `dmat_s`
3. 将 `dmat_s` 去除所有的0，而后计算均值 `average_non0mean` 和方差 `average_non0sd`
4. 对 `dat` 中所有CT样本的信号值进行normalization，使用函数 `non0scale(sig, average_non0mean, average_non0sd)`：
   - **线性**分布建模，公式 `Norm_dat = B*sig+A`
   - `sig`：CT样本的所有信号值
   - `average_non0mean`：抽样记录的非0mean值
   - `average_non0sd`：抽样记录的非0sd值
   - 先拿到所有非0的 `sig` 值
   - 得到非0 `sig` 值的mean值和sd值：`sig_non0_mean` 和 `sig_non0_sd`
   - 利用上述值，根据 `Norm_dat = B*dat+A` 计算出A及B值：
     - `B = average_non0sd/sig_non0_sd`
     - `A = average_non0mean - average_non0mean/sig_non0_sd*average_non0sd`
5. 对CT数值进行normalization：`sig * B + A`
6. 对normalization后的CT数值进行范围限定：所有<0的均设置为0
7. 脚本的输出结果有2个：
   1. `${cell}.${mk}.${id}.ctrl.idsort.bedgraph.norm.bedgraph`：经过normalization后的CT数据
   2. `${cell}.${mk}.${id}.ctrl.idsort.bedgraph.norm.bedgraph.info.txt`：normalization中的参数



### 5. Get NBP for S3V2 normalized data

对每个 `${mk}` 进行如下分析：

```shell
Rscript ${bin_root}/global_nbp_NB_cm.ok.R ${mk}.getave_nbp.list.txt ${mk}.average_sig.bedgraph.S3V2.ave.bedgraph
```

这里面涉及到 `${mk}.getave_nbp.list.txt` 文件，内容为：

```shell
$ cat ${mk}.getave_nbp.list.txt
${cell}_${id}.${mk}.S3V2.bedgraph	${cell}.${mk}.${id}.ctrl.idsort.bedgraph.norm.bedgraph
```

`${mk}.average_sig.bedgraph.S3V2.ave.bedgraph` 文件则为所有 `${cell}_${id}.${mk}.S3V2.bedgraph` 信号值的均值。

接下来对 `global_nbp_NB_cm.ok.R` 脚本进行分析。

#### 5.1 global_nbp_NB_cm.ok.R

该脚本利用 `${mk}.average_sig.bedgraph.S3V2.ave.bedgraph` 文件计算NB分布中 `s` 和 `p` 参数，而后根据 s3v2norm后的EXP和CT文件进行计算P值：

- s3v2norm后的EXP：`${cell_id}.${mk}.S3V2.bedgraph`
- s3v2norm后的CT：`${cell}.${mk}.${id}.ctrl.idsort.bedgraph.norm.bedgraph`

下面一步步来看 `global_nbp_NB_cm.ok.R` 脚本是怎么实现的：

##### 5.1.1 利用$mk平均值文件计算NB模型参数

1. 读入 `${mk}.average_sig.bedgraph.S3V2.ave.bedgraph` 文件，得到信号值 `AVEmat_cbg`
2. 将信号值 `AVEmat_cbg` 小于1的都当作0（负二项分布是整数）
3. 取出信号值大于10的值，排序找出top100的值，并计算mean值 `top_mean`
   1. 如果  `top_mean` 小于200：`scale_down=1`
   2. 如果  `top_mean` 大于200：`(scale_down=200/top_mean) < 1`
4. 计算 `NB_thresh`： `top_mean*scale_down*0.01`
   1. 如果  `top_mean` 小于200：`scale_down=1`，所以 `NB_thresh<2`
   2. 如果  `top_mean` 大于200：`scale_down<1`，所以 `NB_thresh` 同样应该是在2附近
   3. 如果 `NB_thresh<1`，则 `NB_thresh=1`
5. 一般而言，`scale_down=1`，`NB_thresh=1`
6. 将 `AVEmat_cbg` 转为整数，并计算非0最小值 `min_non0`
7. 对信号值进行缩放，`(AVEmat_cbg-min_non0)*scale_down+min_non0`
8. 限制缩放后的数据范围【0，200】
9. 去除 `AVEmat_cbg` 中超过非0 `AVEmat_cbg` 的Q95值，这些是离群异常大的值
10. 对过滤后的数据拟合 `NB` 模型，利用函数 `get_true_NB_prob_size(AVEmat_cbg, NB_thresh)`：
    1. （修改）求PS参数时，只运行了1次，得到模型可能不准
    2. 只使用大于等于 `NB_thresh` 的值进行估算 NB 模型。
    3. 估算得到 `P`（`AVEmat_cbg_prob`）和 `S`（`AVEmat_cbg_size`）参数

这里计算得到的4个数据在后续有用：

- `scale_down`：数据缩放系数，一般为1
- `AVEmat_cbg_size`：NB模型参数
- `AVEmat_cbg_prob`：NB模型参数

##### 5.1.2 $mk平均值带入NB模型计算P值

1. 读入 `${mk}.average_sig.bedgraph.S3V2.ave.bedgraph` 文件，得到信号值 `mk_average_sig`
2. 计算 `mk_average_sig` 非0最小值 `min_non0`
3. 数据缩放：`sig = (mk_average_sig-min_non0)*scale_down + min_non0`
4. 对缩放后的数据，带入 NB 模型计算P值：`pnbinom(sig , AVEmat_cbg_size, AVEmat_cbg_prob, lower.tail=FALSE)`
5. 限制P值范围【1e-323，1】
6. 转为 `-log10(IP_nb_pval)`
7. 脚本的输出结果有2个：
   1. `${mk}.average_sig.bedgraph.S3V2.ave.bedgraph.NBP.bedgraph`：normalization后的数据，拟合到NB模型后，取 `-log10(IP_nb_pval)`
   2. `${mk}.average_sig.bedgraph.S3V2.ave.bedgraph.NBP.bedgraph.info.txt`：normalization后的数据，拟合到NB模型时，NB模型的参数 `AVEmat_cbg_prob`，`AVEmat_cbg_size`，`scale_down`

##### 5.1.3 对所有$mk经过s3v2处理后的信号带入NB模型计算P值

1. 读入 `${mk}.getave_nbp.list.txt` 文件，该文件分别记录了EXP和CT进行s3v2 norm后的数据，分别对这2列数据处理
2. 对EXP的信号值 `IP_tmp` ：
   1. 计算 `IP_tmp` 非0最小值 `min_non0`
   2. 数据缩放：`IP_tmp = (IP_tmp-min_non0)*scale_down+min_non0`
3. 对CT的信号值 `CTRL_tmp` ：
   1. 计算mean值：`CTRL_tmp_mean`
   2. 计算矫正后的S参数：`CTRL_tmp_adj = (CTRL_tmp+1)/(CTRL_tmp_mean+1)*AVEmat_cbg_size`
4. 带入 NB 模型计算P值：`pnbinom(IP_tmp, CTRL_tmp_adj, AVEmat_cbg_prob, lower.tail=FALSE)`
5. 限制P值范围【1e-323，1】
6. 转为 `-log10(IP_nb_pval)`
7. 脚本的输出结果：
   - `${cell}_${id}.${mk}.S3V2.bedgraph.NBP.bedgraph`：normalization后的数据，拟合到NB模型后，取 `-log10(IP_nb_pval)`




























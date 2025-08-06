Usage Manual
============

Content
=======

.. contents:: 
    :local:

1. Installation
+++++++++++++++

The chromIDEAS has been upon on the conda platform, allowing for one-click installation via conda:

.. code-block:: sh

    conda install fatyang::chromideas

2. Test Data
++++++++++++

We provide various epigenetic signal data from human umbilical cord blood HSPC cells (CD34+) and human leukemia cell line (THP1). For the convenience of calculation, we only use the data on **chr1**.

The test data can be downloaded through the following link:

.. code-block:: sh

  $ wget -U "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0" -c "https://figshare.com/ndownloader/files/56572916" -O chr1_cd34_thp1.tar.gz
  $ tar xzf chr1_cd34_thp1.tar.gz

3. Running chromIDEAS
+++++++++++++++++++++

3.1 Input Preparation
---------------------

3.1.1 metadata.txt
******************

When running chromatin state segmentation, we need to provide a metadata file to inform the program of the files corresponding to different epigenetic signals in different cells.

We will create a new file named `metadata.txt`, and then add the following content to it::

  cd34	H3K27ac	rep3	./1.raw_bw/cd34_H3K27ac_rep3_SE.bw	./1.raw_bw/cd34_input_rep18_SE.bw
  cd34	H3K27ac	rep4	./1.raw_bw/cd34_H3K27ac_rep4_SE.bw	./1.raw_bw/cd34_input_rep5_SE.bw
  cd34	H3K27ac	rep5	./1.raw_bw/cd34_H3K27ac_rep5_SE.bw	./1.raw_bw/cd34_input_rep15_SE.bw
  cd34	H3K27me3	rep11	./1.raw_bw/cd34_H3K27me3_rep11_SE.bw	./1.raw_bw/cd34_input_rep18_SE.bw
  cd34	H3K27me3	rep1	./1.raw_bw/cd34_H3K27me3_rep1_SE.bw	./1.raw_bw/cd34_input_rep2_SE.bw
  cd34	H3K27me3	rep2	./1.raw_bw/cd34_H3K27me3_rep2_SE.bw	./1.raw_bw/cd34_input_rep8_SE.bw
  cd34	H3K27me3	rep3	./1.raw_bw/cd34_H3K27me3_rep3_SE.bw	./1.raw_bw/cd34_input_rep1_SE.bw
  cd34	H3K27me3	rep4	./1.raw_bw/cd34_H3K27me3_rep4_SE.bw	./1.raw_bw/cd34_input_rep12_SE.bw
  cd34	H3K27me3	rep5	./1.raw_bw/cd34_H3K27me3_rep5_SE.bw	./1.raw_bw/cd34_input_rep5_SE.bw
  cd34	H3K27me3	rep6	./1.raw_bw/cd34_H3K27me3_rep6_SE.bw	./1.raw_bw/cd34_input_rep6_SE.bw
  cd34	H3K27me3	rep7	./1.raw_bw/cd34_H3K27me3_rep7_SE.bw	./1.raw_bw/cd34_input_rep4_SE.bw
  cd34	H3K27me3	rep8	./1.raw_bw/cd34_H3K27me3_rep8_SE.bw	./1.raw_bw/cd34_input_rep10_SE.bw
  cd34	H3K27me3	rep9	./1.raw_bw/cd34_H3K27me3_rep9_SE.bw	./1.raw_bw/cd34_input_rep11_SE.bw
  cd34	H3K36me3	rep10	./1.raw_bw/cd34_H3K36me3_rep10_SE.bw	./1.raw_bw/cd34_input_rep18_SE.bw
  cd34	H3K36me3	rep1	./1.raw_bw/cd34_H3K36me3_rep1_SE.bw	./1.raw_bw/cd34_input_rep1_SE.bw
  cd34	H3K36me3	rep2	./1.raw_bw/cd34_H3K36me3_rep2_SE.bw	./1.raw_bw/cd34_input_rep4_SE.bw
  cd34	H3K36me3	rep3	./1.raw_bw/cd34_H3K36me3_rep3_SE.bw	./1.raw_bw/cd34_input_rep12_SE.bw
  cd34	H3K36me3	rep4	./1.raw_bw/cd34_H3K36me3_rep4_SE.bw	./1.raw_bw/cd34_input_rep5_SE.bw
  cd34	H3K36me3	rep6	./1.raw_bw/cd34_H3K36me3_rep6_SE.bw	./1.raw_bw/cd34_input_rep2_SE.bw
  cd34	H3K36me3	rep7	./1.raw_bw/cd34_H3K36me3_rep7_SE.bw	./1.raw_bw/cd34_input_rep3_SE.bw
  cd34	H3K36me3	rep8	./1.raw_bw/cd34_H3K36me3_rep8_SE.bw	./1.raw_bw/cd34_input_rep10_SE.bw
  cd34	H3K36me3	rep9	./1.raw_bw/cd34_H3K36me3_rep9_SE.bw	./1.raw_bw/cd34_input_rep11_SE.bw
  cd34	H3K4me1	rep1	./1.raw_bw/cd34_H3K4me1_rep1_SE.bw	./1.raw_bw/cd34_input_rep2_SE.bw
  cd34	H3K4me1	rep2	./1.raw_bw/cd34_H3K4me1_rep2_SE.bw	./1.raw_bw/cd34_input_rep3_SE.bw
  cd34	H3K4me1	rep3	./1.raw_bw/cd34_H3K4me1_rep3_SE.bw	./1.raw_bw/cd34_input_rep4_SE.bw
  cd34	H3K4me1	rep4	./1.raw_bw/cd34_H3K4me1_rep4_SE.bw	./1.raw_bw/cd34_input_rep10_SE.bw
  cd34	H3K4me1	rep5	./1.raw_bw/cd34_H3K4me1_rep5_SE.bw	./1.raw_bw/cd34_input_rep5_SE.bw
  cd34	H3K4me1	rep6	./1.raw_bw/cd34_H3K4me1_rep6_SE.bw	./1.raw_bw/cd34_input_rep8_SE.bw
  cd34	H3K4me1	rep7	./1.raw_bw/cd34_H3K4me1_rep7_SE.bw	./1.raw_bw/cd34_input_rep1_SE.bw
  cd34	H3K4me1	rep8	./1.raw_bw/cd34_H3K4me1_rep8_SE.bw	./1.raw_bw/cd34_input_rep11_SE.bw
  cd34	H3K4me1	rep9	./1.raw_bw/cd34_H3K4me1_rep9_SE.bw	./1.raw_bw/cd34_input_rep15_SE.bw
  cd34	H3K4me3	rep10	./1.raw_bw/cd34_H3K4me3_rep10_SE.bw	./1.raw_bw/cd34_input_rep11_SE.bw
  cd34	H3K4me3	rep1	./1.raw_bw/cd34_H3K4me3_rep1_SE.bw	./1.raw_bw/cd34_input_rep2_SE.bw
  cd34	H3K4me3	rep2	./1.raw_bw/cd34_H3K4me3_rep2_SE.bw	./1.raw_bw/cd34_input_rep3_SE.bw
  cd34	H3K4me3	rep3	./1.raw_bw/cd34_H3K4me3_rep3_SE.bw	./1.raw_bw/cd34_input_rep8_SE.bw
  cd34	H3K4me3	rep4	./1.raw_bw/cd34_H3K4me3_rep4_SE.bw	./1.raw_bw/cd34_input_rep9_SE.bw
  cd34	H3K4me3	rep5	./1.raw_bw/cd34_H3K4me3_rep5_SE.bw	./1.raw_bw/cd34_input_rep1_SE.bw
  cd34	H3K4me3	rep6	./1.raw_bw/cd34_H3K4me3_rep6_SE.bw	./1.raw_bw/cd34_input_rep4_SE.bw
  cd34	H3K4me3	rep7	./1.raw_bw/cd34_H3K4me3_rep7_SE.bw	./1.raw_bw/cd34_input_rep12_SE.bw
  cd34	H3K4me3	rep8	./1.raw_bw/cd34_H3K4me3_rep8_SE.bw	./1.raw_bw/cd34_input_rep6_SE.bw
  cd34	H3K4me3	rep9	./1.raw_bw/cd34_H3K4me3_rep9_SE.bw	./1.raw_bw/cd34_input_rep10_SE.bw
  cd34	H3K9me3	rep1	./1.raw_bw/cd34_H3K9me3_rep1_SE.bw	./1.raw_bw/cd34_input_rep4_SE.bw
  cd34	H3K9me3	rep2	./1.raw_bw/cd34_H3K9me3_rep2_SE.bw	./1.raw_bw/cd34_input_rep1_SE.bw
  cd34	H3K9me3	rep3	./1.raw_bw/cd34_H3K9me3_rep3_SE.bw	./1.raw_bw/cd34_input_rep12_SE.bw
  cd34	H3K9me3	rep4	./1.raw_bw/cd34_H3K9me3_rep4_SE.bw	./1.raw_bw/cd34_input_rep6_SE.bw
  cd34	H3K9me3	rep5	./1.raw_bw/cd34_H3K9me3_rep5_SE.bw	./1.raw_bw/cd34_input_rep5_SE.bw
  cd34	H3K9me3	rep6	./1.raw_bw/cd34_H3K9me3_rep6_SE.bw	./1.raw_bw/cd34_input_rep8_SE.bw
  cd34	H3K9me3	rep7	./1.raw_bw/cd34_H3K9me3_rep7_SE.bw	./1.raw_bw/cd34_input_rep2_SE.bw
  cd34	H3K9me3	rep8	./1.raw_bw/cd34_H3K9me3_rep8_SE.bw	./1.raw_bw/cd34_input_rep3_SE.bw
  cd34	H3K9me3	rep9	./1.raw_bw/cd34_H3K9me3_rep9_SE.bw	./1.raw_bw/cd34_input_rep10_SE.bw
  cd34	H3K27me3	rep12	./1.raw_bw/cd34_H3K27me3_rep12_PE.bw	./1.raw_bw/cd34_input_rep19_PE.bw
  cd34	H3K27me3	rep13	./1.raw_bw/cd34_H3K27me3_rep13_PE.bw	./1.raw_bw/cd34_input_rep20_PE.bw
  cd34	H3K27me3	rep14	./1.raw_bw/cd34_H3K27me3_rep14_PE.bw	./1.raw_bw/cd34_input_rep21_PE.bw
  cd34	H3K27me3	rep15	./1.raw_bw/cd34_H3K27me3_rep15_SE.bw
  cd34	H3K4me3	rep11	./1.raw_bw/cd34_H3K4me3_rep11_PE.bw	./1.raw_bw/cd34_input_rep19_PE.bw
  cd34	H3K4me3	rep12	./1.raw_bw/cd34_H3K4me3_rep12_PE.bw	./1.raw_bw/cd34_input_rep20_PE.bw
  cd34	H3K4me3	rep13	./1.raw_bw/cd34_H3K4me3_rep13_SE.bw
  cd34	H3K79me2	rep2	./1.raw_bw/cd34_H3K79me2_rep2_PE.bw	./1.raw_bw/cd34_input_rep19_PE.bw
  cd34	H3K79me2	rep3	./1.raw_bw/cd34_H3K79me2_rep3_PE.bw	./1.raw_bw/cd34_input_rep20_PE.bw
  cd34	H3K79me2	rep4	./1.raw_bw/cd34_H3K79me2_rep4_PE.bw	./1.raw_bw/cd34_input_rep21_PE.bw
  thp1	H3K36me3	rep1	./1.raw_bw/thp1_H3K36me3_rep1_PE.bw	./1.raw_bw/thp1_mock_rep1_PE.bw
  thp1	H3K36me3	rep2	./1.raw_bw/thp1_H3K36me3_rep2_PE.bw	./1.raw_bw/thp1_mock_rep1_PE.bw
  thp1	H3K36me3	rep3	./1.raw_bw/thp1_H3K36me3_rep3_PE.bw	./1.raw_bw/thp1_mock_rep2_PE.bw
  thp1	H3K36me3	rep4	./1.raw_bw/thp1_H3K36me3_rep4_PE.bw	./1.raw_bw/thp1_mock_rep2_PE.bw
  thp1	H3K79me2	rep1	./1.raw_bw/thp1_H3K79me2_rep1_PE.bw	./1.raw_bw/thp1_input_rep3_PE.bw
  thp1	H3K27me3	rep3	./1.raw_bw/thp1_H3K27me3_rep3_PE.bw	./1.raw_bw/thp1_input_rep4_PE.bw
  thp1	H3K27me3	rep4	./1.raw_bw/thp1_H3K27me3_rep4_PE.bw	./1.raw_bw/thp1_input_rep4_PE.bw
  thp1	H3K27ac	rep2	./1.raw_bw/thp1_H3K27ac_rep2_PE.bw	./1.raw_bw/thp1_input_rep4_PE.bw
  thp1	H3K27ac	rep3	./1.raw_bw/thp1_H3K27ac_rep3_PE.bw	./1.raw_bw/thp1_input_rep4_PE.bw
  thp1	H3K4me1	rep2	./1.raw_bw/thp1_H3K4me1_rep2_PE.bw	./1.raw_bw/thp1_input_rep4_PE.bw
  thp1	H3K4me1	rep3	./1.raw_bw/thp1_H3K4me1_rep3_PE.bw	./1.raw_bw/thp1_input_rep4_PE.bw
  thp1	H3K4me3	rep2	./1.raw_bw/thp1_H3K4me3_rep2_PE.bw	./1.raw_bw/thp1_input_rep4_PE.bw
  thp1	H3K4me3	rep3	./1.raw_bw/thp1_H3K4me3_rep3_PE.bw	./1.raw_bw/thp1_input_rep4_PE.bw
  thp1	H3K9me3	rep3	./1.raw_bw/thp1_H3K9me3_rep3_PE.bw	./1.raw_bw/thp1_input_rep4_PE.bw
  thp1	H3K9me3	rep4	./1.raw_bw/thp1_H3K9me3_rep4_PE.bw	./1.raw_bw/thp1_input_rep4_PE.bw
  cd34	ATAC	rep1	./1.raw_bw/cd34_ATAC_rep1_PE.bw
  cd34	ATAC	rep2	./1.raw_bw/cd34_ATAC_rep2_PE.bw
  thp1	ATAC	rep3	./1.raw_bw/thp1_ATAC_rep3_PE.bw
  thp1	ATAC	rep4	./1.raw_bw/thp1_ATAC_rep4_PE.bw

Each row represents a dataset of epigenetic modification signals for cells, separated by "tab". The format is described as follows:

- col1: Cell type
- col2: Epigenetic modification type
- col3: biological replicate
- col4: Address of the experimental group dataset
- col5: (Optional) Corresponding control dataset address

3.1.2 Genome Length
*******************

Since we only used data from chr1 here, we need to specify the specific genome length.

We can create a new file, name it `chr1.txt`, and fill it with the following content::

  chr1	248956422

Each line represents the length of a piece of chromatin, separated by "tab". The format is described as follows:

- col1: chromosome number
- col2: Chromosome length

3.1.3 Blacklist (optional)
**************************

We can exclude some potentially problematic areas by specifying a blacklist file. The specific file can be downloaded as specified below:

.. code-block:: sh

    $ wget https://github.com/Boyle-Lab/Blacklist/raw/master/lists/hg38-blacklist.v2.bed.gz
    $ gunzip https://github.com/Boyle-Lab/Blacklist/raw/master/lists/hg38-blacklist.v2.bed.gz


3.1.4 File management
*********************

Before starting the operation, let's organize the relevant files that have been prepared:

.. code-block:: sh

    $ mkdir -p 0.sup_dat 1.raw_bw
    $ mv metadata.txt chr1.txt hg38-blacklist.v2.bed 0.sup_dat
    $ mv *.bw 1.raw_bw
    $ tree
    .
    ├── 0.sup_dat
    │   ├── chr1.txt
    │   ├── hg38-blacklist.v2.bed
    │   └── metadata.txt
    ├── 1.raw_bw
    │   ├── cd34_ATAC_rep1_PE.bw
    │   ├── cd34_ATAC_rep2_PE.bw
    │   ├── cd34_H3K27ac_rep3_SE.bw
    │   ├── cd34_H3K27ac_rep4_SE.bw
    ......
    │   ├── thp1_input_rep4_PE.bw
    │   ├── thp1_mock_rep1_PE.bw
    │   └── thp1_mock_rep2_PE.bw
    └── chr1_cd34_thp1.tar.gz

3.2 Chromatin State Segmentation
--------------------------------

3.2.1 One-command execution
***************************

We can use the following command to obtain the chromatin state results with one click:

.. code-block:: sh

    $ time chromIDEAS -m 0.sup_dat/metadata.txt -o 2.CS_Segmentation/ -b 200 -g 0.sup_dat/chr1.txt -n hg38_chr1 -B 0.sup_dat/hg38-blacklist.v2.bed -c -d chr1 -p 20
    Now process (1) genomeWindows.
    Process (1) genomeWindows done successfully.
    ------------------------------------------------------------------------
    
    Now process (2) bigWig2bedGraph.
    The /share/home/fatyang/2.CS_Segmentation/1.bigWig2bedGraph directory is not exist. The program will create it.
    ################# Multiple mode #################
    ./1.raw_bw/cd34_H3K27me3_rep2_SE.bw has been converted to bedgraph format succussfully.
    ./1.raw_bw/cd34_H3K27me3_rep13_PE.bw has been converted to bedgraph format succussfully.
    ./1.raw_bw/cd34_H3K27ac_rep5_SE.bw has been converted to bedgraph format succussfully.
    ...
    All bigWig files have been convert to bedGraph.
    Process (2) bigWig2bedGraph done successfully.
    ------------------------------------------------------------------------
    
    The /share/home/fatyang/2.CS_Segmentation/2.s3v2Norm directory is not exist. The program will create it.
    Now process (3) s3v2norm.
    ########################## s3v2Norm Start ##########################
    [1] "/share/home/fatyang/2.CS_Segmentation/1.bigWig2bedGraph/cd34.H3K9me3.rep1.ip.idsort.bedgraph.gz"
    [1] "/share/home/fatyang/2.CS_Segmentation/1.bigWig2bedGraph/cd34.H3K27ac.rep3.ip.idsort.bedgraph.gz"
    [1] "/share/home/fatyang/2.CS_Segmentation/1.bigWig2bedGraph/cd34.H3K79me2.rep2.ip.idsort.bedgraph.gz"
    ...
    1.Get cpk cbg allpk average_sig done
    2.S3norm average across marks done
            3.S3V2 across samples   ATAC done
            3.S3V2 across samples   H3K27ac done
            3.S3V2 across samples   H3K27me3 done
            3.S3V2 across samples   H3K36me3 done
            3.S3V2 across samples   H3K4me1 done
            3.S3V2 across samples   H3K4me3 done
            3.S3V2 across samples   H3K79me2 done
            3.S3V2 across samples   H3K9me3 done
    3.S3V2 across samples with same mk done
    4.S3V2 across CT samples done
    5.Get NBP for S3V2 normalized data done
    All bedGraph files have been convert to bigWig.
    6.Convert the bedgraph file into bigWig format.
    ########################## s3v2Norm End ##########################
    
    Summary for normalization:
    Ready to show Summary: 3s
    Ready to show Summary: 2s
    Ready to show Summary: 1s
    #=============================================Summary for normalization=============================================#
    ############# 1: get cpk cbg allpk average_sig #############
    Nothing requiring additional attention
    
    
    ############# 2: S3norm average across marks #############
    The normalization parameters (norm=A*raw^B):
            1) ATAC:
                    Mean_ratio           S3norm_B            S3norm_A
                    0.31912402579647464  0.6911416007650284  0.5208180030840445
            2) H3K27ac:
                    Mean_ratio          S3norm_B            S3norm_A
                    0.2642206363218819  0.6683547414300661  0.5435931404498152
            3) H3K27me3:
                    Mean_ratio          S3norm_B            S3norm_A
                    0.4239141842940278  1.0985441458588523  0.4174344884621977
            4) H3K36me3:
                    Mean_ratio          S3norm_B            S3norm_A
                    0.5963609714221206  1.0686476970950924  0.6252879289145848
            5) H3K4me1:
                    Mean_ratio          S3norm_B            S3norm_A
                    0.4325845586543525  0.9183362183254749  0.5464312537007742
            6) H3K4me3:
                    Mean_ratio           S3norm_B           S3norm_A
                    0.42192289933009874  0.665722690663896  0.720874862499352
            7) H3K79me2:
                    Mean_ratio           S3norm_B           S3norm_A
                    0.20716204795844023  0.854490378839077  0.2992704109344474
            8) H3K9me3:
                    Mean_ratio           S3norm_B            S3norm_A
                    0.49297130091515795  1.0498449905490717  0.4729004821135292
    
    
    ############# 3: S3V2 across samples with same mk #############
    The normalization parameters:
    norm_dat = norm_pk + norm_bg
            1) cd34_rep10.H3K36me3.S3V2.bedgraph:
                    Pk region normalization parameters [exponential regression: norm=(2^A)*(raw^B)]:
                            pk_b               pk_a
                            0.860268522487943  0
                    Bg region normalization parameters [linear regression: norm=B*raw+A]:
                            bg_b               bg_a
                            0.379774849916617  -0.054080182987012
            2) cd34_rep10.H3K4me3.S3V2.bedgraph:
                    Pk region normalization parameters [exponential regression: norm=(2^A)*(raw^B)]:
                            pk_b               pk_a
                            0.831459440130634  0
                    Bg region normalization parameters [linear regression: norm=B*raw+A]:
                            bg_b               bg_a
                            0.831817269539945  -0.0950225927820069
            3) cd34_rep11.H3K27me3.S3V2.bedgraph:
                    Pk region normalization parameters [exponential regression: norm=(2^A)*(raw^B)]:
                            pk_b               pk_a
                            0.937802347054138  0
                    Bg region normalization parameters [linear regression: norm=B*raw+A]:
                            bg_b               bg_a
                            0.788937931828074  -0.56781334660776
    ...
    
    
    ############# 4: S3V2 across CT samples #############
    The normalization parameters [linear regression: norm=B*raw+A]:
            1) cd34.ATAC.rep1.ctrl.idsort.bedgraph.gz.norm.bedgraph:
                    B  A
                    1  0
            2) cd34.ATAC.rep2.ctrl.idsort.bedgraph.gz.norm.bedgraph:
                    B  A
                    1  0
            3) cd34.H3K27ac.rep3.ctrl.idsort.bedgraph.gz.norm.bedgraph:
                    B                 A
                    2.08476397079908  -8.09980879317122
    ...
    
    
    ############# 5: Get NBP for S3V2 normalized data #############
    Fit the s3v2 norm data to NB model:
            1) The normalization parameters for average signal of ATAC:
                    AVEmat_cbg_prob    AVEmat_cbg_size   scale_down
                    0.903295995216867  8.72511681090712  1
            2) The normalization parameters for average signal of H3K27ac:
                    AVEmat_cbg_prob    AVEmat_cbg_size   scale_down
                    0.839476840723447  9.03072014304272  1
            3) The normalization parameters for average signal of H3K27me3:
                    AVEmat_cbg_prob    AVEmat_cbg_size   scale_down
                    0.902594813746805  17.7791989962796  1
            4) The normalization parameters for average signal of H3K36me3:
                    AVEmat_cbg_prob    AVEmat_cbg_size   scale_down
                    0.760129737927078  7.60914042205539  1
            5) The normalization parameters for average signal of H3K4me1:
                    AVEmat_cbg_prob    AVEmat_cbg_size   scale_down
                    0.571775852101361  3.82876573811324  1
            6) The normalization parameters for average signal of H3K4me3:
                    AVEmat_cbg_prob   AVEmat_cbg_size   scale_down
                    0.57108169816322  2.68410297948551  1
            7) The normalization parameters for average signal of H3K79me2:
                    AVEmat_cbg_prob    AVEmat_cbg_size   scale_down
                    0.733551180969329  3.71929718967958  1
            8) The normalization parameters for average signal of H3K9me3:
                    AVEmat_cbg_prob    AVEmat_cbg_size   scale_down
                    0.937901568499601  22.8114694786224  1
    
    
    Process (3) s3v2Norm done successfully.
    ------------------------------------------------------------------------
    
    Now process (4) mergeBedgraph.
    ################# Multiple mode #################
    /share/home/fatyang/2.CS_Segmentation/2.s3v2Norm/chr1_bws_NBP/cd34_rep1.ATAC.S3V2.bedgraph.NBP.bedgraph.bw has been converted to bedgraph format succussfully.
    /share/home/fatyang/2.CS_Segmentation/2.s3v2Norm/chr1_bws_NBP/cd34_rep10.H3K4me3.S3V2.bedgraph.NBP.bedgraph.bw has been converted to bedgraph format succussfully.
    /share/home/fatyang/2.CS_Segmentation/2.s3v2Norm/chr1_bws_NBP/cd34_rep13.H3K4me3.S3V2.bedgraph.NBP.bedgraph.bw has been converted to bedgraph format succussfully.
    ...
    All bigWig files have been convert to bedGraph.
    Process (4) mergeBedgraph done successfully.
    ------------------------------------------------------------------------
    
    Now process (5) ideasCS.
    
    real    45m48.857s
    user    711m49.403s
    sys     14m19.501s
    Process (5) ideasCS done successfully.
    ------------------------------------------------------------------------
    
    
    real    59m3.904s
    user    841m18.733s
    sys     28m10.912s


3.2.2 Step-by-step
******************

We can also proceed in three steps.

**(1) Normalization：**

.. code-block:: sh

    $ time s3v2Norm -b 200 -o 2.CS_Segmentation/ -m 0.sup_dat/metadata.txt -n hg38_chr1 -c -d chr1 -p 20 -g 0.sup_dat/chr1.txt -B 0.sup_dat/hg38-blacklist.v2.bed
    Now process (1) genomeWindows.
    Process (1) genomeWindows done successfully.
    ------------------------------------------------------------------------
    
    Now process (2) bigWig2bedGraph.
    The /share/home/fatyang/2.CS_Segmentation/1.bigWig2bedGraph directory is not exist. The program will create it.
    ################# Multiple mode #################
    ./1.raw_bw/cd34_H3K27ac_rep4_SE.bw has been converted to bedgraph format succussfully.
    ./1.raw_bw/cd34_H3K27me3_rep1_SE.bw has been converted to bedgraph format succussfully.
    ./1.raw_bw/cd34_H3K27ac_rep3_SE.bw has been converted to bedgraph format succussfully.
    ......
    All bigWig files have been convert to bedGraph.
    Process (2) bigWig2bedGraph done successfully.
    ------------------------------------------------------------------------
    
    The /share/home/fatyang/2.CS_Segmentation/2.s3v2Norm directory is not exist. The program will create it.
    Now process (3) s3v2norm.
    ########################## s3v2Norm Start ##########################
    [1] "/share/home/fatyang/2.CS_Segmentation/1.bigWig2bedGraph/cd34.H3K4me3.rep10.ip.idsort.bedgraph.gz"
    [1] "/share/home/fatyang/2.CS_Segmentation/1.bigWig2bedGraph/cd34.H3K27ac.rep3.ip.idsort.bedgraph.gz"
    [1] "/share/home/fatyang/2.CS_Segmentation/1.bigWig2bedGraph/cd34.ATAC.rep1.ip.idsort.bedgraph.gz"
    ...
    1.Get cpk cbg allpk average_sig done
    2.S3norm average across marks done
            3.S3V2 across samples   ATAC done
            3.S3V2 across samples   H3K27ac done
            3.S3V2 across samples   H3K27me3 done
            3.S3V2 across samples   H3K36me3 done
            3.S3V2 across samples   H3K4me1 done
            3.S3V2 across samples   H3K4me3 done
            3.S3V2 across samples   H3K79me2 done
            3.S3V2 across samples   H3K9me3 done
    3.S3V2 across samples with same mk done
    4.S3V2 across CT samples done
    5.Get NBP for S3V2 normalized data done
    All bedGraph files have been convert to bigWig.
    6.Convert the bedgraph file into bigWig format.
    ########################## s3v2Norm End ##########################
    
    Summary for normalization:
    Ready to show Summary: 3s
    Ready to show Summary: 2s
    Ready to show Summary: 1s
    #=============================================Summary for normalization=============================================#
    ############# 1: get cpk cbg allpk average_sig #############
    Nothing requiring additional attention
    
    
    ############# 2: S3norm average across marks #############
    The normalization parameters (norm=A*raw^B):
            1) ATAC:
                    Mean_ratio           S3norm_B            S3norm_A
                    0.31912402579647464  0.6911416007650284  0.5208180030840445
            2) H3K27ac:
                    Mean_ratio          S3norm_B            S3norm_A
                    0.2642206363218819  0.6683547414300661  0.5435931404498152
            3) H3K27me3:
                    Mean_ratio          S3norm_B            S3norm_A
                    0.4239141842940278  1.0985441458588523  0.4174344884621977
            4) H3K36me3:
                    Mean_ratio          S3norm_B            S3norm_A
                    0.5963609714221206  1.0686476970950924  0.6252879289145848
            5) H3K4me1:
                    Mean_ratio          S3norm_B            S3norm_A
                    0.4325845586543525  0.9183362183254749  0.5464312537007742
            6) H3K4me3:
                    Mean_ratio           S3norm_B           S3norm_A
                    0.42192289933009874  0.665722690663896  0.720874862499352
            7) H3K79me2:
                    Mean_ratio           S3norm_B           S3norm_A
                    0.20716204795844023  0.854490378839077  0.2992704109344474
            8) H3K9me3:
                    Mean_ratio           S3norm_B            S3norm_A
                    0.49297130091515795  1.0498449905490717  0.4729004821135292
    
    
    ############# 3: S3V2 across samples with same mk #############
    The normalization parameters:
    norm_dat = norm_pk + norm_bg
            1) cd34_rep10.H3K36me3.S3V2.bedgraph:
                    Pk region normalization parameters [exponential regression: norm=(2^A)*(raw^B)]:
                            pk_b               pk_a
                            0.860268522487943  0
                    Bg region normalization parameters [linear regression: norm=B*raw+A]:
                            bg_b               bg_a
                            0.379774849916617  -0.054080182987012
            2) cd34_rep10.H3K4me3.S3V2.bedgraph:
                    Pk region normalization parameters [exponential regression: norm=(2^A)*(raw^B)]:
                            pk_b               pk_a
                            0.831459440130634  0
                    Bg region normalization parameters [linear regression: norm=B*raw+A]:
                            bg_b               bg_a
                            0.831817269539945  -0.0950225927820069
            3) cd34_rep11.H3K27me3.S3V2.bedgraph:
                    Pk region normalization parameters [exponential regression: norm=(2^A)*(raw^B)]:
                            pk_b               pk_a
                            0.937802347054138  0
                    Bg region normalization parameters [linear regression: norm=B*raw+A]:
                            bg_b               bg_a
                            0.788937931828074  -0.56781334660776
    ...
    
    
    ############# 4: S3V2 across CT samples #############
    The normalization parameters [linear regression: norm=B*raw+A]:
            1) cd34.ATAC.rep1.ctrl.idsort.bedgraph.gz.norm.bedgraph:
                    B  A
                    1  0
            2) cd34.ATAC.rep2.ctrl.idsort.bedgraph.gz.norm.bedgraph:
                    B  A
                    1  0
            3) cd34.H3K27ac.rep3.ctrl.idsort.bedgraph.gz.norm.bedgraph:
                    B                 A
                    2.08476397079908  -8.09980879317122
    ...
    
    
    ############# 5: Get NBP for S3V2 normalized data #############
    Fit the s3v2 norm data to NB model:
            1) The normalization parameters for average signal of ATAC:
                    AVEmat_cbg_prob    AVEmat_cbg_size   scale_down
                    0.903295995216867  8.72511681090712  1
            2) The normalization parameters for average signal of H3K27ac:
                    AVEmat_cbg_prob    AVEmat_cbg_size   scale_down
                    0.839476840723447  9.03072014304272  1
            3) The normalization parameters for average signal of H3K27me3:
                    AVEmat_cbg_prob    AVEmat_cbg_size   scale_down
                    0.902594813746805  17.7791989962796  1
            4) The normalization parameters for average signal of H3K36me3:
                    AVEmat_cbg_prob    AVEmat_cbg_size   scale_down
                    0.760129737927078  7.60914042205539  1
            5) The normalization parameters for average signal of H3K4me1:
                    AVEmat_cbg_prob    AVEmat_cbg_size   scale_down
                    0.571775852101361  3.82876573811324  1
            6) The normalization parameters for average signal of H3K4me3:
                    AVEmat_cbg_prob   AVEmat_cbg_size   scale_down
                    0.57108169816322  2.68410297948551  1
            7) The normalization parameters for average signal of H3K79me2:
                    AVEmat_cbg_prob    AVEmat_cbg_size   scale_down
                    0.733551180969329  3.71929718967958  1
            8) The normalization parameters for average signal of H3K9me3:
                    AVEmat_cbg_prob    AVEmat_cbg_size   scale_down
                    0.937901568499601  22.8114694786224  1
    
    
    Process (3) s3v2norm done successfully.
    ------------------------------------------------------------------------
    
    
    real    11m41.485s
    user    111m7.597s
    sys     10m7.581s

----------------------

For comparison, we processed the identical dataset with the same parameters using the `S3V2 software <https://github.com/guanjue/S3V2_IDEAS_ESMP>`_. Due to the maximum thread setting of 4 in S3V2, we set it to the maximum allowed (thread=4).
 
We also recorded the runtime:

.. code-block:: sh

    real    52m54.052s
    user    129m33.996s
    sys     13m47.043s

It can be seen that the chromIDEAS consumes 11m41.485s of time when running data standardization, while the original S3V2 consumes 52m44.052s when processing the same data.

**(2) Merge Replicates：**

.. code-block:: sh

    $ mkdir -p 2.CS_Segmentation/3.CS_segmentation/chr1_IDEAS_input_NB
    $ rm -rf 2.CS_Segmentation/3.CS_segmentation/chr1_IDEAS_input_NB/group.799[12]799.txt
    $ ls 2.CS_Segmentation/2.s3v2Norm/chr1_bws_NBP/*S3V2.bedgraph.NBP.bedgraph.bw | while read id
    do
        bedg=$(basename $id | sed -r "s/.bw$//g")
        echo -e "${id}\t2.CS_Segmentation/3.CS_segmentation/chr1_IDEAS_input_NB/${bedg}" >> 2.CS_Segmentation/3.CS_segmentation/chr1_IDEAS_input_NB/group.7991799.txt
    
        cell=$(basename $id | cut -d "_" -f1)
        mk=$(basename $id | cut -d "." -f2)
        echo -e "2.CS_Segmentation/3.CS_segmentation/chr1_IDEAS_input_NB/${bedg}\t2.CS_Segmentation/3.CS_segmentation/chr1_IDEAS_input_NB/${cell}.${mk}.S3V2.bedgraph.NBP.txt" >> 2.CS_Segmentation/3.CS_segmentation/chr1_IDEAS_input_NB/group.7992799.txt
    done
    
    $ bigWig2bedGraph -n hg38_chr1 -f 2.CS_Segmentation/3.CS_segmentation/chr1_IDEAS_input_NB/group.7991799.txt -p 20 -b 200
    ################# Multiple mode #################
    2.CS_Segmentation/2.s3v2Norm/chr1_bws_NBP/cd34_rep1.H3K36me3.S3V2.bedgraph.NBP.bedgraph.bw has been converted to bedgraph format succussfully.
    2.CS_Segmentation/2.s3v2Norm/chr1_bws_NBP/cd34_rep12.H3K4me3.S3V2.bedgraph.NBP.bedgraph.bw has been converted to bedgraph format succussfully.
    2.CS_Segmentation/2.s3v2Norm/chr1_bws_NBP/cd34_rep1.H3K27me3.S3V2.bedgraph.NBP.bedgraph.bw has been converted to bedgraph format succussfully.
    ...
    All bigWig files have been convert to bedGraph.
    
    $ mergeBedgraph -f 2.CS_Segmentation/3.CS_segmentation/chr1_IDEAS_input_NB/group.7992799.txt -m median -c pearson -p 20
    $ cut -f2 2.CS_Segmentation/3.CS_segmentation/chr1_IDEAS_input_NB/group.7991799.txt | xargs -n1 -i rm -rf {}
    $ cat 0.sup_dat/metadata.txt | while read cell mk id exp ct
    do
        echo "${cell} ${mk} 2.CS_Segmentation/3.CS_segmentation/chr1_IDEAS_input_NB/${cell}.${mk}.S3V2.bedgraph.NBP.txt"
    done | sort -u > 2.CS_Segmentation/3.CS_segmentation/chr1_IDEAS_input_NB/meta.txt
    
    $ rm -rf 2.CS_Segmentation/3.CS_segmentation/chr1_IDEAS_input_NB/group.799[12]799.txt

**(3) State Segmentation：**

.. code-block:: sh

    $ ideasCS -m s3v2/3.CS_segmentation/chr1_IDEAS_input_NB/meta.txt -o s3v2/4.chr1_IDEAS_output -d chr1 -p 20
    
    real    44m22.538s
    user    712m10.945s
    sys     11m7.006s

----------------------

For comparison, we processed the identical dataset with the same parameters using the `S3V2 software <https://github.com/guanjue/S3V2_IDEAS_ESMP>`_. Due to the maximum thread setting of 4 in S3V2, we set it to the maximum allowed (thread=4).

We also recorded the runtime:

.. code-block:: sh

    real    132m56.320s
    user    788m50.320s
    sys     15m58.419s

It can be seen that the chromIDEAS consumes 44m22.538s of time when running state segmentation, while the original S3V2 consumes 132m56.320s when processing the same data.

3.3 Chromatin State Distribution Visualization
----------------------------------------------

.. code-block:: sh

    # wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_40/gencode.v40.annotation.gtf.gz
    # gunzip gencode.v40.annotation.gtf.gz
    
    $ awk -F "\t" '{if($1 == "chr1") {print $0}}' /share/home/fatyang/Genomes/GENCODE/Human/hg38/gtf/gencode.v40.annotation.gtf > chr1.gtf
    $ plotCSprofile TSS -i 2.CS_Segmentation/4.chr1_IDEAS_output/chr1.state -o tss.jpg -r chr1.gtf -W 10 -H 10
    ############################## Prepare the CS matrix ##############################
    U5 U4 U3 U2 U1 TSS D1 D2 D3 D4 D5
    ###################################### Done #######################################
    
    ############################## Calculate cell specific CS matrix ##############################
    cd34:
    thp1:
    ############################################ Done #############################################
    
    ############################## Plot cell specific CS distribution ##############################
    ############################################# Done #############################################
    
    $ plotCSprofile Body -i 2.CS_Segmentation/4.chr1_IDEAS_output/chr1.state -o body.jpg -r chr1.gtf -p 20 -W 10 -H 10
    ############################## Prepare the CS matrix ##############################
    There are 21630/21800 TSSs of target regions have chromatin state info.
    There are 21651/21800 TESs of target regions have chromatin state info.
    There are 21628 target regions where both the TSS (21630) and TES (21651) have chromatin state information.
    The minimum length should be more than 3, including at least tss, tes, and a gene body bin.
    Filter out 898/21628 (4.15%) regions, whose length is less than 3 bins.
    U5 U4 U3 U2 U1 TSS B1 B2 B3 B4 B5 B6 B7 B8 B9 B10 TES D1 D2 D3 D4 D5
    ###################################### Done #######################################
    
    ############################## Calculate cell specific CS matrix ##############################
    cd34:
    |----------------------------------------------------------------------------------------------------|
    starting worker pid=10546 on localhost:11944 at 15:56:37.874
    starting worker pid=10539 on localhost:11944 at 15:56:37.899
    starting worker pid=10545 on localhost:11944 at 15:56:37.901
    starting worker pid=10532 on localhost:11944 at 15:56:37.901
    starting worker pid=10538 on localhost:11944 at 15:56:37.905
    starting worker pid=10534 on localhost:11944 at 15:56:37.905
    starting worker pid=10535 on localhost:11944 at 15:56:37.906
    starting worker pid=10540 on localhost:11944 at 15:56:37.912
    starting worker pid=10543 on localhost:11944 at 15:56:37.913
    starting worker pid=10544 on localhost:11944 at 15:56:37.919
    starting worker pid=10533 on localhost:11944 at 15:56:37.921
    starting worker pid=10549 on localhost:11944 at 15:56:37.922
    starting worker pid=10542 on localhost:11944 at 15:56:37.923
    starting worker pid=10551 on localhost:11944 at 15:56:37.924
    starting worker pid=10536 on localhost:11944 at 15:56:37.926
    starting worker pid=10548 on localhost:11944 at 15:56:37.929
    starting worker pid=10541 on localhost:11944 at 15:56:37.933
    starting worker pid=10547 on localhost:11944 at 15:56:37.933
    starting worker pid=10537 on localhost:11944 at 15:56:37.933
    starting worker pid=10550 on localhost:11944 at 15:56:37.937
    |***************************************************************************************************|
    *thp1:
    |----------------------------------------------------------------------------------------------------|
    starting worker pid=12018 on localhost:11944 at 15:56:57.811
    starting worker pid=12016 on localhost:11944 at 15:56:57.812
    starting worker pid=12023 on localhost:11944 at 15:56:57.819
    starting worker pid=12021 on localhost:11944 at 15:56:57.822
    starting worker pid=12030 on localhost:11944 at 15:56:57.824
    starting worker pid=12017 on localhost:11944 at 15:56:57.824
    starting worker pid=12029 on localhost:11944 at 15:56:57.825
    starting worker pid=12011 on localhost:11944 at 15:56:57.826
    starting worker pid=12028 on localhost:11944 at 15:56:57.825
    starting worker pid=12024 on localhost:11944 at 15:56:57.826
    starting worker pid=12015 on localhost:11944 at 15:56:57.826
    starting worker pid=12019 on localhost:11944 at 15:56:57.830
    starting worker pid=12025 on localhost:11944 at 15:56:57.831
    starting worker pid=12022 on localhost:11944 at 15:56:57.832
    starting worker pid=12020 on localhost:11944 at 15:56:57.834
    starting worker pid=12012 on localhost:11944 at 15:56:57.835
    starting worker pid=12026 on localhost:11944 at 15:56:57.840
    starting worker pid=12014 on localhost:11944 at 15:56:57.842
    starting worker pid=12027 on localhost:11944 at 15:56:57.842
    starting worker pid=12013 on localhost:11944 at 15:56:57.848
    |****************************************************************************************************|
    ############################################ Done #############################################
    
    ############################## Plot cell specific CS distribution ##############################
    ############################################# Done #############################################

+------------------------------+-------------------------------+
| TSS Distribution             | Body Distribution             |
+==============================+===============================+
| .. image:: ../images/tss.jpg | .. image:: ../images/body.jpg |
|    :width: 100%              |             :width: 100%      |
+------------------------------+-------------------------------+

.. image:: 
   :align: center
   :alt: tss
   :class: figures

.. image:: 
   :align: center
   :alt: body
   :class: figures

3.4 Chromatin State Similarity Assessment
-----------------------------------------

.. code-block:: sh

    $ stateCompare -f 2.CS_Segmentation/4.chr1_IDEAS_output/chr1.state -a cd34 -b thp1 -m All
      H_Cell1   H_Cell2        RI       ARI        MI        VI       NVI        ID
    1.8314815 1.9278631 0.6957417 0.2335242 0.6470431 2.4652584 0.7921014 1.2808200
          NID       NMI
    0.6643729 0.3356271

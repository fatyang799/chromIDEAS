mergeBigwig
=============

mergeBigwig is a tool to merge multiple bigwig files with multiple replicates.

.. code-block:: sh

    Usage: mergeBigwig [options] ...
        1) pre-existing window bins
        mergeBigwig -f <file_list> -m <average_method> -n <windows_name>
        2) building window bins for hg38/hg19/mm10
        mergeBigwig -f <file_list> -m <average_method> -b <bin_size> -s <species> [-n <windows_name>]
        3) building window bins for custom species
        mergeBigwig -f <file_list> -m <average_method> -b <bin_size> -g <genomesizes> -n <windows_name> [-B <blackList>]

Content
=======

.. contents:: 
    :local:

Required arguments
^^^^^^^^^^^^^^^^^^

``-f <file_list>``
  Tab-delimited file listing input/output pairs **[Default: None]**. Example::

    /PATH/TO/A_rep1.H3K36me3.bw   /PATH/TO/A.H3K36me3.bw
    /PATH/TO/A_rep2.H3K36me3.bw   /PATH/TO/A.H3K36me3.bw
    /PATH/TO/B_rep1.H3K36me3.bw   /PATH/TO/B.H3K36me3.bw
    /PATH/TO/B_rep2.H3K36me3.bw   /PATH/TO/B.H3K36me3.bw
    /PATH/TO/B_rep1.H3K9me3.bw    /PATH/TO/A.H3K9me3.bw
    /PATH/TO/B_rep2.H3K9me3.bw    /PATH/TO/A.H3K9me3.bw
    ...


``-m <average_method>``
  Merging method for signal values. Support choices: mean, median. **[Default: mean]**

``-b <bin_size>``
  Bin size (in base pairs). **[Default: 200]**

``-s <species>``
  Supported species: hg38, hg19, or mm10. Selecting this option automatically loads the corresponding  genomesizes file and blacklist file. If your species is not listed, manually provide these files via ``-g <genome_sizes> -n <windows_name> [-B <blackList>]``. **[Default: None]**

``-g <genomesizes>``
  Required if ``-s`` is unspecified. Path to a genomesizes file (tab-delimited) listing chromosome lengths **[Default: None]**. Example::

    chr1  249250621
    ...


``-n <windows_name>``
  Required if ``-s`` is unspecified. A unique name to identify the generated window bins for downstream processing. **[Default: None]**

Optional arguments
^^^^^^^^^^^^^^^^^^

``-B <blackList>``
  Path to the blacklist file (tab-delimited). If ``-s`` is set to hg38/hg19/mm10, the default blacklist is used **[Default: None]**. Example::

    chr1  200 3000
    ...


``-c <cor_method>``
  Correlation method for quality control. Support choices: spearman, pearson. **[Default: pearson]**

``-z``
  By setting this option, genomic regions that have zero or missing (nan) values in all samples are excluded. **[Default: false]**

``-l <cutoff_cor>``
  Minimum correlation threshold for QC warnings **[Default: 0.1]**

``-q``
  Disable QC warnings. **[Default: false]**

``-p <nthreads>``
  Number of parallel processes. **[Default: 4]**

``-h``
  Show this help message and exit.

``-v``
  Show program's version number and exit.
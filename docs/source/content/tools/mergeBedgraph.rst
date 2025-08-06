mergeBedgraph
=============

mergeBedgraph is a tool to merge multiple bedgraph files with multiple replicates.

.. code-block:: sh

    Usage: mergeBedgraph [options] ...

Content
=======

.. contents:: 
    :local:

Required arguments
^^^^^^^^^^^^^^^^^^

``-f <file_list>``
  Tab-delimited file listing input/output pairs **[Default: None]**. Example::

    /PATH/TO/A_rep1.H3K36me3.bedgraph   /PATH/TO/A.H3K36me3.bedgraph
    /PATH/TO/A_rep2.H3K36me3.bedgraph   /PATH/TO/A.H3K36me3.bedgraph
    /PATH/TO/B_rep1.H3K36me3.bedgraph   /PATH/TO/B.H3K36me3.bedgraph
    /PATH/TO/B_rep2.H3K36me3.bedgraph   /PATH/TO/B.H3K36me3.bedgraph
    /PATH/TO/B_rep1.H3K9me3.bedgraph    /PATH/TO/A.H3K9me3.bedgraph
    /PATH/TO/B_rep2.H3K9me3.bedgraph    /PATH/TO/A.H3K9me3.bedgraph
    ...

``-m <average_method>``
  Merging method for signal values. Support choices: mean, median. **[Default: mean]**

Optional arguments
^^^^^^^^^^^^^^^^^^

``-c <cor_method>``
  Correlation method for quality control. Support choices: spearman, pearson. **[Default: pearson]**

``-z``
  By setting this option, genomic regions that have zero or missing (nan) values in all samples are excluded. **[Default: false]**

``-l <cutoff_cor>``
  Minimum correlation threshold for QC warnings. **[Default: 0.1]**

``-q``
  Disable QC warnings. **[Default: false]**

``-p <nthreads>``
  Number of parallel processes. **[Default: 4]**

``-h``
  Show this help message and exit.

``-v``
  Show program's version number and exit.
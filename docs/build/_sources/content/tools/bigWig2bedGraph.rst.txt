bigWig2bedGraph
===============

bigWig2bedGraph converts bigWig files to bedGraph format using standardized genomic windows. Two operation modes are available:

1) Multiple File Mode: Process batches of files specified in a manifest
2) Single File Mode: Convert individual bigWig files

.. code-block:: sh

    Usage: bigWig2bedGraph [options] ...

Content
=======

.. contents:: 
    :local:

Required arguments
^^^^^^^^^^^^^^^^^^

``-n <windows_name>``
  Unique identifier for window bins (check available bins with: ``genomeWindows -l``). To create new window bins: 1) ``bigWig2bedGraph -b <size> -s <species> [...]`` OR 2) ``bigWig2bedGraph -b <size> -g <genomesizes> -n <windows_name> [-B <blackList> ...]``. **[Default: None]**

Multiple File Mode
""""""""""""""""""

``-f <file_list>``
  Tab-delimited file listing input/output pairs, required for batch mode **[Default: None]**. Example::

    /PATH/TO/H2AFZ_rep1.bw  /PATH/TO/H2AFZ_rep1.bedgraph
    /PATH/TO/H2AFZ_rep2.bw  /PATH/TO/H2AFZ_rep2.bedgraph
    ...

Single File Mode
""""""""""""""""

``-i <bigwig>``
  Input bigWig file, required for single mode. **[Default: None]**

``-o <outfile>``
  Output bedGraph file, required for single mode. **[Default: None]**

Optional arguments
^^^^^^^^^^^^^^^^^^

``-p <nthreads>``
  Number of parallel processes. **[Default: 4]**

``-z``
  Output compressed (gzipped) bedGraph files. **[Default: false]**

``-h``
  Show this help message and exit.

``-v``
  Show program's version number and exit.


Window Bin Creation
""""""""""""""""""

``-b <bin_size>``
  Bin size (in base pairs). **[Default: 200]**

``-s <species>``
  Supported species: hg38, hg19, or mm10. Selecting this option automatically loads the corresponding genomesizes file and blacklist file. If your species is not listed, manually provide these files via ``-g <genome_sizes> -n <windows_name> [-B <blackList>]``. **[Default: None]**

``-g <genomesizes>``
  Required if ``-s`` is unspecified. Path to a genomesizes file (tab-delimited) listing chromosome lengths **[Default: None]**. Example::

    chr1  249250621
    ...

``-B <blackList>``
  Path to the blacklist file (tab-delimited). If ``-s`` is set to hg38/hg19/mm10, the default blacklist is used **[Default: None]**. Example::

    chr1  200 3000
    ...

genomeWindows
=============

genomeWindows is a tool to segment the genome into equally sized and contiguous bin. The output 
files are used for downstream S3V2 normalization.

.. code-block:: sh
 
    Usage: genomeWindows [options] -b <bin_size> -s <species> [-n <windows_name>]
           genomeWindows [options] -b <bin_size> -g <genomesizes> -n <windows_name> [-B <blackList>]

Content
=======

.. contents:: 
    :local:

Required arguments
^^^^^^^^^^^^^^^^^^
``-b <bin_size>``
  Bin size (in base pairs). **[Default: 200]**

``-s <species>``
  Supported species: hg38, hg19, or mm10. Selecting this option automatically loads the corresponding  genomesizes file and blacklist file. If your species is not listed, manually provide these files via ``-g <genome_sizes> -n <windows_name> [-B <blackList>]``. **[Default: None]**

``-g <genomesizes>``
  Required if ``-s`` is unspecified. Path to a genomesizes file (tab-delimited) listing chromosome lengths **[Default: None]**. Example::

    chr1  249250621
    ...

``-n <windows_name>``
  Required if ``-s`` is unspecified. A unique name to identify the generated window bins for downstream processing **[Default: None]**.

Optional arguments
^^^^^^^^^^^^^^^^^^

``-B <blackList>``
  Path to the blacklist file (tab-delimited). If ``-s`` is set to hg38/hg19/mm10, the default blacklist is used **[Default: None]**. Example::

    chr1  200 3000
    ...

``-l``
  List available pre-built window bins and their metadata.

``-h``
  Show help message and exit.

``-v``
  Show version number and exit.

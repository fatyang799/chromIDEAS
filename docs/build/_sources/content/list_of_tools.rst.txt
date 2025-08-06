The tools
=========

.. contents:: 
    :local:

+-----------------------------+---------------------------------------+-----------------------------------+--------------------------------------------+
| Tool                        | Type                                  | Input Files                       | Main Output File(s)                        |
+=============================+=======================================+===================================+============================================+
|:doc:`tools/genomeWindows`   | Basic Coordinate Preparation          | a genome length file              | bin-based coordinate                       |
+-----------------------------+---------------------------------------+-----------------------------------+--------------------------------------------+
|:doc:`tools/bigWig2bedGraph` | Data Format Conversion                | 1 or more bigWig file(s)          | bedGraph file(s)                           |
+-----------------------------+---------------------------------------+-----------------------------------+--------------------------------------------+
|:doc:`tools/bedGraph2bigWig` | Data Format Conversion                | 1 or more bedGraph file(s)        | bigWig file(s)                             |
+-----------------------------+---------------------------------------+-----------------------------------+--------------------------------------------+
|:doc:`tools/s3v2Norm`        | Normalization                         | bigWig files and a metadata file  | Normal signal files                        |
+-----------------------------+---------------------------------------+-----------------------------------+--------------------------------------------+
|:doc:`tools/mergeBedgraph`   | Data Integration                      | 2 or more bedGraph file(s)        | 1 bedGraph file                            |
+-----------------------------+---------------------------------------+-----------------------------------+--------------------------------------------+
|:doc:`tools/mergeBigwig`     | Data Integration                      | 2 or more bigWig file(s)          | 1 bigWig file                              |
+-----------------------------+---------------------------------------+-----------------------------------+--------------------------------------------+
|:doc:`tools/ideasCS`         | Chromatin State Segmentation          | output from s3v2Norm              | bin-based chromatin state segmentation     |
+-----------------------------+---------------------------------------+-----------------------------------+--------------------------------------------+
|:doc:`tools/chromIDEAS`      | One Step Chromatin State Segmentation | bigWig files and a metadata file  | bin-based chromatin state segmentation     |
+-----------------------------+---------------------------------------+-----------------------------------+--------------------------------------------+
|:doc:`tools/plotCSprofile`   | Visualization                         | output from ideasCS or chromIDEAS | chromatin state genomic distribution curve |
+-----------------------------+---------------------------------------+-----------------------------------+--------------------------------------------+
|:doc:`tools/stateCompare`    | Statistical Analysis                  | output from ideasCS or chromIDEAS | NULL                                       |
+-----------------------------+---------------------------------------+-----------------------------------+--------------------------------------------+

General principles
^^^^^^^^^^^^^^^^^^

A typical chromIDEAS command could look like this:

.. code:: bash

    $ chromIDEAS -m metadata.txt \
    -o outdir/ \
    -b 200 \
    -g hg38.txt \
    -n hg38_200 \
    -p 10 \
    -c

You can always view all available command-line options via -h or directly entering the command:

.. code:: bash

    $ chromIDEAS -h
    $ chromIDEAS

Parameters to decrease the run time
"""""""""""""""""""""""""""""""""""

``-p <nthreads>``
  Number of processors to be used

.. note:: 

 This parameter is available throughout almost all tools.

Relationship between ``-s <species>``, ``-g <genomesizes>`` and ``-n <windows_name>``
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

``-s <species>``
  Supported species: hg38, hg19, or mm10. Selecting this option automatically loads the corresponding  genomesizes file and blacklist file. If your species is not listed, manually provide these files via ``-g <genome_sizes> -n <windows_name> [-B <blackList>]``. 

``-g <genomesizes>``
  The genomesizes file (tab-delimited) listing chromosome lengths. An example::

    chr1  249250621
    ...

``-n <windows_name>``
  A unique name to identify the generated window bins.

These three parameters are used to construct the coordinate system. The relationship between them can be divided into the following four usage scenarios:

1. Situation 1: Only with ``-n <windows_name>``. This case applies only when a windows bin coordinate system named ``<windows_name>`` has already been successfully constructed. The remaining three situations apply when no windows bin coordinate system has been constructed yet.
2. Situation 2: Only with ``-s <species>``. The program will automatically match the corresponding ``<genomesizes>`` file and ``<blackList>`` file for the specified species, and it will automatically set ``<windows_name>`` using "``<species>``".
3. Situation3: ``-s <species> -n <windows_name>``. The program will automatically match the corresponding ``<genomesizes>`` file and ``<blackList>`` file for the specified species, while also setting ``<windows_name>`` according to the parameter.
4. Situation4: ``-g <genomesizes> -n <windows_name>``. The program will generate windows bins based on ``<genomesizes>`` and set ``<windows_name>`` according to the parameter.

.. note:: 

 These parameters are available throughout almost all tools.


(1) Tools for Coordinate Preparation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

:doc:`tools/genomeWindows`
""""""""""""""""""""""""""

(2) Tools for Data Format Conversion
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

:doc:`tools/bigWig2bedGraph`
""""""""""""""""""""""""""""
:doc:`tools/bedGraph2bigWig`
""""""""""""""""""""""""""""

(3) Tools for Data Normalization
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

:doc:`tools/s3v2Norm`
"""""""""""""""""""""

(4) Tools for Data Integration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

:doc:`tools/mergeBedgraph`
""""""""""""""""""""""""""
:doc:`tools/mergeBigwig`
""""""""""""""""""""""""

(5) Tools for Chromatin State Segmentation 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

:doc:`tools/ideasCS`
""""""""""""""""""""
:doc:`tools/chromIDEAS`
"""""""""""""""""""""""

(6) Tools for Visualization
^^^^^^^^^^^^^^^^^^^^^^^^^^^

:doc:`tools/plotCSprofile`
""""""""""""""""""""""""""

(7) Tools for Statistical Analysis
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

:doc:`tools/stateCompare`
"""""""""""""""""""""""""

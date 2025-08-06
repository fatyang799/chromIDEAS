Installation
=============

.. contents:: 
    :local:

Command line installation using ``conda``
-----------------------------------------

The recommended way to install chromIDEAS (including its requirements) is via `miniconda <https://www.anaconda.com/docs/getting-started/miniconda/main>`_ or `micromamba <https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html/>`_.

.. code:: bash

    $ conda install fatyang::chromideas


Command line installation using source code
---------------------------------------

chromIDEAS can also be installed step by step.

1. Download the software package source code file from GitHub:

.. code:: bash

	$ wget -c https://github.com/fatyang799/chromIDEAS/releases/download/v1.0-0/chromideas-1.0-0.tar.gz
	$ tar xzf chromideas-1.0-0.tar.gz
	$ cp -r chromIDEAS /PATH/TO/TARGET/

2. Configure system settings:

.. code:: bash

	# replace the '/PATH/TO/TARGET/' with your actual target path
	$ echo "export CONDA_PREFIX='/PATH/TO/TARGET/'" >> ~/.bashrc
	$ source ~/.bashrc
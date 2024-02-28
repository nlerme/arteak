+-------------------------------------------------------------------------+
|                                                                         |
| README                                                                  |
|                                                                         |
+-------------------------------------------------------------------------+

* The entry point of this software is the function `generate_dataset' of 
  the MATLAB file named `generate_dataset.m'.
* Settings can be modified at the beginning of this file.
* The `input_dir' variable refers to the directory where input images are stored.
* The `output_dir variable refers to the directory where output images are stored.
* Resulting directories are named as follows: fresco_name_a_b_c_d where
  * a denotes the fragment size (in N_{>0}).
  * b denotes the missing rate (in {0,...,100}).
  * c denotes the spurious rate (in {0,...,100}).
  * d denotes the erosion radius (in N_{>0}).

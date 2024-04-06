Presentation
------------
This directory contains tools for automatically generating simulated frescoes and provide them in the appropriate format with ground truths (see next section):

* **irregular_dafne1** just takes the dataset [1] as input and formats it appropriately. It does not add new degradations nor new fragmentations.
* **irregular_dafne2** takes the fresco models from [1] as input and generates new data by simulating fragmentations but also degradations on both fresco models 
  (noise, missing parts, color fading) and fragment images (noise, erosion and color fading).
* **regular** is the same as **irregular_dafne2** except that fragments are constrained to be rectangular.

File format
-----------
The format described here is common to all our datasets. A fresco typically has the following tree structure:

* **fresco.png**: RGB fresco (model) image. The image intensities are in the range {0,...,255}. The alpha channel indicates missing and available parts where intensities are null or positive, respectively.
* **frag_eroded**: directory where information about fragments is stored.
  * **frag_eroded_XXX.png**: RGBA fragment image where X denotes its index (starting from 0). The image intensities are in the range {0,...,255}. 
  The alpha channel indicates the location of the fragment where intensities are positive.
  * **gen_parameters.txt**: text file with parameters that made it possible to generate that fresco.
    ```
    mean_frags_gap 6.346201
    interpolation_type nearest
    spurious_rate 25.235
    ...
    ```
    In the above example, each parameter is written on the same line as its value. The type of the latter can be an integer, a real number or a string.
  * **geometric_constraints.txt**: text file constraining the placement of true fragments:
    ```
    3
    512.83 49.76
    8.33 3.61
    97.32 216.59
    4
    -270.73
    0.0
    -48.28
    -12.86
    ```
    In the above example, the number of constrained locations and then their list (as a couple of x,y coordinates) is written. 
    Next, the number of orientations and then their list (as a couple of angles in degrees in ]-360,0]) is written.
* **fragments.txt**: text file about the true fragments (i.e. belonging to the ground truth):
  ```
  109 2059.661621 1382.903931 -14.727097
  52 1447.260742 1279.249512 -228.095825
  36 1767.006104 655.227539 -184.568848
  ...
  ```
  In the above example, the fragment n°52 is located at x=1447.260742 and y=1279.249512 and turned by an angle of -228.095825 degrees. 
  The first fragment is assumed to be indexed with 0. Angles are assumed to lie in ]-360,0]. Location are not constrained to lie in the 
  domain of the fresco model to allow us partial inclusions. The list is not assumed to be ordered by fragment indexes.
* **fragments_s.txt**: text file about the spurious fragments (if so):
  ```
  71
  0
  379
  ...
  ```
  In the above example, the fragments n°71, 0 and 379 and defined to be spurious. The first fragment is assumed to be indexed by 0. 
  The list is not assumed to be ordered. If no spurious fragments exist (like for real data), this file must be created but left empty.
* **neighbors.txt**: text file describing relationships between adjacent fragments:
  ```
  0 10
  2 4
  0 9
  ...
  ```
  In the above example, fragments 0 and 10 are defined as adjacent. No matter if the line "10 0" is present, symmetry between is ensured to save memory. 
  The list is not assumed to be ordered. Self-relationships (loops) are discarded. The first fragment is assumed to be indexed by 0.

References
----------
[1] DAFNE: A dataset of fresco fragments for digital anastlylosis. P. Dondi, L. Lombardi, A. Setti, Pattern Recognition Letters, volume 138, pages 631-637, 2020.

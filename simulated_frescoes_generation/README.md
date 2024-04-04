Presentation
------------
This directory contains tools for automatically generating simulated frescoes and provide them in the appropriate format with ground truths (see next section):

* **irregular_dafne1** just takes the dataset [1] as input and formats it appropriately. In particular, it does not add new degradations nor new fragmentations.
* **irregular_dafne2** takes the fresco models from [1] as input and generates new data by simulating fragmentations but also degradations on both fresco models 
  (noise, missing parts, color fading) and fragment images (noise, spatially variable erosion and color fading).
* **regular** is the same as **irregular_dafne2** except that fragments are constrained to be rectangular.

[1] DAFNE: A dataset of fresco fragments for digital anastlylosis. P. Dondi, L. Lombardi, A. Setti, Pattern Recognition Letters, volume 138, pages 631-637, 2020.

File format
-----------
The format described here is common to all our datasets. A fresco typically has the following tree structure

* **frag_eroded**: directory where fragment images are stored.
  * **frag_eroded_XXX.png**: fragment image where 
  * 
* **fragments.txt**: text file about the true fragments (i.e. belonging to the ground truth):
  ```
  109 2059.661621 1382.903931 -14.727097
  52 1447.260742 1279.249512 -228.095825
  36 1767.006104 655.227539 -184.568848
  ...
  ```
  In the above example, the fragment n°52 is located at $x=1447.260742$ and $y=1279.249512$ and turned by an angle of -228.095825 degrees. 
  The first fragment is assumed to be indexed with 0. Angles are assumed to lie in $]-360,0]$. Location are not constrained to lie in the 
  domain of the fresco model to allow us partial inclusions. The list is not assumed to be ordered by fragment indexes.
* **fragments_s.txt**: text file about the spurious fragments (if so):
  ```
  71
  0
  379
  ...
  ```
  In the above example, the fragments n°71, 0 and 379 and defined to be spurious. The first fragment is assumed to be indexed with 0. 
  The list is not assumed to be ordered. If no spurious fragments exist (like for real data), this file must be created but left empty.
* **neighbors.txt**: text file describing relationships between adjacent fragments:
  ```
  0 1
  2 4
  0 9
  ...
  ```
  In the above example, fragments 0 and 1 are defined as adjacent.

Let us consider a color fresco image $v:\mathcal{P} \subset \mathbb{R}^2 \rightarrow [0,255]^3$ 
and a set of $K>0$ color fragment images $\{u_i\}_{i=1}^K where $u_i:\mathcal{P}_i \subset \mathbb{R}^2 \rightarrow [0,1]^3$.

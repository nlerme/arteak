Presentation
------------
This directory contains tools for automatically generating simulated frescoes and provide them in the appropriate format with ground truths. More precisely, it 
takes the fresco models from [1] as input and generates new data by simulating fragmentations but also degradations on both fresco models (noise, missing parts, 
color fading) and fragment images (noise, erosion and color fading). The generated fragments are of arbitrary shape. The fragmentation process is described 
in the next section. An example of illustration is given below for the fresco ``Resurrection'' from Piero Della Francesca.

![Full fresco model with color fading, noise and missing parts](https://ibb.co/PGDmDn4)
![Ideal reconstruction](https://ibb.co/PGDmDn4)

Fragmentation process
---------------------
1) Generation of random seeds using Poisson sampling
2) Generation of normalized power law noise image
3) Computation of Voronoi diagram from seeds
4) Computation of distance map to the contours of Voronoi diagram
5) Erosion of Voronoi cells based on the distance map
6) Normalization of distance map
7) Watershed-based segmentation between eroded Voronoi cells

For the last step, the involved weights is a linear combination between the noise image and the distance map. Since pixels at the boundary between adjacent 
fragments is assigned with the same dummy label (zero), we need to assign them a label from a fragment. For such pixels, we assign them with the label having the 
largest number of occurrences in their immediate neighborhood. Notice that such a fragmentation process does not take into account the nature of the support on 
which a fresco is hung nor its pigments aging.

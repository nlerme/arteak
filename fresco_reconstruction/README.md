Presentation
------------
This directory includes different approaches for automatically reconstructing frescoes:

1) Permutation learning [1].
2) Stable diffusion.
3) Marked point processes [3].

For the third approach, the reconstruction task is solved with an algorithm alternating three steps until concergence: (i) sampling, (ii) fragments selection and (iii) 
fragments placement steps. The algorithm is initialized with [2] or exhaustive search, depending on the availability of the fresco model. The sampling step is performed 
using machine learning. The fragments placement step is performed in the continuous domain using gradient descent. Finally, the fragments selection step is performed in 
the discrete domain using graph cuts [4,5,6].

References
----------
[1] Solving Jigsaw Puzzles With Vision Transformers. G. Heck, N. Lermé, S. Le Hégarat-Mascle. Pattern Analysis And Applications. Preprint, 2024.

[2] N. Lermé, S. Le Hégarat-Mascle, B. Zhang, E. Aldea, Fast and Efficient Reconstruction of Digitized Frescoes, Pattern Recognition Letters, 138, 417-423, 2020.

[3] Automatic Reconstruction of Digitized Frescoes, N. Lermé, S. Le Hégarat-Mascle, F. Malgouyres, G. Alkan. Preprint, 2022.

[4] Efficient Approximate Energy Minimization via Graph Cuts. Y. Boykov, O. Veksler, R.Zabih. IEEE Transactions on Pattern Analysis and Machine Intelligence, 20(12):1222-1239, 2001.

[5] What Energy Functions can be Minimized via Graph Cuts? V. Kolmogorov, R.Zabih. IEEE Transactions on Pattern Analysis and Machine Intelligence, 26(2):147-159, 2004. 

[6] An Experimental Comparison of Min-Cut/Max-Flow Algorithms for Energy Minimization in Vision. Y. Boykov, V. Kolmogorov. IEEE Transactions on Pattern Analysis and Machine Intelligence, 26(9):1124-1137, 2004.

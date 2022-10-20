Presentation
------------
ARTEAK is an scientific project aiming at recovering the optimal spatial organization of a damaged fresco from its original elements with or without a picture of the fresco. 
This problem is very challenging because of local aspects (elements must locally match with each other) but also global aspects (the reassembled elements must depict a picture 
making sense). The main application of this problem concerns the reconstruction of artworks in cultural heritage and archaeology. It is of great importance to to improve the 
understanding and the conservation of artworks.

The software related to this project is mostly written in MATLAB and is distributed under GPL license but only for research purposes. It has been heavily tested on a large 
dataset with simulated undegraded fragmented frescoes [1]. This software involves 5 distinct different packages:

* fresco_reconstruction : scripts for running fresco reconstruction
* graphical_user_interface : interface for handling multiple fresco reconstructions
* common_tools : scripts shared by one or several packages
* regular_fragments_generation : script for constructing a dataset derived from [1] with fragments of regular shape and simulated degradations on the fresco model.
* irregular_fragments_generation : script for constructing a dataset derived from [1] with fragments of irregular shape and simulated degradations on the fresco model.

The fresco reconstruction is based on Marked point processes and solved with an algorithm alternating sampling, fragments selection and fragments placement until convergence [3]. 
The algorithm is initialized with [2] or exhaustive, depending on the availability of the fresco model. The sampling step is performed using machine learning. The fragments 
placement step is performed in the continuous domain using gradient descent. Finally, the fragments selection step is performed in the discrete domain using graph cuts [4,5,6].

An example of execution of the graphical user interface is shown below:

![Screenshot](https://i.ibb.co/8PvF9Lm/screenshot.png)

References
----------
[1] DAFNE: A dataset of fresco fragments for digital anastlylosis. P. Dondi, L. Lombardi, A. Setti, Pattern Recognition Letters, volume 138, pages 631-637, 2020.

[2] N. Lermé, S. Le Hégarat-Mascle, B. Zhang, E. Aldea, Fast and Efficient Reconstruction of Digitized Frescoes, Pattern Recognition Letters, 138, 417-423, 2020.

[3] Automatic Reconstruction of Digitized Frescoes, N. Lermé, S. Le Hégarat-Mascle, F. Malgouyres, G. Alkan. Preprint, 2022.

[4] Efficient Approximate Energy Minimization via Graph Cuts. Y. Boykov, O. Veksler, R.Zabih. IEEE Transactions on Pattern Analysis and Machine Intelligence, 20(12):1222-1239, 2001.

[5] What Energy Functions can be Minimized via Graph Cuts? V. Kolmogorov, R.Zabih. IEEE Transactions on Pattern Analysis and Machine Intelligence, 26(2):147-159, 2004. 

[6] An Experimental Comparison of Min-Cut/Max-Flow Algorithms for Energy Minimization in Vision. Y. Boykov, V. Kolmogorov. IEEE Transactions on Pattern Analysis and Machine Intelligence, 26(9):1124-1137, 2004.

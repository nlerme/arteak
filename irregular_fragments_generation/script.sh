#dirs=$(find ../data/DB1/PierodellaFrancesca_Resurrezione_730x826/ -maxdepth 1 -type d -name "*" | tail -n +2)

for d in ${dirs}
do
	radius_erosion=$(cat "${d}/parameters.txt" | sed -n 's/.*radius_erosion:\([0-9.]\+\).*/\1/p')
	diagonal_dimension_erosion=$(cat "${d}/parameters.txt" | sed -n 's/^.*diagonal_dimension_erosion:\([0-9.]\+\).*/\1/p')
	circle_radius=$(cat "${d}/parameters.txt" | sed -n 's/^.*circle_radius:\([0-9.]\+\).*/\1/p')
	circle_border=$(cat "${d}/parameters.txt" | sed -n 's/^.*circle_border:\([0-9.]\+\).*/\1/p')
	annular_prob=$(cat "${d}/parameters.txt" | sed -n 's/^.*annular_probability:\([0-9.]\+\).*/\1/p')
	min_diag_dim=$(cat "${d}/parameters.txt" | sed -n 's/^.*minimum_diag_dimension:\([0-9.]\+\).*/\1/p')
	name=$(basename ${d})
	echo "+ ${name} | radius_erosion=${radius_erosion}, diagonal_dimension_erosion=${diagonal_dimension_erosion}, circle_radius=${circle_radius}, circle_border=${circle_border}, min_diag_dim=${min_diag_dim}, annular_prob=${annular_prob}"
done

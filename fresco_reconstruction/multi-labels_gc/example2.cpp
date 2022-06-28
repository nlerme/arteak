#include <cstdio>
#include <iostream>
#include <cstdlib>
#include <cmath>
#include <string>
#include <ctime>
#include "GCoptimization.h"

typedef GCoptimization::SiteID SiteID;
typedef GCoptimization::LabelID LabelID;
typedef GCoptimization::EnergyTermType EnergyTermType;

EnergyTermType dataFn( SiteID p, LabelID l )
{
	if( p==0 ) return (l==0?10:1);
	else return (l==0?1:10);
}

EnergyTermType smoothFn( SiteID p1, SiteID p2, LabelID l1, LabelID l2 )
{
	if( p1==0 && p2==1 ) return (l1==1 && l2==0) ? 100.0 : 0.0;
	else return (l1==0 && l2==1) ? 100.0 : 0.0;
}

struct MySmoothCostFunctor : public GCoptimization::SmoothCostFunctor
{
	virtual EnergyTermType compute( SiteID p1, SiteID p2, LabelID l1, LabelID l2 )
	{
		if( p1==0 && p2==1 ) return (l1==1 && l2==0) ? 100.0 : 0.0;
		else return (l1==0 && l2==1) ? 100.0 : 0.0;
	}
};

struct MyDataCostFunctor : public GCoptimization::DataCostFunctor
{
	virtual EnergyTermType compute( SiteID p, LabelID l )
	{
		if( p==0 ) return (l==0?10:1);
		else return (l==0?1:10);
	}
};

int main(int argc, char **argv)
{
	try
	{
		/*GCoptimization::EnergyT e(2, 2);
		e.add_variable(2);
		e.add_term1(0, 10, 1);
		e.add_term1(1, 1, 10);
		e.add_term2(0, 1, 0, 0, 100, 0);
		std::cout << e.minimize() << '\n';
		std::cout << "u_p = " << e.get_var(0) << ", u_q = " << e.get_var(1) << '\n';*/

		//--------------------------------------

		GCoptimizationGeneralGraph *gc = new GCoptimizationGeneralGraph(2, 2);
		//gc->setDataCost(dataFn);
		//gc->setSmoothCost(smoothFn);
		gc->setDataCostFunctor(new MyDataCostFunctor);
		gc->setSmoothCostFunctor(new MySmoothCostFunctor);
		gc->setNeighbors(0, 1, 1.0);
		gc->setVerbosity(2);
		gc->swap();
		std::cout << "u_p = " << gc->whatLabel(0) << ", u_q = " << gc->whatLabel(1) << '\n';
		delete gc;
	}
	catch( GCException & e )
	{
		e.Report();
	}

	return EXIT_SUCCESS;
}

clc;
clear all;
close all;

% h = GCO_Create(2,2);
% GCO_SetVerbosity(h,2);
% GCO_SetDataCost(h, [1,20;20,1]);
% GCO_SetSmoothCost(h, [0,1;20,0]);
% GCO_SetNeighbors(h,[0,1;0,0]);
% GCO_Swap(h);
% GCO_GetLabeling(h)
% [E D S] = GCO_ComputeEnergy(h)
% GCO_Delete(h);

% h = GCO_Create(2, 2);
% GCO_SetVerbosity(h, 2);
% GCO_SetDataCost(h, [10,1;1,10]);
% GCO_SetSmoothCost(h, [0,100;100,0]);
% GCO_SetNeighbors(h, [0,1;0,0]);
% GCO_Swap(h);
% GCO_GetLabeling(h)
% [E D S] = GCO_ComputeEnergy(h)
% GCO_Delete(h);

% disp('---------------------------');

h = GCO_Create(3, 2);
GCO_SetVerbosity(h, 2);
GCO_SetDataCost(h, 'my_datacost_fn');
GCO_SetSmoothCost(h, 'my_smoothcost_fn');
GCO_SetNeighbors(h, [0,1,0;0,0,1;0,0,0]);
GCO_Swap(h);
GCO_GetLabeling(h)
[E D S] = GCO_ComputeEnergy(h)
GCO_Delete(h);
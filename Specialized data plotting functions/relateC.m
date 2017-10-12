function relateC(data1,data2,res)


if ~iscolumn(data1)
    data1 = data1';
end

if ~iscolumn(data2)
    data2 = data2';
end 

[N C] = hist3([data2 data1],[res res]);
% N2 = repmat(flipud(N),[1 3]);
contourf(C{2},C{1},N,res,'LineStyle','none');
% imagesc(N);
% imagesc(linspace(-2,4,300),C{1},N);
% axis image;
% imagesc(flipud(log(N)))
% imagesc(flipud(N));

mapi = [1.0000e+000     1.0000e+000     1.0000e+000; ...
   929.6296e-003   929.6296e-003     1.0000e+000; ...
   859.2593e-003   859.2593e-003     1.0000e+000; ...
   788.8889e-003   788.8889e-003     1.0000e+000; ...
   718.5185e-003   718.5185e-003     1.0000e+000; ...
   648.1481e-003   648.1481e-003     1.0000e+000; ...
   577.7778e-003   577.7778e-003     1.0000e+000; ...
   507.4074e-003   507.4074e-003     1.0000e+000; ...
   437.0370e-003   437.0370e-003     1.0000e+000; ...
   366.6667e-003   366.6667e-003     1.0000e+000; ...
   298.4127e-003   298.4127e-003     1.0000e+000; ...
   268.2540e-003   268.2540e-003     1.0000e+000; ...
   238.0952e-003   238.0952e-003     1.0000e+000; ...
   207.9365e-003   207.9365e-003     1.0000e+000; ...
   177.7778e-003   177.7778e-003     1.0000e+000; ...
   147.6190e-003   147.6190e-003     1.0000e+000; ...
   117.4603e-003   117.4603e-003     1.0000e+000; ...
    87.3016e-003    87.3016e-003     1.0000e+000; ...
    57.1429e-003    57.1429e-003     1.0000e+000; ...
    26.9841e-003    26.9841e-003     1.0000e+000; ...
     0.0000e+000     7.9365e-003   992.0635e-003; ...
     0.0000e+000    83.3333e-003   916.6667e-003; ...
     0.0000e+000   158.7302e-003   841.2698e-003; ...
     0.0000e+000   234.1270e-003   765.8730e-003; ...
     0.0000e+000   309.5238e-003   690.4762e-003; ...
     0.0000e+000   384.9206e-003   615.0794e-003; ...
     0.0000e+000   460.3175e-003   539.6825e-003; ...
     0.0000e+000   535.7143e-003   464.2857e-003; ...
     0.0000e+000   611.1111e-003   388.8889e-003; ...
     0.0000e+000   686.5079e-003   313.4921e-003; ...
     0.0000e+000   761.9048e-003   238.0952e-003; ...
     0.0000e+000   837.3016e-003   162.6984e-003; ...
     0.0000e+000   912.6984e-003    87.3016e-003; ...
     0.0000e+000   988.0952e-003    11.9048e-003; ...
    84.6561e-003     1.0000e+000     0.0000e+000; ...
   185.1852e-003     1.0000e+000     0.0000e+000; ...
   285.7143e-003     1.0000e+000     0.0000e+000; ...
   386.2434e-003     1.0000e+000     0.0000e+000; ...
   486.7725e-003     1.0000e+000     0.0000e+000; ...
   587.3016e-003     1.0000e+000     0.0000e+000; ...
   687.8307e-003     1.0000e+000     0.0000e+000; ...
   788.3598e-003     1.0000e+000     0.0000e+000; ...
   888.8889e-003     1.0000e+000     0.0000e+000; ...
   989.4180e-003     1.0000e+000     0.0000e+000; ...
     1.0000e+000   955.0264e-003     0.0000e+000; ...
     1.0000e+000   904.7619e-003     0.0000e+000; ...
     1.0000e+000   854.4973e-003     0.0000e+000; ...
     1.0000e+000   804.2328e-003     0.0000e+000; ...
     1.0000e+000   753.9683e-003     0.0000e+000; ...
     1.0000e+000   703.7037e-003     0.0000e+000; ...
     1.0000e+000   653.4392e-003     0.0000e+000; ...
     1.0000e+000   603.1746e-003     0.0000e+000; ...
     1.0000e+000   552.9101e-003     0.0000e+000; ...
     1.0000e+000   502.6455e-003     0.0000e+000; ...
     1.0000e+000   452.3809e-003     0.0000e+000; ...
     1.0000e+000   402.1164e-003     0.0000e+000; ...
     1.0000e+000   351.8518e-003     0.0000e+000; ...
     1.0000e+000   301.5873e-003     0.0000e+000; ...
     1.0000e+000   251.3228e-003     0.0000e+000; ...
     1.0000e+000   201.0582e-003     0.0000e+000; ...
     1.0000e+000   150.7937e-003     0.0000e+000; ...
     1.0000e+000   100.5291e-003     0.0000e+000; ...
     1.0000e+000    50.2646e-003     0.0000e+000; ...
     1.0000e+000     0.0000e+000     0.0000e+000 ];
     



colormap(mapi);
end



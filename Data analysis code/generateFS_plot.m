
% produce a plot of the Fourier series correction

for m = 1:1
    
    results.I(:,m) = exp(-subPoly(results.zEvNano(:,m),0)/140);
    angleWrapped = atan2(results.yc(:,m),results.xc(:,m));
    [awsorted IX] = sort(angleWrapped);
    ITrysorted = results.I(IX,m);
    awsorted = imresize(awsorted,.001);
    ITrysorted = imresize(ITrysorted,.001);
    
    FS_coeffs(:,m) = Fcoeffs4(awsorted,ITrysorted);
    FS_func(:,m) = FS_gen(angleWrapped,FS_coeffs(:,m));
    ItryFS(:,m) = results.I(:,m)./FS_func(:,m);
    ItryFS_sorted = ItryFS(IX,m);
    ItryFS_sorted = imresize(ItryFS_sorted,.001);
    FS_coeffs2 = Fcoeffs4(awsorted,ItryFS_sorted);
    
    fs_function = FS_gen(awsorted,FS_coeffs(:,m));
    fs_function2 = FS_gen(awsorted,FS_coeffs2);
    
%     subplot(1,2,1);
    plot(awsorted,zplp(ITrysorted,10,2),'o','markersize',2);
    hold all; plot(awsorted,fs_function,'r');
%     ylim([0 1.2]);
    
%     subplot(1,2,2);
    plot(awsorted,zplp(ItryFS_sorted,10,2),'go','markersize',2);
    hold all; plot(awsorted,fs_function2,'r');
    ylim([0 1.2]);
end
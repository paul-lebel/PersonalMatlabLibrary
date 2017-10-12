function [FRET alpha gammaRatio] = trace2FRET(donor,acceptor)
n = numel(donor);

prompt = {
    'Donor bleaching present? (1/0)'
    'Acceptor bleaching present? (1/0)'
    'Enter alpha (if donor bleaching not present)'
    'Enter gammaRatio (if acceptor bleaching did not occur before donor)'
    };

fields = {
    'dFlag'
    'aFlag'
    'alphaInput'
    'gammaInput'
    };


figure;
plot(acceptor,'r','linewidth',2); hold all;
plot(donor,'g','linewidth',2); 

dlginfo = inputdlg(prompt, 'Describe trace');
% Convert numeric entries from text to numbers
for i=1:numel(dlginfo)
    dlginfo{i} = str2num(dlginfo{i});
end

% Convert the info to a struct
dlginfo = cell2struct(dlginfo,fields);


% Get background signal averages for both channels
disp('Select laser-on background')
[xdbg ~] = ginput(2);
% disp('Select laser-on acceptor background');
% [xabg ~] = ginput(2);
xabg = xdbg;
dbg = mean(donor(round(xdbg(1)):round(xdbg(2))));
abg = mean(acceptor(round(xabg(1)):round(xabg(2)))); 

if dlginfo.aFlag
% Get the pre and post signal levels for the acceptor bleaching event
disp('Acceptor bleaching event: select right before');
[xapr ~] = ginput(2);
disp('Acceptor bleaching event: select right after');
[xapo ~] = ginput(2);
abab = mean(acceptor(round(xapr(1)):round(xapr(2))));
aaab = mean(acceptor(round(xapo(1)):round(xapo(2))));
dbab = mean(donor(round(xapr(1)):round(xapr(2))));
daab = mean(donor(round(xapo(1)):round(xapo(2))));
Delta1 = daab-dbab;
Delta2 = abab-aaab;
gammaRatio = Delta2/Delta1;
else
    gammaRatio = dlginfo.gammaInput;
end

if dlginfo.dFlag
% Get the pre and post signal levels for the donor bleaching event
disp('Donor bleaching event: Select right before');
[xdpr ~] = ginput(2);
disp('Donor bleaching event: Select right after');
[xdpo ~] = ginput(2);
dbdb = mean(donor(round(xdpr(1)):round(xdpr(2))));
dadb = mean(donor(round(xdpo(1)):round(xdpo(2))));
abdb = mean(acceptor(round(xdpr(1)):round(xdpr(2))));
aadb = mean(acceptor(round(xdpo(1)):round(xdpo(2))));
delta1 = dbdb-dadb;
delta2 = abdb-aadb;
alpha = delta2/delta1;
else
    alpha = dlginfo.alphaInput;
end

% Bleedthrough corrected donor and acceptor traces:
dPrime = (donor - dbg)/(1-alpha);
aPrime = acceptor - abg - alpha*dPrime;

FRET = 1./(1 + gammaRatio*dPrime./aPrime);
inds = FRET > 1 | FRET < 0;
FRET(inds)= 0;
cla;
plot(FRET);
ylim([-.1 1.1])

disp('');
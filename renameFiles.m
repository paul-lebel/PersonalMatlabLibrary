

% This is a script to rename files in a certain directory based on
% specified criteria
initDir = pwd;
sourceDir = '\\Flexo\MicroscopyData\Bioengineering\UV Microscopy\RawData\';
destDir = '\\Flexo\MicroscopyData\Bioengineering\UV Microscopy\Processed data\Resaved raw data temp\';

cd(sourceDir)
list = ls;

dirInds = 14:27;
commonInds = 1:18;
suf = '.tif';

for i = dirInds
    fprintf(['\n' list(i,:) '\n']);
    
    processDir = input('Process this directory? (0/1)');
    
    if processDir
        nChannels = input('Number of channels?');
        
        % Tunnel into the subdirectory
        cd([list(i,:) '\']);
        sublist = ls;
        % Skip first two which are '.' and '..'
        sublist = sublist(3:end,:);
        
        % Check if the number of files is a multiple of the number of
        % channels
        proceed = 1;
        if rem(size(sublist,1),nChannels) ~= 0
            proceed = input('Warning! The number of files is not a multiple of the number of channels! Proceed anyway? (0/1)');
        end
        
        if proceed
            % Loop through the sub-directory
            j = 1;
            oldNames = '';
            newNames = '';
            
            while j < size(sublist,1)
                commonStr = sublist(j,commonInds);
                for k=1:nChannels
                    oldNames(j,:) = sublist(j,:);
                    newNames(j,:) = [commonStr '-ch-' num2str(k-1,'%02i') '-' num2str(floor((j-1)/nChannels), '%05i') suf];
                    j = j+1;
                end
            end
            disp(oldNames);
            fprintf('\n');
            disp(newNames);
            fprintf('\n');
            
            if input('Copy files? (0/1)')
                for l = 1:size(oldNames,1)
                    if ~exist(fullfile(destDir, list(i,:)),'dir')
                        mkdir(fullfile(destDir, list(i,:)));
                    end
                    copyfile(fullfile(sourceDir,list(i,:), oldNames(l,:)), ...
                        fullfile(destDir, list(i,:), newNames(l,:)));
                end
            end
            
        end
        
        cd(sourceDir);
        
    end
end

cd(initDir);
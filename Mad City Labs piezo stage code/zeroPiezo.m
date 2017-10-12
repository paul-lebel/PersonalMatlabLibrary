


function zeroPiezo(mcl_handle)

% % Make a pointer to the handles array
% mcl_handles = zeros(1,5,'uint16');
% p_handles = libpointer('uint16Ptr',mcl_handles);
% 
% n_handles = calllib('Madlib','MCL_GetAllHandles',p_handles,5);
% 
% % Retrieve the data from the 
% handles = get(p_handles, 'Value');
% 
% 
% 
% if mcl_handles == 0
%     error('No MCL handles found')
% end


n_handles = 1;



% Set all axes on all handles to zero
for i=1:numel(n_handles)
    
    % x axis to zero
    temp = calllib('Madlib','MCL_SingleWriteN',0,1,mcl_handle(i));
    
    % y axis to zero
    temp = calllib('Madlib','MCL_SingleWriteN',0,2,mcl_handle(i));
    
    % z axis to zero
    temp = calllib('Madlib','MCL_SingleWriteN',0,3,mcl_handle(i));
    
end

pause(2);

for i=1:numel(n_handles)
    
    %Display x position of stage
    temp = calllib('Madlib','MCL_SingleReadN',1,mcl_handle(i));
    txtstr = [ 'stage ' num2str(i) ' x position = ' num2str(temp)];
    disp(txtstr);
    
    temp = calllib('Madlib','MCL_SingleReadN',2,mcl_handle(i));
    txtstr = [ 'stage ' num2str(i) ' y position = ' num2str(temp)];
    disp(txtstr);
    
    temp = calllib('Madlib','MCL_SingleReadN',3,mcl_handle(i));
    txtstr = [ 'stage ' num2str(i) ' z position = ' num2str(temp)];
    disp(txtstr);
    
end

    

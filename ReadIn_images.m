function [specimen]=ReadIn_images(filepath, StartImage, EndImage)
clear specimen 
addpath(filepath);
if ~exist('StartImage','var')
    StartImage=1;
end

dir_files=dir([filepath '*.tif']);
dir_files={dir_files(:).name};
num_files=numel(dir_files);

if ~exist('EndImage','var')
    EndImage=num_files;
end

parfor i=StartImage:EndImage
    specimen(:,:,i)=imread(cell2mat(dir_files(i)));
end

rmpath(filepath);
end
function folderPath = projectdir()
% projectdir - Get the project (repository) root directory of the Brain Observatory Toolbox
    folderPath = string(fileparts(fileparts(fileparts(mfilename('fullpath')))));
end

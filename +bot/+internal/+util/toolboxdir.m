function toolboxFolderPath = toolboxdir()

    % This file is <toolbox>/+bot/+internal/+util/toolboxdir.m. Move 3
    % folders up from the folder of this file. (Splitting the path on
    % filesep and rejoining it with fullfile drops the leading "/" of an
    % absolute path on Linux and macOS.)
    thisFolderPath = fileparts( mfilename('fullpath') );
    toolboxFolderPath = fileparts(fileparts(fileparts( thisFolderPath )));
end

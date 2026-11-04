function stagingFolder = stageToolboxFiles(stagingFolderName)
% stageToolboxFiles - Copy the files that make up the distributed toolbox into a staging folder
%
%   stagingFolder = bottools.stageToolboxFiles(stagingFolderName) deletes
%   and recreates <projectRoot>/<stagingFolderName> and copies into it every
%   file or folder listed in the "FilesToPackage" field of
%   tools/MLToolboxInfo.json, keeping their relative layout.
%
%   The Brain Observatory Toolbox keeps its code at the repository root
%   (+bot, examples, gettingStarted.mlx) rather than in a src/ folder, so
%   that MATLAB Online and File Exchange links to those files keep working.
%   MatBox packages everything below a single source folder, so packaging
%   the repository root directly would also ship .git, .github, tools and
%   tests. Staging an explicit list of files avoids that.

    arguments
        stagingFolderName (1,1) string = "build/toolbox"
    end

    projectRoot = bottools.projectdir();
    toolboxInfo = bottools.readToolboxInfo();
    itemsToPackage = reshape(string(toolboxInfo.FilesToPackage), 1, []);

    stagingFolder = fullfile(projectRoot, stagingFolderName);
    if isfolder(stagingFolder)
        rmdir(stagingFolder, 's');
    end
    mkdir(stagingFolder);

    for item = itemsToPackage
        sourcePath = fullfile(projectRoot, item);
        targetPath = fullfile(stagingFolder, item);
        if isfolder(sourcePath)
            copyfile(sourcePath, targetPath);
        elseif isfile(sourcePath)
            targetFolder = fileparts(targetPath);
            if ~isfolder(targetFolder)
                mkdir(targetFolder);
            end
            copyfile(sourcePath, targetPath);
        else
            error('BOT:Packaging:FileNotFound', ...
                '"%s" is listed in FilesToPackage in tools/MLToolboxInfo.json but does not exist.', item);
        end
    end

    % Never ship local data caches, even if one exists in the working copy.
    listing = dir(fullfile(stagingFolder, '**'));
    isCacheFolder = [listing.isdir] & strcmp({listing.name}, 'Cache');
    cacheFolders = unique(fullfile({listing(isCacheFolder).folder}, {listing(isCacheFolder).name}));
    for i = 1:numel(cacheFolders)
        if isfolder(cacheFolders{i})
            rmdir(cacheFolders{i}, 's');
        end
    end

    fprintf('Staged %d item(s) for packaging in %s\n', numel(itemsToPackage), stagingFolder);
end

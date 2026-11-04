function [newVersion, mltbxPath] = packageToolbox(releaseType, versionString, options)
% packageToolbox - Package the Brain Observatory Toolbox into an .mltbx file
%
%   [newVersion, mltbxPath] = packageToolbox(releaseType, versionString)
%   stages the files listed in tools/MLToolboxInfo.json ("FilesToPackage")
%   into build/toolbox and packages them with MatBox. The .mltbx file is
%   written to releases/.
%
%   releaseType is "build" (default), "major", "minor", "patch" or
%   "specific". With "specific", versionString gives the version, e.g.
%   "v0.9.5" or "0.9.5". The other release types bump the version found in
%   Contents.m.
%
%   This function has the signature that ehennestad/matbox-actions'
%   package-toolbox action expects of a project's own packageToolbox, so the
%   action calls it instead of matbox.tasks.packageToolbox. The action's
%   source_directory input arrives as SourceFolderName and names the staging
%   folder; it must match the folder that ToolboxGettingStartedGuide in
%   tools/MLToolboxInfo.json points into.
%
%   Requires MatBox (see bottools.installMatBox).
%
%   Example (from the repository root):
%       addpath(genpath("tools"))
%       [version, mltbxPath] = packageToolbox("specific", "0.9.5")

    arguments
        releaseType {mustBeTextScalar} = "build"
        versionString {mustBeTextScalar} = ""
        options.SourceFolderName (1,1) string = "build/toolbox"
    end

    projectRoot = bottools.projectdir();

    toolboxInfo = bottools.readToolboxInfo();
    gettingStartedGuide = string(toolboxInfo.ToolboxOptions.ToolboxGettingStartedGuide);
    if ~startsWith(gettingStartedGuide, options.SourceFolderName + "/")
        error('BOT:Packaging:GettingStartedGuideOutsideStaging', ...
            ['ToolboxGettingStartedGuide ("%s") in tools/MLToolboxInfo.json must be ', ...
             'inside the staging folder "%s".'], gettingStartedGuide, options.SourceFolderName);
    end

    bottools.stageToolboxFiles(options.SourceFolderName);

    [newVersion, mltbxPath] = matbox.tasks.packageToolbox(projectRoot, releaseType, versionString, ...
        "SourceFolderName", options.SourceFolderName, ...
        "ToolboxShortName", "BrainObservatoryToolbox");

    if ~nargout
        clear newVersion
    end
end

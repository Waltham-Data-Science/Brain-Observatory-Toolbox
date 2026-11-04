function verifyToolboxInstallation(mltbxFile, options)
% verifyToolboxInstallation - Install a packaged .mltbx and check that the installed toolbox works
%
%   verifyToolboxInstallation(mltbxFile) installs mltbxFile with
%   matlab.addons.install and then checks that:
%     1. the installed add-on has the name and identifier from
%        tools/MLToolboxInfo.json (and the expected version, if given),
%     2. bot resolves to the installed copy, not to a working copy,
%     3. every file in FilesToPackage made it into the installation, and
%        no development files (tools, tests, .github) did,
%     4. bot.internal.util.getToolboxVersion reports the installed version,
%     5. the test suite in tests/ passes against the installed copy, and
%     6. the toolbox uninstalls cleanly and bot leaves the path.
%
%   The current folder is always on MATLAB's search path, so this function
%   changes to a temporary folder before installing. Make sure the
%   repository root is not on the path either.
%
%   Options:
%     ExpectedVersion - e.g. "0.9.5"; checked against the installed version
%     ExcludeTags     - test tags to skip, e.g. "Online"
%     RunTests        - run tests/ against the installed copy (default: true)

    arguments
        mltbxFile (1,1) string {mustBeFile}
        options.ExpectedVersion (1,1) string = ""
        options.ExcludeTags (1,:) string = string.empty
        options.RunTests (1,1) logical = true
    end

    fileInfo = dir(mltbxFile);
    mltbxFile = string(fullfile(fileInfo.folder, fileInfo.name));

    projectRoot = bottools.projectdir();
    toolboxInfo = bottools.readToolboxInfo();
    expectedName = string(toolboxInfo.ToolboxOptions.ToolboxName);
    expectedIdentifier = string(toolboxInfo.ToolboxOptions.Identifier);

    % Work from an empty folder so nothing in the current folder shadows
    % the installed toolbox.
    workFolder = string(tempname);
    mkdir(workFolder);
    previousFolder = cd(workFolder);
    returnToFolder = onCleanup(@() cd(previousFolder)); %#ok<NASGU>

    assert(string(which('bot.listSessions')) == "", 'BOT:Verify:AlreadyOnPath', ...
        ['bot is already on the path (%s) before installing. Remove it first, ', ...
         'otherwise the test would not exercise the packaged toolbox.'], which('bot.listSessions'));

    %% 1. Install
    fprintf('Installing toolbox: %s\n', mltbxFile);
    installed = matlab.addons.install(mltbxFile, true);
    uninstallIfNeeded = onCleanup(@() uninstallQuietly(installed.Identifier)); %#ok<NASGU>

    fprintf('Installed add-on:\n  Name: %s\n  Version: %s\n  Identifier: %s\n', ...
        installed.Name, installed.Version, installed.Identifier);

    assert(string(installed.Name) == expectedName, 'BOT:Verify:WrongName', ...
        'Installed add-on is named "%s", expected "%s".', installed.Name, expectedName);
    assert(string(installed.Identifier) == expectedIdentifier, 'BOT:Verify:WrongIdentifier', ...
        'Installed add-on has identifier "%s", expected "%s".', installed.Identifier, expectedIdentifier);
    installedVersion = coreVersion(installed.Version);
    if options.ExpectedVersion ~= ""
        expectedVersion = coreVersion(options.ExpectedVersion);
        assert(installedVersion == expectedVersion, 'BOT:Verify:WrongVersion', ...
            'Installed version is %s, expected %s.', installed.Version, options.ExpectedVersion);
    end

    %% 2. bot resolves to the installed copy
    botLocation = string(which('bot.listSessions'));
    assert(botLocation ~= "", 'BOT:Verify:NotOnPath', ...
        'bot.listSessions is not on the path after installing the toolbox.');
    assert(~startsWith(botLocation, projectRoot + filesep), 'BOT:Verify:WorkingCopyOnPath', ...
        'bot.listSessions resolves to the working copy (%s), not the installed toolbox.', botLocation);
    installRoot = string(fileparts(fileparts(botLocation)));
    fprintf('Toolbox installed in %s\n', installRoot);

    %% 3. Package contents
    for item = reshape(string(toolboxInfo.FilesToPackage), 1, [])
        assert(isfile(fullfile(installRoot, item)) || isfolder(fullfile(installRoot, item)), ...
            'BOT:Verify:MissingFile', '"%s" is missing from the installed toolbox.', item);
    end
    exampleFiles = dir(fullfile(projectRoot, "examples", "*.mlx"));
    for i = 1:numel(exampleFiles)
        assert(isfile(fullfile(installRoot, "examples", exampleFiles(i).name)), ...
            'BOT:Verify:MissingExample', 'Example "%s" is missing from the installed toolbox.', ...
            exampleFiles(i).name);
    end
    for devItem = ["tools", "tests", ".github", ".git", "build", "releases", "docs"]
        assert(~isfolder(fullfile(installRoot, devItem)), 'BOT:Verify:DevelopmentFilePackaged', ...
            'Development folder "%s" should not be in the installed toolbox.', devItem);
    end

    %% 4. Version reported by the toolbox itself
    reportedVersion = string(bot.internal.util.getToolboxVersion());
    fprintf('bot.internal.util.getToolboxVersion() returns %s\n', reportedVersion);
    assert(coreVersion(reportedVersion) == installedVersion, 'BOT:Verify:VersionMismatch', ...
        'bot.internal.util.getToolboxVersion() returns %s, but the installed add-on is version %s.', ...
        reportedVersion, installed.Version);

    %% 5. Test suite against the installed copy
    if options.RunTests
        testToolbox("UseInstalledToolbox", true, "ExcludeTags", options.ExcludeTags);
    end

    %% 6. Uninstall
    matlab.addons.uninstall(installed.Identifier);
    rehash
    assert(string(which('bot.listSessions')) == "", 'BOT:Verify:StillOnPathAfterUninstall', ...
        'bot.listSessions is still on the path after uninstalling (%s).', which('bot.listSessions'));
    fprintf('Toolbox uninstalled cleanly.\n');

    fprintf('Verification completed successfully on %s (MATLAB %s)\n', computer, version('-release'));
end

function versionString = coreVersion(versionString)
% coreVersion - <major>.<minor>.<patch> part of a version, without a leading "v" or build number
    versionString = string(regexp(char(versionString), '\d+\.\d+\.\d+', 'match', 'once'));
end

function uninstallQuietly(identifier)
    try
        installedAddons = matlab.addons.installedAddons();
        if any(installedAddons.Identifier == identifier)
            matlab.addons.uninstall(identifier);
        end
    catch
        % Best-effort cleanup only.
    end
end

classdef ToolboxVersionTest < matlab.unittest.TestCase
% ToolboxVersionTest - Offline checks of toolbox location and version reporting

    methods (Test)
        function toolboxdirIsTheToolboxRoot(testCase)
            rootFolder = bot.internal.util.toolboxdir();
            testCase.verifyTrue(isfolder(rootFolder), ...
                sprintf('toolboxdir returned "%s", which is not a folder.', rootFolder));
            testCase.verifyTrue(isfile(fullfile(rootFolder, 'Contents.m')), ...
                'toolboxdir does not contain Contents.m.');
            testCase.verifyTrue(isfolder(fullfile(rootFolder, '+bot')), ...
                'toolboxdir does not contain the +bot package.');
        end

        function toolboxdirIsAbsolute(testCase)
            rootFolder = string(bot.internal.util.toolboxdir());
            if ispc
                isAbsolute = ~isempty(regexp(rootFolder, '^([A-Za-z]:|\\\\)', 'once'));
            else
                isAbsolute = startsWith(rootFolder, "/");
            end
            testCase.verifyTrue(isAbsolute, ...
                sprintf('toolboxdir returned a relative path: "%s".', rootFolder));
        end

        function versionMatchesContentsFile(testCase)
            [versionStr, versionNumber] = bot.internal.util.getToolboxVersion();
            testCase.verifyMatches(versionStr, '^\d+\.\d+\.\d+(\.\d+)?$');
            testCase.verifyClass(versionNumber, 'double');
            testCase.verifyGreaterThanOrEqual(numel(versionNumber), 3);

            contentsText = fileread(fullfile(bot.internal.util.toolboxdir(), 'Contents.m'));
            contentsVersion = regexp(contentsText, '(?<=Version )\d+\.\d+\.\d+', 'match', 'once');
            testCase.verifyTrue(startsWith(versionStr, contentsVersion), ...
                sprintf('getToolboxVersion returned %s, but Contents.m says %s.', versionStr, contentsVersion));
        end

        function onlyOneCopyOnPath(testCase)
            locations = which(fullfile('+bot', 'getSessions.m'), '-all');
            testCase.verifyNumElements(locations, 1, ...
                sprintf('Expected one copy of the toolbox on the path, found:\n%s', strjoin(locations, newline)));
        end
    end
end

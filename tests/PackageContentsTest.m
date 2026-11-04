classdef PackageContentsTest < matlab.unittest.TestCase
% PackageContentsTest - Offline checks that the toolbox's public API and files are present
%
%   These tests need no network access. They run against the working copy
%   (tools/tasks/testToolbox) and against an installed .mltbx
%   (tools/tasks/verifyToolboxInstallation), so they also catch files that
%   were left out of the packaged toolbox.

    properties (TestParameter)
        PublicFunction = {'listExperiments', 'listSessions', 'listProbes', ...
            'listChannels', 'listUnits', 'listCells', ...
            'getExperiments', 'getSessions', 'getProbes', ...
            'getChannels', 'getUnits', 'getCells', 'README'}
        ItemClass = {'bot.item.Session', 'bot.item.Experiment', 'bot.item.Probe', ...
            'bot.item.Channel', 'bot.item.Unit', 'bot.item.Cell', ...
            'bot.internal.Preferences', 'bot.internal.Cache'}
    end

    methods (Test)
        function publicFunctionIsOnPath(testCase, PublicFunction)
            location = which(char("bot." + PublicFunction));
            testCase.verifyNotEmpty(location, ...
                sprintf('bot.%s is not on the MATLAB path.', PublicFunction));
        end

        function publicFunctionHasHelp(testCase, PublicFunction)
            helpText = help(char("bot." + PublicFunction));
            testCase.verifyNotEmpty(strtrim(helpText), ...
                sprintf('bot.%s has no help text.', PublicFunction));
        end

        function classIsDefined(testCase, ItemClass)
            mc = meta.class.fromName(ItemClass);
            testCase.verifyNotEmpty(mc, sprintf('Class %s could not be found.', ItemClass));
        end

        function contentsListsPublicFunctions(testCase)
            contentsText = fileread(fullfile(bot.internal.util.toolboxdir(), 'Contents.m'));
            functionNames = {'listExperiments', 'listSessions', 'listProbes', ...
                'listChannels', 'listUnits', 'listCells', ...
                'getExperiments', 'getSessions', 'getProbes', ...
                'getChannels', 'getUnits', 'getCells'};
            for i = 1:numel(functionNames)
                testCase.verifySubstring(contentsText, "bot." + functionNames{i});
            end
        end

        function examplesAreShipped(testCase)
            examplesFolder = fullfile(bot.internal.util.toolboxdir(), 'examples');
            testCase.assertTrue(isfolder(examplesFolder), 'The examples folder is missing.');
            quickstarts = dir(fullfile(examplesFolder, '*Quickstart.mlx'));
            testCase.verifyNotEmpty(quickstarts, 'No quickstart live scripts were found in examples/.');
        end

        function gettingStartedGuideIsShipped(testCase)
            testCase.verifyTrue(isfile(fullfile(bot.internal.util.toolboxdir(), 'gettingStarted.mlx')));
        end

        function licenseIsShipped(testCase)
            testCase.verifyTrue(isfile(fullfile(bot.internal.util.toolboxdir(), 'LICENSE')));
        end

        function datasetEnumerationsResolve(testCase)
            [~, datasetNames] = enumeration('bot.item.internal.enum.Dataset');
            testCase.verifyEqual(sort(string(datasetNames)), ["VisualBehavior"; "VisualCoding"]);
            [~, datasetTypeNames] = enumeration('bot.item.internal.enum.DatasetType');
            testCase.verifyEqual(sort(string(datasetTypeNames)), ["Ephys"; "Ophys"]);
        end
    end
end

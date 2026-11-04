classdef (TestTags = {'Online'}) OnlineDataAccessTest < matlab.unittest.TestCase
% OnlineDataAccessTest - Smoke test that the toolbox can reach the Allen Brain Observatory
%
%   Downloads the Visual Coding 2P session manifest. Needs network access;
%   exclude it with testToolbox(ExcludeTags="Online").
%
%   On first use the toolbox asks (with a dialog) where to cache downloaded
%   data, unless a cache folder is already configured or the factory cache
%   folder exists. The setup creates the factory cache folder when neither
%   is present, so the test runs non-interactively (e.g. on CI).

    methods (TestClassSetup)
        function avoidFirstRunCacheDialog(testCase) %#ok<MANU>
            preferredCache = bot.internal.Preferences.getPreferenceValue('CacheDirectory');
            if preferredCache == ""
                factoryCache = fullfile(fileparts(which('bot.listSessions')), 'Cache');
                if ~isfolder(factoryCache)
                    mkdir(factoryCache);
                end
            end
        end
    end

    methods (Test)
        function listVisualCodingOphysSessions(testCase)
            sessions = bot.listSessions("VisualCoding", "Ophys");
            testCase.verifyClass(sessions, 'table');
            testCase.verifyGreaterThan(height(sessions), 0);
            testCase.verifyTrue(ismember('id', sessions.Properties.VariableNames));
        end
    end
end

classdef (TestTags = {'Online'}) OnlineDataAccessTest < matlab.unittest.TestCase
% OnlineDataAccessTest - Smoke test that the toolbox can reach the Allen Brain Observatory
%
%   Downloads the Visual Coding 2P session manifest. Needs network access;
%   exclude it with testToolbox(ExcludeTags="Online").
%
%   On first use the toolbox asks (with a dialog) where to cache downloaded
%   data. When no cache folder is configured, the setup points the
%   CacheDirectory preference at a temporary folder for the duration of the
%   test, so it runs non-interactively (e.g. on CI), and restores the
%   preference afterwards. (The factory cache folder lives inside the
%   toolbox folder, which is read-only for an installed toolbox.)

    methods (TestClassSetup)
        function avoidFirstRunCacheDialog(testCase)
            preferredCache = bot.internal.Preferences.getPreferenceValue('CacheDirectory');
            if preferredCache == ""
                tempCache = string(tempname);
                mkdir(tempCache);
                prefs = bot.util.getPreferences();
                prefs.CacheDirectory = tempCache;
                testCase.addTeardown(@() restoreCacheDirectory(prefs, preferredCache, tempCache));
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

function restoreCacheDirectory(prefs, originalValue, tempCache)
    try
        prefs.CacheDirectory = originalValue;
    catch ME
        warning('BOT:Test:RestoreCacheDirectoryFailed', ...
            'Could not restore the CacheDirectory preference to "%s": %s', originalValue, ME.message);
    end
    if isfolder(tempCache)
        rmdir(tempCache, 's');
    end
end

function results = testToolbox(options)
% testToolbox - Run the Brain Observatory Toolbox test suite in tests/
%
%   results = testToolbox() runs every test in tests/ against the working
%   copy (the repository root is added to the path), writes a JUnit report
%   and a Cobertura coverage report to docs/reports, and errors if any test
%   fails or if no tests were found.
%
%   results = testToolbox(UseInstalledToolbox=true) runs the same tests
%   against an installed copy of the toolbox (an .mltbx installed with
%   matlab.addons.install) instead. The repository root is NOT added to the
%   path, and the run errors if bot is not on the path or resolves to the
%   working copy. Code coverage is not collected in this mode.
%
%   Options:
%     ExcludeTags          - tests with any of these tags are skipped, e.g. "Online"
%     HasTag               - only run tests with this tag
%     UseInstalledToolbox  - test an installed toolbox instead of the working copy
%     CodeCoverage         - collect code coverage (default: true, unless installed)
%     ReportSubdirectory   - subfolder of docs/reports for the reports
%     Verbosity            - test runner verbosity (default: "Terse")

    arguments
        options.ExcludeTags (1,:) string = string.empty
        options.HasTag (1,1) string = ""
        options.UseInstalledToolbox (1,1) logical = false
        options.CodeCoverage (1,1) logical = true
        options.ReportSubdirectory (1,1) string = ""
        options.Verbosity (1,1) matlab.unittest.Verbosity = "Terse"
    end

    import matlab.unittest.TestSuite
    import matlab.unittest.TestRunner
    import matlab.unittest.plugins.CodeCoveragePlugin
    import matlab.unittest.plugins.XMLPlugin
    import matlab.unittest.plugins.codecoverage.CoberturaFormat
    import matlab.unittest.selectors.HasTag

    projectRoot = bottools.projectdir();
    testFolder = fullfile(projectRoot, "tests");

    if options.UseInstalledToolbox
        oldPath = addpath(testFolder);
        botLocation = string(which('bot.listSessions'));
        assert(botLocation ~= "", 'BOT:Test:ToolboxNotOnPath', ...
            'UseInstalledToolbox is true, but the Brain Observatory Toolbox is not on the path.');
        assert(~startsWith(botLocation, projectRoot + filesep), 'BOT:Test:WorkingCopyOnPath', ...
            ['UseInstalledToolbox is true, but bot resolves to the working copy (%s). ', ...
             'Run from another folder and remove the repository root from the path.'], botLocation);
        fprintf('Testing installed toolbox at %s\n', fileparts(fileparts(botLocation)));
        collectCoverage = false;
    else
        oldPath = addpath(projectRoot, testFolder);
        collectCoverage = options.CodeCoverage;
    end
    restorePath = onCleanup(@() path(oldPath)); %#ok<NASGU>

    outputDirectory = fullfile(projectRoot, "docs", "reports", options.ReportSubdirectory);
    if ~isfolder(outputDirectory)
        mkdir(outputDirectory)
    end

    suite = TestSuite.fromFolder(testFolder, "IncludingSubfolders", true);
    if options.HasTag ~= ""
        suite = suite.selectIf(HasTag(options.HasTag));
    end
    for tag = options.ExcludeTags
        suite = suite.selectIf(~HasTag(tag));
    end

    runner = TestRunner.withTextOutput("Verbosity", options.Verbosity);
    runner.addPlugin(XMLPlugin.producingJUnitFormat(fullfile(outputDirectory, "test-results.xml")));

    if collectCoverage
        mfileListing = dir(fullfile(projectRoot, "+bot", "**", "*.m"));
        coverageFiles = fullfile({mfileListing.folder}, {mfileListing.name});
        runner.addPlugin(CodeCoveragePlugin.forFile(coverageFiles, ...
            "Producing", CoberturaFormat(fullfile(outputDirectory, "codecoverage.xml"))));
    end

    results = runner.run(suite);

    fprintf(['Test result summary:\n', ...
        '   %d Passed, %d Failed, %d Incomplete.\n', ...
        '   %.04f seconds testing time.\n'], ...
        sum([results.Passed]), sum([results.Failed]), ...
        sum([results.Incomplete]), sum([results.Duration]));

    % assertSuccess() passes on an empty result array, so a broken test
    % discovery would otherwise report success.
    assert(numel(results) > 0, 'BOT:Test:NoTestsDiscovered', ...
        'Test discovery found no tests to run; failing rather than reporting success.');

    results.assertSuccess();

    if ~nargout
        clear results
    end
end

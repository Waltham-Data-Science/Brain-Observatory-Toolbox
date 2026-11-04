# Packaging, testing and releasing the toolbox

The Brain Observatory Toolbox is distributed as a MATLAB toolbox file
(`.mltbx`) attached to each [GitHub release](../../releases). The workflow is
modelled on [NDI-matlab](https://github.com/VH-Lab/NDI-matlab)'s and uses
[MatBox](https://github.com/ehennestad/MatBox) and
[matbox-actions](https://github.com/ehennestad/matbox-actions).

## What goes into the `.mltbx`

The code stays at the repository root, so MATLAB Online and File Exchange
links to `examples/` and `gettingStarted.mlx` keep working. To keep `.git`,
`.github`, `tools/` and `tests/` out of the toolbox, `tools/tasks/packageToolbox.m`
copies only the items listed under `FilesToPackage` in
[`tools/MLToolboxInfo.json`](tools/MLToolboxInfo.json) into `build/toolbox/`,
then packages that folder with MatBox. The `.mltbx` file is written to
`releases/`.

Toolbox metadata (name, identifier, author, minimum MATLAB release, getting
started guide) is also in `tools/MLToolboxInfo.json`. Keep the `Identifier`
the same from one release to the next: MATLAB uses it to recognise a new
version of an installed add-on.

## GitHub workflows

| Workflow | Runs on | What it does |
| --- | --- | --- |
| `run-tests.yml` | PRs, pushes to `main` | Code check of `+bot`, then the tests in `tests/` against the working copy |
| `test-packaging.yml` | PRs, pushes to `main` | Packages a test build with the same steps a release uses, checks no development files were packaged, then calls `verify-toolbox-installation.yml` |
| `verify-toolbox-installation.yml` | called by the other two | On Linux, Windows and macOS: installs the `.mltbx`, checks the installed toolbox, runs `tests/` against the installed copy, uninstalls it |
| `prepare-release.yml` | `v*.*.*` tags, manual runs | Validates the version, tests on every MATLAB release from `MinimumMatlabRelease` on, packages the `.mltbx`, creates the tag and a **draft** release with the `.mltbx` attached, then verifies the released file installs |

## Making a release

1. In a PR to `main`, update the `Version` line in `Contents.m`, e.g.
   `% Version 0.9.5 04-Nov-2026`. The release workflow does not commit to
   `main`, and it fails if `Contents.m` and the release version disagree.
2. Run **Prepare toolbox release** from the Actions tab with the version
   (e.g. `0.9.5`), or push a `v0.9.5` tag.
3. When all jobs pass, edit the draft release and publish it.

## Testing a distribution

These are the ways to test, from cheapest to most thorough.

**Automatically on every PR.** `test-packaging.yml` builds the `.mltbx`,
installs it on three operating systems and runs the test suite against the
installed copy. Only `tools/` and `tests/` are checked out for that job, so the
tests can only pass if the installed toolbox works. Specifically,
`tools/tasks/verifyToolboxInstallation.m` checks that:

- the add-on installs with the expected name, identifier and version
- `bot` resolves to the installed copy, not a working copy
- every `FilesToPackage` item and every example ships, and no `tools/`,
  `tests/` or `.github/` does
- `bot.internal.util.getToolboxVersion()` reports the installed version
- `tests/` passes against the installed toolbox, including an online test
  that downloads a session table from the Allen Brain Observatory
- the toolbox uninstalls and `bot` leaves the path

**By hand, from a CI build.** Every run of `test-packaging.yml` uploads the
`.mltbx` as the `toolbox-mltbx` artifact (kept for 14 days). Download it from
the run's summary page, double-click it in MATLAB (or call
`matlab.addons.install`), and open the getting started guide and examples.

**Locally.** With MatBox installed (`addpath(genpath("tools")); bottools.installMatBox`),
from the repository root:

```matlab
addpath(genpath("tools"))
testToolbox()                                        % test the working copy
testToolbox(ExcludeTags="Online")                    % ...without network access
[version, mltbx] = packageToolbox("specific", "0.9.5");  % build releases/*.mltbx
```

To test the built file, start a fresh MATLAB session in which the repository
root is not on the path, then:

```matlab
addpath(genpath("<repo>/tools"))
verifyToolboxInstallation("<repo>/releases/BrainObservatoryToolbox_v0_9_5.mltbx", ExpectedVersion="0.9.5")
```

**Before publishing a release.** The release stays a draft until you publish
it. Its `verify_installation` jobs install the exact `.mltbx` attached to the
draft, and you can download that file from the draft release and try it
yourself first.

function installMatBox()
% installMatBox - Install MatBox (https://github.com/ehennestad/MatBox) for local development
%
%   MatBox provides the packaging, testing and code checking tasks used by
%   tools/tasks/*.m. On GitHub Actions it is installed by the
%   ehennestad/matbox-actions/install-matbox action instead.
    websave('installMatBox.m', 'https://github.com/ehennestad/Matlab-Toolbox-Template/raw/refs/heads/main/tools/tasks/installMatBox.m');
    installMatBox()
    delete('installMatBox.m')
end

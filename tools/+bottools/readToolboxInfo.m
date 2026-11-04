function toolboxInfo = readToolboxInfo()
% readToolboxInfo - Read tools/MLToolboxInfo.json as a struct
    infoFile = fullfile(bottools.projectdir(), "tools", "MLToolboxInfo.json");
    toolboxInfo = jsondecode(fileread(infoFile));
end

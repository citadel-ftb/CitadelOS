--- Update the temp installer on boot
local citadel_os = require('citadel_rom/citadel_os')
local temp_install_file = shell.resolve("tmp/citadel_rom/install.lua")
local install_file = shell.resolve("install.lua")

if fs.exists(temp_install_file) then
    if fs.exists(install_file) then
        fs.delete(install_file)
    end
    fs.move(temp_install_file, install_file)
end

--- display status characteristics
print("Booting: "..os.getComputerLabel())

if type(citadel_os) == "table" and citadel_os.version ~= nil then
    slowPrint("CitadelOS "..citadel_os.version)
    local s_programs = "Citadel Programs: "
    local t_programs = citadel_os.get_programs()
    for _,file in pairs(install.files) do
        if file.label == "install" or file.label == citadel_os.program_label then
            if empty then
                empty = false
            else
                s_programs = s_programs..", "
            end
            s_programs = s_programs.file.target
        end
    end
    print(s_programs)
end
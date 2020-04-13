local citadel_os = require('/citadel_rom/citadel_os')
local install_file = "/citadel_rom/programs/install.lua"
local temp_install_file = install_file..".tmp"

if fs.exists(temp_install_file) then
    if fs.exists(install_file) then
        fs.delete(install_file)
    end
    fs.move(temp_install_file, install_file)
end

--- display status characteristics
print("Booting: "..os.getComputerLabel())

if type(citadel_os) == "table" and citadel_os.version ~= nil then
    print("CitadelOS "..citadel_os.version)
    local s_programs = "CitadelOS Programs: "
    local t_programs = citadel_os.get_programs()
    local empty = true
    for _,file in pairs(t_programs) do
        if empty then
            empty = false
        else
            s_programs = s_programs..", "
        end
        s_programs = s_programs..file.target
    end
    print(s_programs)
end
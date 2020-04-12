local citadel_os = {
    url = "https://raw.githubusercontent.com/citadel-ftb/CitadelOS/",
    branch = "master",
    program_label = (turtle and "program_turtle") or "program_computer",
    files = {
        { target = "startup/citadel_os.lua", label = "startup", source = "citadel/programs/startup.lua" },
        { target = "rom/modules/main/citadel/citadel_os.lua", label = "citadel_os", source = "citadel/citadel_os.lua" },
        { target = "rom/modules/main/citadel/modules/chunk.lua", label = "module", source = "citadel/modules/chunk.lua" },
        { target = "rom/modules/main/citadel/modules/gps_ext.lua", label = "module", source = "citadel/modules/gps_ext.lua" },
        { target = "rom/programs/citadel/install.lua", label = "installer", source = "citadel/programs/install.lua" },
        { target = "rom/programs/citadel/control.lua", label = "program_computer", source = "citadel/programs/computers/control.lua" },
        { target = "rom/programs/citadel/excavate.lua", label = "program_turtle", source = "citadel/programs/turtles/excavate.lua" },
        { target = "rom/programs/citadel/scaffold.lua", label = "program_turtle", source = "citadel/programs/turtles/scaffold.lua" },
    },
    version = "0.1.0"
}

function citadel_os.get_programs()
    local programs = {}
    for _,file in pairs(citadel_os.files) do
        if file.label == "installer" or file.label == citadel_os.program_label then
            table.insert(programs, file.target)
        end
    end
    return programs
end

local function contains(list, x)
    for _,value in pairs(list) do
        if value == x then
            return true
        end
    end
    return false
end

function citadel_os.get_files()
    local supported_labels = { "startup", "installer", "module", citadel_os.program_label }
    local supported_files = {}

    for _,file in pairs(citadel_os.files) do
        if contains(supported_labels, file.label) then
            table.insert(supported_files, file)
        end
    end

    return supported_files
end

function citadel_os.get_citadel_os_file()
    for _,file in pairs(citadel_os.files) do
        if file.label == "citadel_os" then
            return file
        end
    end
    return nil
end

return citadel_os
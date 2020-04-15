local citadel_os = {
    url = "https://raw.githubusercontent.com/citadel-ftb/CitadelOS/",
    branch = "feature-excavate",
    program_label = (turtle and "program_turtle") or "program_computer",
    files = {
        { target = "/startup/citadel_os.lua", label = "startup", source = "startup/citadel_os.lua" },
        { target = "/citadel_rom/citadel_os.lua", label = "citadel_os", source = "citadel_rom/citadel_os.lua" },
        { target = "/citadel_rom/apis/chunk.lua", label = "api", source = "citadel_rom/apis/chunk.lua" },
        { target = "/citadel_rom/apis/gps_ext.lua", label = "api", source = "citadel_rom/apis/gps_ext.lua" },
        { target = "/citadel_rom/programs/install.lua", label = "installer", source = "citadel_rom/programs/install.lua" },
        { target = "/citadel_rom/programs/control.lua", label = "program_computer", source = "citadel_rom/programs/computers/control.lua" },
        { target = "/citadel_rom/programs/extract.lua", label = "program_turtle", source = "citadel_rom/programs/turtles/extract.lua" },
        { target = "/citadel_rom/programs/scaffold.lua", label = "program_turtle", source = "citadel_rom/programs/turtles/scaffold.lua" },
    },
    version = "0.1.6"
}

function citadel_os.get_programs()
    local programs = {}
    for _,file in pairs(citadel_os.files) do
        if file.label == "installer" or file.label == citadel_os.program_label then
            table.insert(programs, file)
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
    local supported_labels = { "startup", "installer", "api", citadel_os.program_label }
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
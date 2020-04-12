local function sync_file(source_url, target_file)
    if fs.exists(target_file) then
        return "Bootstrap: can't run, file conflict"
    end

    local ok, err = http.checkURL( source_url )
    if not ok then
        return nil, err
    end

    local response = http.get( source_url , nil , true )
    if not response then
        return nil, "no response"
    end

    local s_response = response.readAll()
    response.close()

    local file = fs.open( target_file, "wb" )
    file.write( s_response )
    file.close()

    return target_file, nil
end

local err = sync_file("https://raw.githubusercontent.com/citadel-ftb/CitadelOS/master/citadel_rom/citadel_os.lua", "citadel_rom/citadel_os.lua")
if err ~= nil then
    return
end

err = sync_file("https://raw.githubusercontent.com/citadel-ftb/CitadelOS/master/citadel_rom/programs/install.lua", "citadel_rom/programs/citadel_os.lua")
if err ~= nil then
    return
end

shell.setPath(shell.path()..":/citadel_rom/programs")
shell.run("install")
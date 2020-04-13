
_G.package = {}

_G.package.cpath = ""
_G.package.loaded = {}
_G.package.loadlib = function() error("NotImplemented: package.loadlib") end
_G.package.path = table.concat({
    "?",
    "?.lua",
    "?/init.lua",
    "/lib/?",
    "/lib/?.lua",
    "/lib/?/init.lua",
    "/rom/apis/?",
    "/rom/apis/?.lua",
    "/rom/apis/?/init.lua",
    "/rom/apis/turtle/?",
    "/rom/apis/turtle/?.lua",
    "/rom/apis/turtle/?/init.lua",
    "/rom/apis/command/?",
    "/rom/apis/command/?.lua",
    "/rom/apis/command/?/init.lua",
}, ";")
_G.package.preload = {}
_G.package.seeall = function(module) error("NotImplemented: package.seeall") end
_G.module = function(m) error("NotImplemented: module") end

local _package_path_loader = function(name)

    local fname = name:gsub("%.", "/")

    for pattern in package.path:gmatch("[^;]+") do

        local fpath = pattern:gsub("%?", fname)

        if fs.exists(fpath) and not fs.isDir(fpath) then

            local apienv = {}
            setmetatable(apienv, {__index = _G})

            local apifunc, err = loadfile(fpath)
            local ok

            if apifunc then
                setfenv(apifunc, apienv)
                ok, err = pcall(apifunc)
            end

            if not apifunc or not ok then
                error("error loading module '" .. name .. "' from file '" .. fpath .. "'\n\t" .. err)
            end

            local api = {}
            if type(err) == "table" then
                api = err
            end
            for k,v in pairs( apienv ) do
                api[k] = v
            end

            return api
        end
    end
end

_G.package.loaders = {
    function(name)
        if package.preload[name] then
            return package.preload[name]
        else
            return "\tno field package.preload['" .. name .. "']"
        end
    end,

    function(name)
        local _errors = {}

        local fname = name:gsub("%.", "/")

        for pattern in package.path:gmatch("[^;]+") do

            local fpath = pattern:gsub("%?", fname)
            if fs.exists(fpath) and not fs.isDir(fpath) then
                return _package_path_loader
            else
                table.insert(_errors, "\tno file '" .. fpath .. "'")
            end
        end

        return table.concat(_errors, "\n")
    end
}

_G.require = function(name)
    if package.loaded[name] then
        return package.loaded[name]
    end

    local _errors = {}

    for _, searcher in pairs(package.loaders) do
        local loader = searcher(name)
        if type(loader) == "function" then
            local res = loader(name)
            if res ~= nil then
                package.loaded[name] = res
            end

            if package.loaded[name] == nil then
                package.loaded[name] = true
            end

            return package.loaded[name]
        elseif type(loader) == "string" then
            table.insert(_errors, loader)
        end
    end

    error("module '" .. name .. "' not found:\n" .. table.concat(_errors, "\n"))
end

local function printUsage()
    print( "Usages:" )
    print( "install <branch>" )
end

local citadel_os = require('citadel_rom/citadel_os')
local tArgs = { ... }
if #tArgs > 1 then
    printUsage()
    return
elseif #tArgs == 1 then
    citadel_os.branch = tArgs[1]
end

local function sync_file(manifest, manifest_file)
    local source_url = manifest.url..manifest.branch.."/"..manifest_file.source
    local target_file = shell.resolve((manifest_file.label == "installer" and manifest_file.target..".tmp") or manifest_file.target)
    if fs.exists(target_file) then
        fs.delete(target_file)
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

-- first we update citadel_os

local path, err = sync_file(citadel_os, citadel_os.get_citadel_os_file())
if err ~= nil then
    print("Error syncing installer: "..err)
    return
end
citadel_os = require(path)

if type(citadel_os) ~= "table" or citadel_os.version == nil then
    print("Error loading CitadelOS: could not load table or version")
    return
end

local sync_files = citadel_os.get_files()
for _,file in pairs(sync_files) do
    sync_file(citadel_os, file)
end

slowPrint("Installed CitadelOS "..citadel_os.version..".....")
shell.run("reboot")
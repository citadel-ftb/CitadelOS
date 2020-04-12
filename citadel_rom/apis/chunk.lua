local chunk = {
    SIZE = 16,
}

local function get_vectors_min(vectors, component)
    local length = table.getn(vectors)
    if length == 0 then
        return 0
    elseif length == 1 then
        return vectors[1][component]
    end
    local min_result = vectors[1][component]
    for i=2,length do
        local tmp = vectors[i][component]
        if tmp < min_result then
            min_result = tmp
        end
    end
    return min_result
end

function chunk.get_origin(gps_hosts) -- for this param you'll need to call extgps.locate()
    return { x = get_vectors_min(gps_hosts, 'x'), z = get_vectors_min(gps_hosts, 'z') }
end

function chunk.get_index(origin, pos)
    local dx = pos.x - origin.x
    local dz = pos.z - origin.z
    return { x = math.floor(dx / chunk.SIZE), z = math.floor(dz / chunk.SIZE) }
end

function chunk.get_position(origin, pos)
    local dx = pos.x - origin.x
    local dz = pos.z - origin.z
    return { x = dx % chunk.SIZE, y = pos.y, z = dz % chunk.SIZE }
end

return chunk
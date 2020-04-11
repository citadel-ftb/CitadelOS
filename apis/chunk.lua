local chunk = { SIZE = 16 }

local function getPositionsMin(fixes, axis)
    local length = table.getn(fixes)
    if length == 0 then
        return 0
    elseif length == 1 then
        return fixes[1].vPosition[axis]
    end
    local minResult = fixes[1].vPosition[axis]
    for i=2,length do
        local tmp = fixes[i].vPosition[axis]
        if tmp < minResult then
            minResult = tmp
        end
    end
    return minResult
end

function chunk.fromGPS(pos, fixes)
    local xMin = getPositionsMin(fixes, 'x')
    local zMin = getPositionsMin(fixes, 'z')
    local dx = pos.x - xMin
    local dz = pos.z - zMin

    return {
        index = { math.floor(dx / chunk.SIZE), -math.floor(dz / chunk.SIZE) },
        position = { x = dx % chunk.SIZE, y = pos.y, z = (chunk.SIZE - 1) - dz % chunk.SIZE },
    }
end

return chunk
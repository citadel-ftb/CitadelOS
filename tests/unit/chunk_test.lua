local chunk = require('citadel_rom/apis/chunk')

function testFromGPS()
    fixes = {}
    table.insert(fixes,{vPosition = { x = 335, y = 71, z = -128}})
    table.insert(fixes,{vPosition = { x = 320, y = 75, z = -128}})
    table.insert(fixes, {vPosition = { x = 335, y = 75, z = -113}})
    table.insert(fixes, {vPosition = { x = 320, y = 71, z = -113}})

    pos = { x = 332, y = 70, z = -116}
    result = chunk.parse_gps(pos, fixes)
    lu.assertEquals(result.index,{0, 0})
    lu.assertEquals(result.position, { x = 12, y = pos.y, z = 12})

    pos = { x = 315, y = 70, z = -120} -- west of origin
    result = chunk.parse_gps(pos, fixes)
    lu.assertEquals(result.index,{-1, 0})

    pos = { x = 348, y = 70, z = -114} -- east of origin
    result = chunk.parse_gps(pos, fixes)
    lu.assertEquals(result.index,{1, 0})

    pos = { x = 355, y = 70, z = -107} -- south east of origin
    result = chunk.parse_gps(pos, fixes)
    lu.assertEquals(result.index,{2, 1})

    pos = { x = 373, y = 70, z = -153} -- north east of origin
    result = chunk.parse_gps(pos, fixes)
    lu.assertEquals(result.index,{3, -2})

    pos = { x = 319, y = 70, z = -161} -- north west of origin
    result = chunk.parse_gps(pos, fixes)
    lu.assertEquals(result.index,{-1, -3})
end
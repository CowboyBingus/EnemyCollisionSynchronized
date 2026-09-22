-- Synthetic native-layout scene in this test process only. Native mutators are
-- stubs. Real ReadProcessMemory cost is measured without opening the game.
return function(M, api, living, dead, corpse_count)
    local ffi, bit = require('ffi'), require('bit')
    local owners = {}
    local function alloc(size)
        local storage = ffi.new('uint8_t[?]', math.max(size, 8))
        owners[#owners + 1] = storage
        return ffi.cast('uint8_t *', storage)
    end
    local function u(at, value) ffi.cast('uint32_t *', at)[0] = value end
    local function p(at, value) ffi.cast('uint8_t **', at)[0] = value end
    local function matrix(at, x)
        ffi.copy(at, ffi.new('float[16]', {1,0,0,0,0,1,0,0,0,0,1,0,x or 0,0,0,1}), 64)
    end
    local g, e = alloc(0x3330000), alloc(0x2800000)
    local resource, profile
    for key, value in pairs(M.profiles) do if value.name == 'Bile Titan' then resource, profile = key, value end end
    local actors_per_unit = profile.bodies
    local aux = {}
    for name, node in pairs(profile.actors) do
        if not profile.main_names[name] then aux[#aux + 1] = {name, node}; actors_per_unit = actors_per_unit + 1 end
    end
    assert(actors_per_unit < 128)
    local total = living + dead + corpse_count
    local mode = alloc(0x44); u(mode+8, 1); u(mode+0x40, 2); p(g+0x33266a0, mode)
    local registry, generations, slots = alloc(0xa8), alloc(total), alloc(total*8)
    p(e+0x1a100f0, registry); p(registry+0xa0, generations); p(registry+0x88, slots); u(registry+0x98, total)
    ffi.fill(generations, total, 1)
    local lists = alloc(total*24); p(e+0x27c5b40, lists)
    local maximum = (dead+corpse_count)*actors_per_unit+1
    local actor_rows, body_rows = alloc(maximum*40), alloc(maximum*160)
    local pool = e+0x2369b00+64*21
    p(pool, actor_rows); u(pool+28, 40); u(pool+36, maximum); u(pool+40, 0xfffffff); u(pool+52, 0xc0000000)
    local world, vt = alloc(64), alloc(144)
    p(e+0x27ba8a8+176*2, world); p(world, vt); p(vt+136, e+0xd0cfa0); p(world+24, body_rows)
    local next_actor, units, handles_by_unit, runtimes, entity_rows = 1, {}, {}, {}, {}
    for _, corpse in ipairs({false, true}) do
        local count = corpse and corpse_count or living+dead
        local manager, entities = alloc(88), alloc(count*8)
        local runtime, sync = alloc(count*(corpse and 72 or 11192)), alloc(count*(corpse and 56 or 432))
        p(g+(corpse and 0x3326920 or 0x3326948), manager)
        u(manager+(corpse and 16 or 4), count); u(manager+(corpse and 24 or 12), count); u(manager+(corpse and 28 or 16), count)
        p(manager+(corpse and 64 or 56), entities); p(manager+72, runtime); p(manager+80, sync)
        for index = 0, count-1 do
            local slot = corpse and living+dead+index or index
            local unit = 0x400000+slot
            local entity = alloc(24); ffi.copy(entity, resource, 8); u(entity+8, slot+100); u(entity+12, unit)
            entity_rows[unit]=entity
            p(entities+index*8, entity)
            local r = runtime+index*11192
            if not corpse then
                u(r+11160, profile.bodies); r[11172] = 1
                if index >= living then u(sync+index*432, profile.bodies); u(sync+index*432+184, profile.bodies) end
            end
            if corpse or index >= living then
                units[#units+1] = unit
                local object, nodes = alloc(0x100), alloc(profile.nodes*64)
                p(slots+slot*8, object); u(object+8, unit); u(object+0x70, profile.nodes); p(object+0x88, nodes)
                for node = 0, profile.nodes-1 do matrix(nodes+node*64) end
                local list, handles = lists+slot*24, alloc(actors_per_unit*4)
                u(list, unit); u(list+4, 0x40000000+actors_per_unit); p(list+8, handles)
                handles_by_unit[unit] = {}
                for i = 1, actors_per_unit do
                    local id = 0x90000000+next_actor
                    local ar, body = actor_rows+next_actor*40, body_rows+next_actor*160
                    local name = i <= profile.bodies and profile.main[i] or aux[i-profile.bodies][1]
                    local node_hash = i <= profile.bodies and name or aux[i-profile.bodies][2]
                    u(handles+(i-1)*4, id); u(ar, id); u(ar+12, unit); u(ar+16, 1); u(ar+20, next_actor)
                    u(ar+24, name); u(ar+28, i-1); u(ar+32, node_hash)
                    matrix(body); u(body+108, i<=profile.bodies and (corpse and 48 or 52) or 20)
                    u(body+144, id); u(body+148, unit)
                    handles_by_unit[unit][i] = body
                    if not corpse and i<=profile.bodies then u(r+(i-1)*712, id) end
                    next_actor = next_actor+1
                end
                if not corpse then runtimes[unit] = {r=r, manager=manager, index=index} end
            end
        end
    end
    local clock = 0
    api.time = function() return clock end
    local state = {native={pose=function()end, disable=function()end, request_completion=function()end,
        stop_sync=function(manager,index)
            for _, row in pairs(runtimes) do if row.manager==manager and row.index==index then row.r[11172]=0 end end
        end}}
    return api, g, e, state, {owners=owners, units=units, bodies=handles_by_unit, mode=mode,
        tick=function(t) clock=t end, matrix=matrix, u=u, actors_per_unit=actors_per_unit, entities=entity_rows}
end

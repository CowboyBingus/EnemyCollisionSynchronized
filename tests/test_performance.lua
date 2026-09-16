local source, fixtures = assert(arg[1]), assert(arg[2])
local ffi = require('ffi')
local M = dofile(source..'/corpse_data.lua')
local scene = dofile(fixtures..'/perf_scene.lua')
local production = dofile(source..'/windows_api.lua')()
local memory = ffi.new('uint8_t[16]',{1,2,3,4,5,6,7,8})
local first=assert(production.read(memory,8))
memory[0]=99;assert(production.read(memory,8):byte()==99 and first:byte()==1)
assert(production.read(nil,8)==nil and production.read(memory,32769)==nil)
assert(production.read(memory,0)==nil and production.read(memory,-1)==nil)
local before=production.clock();assert(production.clock()>=before)

-- Batched checks preserve every byte predicate, including overlapping guards,
-- cache invalidation, changed addresses and fallback across unreadable gaps.
local block=ffi.new('uint8_t[256]');ffi.fill(block,256,3)
local guards={{address=block+4,bytes=string.rep('\3',4)},{address=block+20,bytes=string.rep('\3',4)}}
assert(M.same(production,guards));block[22]=9;assert(not M.same(production,guards));block[22]=3
guards[2].bytes='\3\3\9\3';assert(not M.same(production,guards));guards[2].bytes=string.rep('\3',4)
guards[2].address=block+40;assert(M.same(production,guards));block[40]=9;assert(not M.same(production,guards))
guards[2].address=block+20
guards[#guards+1]={address=block+6,bytes='bad!'};assert(not M.same(production,guards));guards[3]=nil
local underlying=production.read
production.read=function(at,size)if size>4 then return nil end;return underlying(at,size)end
assert(M.same(production,guards),'Unreadable batching gap falls back to individual checks')
production.read=underlying

local function fixture(living,dead,corpses,cost)
    local api={pointer=production.pointer,address=production.address,distance=production.distance}
    local ticks,reads=0,0
    -- Synthetic storage is owned by this process; only benchmark.lua measures
    -- operating-system read overhead. Correctness tests use a deterministic clock.
    api.read=function(at,size)ticks=ticks+(cost or 0);reads=reads+1;return ffi.string(at,size)end
    api.clock=function()return ticks end
    local _,g,e,state,f=scene(M,api,living,dead,corpses)
    return api,g,e,state,f,function()return reads end
end
do
    local api,g,e,state,f,reads=fixture(1500,0,0)
    for i=1,20 do
        local scanned,inspected=state.scan_entities or 0,state.deep_inspections or 0
        local old=reads();f.tick(i/30);assert(M.apply(api,g,e,state))
        assert(state.scan_entities-scanned<=M.max_entities and state.deep_inspections-inspected==0)
        assert(reads()-old<300 and state.observed==0,'Living crowds must not trigger deep reads')
    end
    assert(state.budget_yields==20)
end
collectgarbage('collect')
do
    local api,g,e,state,f=fixture(300,24,24)
    local seen,original={},M.plan
    M.plan=function(unit)seen[unit.unit]=true;return original(unit)end
    for i=1,240 do
        local before=state.deep_inspections or 0
        f.tick(i/30);assert(M.apply(api,g,e,state))
        assert(state.deep_inspections-before<=M.max_units)
    end
    M.plan=original
    for _,unit in ipairs(f.units) do assert(seen[unit],'A manager or unit starved') end
    f.u(f.mode+8,0);M.apply(api,g,e,state)
    assert(next(state.fling_history)==nil and next(state.fling_stopped)==nil and next(state.cursors)==nil)
end
collectgarbage('collect')
do
    local api,g,e,state,f=fixture(500,2,2,.00003)
    for i=1,160 do
        local scanned=state.scan_entities or 0
        local deep=state.deep_inspections or 0
        f.tick(i/30);M.apply(api,g,e,state)
        assert(state.scan_entities-scanned<=M.max_entities and state.deep_inspections-deep<=1)
    end
    assert(state.budget_yields>0,'Deadline must end the current work slice')
end
collectgarbage('collect')
-- A large living crowd must still permit repeated observations, arming and a
-- verified stop for a remote corpse. Deliberately expire a later sampling gap:
-- deferred work must never reuse a stale motion baseline to issue a stop.
do
    local api,g,e,state,f=fixture(1500,1,1,.000001)
    local unit=f.units[1]
    for i=1,180 do f.tick(i/30);M.apply(api,g,e,state) end
    assert(state.fling_history[unit] and state.fling_history[unit].armed,'Living crowd prevented motion arming')
    for _,body in ipairs(f.bodies[unit]) do f.matrix(body,2) end
    for i=600,620 do f.tick(i/30);M.apply(api,g,e,state) end
    assert(not state.fling_stops and state.max_revisit_seconds>1,'Expired history was reused to stop motion')
    for i=621,800 do f.tick(i/30);M.apply(api,g,e,state) end
    assert(state.fling_history[unit] and state.fling_history[unit].armed)
    for _,body in ipairs(f.bodies[unit]) do f.matrix(body,4) end
    for i=801,860 do f.tick(i/30);M.apply(api,g,e,state) end
    assert(state.fling_stops==1 and state.fling_stops_verified==1,'Bounded scan missed renewed root motion')
end
collectgarbage('collect')
-- Revalidation must remain between native commands, even though actor headers
-- and guard reads are batched. First command changes identity: no second write.
do
    local api,g,e,state,f=fixture(0,0,1)
    local unit=f.units[1]
    f.matrix(f.bodies[unit][16],2);f.matrix(f.bodies[unit][17],3)
    local calls=0
    state.native.pose=function()
        calls=calls+1;f.u(f.entities[unit]+16,123)
    end
    M.apply(api,g,e,state);assert(calls==1,'Identity change must cancel remaining commands')
end
print('PASS: scratch read ownership, precise batched guards, living-crowd read cap, bounded work, manager fairness, mission reset and between-command identity races')

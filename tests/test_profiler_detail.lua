local source=assert(arg[1])
local now,cycles,heap,writes=0,0,100,0
local output
local env=setmetatable({collectgarbage=function(mode)assert(mode=='count');return heap end,
    os={getenv=function()return 'test'end},io={open=function()return {
        write=function(_,text)writes=writes+1;output=text;return true end,close=function()return true end}end}},{__index=_G})
env._G=env
env.CowboyBingusModLoader={open_log=function(name)
    assert(name=='EnemyCollisionSynchronized-Performance.log')
    return env.io.open('test/CowboyBingus/Helldivers2/Logs/'..name,'w')
end}
local P=setfenv(assert(loadfile(source..'/profiler.lua')),env)()
local api={clock=function()return now end,time=function()return now end,
    thread_cycles=function()return cycles end,read=function(_,size)return string.rep('a',size)end}
local p=P.new(api,'test');local state={mission_flag=1,realignments=0}
local function step(ms,c)now=now+ms/1000;cycles=cycles+(c or 100)end
local start=p.update_started();step(20);p.update_finished(start,true)
assert(p.chain.count==1 and math.abs(p.chain.maximum-20)<.00001)
p.begin(state);p.phase('snapshot');p.detail('skeleton');api.read(1234567,64);step(10,10000)
local old=p.phase('validation');step(5);p.phase(old);p.detail('actors');step(25,100)
state.realignments=2;heap=80;p.finish(state)
assert(p.worst[1].wall_ms>39.99 and p.worst[1].phases.snapshot>34.99)
assert(p.worst[1].phases.validation>4.99 and p.worst[1].actions.realignments==2)
assert(p.worst[1].cycles>0 and p.worst[1].heap_delta_kb==-20)
assert(p.rows.snapshot.max_poll_ms>34.99)
assert(p.details.skeleton.sampled_ms>9.99 and p.details.skeleton.sampled_ms<10.01)
assert(p.details.actors.sampled_ms>24.99 and p.details.actors.sampled_ms<25.01)
assert(p.details.skeleton.reads==1 and p.details.skeleton.bytes==64)
assert(p.scopes.mission.count==1 and p.stats.over33==1)
for i=1,20 do p.begin(state);step(i);p.finish(state)end
assert(#p.worst==8 and p.worst[1].wall_ms>39.99)
local unit={unit=77,id=88,resource='synthetic',owner=false,active=true,update_enabled=true,profile_lifecycle='ragdoll_settled'}
p.begin(state);p.unit('Impaler',now,p.reads,unit);p.finish(state)
step(1100)
p.begin(state);p.unit('Impaler',now,p.reads,unit);p.finish(state)
assert(p.late_revisits==1 and p.max_late_revisit>1)
step(1100);unit.profile_lifecycle='corpse_aligned'
p.begin(state);p.unit('Impaler',now,p.reads,unit);p.finish(state)
assert(p.late_revisits==1,'Conversion is not a late ragdoll revisit')
step(1100);unit.profile_lifecycle='ragdoll_settled';unit.id=89
p.begin(state);p.unit('Impaler',now,p.reads,unit);p.finish(state)
assert(p.late_revisits==1,'Reused unit identity is not a late revisit')
state.mission_flag=0;state.max_revisit_seconds=2
p.begin(state);p.finish(state)
assert(next(p.revisits)==nil and p.scopes.outside_mission.count==1)
local text=p.text(state)
assert(text:find('late_ragdoll_revisit',1,true) and not text:find('motion_history_sampling_gap',1,true))
assert(text:find('workload=Impaler lifecycle=corpse_aligned ownership=remote',1,true))
assert(not text:find('1234567',1,true) and not text:find('synthetic',1,true),'No addresses or resource identity in export')
now=20;p.flush(state);assert(writes==1 and p.window.count==0)
p.begin(state);step(1);p.finish(state)
assert(p.window.count==1 and p.stats.count>1)
assert(p.text(state):find('window_polls=1 ',1,true))
p.flush(state);assert(writes==1)
p.flush(state,true);assert(writes==2)
-- Failure to export must retain the recent window for the next successful write.
env.io.open=function()error('locked')end
p.begin(state);step(1);p.finish(state);p.flush(state,true);assert(p.window.count==1)
-- Optional timing probes may fail without breaking the profiler.
api.thread_cycles=function()error('unavailable')end;env.collectgarbage=function()error('unavailable')end
p.begin(state);step(1);p.finish(state)
assert(#p.text(state)<40000,'Report size must stay bounded')
print('PASS: slow-poll context, exclusive sampled subphases, cycles/heap probes, bounded records, lifecycle costs, real late revisits, update-chain timing, windows and failure isolation')

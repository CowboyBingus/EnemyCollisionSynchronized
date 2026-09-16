local source=assert(arg[1])
local now,writes,closes,text=0,0,0,nil
local env=setmetatable({os={getenv=function()return 'test-output'end},io={open=function()
    return {write=function(_,bytes)writes=writes+1;text=bytes end,close=function()closes=closes+1 end}
end}},{__index=_G})
local P=setfenv(assert(loadfile(source..'/profiler.lua')),env)()
local api={clock=function()return now end,read=function(_,size)now=now+.0001;return string.rep('x',size)end}
local profiler=P.new(api,'test')
local state={}
profiler.begin();profiler.phase('snapshot');api.read(123,8)
profiler.phase('validation');api.read(456,4);profiler.finish(state)
assert(state.read_calls==2 and state.read_bytes==12)
assert(profiler.rows.snapshot.reads==1 and profiler.rows.validation.reads==1)
assert(profiler.rows.snapshot.sampled_reads==1 and profiler.rows.validation.sampled_reads==1)
assert(math.abs(profiler.total-.2)<.00001)
assert(profiler.text(state):find('dominant_phase=',1,true))
profiler.flush(state);assert(writes==0)
now=10;profiler.flush(state);assert(writes==1 and closes==1)
assert(not text:find('123',1,true) and not text:find('456',1,true),'No entity pointers in export')
profiler.begin();profiler.phase('native');now=now+.003;profiler.finish(state)
assert(profiler.text(state):find('slow_mod_poll',1,true))
assert(profiler.rows.native.ms>=3)
profiler.flush(state);assert(writes==1)
profiler.flush(state,true);assert(writes==2 and closes==2)
env.io.open=function()error('Locked output')end
assert(pcall(profiler.flush,state,true),'Diagnostic errors must not affect gameplay')
-- Nested validation scopes restore attribution to their caller.
profiler.begin();profiler.phase('snapshot')
local previous=profiler.phase('validation');api.read(789,16);profiler.phase(previous)
api.read(790,4);profiler.finish(state)
assert(profiler.rows.snapshot.reads==2 and profiler.rows.validation.reads==2)
print('PASS: complete read accounting, exclusive phase timing, sampled read timing, hotspot flagging, bounded output and failure isolation')

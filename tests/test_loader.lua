local source=assert(arg[1])
local function test(kind)
    local env=setmetatable({print=function()end,os={getenv=function()end}},{__index=_G});env._G=env
    env.CowboyBingusModLoader={api=1,version=kind=='old' and 8 or 9}
    local now,calls,order=0,0,{}
    env.update=function(...)order[#order+1]='game';if kind=='game_error' then error('game error') end;return 1,nil,3 end
    env.shutdown=function()return 4,nil,6 end
    local original=env.update
    local api={time=function()return now end,module=function(n)return n and 1 or 2 end,
        module_hash=function(n)return kind=='build' and 'wrong' or n==1 and 'game' or 'exe' end,
        bind=function()if kind=='binding' then error('wrong physics API') end;return {} end}
    local patch={interval=1/30,apply=function(a,g,e,state)
        assert(a==api and g==1 and e==2);calls=calls+1;order[#order+1]='repair'
        if kind=='transient' and calls==1 then error('manager changed') end
        return true,'ready',true
    end}
    patch.profiler=setfenv(assert(loadfile(source..'/profiler.lua')),env)()
    local install=setfenv(assert(loadfile(source..'/archive_loader.lua')),env)()
    install(function()return api end,patch,{revision='test',game_sha256='game',exe_sha256='exe'})
    if kind=='old' or kind=='build' or kind=='binding' then assert(env.update==original and calls==0);return end
    local wrapped=env.update;install(function()error('duplicate')end,patch,{});assert(env.update==wrapped)
    if kind=='game_error' then
        assert(not pcall(env.update));assert(calls==0 and env.CorpseCollisionRepair.status=='stopped_after_update_error')
    else
        local a,b,c=env.update();assert(a==1 and b==nil and c==3 and calls==1)
        assert(order[1]=='game' and order[2]=='repair')
        assert(select('#',env.update())==3 and calls==1,'Duplicate frame cannot submit again')
        now=.04;env.update();assert(calls==2)
        if kind=='transient' then assert(env.CorpseCollisionRepair.retries==1 and env.CorpseCollisionRepair.active) end
    end
    local a,b,c=env.shutdown();assert(a==4 and b==nil and c==6)
    local saved=calls;now=100;pcall(env.update);assert(calls==saved)
end
for _,kind in ipairs({'normal','old','build','binding','transient','game_error'}) do test(kind) end
print('PASS: dependency/build/binding gates, callback order and tuples, bounded poll frequency, retry, failure isolation, duplicate loads and shutdown')

-- Routine gameplay must not write diagnostics unless explicitly enabled.
for _,diagnostics in ipairs({false,true})do
    local now,opens,profiles=0,0,0
    local e=setmetatable({print=function()end},{__index=_G});e._G=e
    e.CowboyBingusDiagnostics=diagnostics
    e.CowboyBingusModLoader={api=1,version=99,open_log=function()
        opens=opens+1;return {write=function()end,close=function()end}
    end}
    e.update=function()return 1,nil,3 end;e.shutdown=function()return 4,nil,6 end
    local api={time=function()return now end,module=function(n)return n or 'exe'end,
        module_hash=function()return 'hash'end,bind=function()return {}end,read=function()return ''end}
    local patch={interval=1/30,apply=function()return true,'waiting_for_mission',false end,
        profiler={new=function()profiles=profiles+1;return {}end},stop=function()return true end,cleanup=function()return true end}
    setfenv(assert(loadfile(source..'/archive_loader.lua')),e)()(function()return api end,patch,
        {revision='fixture',game_sha256='hash',exe_sha256='hash'})
    local startup=opens
    for i=1,600 do now=i/60;local a,b,c=e.update(1/60);assert(a==1 and b==nil and c==3)end
    assert(diagnostics and opens>startup or not diagnostics and opens==startup,'routine log writes require opt-in')
    assert(profiles==(diagnostics and 1 or 0),'profiler requires explicit opt-in')
    e.shutdown();assert(opens>startup,'shutdown report remains available')
end
print('PASS: silent default, opt-in diagnostics, shutdown report and callback returns')

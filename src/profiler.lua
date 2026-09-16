-- Bounded aggregate telemetry: no entity IDs, pointers, positions or per-frame
-- file writes. Read timings are sampled; phase timings cover every mod poll.
local P = {}
local stages = {'discovery','snapshot','validation','planning','motion','native','maintenance','logging'}
local buckets = {.1,.25,.5,1,2,4,8,16,33,100,1000,math.huge}
function P.new(api, revision)
    local clock = api.clock or api.time
    local p = {rows={}, units={}, histogram={}, polls=0, updates=0, reads=0, bytes=0,
        total=0, maximum=0, output_max=0, started=clock(), revision=revision}
    for _, name in ipairs(stages) do p.rows[name]={ms=0,reads=0,bytes=0,read_ms=0,sampled_reads=0} end
    function p.phase(name)
        local old=p.current
        if p.running then
            local now=clock()
            if old then p.rows[old].ms=p.rows[old].ms+(now-p.phase_at)*1000 end
            p.current=name;p.phase_at=now
        end
        return old
    end
    function p.begin()
        p.running=true;p.current='maintenance';p.start=clock();p.phase_at=p.start
        p.read_start=p.reads;p.byte_start=p.bytes;p.sample=p.polls%30==0
    end
    local read=api.read
    api.read=function(address,size)
        if not p.running then return read(address,size) end
        local row=p.rows[p.current]
        p.reads=p.reads+1;p.bytes=p.bytes+size;row.reads=row.reads+1;row.bytes=row.bytes+size
        if p.sample then
            local start=clock();local bytes=read(address,size)
            row.read_ms=row.read_ms+(clock()-start)*1000;row.sampled_reads=row.sampled_reads+1
            return bytes
        end
        return read(address,size)
    end
    function p.unit(name, start, reads)
        local row=p.units[name]
        if not row then row={count=0,ms=0,max=0,reads=0};p.units[name]=row end
        local elapsed=(clock()-start)*1000
        row.count=row.count+1;row.ms=row.ms+elapsed;row.max=math.max(row.max,elapsed);row.reads=row.reads+p.reads-reads
    end
    function p.finish(state)
        local now=clock()
        p.rows[p.current].ms=p.rows[p.current].ms+(now-p.phase_at)*1000
        p.running=false
        local elapsed=(now-p.start)*1000
        p.polls=p.polls+1;p.total=p.total+elapsed;p.maximum=math.max(p.maximum,elapsed)
        for i,upper in ipairs(buckets) do if elapsed<=upper then p.histogram[i]=(p.histogram[i] or 0)+1;break end end
        state.read_calls=p.reads-p.read_start;state.read_bytes=p.bytes-p.byte_start
        state.performance_last_ms=elapsed;state.performance_max_ms=p.maximum
    end
    function p.text(state)
        local seconds=math.max(.001,clock()-p.started)
        local dominant, dominant_ms='none',0
        for _,name in ipairs(stages) do if p.rows[name].ms>dominant_ms then dominant,dominant_ms=name,p.rows[name].ms end end
        local percentile,seen=0,0
        if p.polls>0 then
            for i,upper in ipairs(buckets) do seen=seen+(p.histogram[i] or 0);if seen>=p.polls*.95 then percentile=upper;break end end
        end
        local flags={}
        if p.maximum>2 then flags[#flags+1]='slow_mod_poll' end
        if p.output_max>2 then flags[#flags+1]='slow_diagnostic_output' end
        if (state.budget_yields or 0)>0 then flags[#flags+1]='work_deferred' end
        if (state.max_revisit_seconds or 0)>1 then flags[#flags+1]='motion_history_sampling_gap' end
        local lines={'Enemy Collision Synchronized performance '..revision,
            'scope=mod_callback_only; phase times are exclusive; read timings sample one poll in 30',
            'native timings measure dispatch, not later engine physics work; update rate is not GPU FPS',
            string.format('seconds=%.2f polls=%d update_calls=%d update_calls_per_second=%.2f',seconds,p.polls,p.updates,p.updates/seconds),
            string.format('mod_ms_mean=%.4f mod_ms_p95_upper=%.4f mod_ms_max=%.4f mod_ms_per_second=%.4f',p.total/math.max(1,p.polls),percentile,p.maximum,p.total/seconds),
            string.format('profiler_output_ms_max=%.4f dominant_phase=%s flags=%s',p.output_max,dominant,table.concat(flags,','))}
        for _,name in ipairs(stages) do
            local row=p.rows[name]
            lines[#lines+1]=string.format('phase=%s ms=%.4f reads=%d bytes=%d sampled_read_ms=%.4f sampled_reads=%d',
                name,row.ms,row.reads,row.bytes,row.read_ms,row.sampled_reads)
        end
        local names={};for name in pairs(p.units) do names[#names+1]=name end;table.sort(names)
        for _,name in ipairs(names) do
            local row=p.units[name]
            lines[#lines+1]=string.format('enemy=%s inspections=%d mean_ms=%.4f max_ms=%.4f reads=%d',name,row.count,row.ms/row.count,row.max,row.reads)
        end
        for _,key in ipairs({'scan_entities','deep_inspections','budget_yields','max_revisit_seconds','ragdoll_count','corpse_count',
            'realignments','claws_disabled','fling_stops','completion_requests','skipped','retries'}) do
            lines[#lines+1]=key..'='..tostring(state[key] or 0)
        end
        return table.concat(lines,'\n')..'\n'
    end
    function p.flush(state, force)
        local now=clock()
        if not force and now-(p.last_output or p.started)<10 then return end
        p.last_output=now
        -- Diagnostics must never disable collision repair when a file is locked.
        pcall(function()
            local directory=os.getenv('LOCALAPPDATA');if not directory then return end
            local file=io.open(directory..'/EnemyCollisionSynchronized-Performance.log','w');if not file then return end
            local ok=pcall(function() file:write(p.text(state)) end)
            file:close();assert(ok,'Profiler output failed')
        end)
        p.output_max=math.max(p.output_max,(clock()-now)*1000)
    end
    return p
end
return P

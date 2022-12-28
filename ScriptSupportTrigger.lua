
-- <定义开发者触发器>

--[[ 加载模式 （参考_G.ScriptSupportLoadMode）
    {
        ssvar2 = true, -- 通用变量模式，整合了对象库和变量库
        ...
    }
]]
_G._owid_ = nil -- 当前地图ID
_G._LoadMode_ = {} -- 加载模式
_G._Active_ = false -- 是否活跃
_G._ScriptFenv_ = nil -- 脚本运行的域空间

-- API 管理器
_G.APIMgrList = {
    ScriptSupportEvent = true, -- 事件
    Game = true,
    World = true,
    Actor = true,
    Player = true,
    PlayerGroup = true,
    Creature = true,
    CreatureGroup = true,
    GameRule = true,
    MapMark = true,
    UI = true,
    GameEventQue = true,
    WorldContainer = true,
    MiniTimer = true,
    Block = true,
    Team = true,
    Area = true,
    Spawnport = true,
    Backpack = true,
    VarLib2 = true, -- 变量库2.0 整合后版本
    ObjectLib = true,
    Item = true,
    Chat = true,
    Debug = true,
    Task = true,
    Buff = true, -- 效果
    Graphics = true, -- 图文信息
    ListenParam = true, -- 监听事件函数
    Valuegroup = true, -- 监听事件函数
    ScriptSupportListenMgr = true, -- 监听数据管理类
}



-----------------------------------------------------------------------------------------

-- 开发者触发器加载
-- owid : number : 当前地图ID
-- debugToggle : boolean : 调试模式是否开启
-- loadMode : table : 模式，用来控制加载方式
function SSTLoadTrigger(owid, debugToggle, loadMode)
    print('--- Script Support Trigger Init ---', owid, debugToggle, loadMode)

    --{{{ 每次进来初始化
    _G._owid_ = owid
    _G._LoadMode_ = loadMode or {}
    _G._Active_ = false
    _G._ScriptFenv_ = nil
    --}}}

    -- API加载
    for apiname, _ in pairs(APIMgrList) do
        _G[apiname] = class[apiname].new()
    end

    -- 其他对象
    --_G.CurEventParam = {}

    -- 加载触发器
    do
        _G.Trigger = class.Trigger.new(debugToggle, _LoadMode_)

        -- init
        -- TODO...
    end
    
    -- 加载热更新内容
    Dev_HotFixByFile()
    -- 加载域
    InitScriptFenv()

    -- 重定向'print'
    SSTPrintInit();
    _G._Active_ = true -- 活跃
end

-- 开发者触发器释放
function SSTReleaseTrigger()
    print('--- Script Support Trigger Release ---')
    _G._Active_ = false -- 取消活跃

    -- 释放域
    ReleaseScriptFenv()

    -- 释放触发器
    do
        Trigger:stop()

        -- release
        -- TODO...

        _G.Trigger = nil
    end

    -- 其他对象
    --_G.CurEventParam = {}
    ScriptSupportListenMgr:ClearnAllLIsten()
    -- API加载
    for apiname, _ in pairs(APIMgrList) do
        _G[apiname] = nil
    end

    _G._LoadMode_ = nil
    _G._owid_ = nil
end

-- 初始化域
function InitScriptFenv()
    local os_time = os.time
    local os_date = os.date
    local genv = _G

    local _ScriptFenv_buffer_ = {}
    local _ScriptFenv_base_ = {
        io = {}, -- 屏蔽io
        loadfile = function() end, -- 屏蔽加载文件
        dofile = function() end, -- 屏蔽加载文件
        package = {}, -- 屏蔽package
        require = function() end, -- 屏蔽require
        os = { -- 屏蔽os
            time = os_time,
			date = os_date,
        },
    }
    _G._ScriptFenv_ = setmetatable({}, {
        __index = function(t, key)
            local data = _ScriptFenv_base_[key]
            if data ~= nil then
                return data
            end
            local data = _ScriptFenv_buffer_[key]
            if data ~= nil then
                return data
            end
            return genv[key]
        end,
        __newindex = function(t, key, val)
            if _ScriptFenv_base_[key] ~= nil then
                return
            end
            _ScriptFenv_buffer_[key] = val
        end,
    })
end

-- 释放域
function ReleaseScriptFenv()
    _G._ScriptFenv_ = nil
end

-- 调试是否活跃，仅PC支持调试
function IsDebugOn()
    return (_LoadMode_.debug and _LoadMode_.pc) and true or false
end



-- 开发者模块tick，用于触发器每个tick执行一次
-- 在 SSTLoadTrigger() 执行之后才被执行
function SSTTick()
    if not _G._Active_ then -- 活跃才执行
        return
    end
    -- TODO...
    ScriptSupportListenMgr:Tick()
    Trigger:tick()
end

--移除监听事件
function SSTRemoveListenMgr(data)
    ScriptSupportListenMgr:removeListenObjs(data)
end

--保存监听事件
function SSTRefreshGraphicsEvent(data)
    -- ScriptSupportListenMgr:refevent(data)
end

-- 解析事件参数, 生成
-- param : table : 由事件触发时附带
function SSTParseParam(param)

    -- 触发事件玩家 TriggerByPlayer
    -- 触发事件生物 TriggerByCreature
    -- 事件目标玩家 EventTargetPlayer
    -- 事件目标生物 EventTargetCreature
    -- 触发事件道具(投掷物) TriggerByMissile
    -- 事件目标道具(掉落物) EventTargetDropItem
    -- 事件目标道具类型(使用道具) EventTargetItemID
    -- 事件中道具数量 EventTargetItemNum
    -- 事件中的方块 EventTargetBlock
    -- 事件触发位置 EventTargetPos
    -- 事件中的动作表情 EventTargetAct
    -- 事件中的特效 EventTargetEffect
    -- 事件中的快捷栏 EventShortCutIdx
    -- 事件中的执行结果 EventExeResult
    -- 事件中的广告名称 EventADName
    -- 事件中的状态效果 EventBuffid
    -- 事件中的装备栏 EquipItemPos
    -- 事件中的字符串 EventString
    -- 自定义参数 ex_customparams

    local CurEventParam = {}

    if not param then
        return CurEventParam
    end

    -- 事件参数传递
    if param.def then
        CurEventParam = copy_table(param.def)
    end
    

    
    -- 事件
    local t_param = {
       eventobjid = param.eventobjid, -- 计时器ID
       toobjid = param.toobjid, -- 计时器名称
    }

    local obevent = (param.eventobjid and param.eventobjid > 0 and observer_event_info) and observer_event_info(t_param) or nil
    local objtype = nil
    local toltype = nil
    local shortix = nil
    if obevent then
        objtype = obevent.objtype
        toltype = obevent.toltype
        shortix = obevent.shortix
        if not param.x or not param.z then
            param.x,param.y,param.z = obevent.x,obevent.y,obevent.z
        end
    end
    -- 触发事件
    local eventobjid = param.eventobjid
    if eventobjid then
        if objtype then
            objtype = GameActorTypeToObjType[objtype]
            if objtype == OBJ_TYPE.OBJTYPE_PLAYER then
                CurEventParam.TriggerByPlayer = eventobjid
                if shortix then
                    CurEventParam.EventShortCutIdx = shortix
                else
                    if Player and Player.getCurShotcut then
                        local ret, shotcut = Player:getCurShotcut(eventobjid)
                        if ret == ErrorCode.OK then
                            CurEventParam.EventShortCutIdx = shotcut
                        end
                    end
                end
            elseif objtype == OBJ_TYPE.OBJTYPE_CREATURE then
                CurEventParam.TriggerByCreature = eventobjid
            elseif objtype == OBJ_TYPE.OBJTYPE_DROPITEM then
                CurEventParam.EventTargetDropItem = eventobjid
            elseif objtype == OBJ_TYPE.OBJTYPE_MISSILE then
                CurEventParam.TriggerByMissile = eventobjid
            end
        else
            if Actor and Actor.getObjType then
                local ret, objtype = Actor:getObjType(eventobjid)
                if ret == ErrorCode.OK then
                    if objtype == OBJ_TYPE.OBJTYPE_PLAYER then
                        CurEventParam.TriggerByPlayer = eventobjid
                    elseif objtype == OBJ_TYPE.OBJTYPE_CREATURE then
                        CurEventParam.TriggerByCreature = eventobjid
                    elseif objtype == OBJ_TYPE.OBJTYPE_DROPITEM then
                        CurEventParam.EventTargetDropItem = eventobjid
                    elseif objtype == OBJ_TYPE.OBJTYPE_MISSILE then
                        CurEventParam.TriggerByMissile = eventobjid
                    end
                end
            end
        end
    end

    -- 事件目标
    local toobjid = param.toobjid
    if toobjid then
        if toltype then
            toltype = GameActorTypeToObjType[toltype]
            if toltype == OBJ_TYPE.OBJTYPE_PLAYER then
                CurEventParam.EventTargetPlayer = toobjid
            elseif toltype == OBJ_TYPE.OBJTYPE_CREATURE then
                CurEventParam.EventTargetCreature = toobjid
            elseif toltype == OBJ_TYPE.OBJTYPE_DROPITEM then
                CurEventParam.EventTargetDropItem = toobjid
            elseif toltype == OBJ_TYPE.OBJTYPE_MISSILE then
                CurEventParam.TriggerByMissile = toobjid
            end
        else
            if Actor and Actor.getObjType then
                local ret, objtype = Actor:getObjType(toobjid)
                if ret == ErrorCode.OK then
                    if objtype == OBJ_TYPE.OBJTYPE_PLAYER then
                        CurEventParam.EventTargetPlayer = toobjid
                    elseif objtype == OBJ_TYPE.OBJTYPE_CREATURE then
                        CurEventParam.EventTargetCreature = toobjid
                    elseif objtype == OBJ_TYPE.OBJTYPE_DROPITEM then
                        CurEventParam.EventTargetDropItem = toobjid
                    elseif objtype == OBJ_TYPE.OBJTYPE_MISSILE then
                        CurEventParam.TriggerByMissile = toobjid
                    end
                end
            end
        end
        
    end
    
    -- 位置 x, y, z
    local x = param.x
    local y = param.y or -1
    local z = param.z
    if x and z then
        CurEventParam.EventTargetPos = {x = x, y = y, z = z}
    elseif not CurEventParam.EventTargetPos then
        -- 如果有触发事件对象，取其位置
        if eventobjid then
            if Actor and Actor.getPosition then
                local ret, x, y, z = Actor:getPosition(eventobjid)
                if ret == ErrorCode.OK then
                    CurEventParam.EventTargetPos = {x = x, y = y, z = z}
                end
            end
        end
    end

    CurEventParam.EventTargetItemNum = param.itemnum -- 道具数量
    CurEventParam.EventTargetAct = param.act -- 动画表情
    CurEventParam.EventTargetEffect = param.effectid -- 事件中的特效
    CurEventParam.EventADName = param.EventADName -- 广告名
    CurEventParam.EventExeResult = param.EventExeResult -- 执行结果
    CurEventParam.EquipItemPos = param.itemix --装备栏位置取值范围[8000 ~ 8004] 上下可取,事件中的装备栏
    CurEventParam.Hurtlv = param.hurtlv   -- 伤害值
    CurEventParam.Itemnum = param.itemnum
    CurEventParam.ex_customparams = param.ex_customparams -- *自定义参数*
    CurEventParam.EventString = param.content --字符串
    --设备时间的年月日时分秒
    local time = os.time()
    CurEventParam.EventDate = {
        year = os.date("%Y", time),
        month = os.date("%m", time),
        day = os.date("%d", time),
        hour = os.date("%H", time),
        minute = os.date("%M", time),
        second = os.date("%S", time),
        time = os.date("%Y-%m-%d %H:%M:%S", time),
    }
    return CurEventParam
end

-- 解析事件参数, 生成
-- param : table : 由事件触发时附带
function SSTParseParamEx(CurEventParam, param,modpacketid)
    CurEventParam.EventTargetBlock = param.blockid -- 方块
    CurEventParam.EventTargetItemID = param.itemid -- 道具类型
    CurEventParam.Actorid = param.actorid
    CurEventParam.Craftid = param.craftid
    CurEventParam.Furanceid = param.furanceid
    CurEventParam.Plotid = param.plotid
    CurEventParam.EventTargetBuff = { -- 事件中的状态效果
    id = param.buffid,
    lvl = param.bufflvl or 1,
    }
    CurEventParam.targetactorid = param.targetactorid -- 目标生物类型
    CurEventParam.modpacketid = modpacketid or nil
end

-- 填充插件相关信息
local plugintype_fill = {
    block = {
        plugintype = "blockid",
        transCurrent2Origin = function(pluginid, modpacketid)
            return scriptsupport.transfom_pluginid_current2origin(modpacketid, "block", pluginid)
        end,
    },
    actor = {
        plugintype = "actorid",
        transCurrent2Origin = function(pluginid, modpacketid)
            return scriptsupport.transfom_pluginid_current2origin(modpacketid, "actor", pluginid)
        end,
    },
    item = {
        plugintype = "itemid",
        transCurrent2Origin = function(pluginid, modpacketid)
            return scriptsupport.transfom_pluginid_current2origin(modpacketid, "item", pluginid)
        end,
    },
    craft = {
        plugintype = "craftid",
        transCurrent2Origin = function(pluginid, modpacketid)
            return scriptsupport.transfom_pluginid_current2origin(modpacketid, "craft", pluginid)
        end,
    },
    furnace = {
        plugintype = "furnaceid",
        transCurrent2Origin = function(pluginid, modpacketid)
            return scriptsupport.transfom_pluginid_current2origin(modpacketid, "furnace", pluginid)
        end,
    },
    plot = {
        plugintype = "plotid",
        transCurrent2Origin = function(pluginid, modpacketid)
            return scriptsupport.transfom_pluginid_current2origin(modpacketid, "plot", pluginid)
        end,
    },
    status = {
        plugintype = "buffid",
        transCurrent2Origin = function(pluginid, modpacketid)
            local ok, pluginid_origin = TransfomStatusCurrent2Origin(modpacketid,pluginid)
            return pluginid_origin
        end,
    },
}
function SSTFillPluginData(param, param_def, modpacketid)
    -- 按插件类型依次变更
    for _, info in pairs(plugintype_fill) do
        local plugintype = info.plugintype
        local pluginid = param_def[plugintype]
        if pluginid then
            param[plugintype] = info.transCurrent2Origin(pluginid, modpacketid)
        end
    end
end

-- table深度拷贝
function copy_table(ori_tab)
    if (type(ori_tab) ~= "table") then
        return nil
    end
    local new_tab = {}
    for i,v in pairs(ori_tab) do
        local vtyp = type(v)
        if (vtyp == "table") then
            new_tab[i] = copy_table(v)
        elseif (vtyp == "thread") then
            new_tab[i] = v
        elseif (vtyp == "userdata") then
            new_tab[i] = v
        else
            new_tab[i] = v
        end
    end
    return new_tab
end

--初始化'print'
function SSTPrintInit()
    -- 脚本执行环境
    local newgt = _G._ScriptFenv_
    if not newgt then
        return
    end
    
    -- 脚本环境重载print
    if UI and UI.Print2Wnd and UI.InitPrintData then
		if ClientMgr and ClientMgr:isPureServer() then
            newgt.print_console = _G.print
			return
		end

        -- 打印到控制台
        newgt.print_console = _G.print
        
        --普通全局打印
        newgt.print = function(...)
            UI:Print2Wnd(...)
        end

        --带tag的打印
        newgt.printtag = function(tag, ...)
            UI:Print2WndWithTag(tag, ...);
        end

        --error
        newgt.error = function(...)
            local tag = "error";
            UI:Print2WndWithTag(tag, ...); 
        end

        --warn
        newgt.warn = function(...)
            local tag = "warning";
            UI:Print2WndWithTag(tag, ...); 
        end

        UI:InitPrintData();
    end
end

-- 加载lua脚本
function LoadLuaScript(luascript, scriptname)
    if not luascript or string.len(luascript) == 0 then
        return nil
    end

    scriptname = scriptname or "(noname)"
    local fcallback

    -- 调试模式
    if false and IsDebugOn() then
        local filepath = LoadLuaScriptDebug(luascript, scriptname)
        if filepath then
            -- 编译
            local f, errorlog = loadfile(filepath)
            if f then
                fcallback = f
            else
                SSScriptErrorPrint(errorlog, scriptname, "COMPILE ERROR!")
            end
        else
            SSScriptErrorPrint(nil, scriptname, "COMPILE ERROR!")
        end
    end

    -- 默认模式
    if not fcallback then
        -- 编译
        local f, errorlog = loadstring(luascript)
        if f then
            fcallback = f
        else
            SSScriptErrorPrint(errorlog, scriptname, "COMPILE ERROR!")
        end
    end

    return function (...)
        if fcallback then
            return DoLuaScriptFunction(fcallback, scriptname, ...)
        end
    end
end

-- 加载lua脚本(调试模式)
function LoadLuaScriptDebug(luascript, scriptname)
    -- 脚本名称转化成可以作为文件名的字符串
    scriptname = string.gsub(scriptname, "[\\/:*?\"<>|]", "_") or ""
    
    -- 限制长度
    if string.len(scriptname) > 100 then
        scriptname = string.sub(scriptname, 1, 100)
    end
    
    -- 写入文件，用于调试
    return scriptsupport.load_debug_file(luascript, scriptname)
end

-- 执行lua脚本
function DoLuaScript(luascript, scriptname, mod, modpacketid)
    local fcallback = LoadLuaScript(luascript, scriptname)
    if fcallback then
        return fcallback(mod, modpacketid)
    end
end

-- 加载lua脚本方法
-- param : f : function : 脚本主体功能的方法
-- param : scriptname : string : 脚本名称
-- param : mod : table : 局部触发器，如actorid=123 或者 blockid=300等
-- param : modpacketid : number : 插件包ID，默认全局的，插件包ID是nil
function DoLuaScriptFunction(f, scriptname, mod, modpacketid)
    local script_Fenv = _ScriptFenv_
    if not script_Fenv then
        print("SS ERROR! _ScriptFenv_ is nil!")
        return nil
    end
    local genv = _G

    -- 设置域
    local newgt = {
        __FILE__ = scriptname,
        __ssmod__ = mod, -- 插件，局部触发器，默认全局，nil
        __modpacketid__ = modpacketid, -- 插件包ID，默认全局，nil
    }
    local newgt_api = copy_table(newgt)
    newgt._G = script_Fenv
    newgt_api._G = genv
    newgt_api.print = script_Fenv.print_console

    local function getApiMgr(mgrins, gt, validkeys)
        -- api service
        mgrins = mgrins or {}
    
        local mgrgt = {}
        setmetatable(mgrgt, {
            __index = function(tF, keyF)
                local methodins = mgrins[keyF]
                if (not validkeys or validkeys[keyF]) and type(methodins) == "function" then
                    setfenv(methodins, gt) -- 对API也应用函数域
                end
                return methodins
            end,
            __newindex = function(tF, keyF, valF)
                if type(mgrins[keyF]) ~= "function" then -- api不允许修改
                    mgrins[keyF] = valF
                end
            end,
        })
        return mgrgt
    end

    -- 设置API域以及全局域
    local triggerins = _G.Trigger or {}
    local classins = _G.class or {}
    local apiTriggerList = triggerins.apiTriggerList or {}
    local env = {
        __index = function(t, key)
            if key == "Trigger" then
                -- 触发器调用api
                local triggergt = {}
                setmetatable(triggergt, {
                    __index = function(tT, keyT)
                        local tgt = triggerins[keyT]
                        if type(tgt) == "function" then
                            setfenv(tgt, newgt_api) -- 对API也应用函数域
                        elseif apiTriggerList[keyT] then
                            return getApiMgr(tgt, newgt_api)
                        end
                        return tgt
                    end,
                    __newindex = function(tT, keyT, valT)
                        if apiTriggerList[keyT] then
                            return
                        end
                        triggerins[keyT] = valT
                    end,
                })
                return triggergt
            elseif key == "class" then
                -- 左值
                local classgt = {}
                setmetatable(classgt, {
                    __index = function(tC, keyC)
                        local mgrins = classins[keyC]
                        local mgrgt = {}
                        setmetatable(mgrgt, {
                            __index = function(tF, keyF)
                                local methodins = mgrins[keyF]
                                if keyF == "new" then
                                    return function(...)
                                        local obj = methodins(...) or {}
                                        if obj.setenv then
                                            obj:setenv(newgt_api) -- 环境
                                        else
                                            print("SS ERROR! setenv is not function(is nil)!")
                                        end
                                        return obj
                                    end
                                end
                                return methodins
                            end,
                            __newindex = function(tF, keyF, valF)
                                return
                            end,
                        })
                        return mgrgt
                    end,
                    __newindex = function(tC, keyC, valC)
                        classins[keyC] = valC
                    end,
                })
                return classgt
            elseif key == "ScriptSupportEvent" then
                return getApiMgr(genv[key], newgt_api, {
                    registerEvent = true, -- 有效key
                    registerEvent_NoError = true, -- 有效key
                    regDynamicEventOnce = true, -- 有效key
                })
            elseif APIMgrList[key] then
                return getApiMgr(genv[key], newgt_api)
            end
            return script_Fenv[key]
        end,
        __newindex = function(t, key, val)
            if APIMgrList[key] then
                return
            end
            script_Fenv[key] = val
        end
    }
    setmetatable(newgt_api, env)
    setmetatable(newgt, env)
    --setfenv(1, newgt)
    setfenv(f, newgt) -- 设置编译出的函数的域

    -- 运行
    local ok, ret = pcall(f)
    if not ok then
        SSScriptErrorPrint(ret, scriptname, "RUN ERROR!")
        return nil
    end

    return ret
end

-- 脚本错误打印
-- errorlog : string : 错误消息
-- script : string : 脚本提示
-- title : string : 显示错误消息的title
function SSScriptErrorPrint(errorlog, script, title)
    print("SSLuaScript Failed! errorlog=" .. tostring(errorlog))

    script = script and tostring(script)  or '<no tip>'
    title = title and tostring(title) or 'ERROR'

    local errorPrint = _G._ScriptFenv_ and _G._ScriptFenv_.print or _G.print

    -- 限制脚本提示长度
    local scriptlimit = 33 -- 依实际情况调整(>3)
    if string.len(script) > scriptlimit then
        script = string.sub(script, 1, scriptlimit - 3) .. '...'
    end

    local content = title .. '#cff0000[' .. script .. ']#n'

    local function get_error_desc(errorlog)
        if type(errorlog) ~= 'string' then
            return
        end

        local begi, endi = string.find(errorlog, '%[string "(.+)"%]:')
        if not begi then
            return
        end

        -- 检测是否系统报错，系统报错不提示详情
        local checki = string.find(errorlog, "luascript")
        if checki == begi + string.len('[string "') then
            return
        end

        begi, endi = string.find(errorlog, '(%d+):', endi + 1)
        if not begi then
            return
        end
    
        local numline = tonumber(string.sub(errorlog, begi, endi - 1) or 0) or 0
        local errorContent = string.sub(errorlog, endi + 1) or ''

        numline = '#cff0000' .. tostring(numline) .. "#n"
        errorContent = '#cff0000' .. errorContent .. "#n"
        return ':' .. numline .. ':' .. errorContent
    end

    local errordesc = get_error_desc(errorlog)
    if errordesc then
        content = content .. errordesc
    end

    errorPrint(content)
end

-- 调用API
-- modulename : string : api对象
-- methodname : string : api对象的方法
-- paramjson : string : json字符串参数，数组
function SSCallApi(modulename, methodname, paramjson)
    if not modulename or not methodname or not paramjson then
        assert(false)
        return
    end

    local module = _G[modulename]
    local method = module and module[methodname]
    if not method then
        assert(false)
        return
    end

    -- 参数是json
    local params = {}
    if #paramjson > 0 then
        local ok, dataT = pcall(JSON.decode, JSON, paramjson)
        if not ok then
            assert(false)
            return
        else
            params = dataT
        end
    end

    -- 执行
    local ret = {method(module, unpack(params))} -- 返回值转成数组
    if not ret[1] then
        return
    end

    -- 返回指转换回json
    local ok, jsonout = pcall(JSON.encode, JSON, ret)
    if not ok then
        return
    end

    return jsonout
end


function TransfomStatusCurrent2Origin(modpacketid,buffid, bufflv)
    bufflv = bufflv or 1
    if not modpacketid or modpacketid == "" then
        return ErrorCode.OK,  buffid, bufflv
    end

    buffid = scriptsupport.transfom_pluginid_current2origin(modpacketid, "status", buffid)
    if not buffid then
        return ErrorCode.FAILED, 0, 0
    end
    return  ErrorCode.OK, buffid, bufflv
end

function TransfomPluginOrigin2Current(modpacketid,buffid, bufflv)
    bufflv = bufflv or 1
    if not modpacketid or modpacketid == "" then
        return ErrorCode.OK, buffid, bufflv
    end

    buffid = scriptsupport.transfom_pluginid_origin2current(modpacketid, "status", buffid)
    if not buffid then
        return ErrorCode.FAILED, 0, 0
    end
    return ErrorCode.OK, buffid, bufflv
end

function Dev_HotFixByFile()
    local content = ""
    local root = scriptsupport.getStdioRoot and scriptsupport.getStdioRoot() or ""
    local filepath = 'data/http/ma/dev_hotfix.lua'
    local file = io.open(root..filepath, 'r')
    if file then
        content = file:read('*a')
        file:close()
    end

    local data = json2table(content)
    if data and type(data) == "table" then
        for k, v in pairs(data) do
            local fun = loadstring(v)
            if type(fun) =="function" then
                fun()
            else
                print(v)
            end
        end
    end
    
end

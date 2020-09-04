
--[[in C===================================================================
local data,len = _encode(p1,...) --p1 must not nil
local p1,... = _decode(pack)
_callin( net, data )
_callout( remote,onCallout:(remote,name,args,_encode(name,args)) 
--]]
--lua===================================================================
--[[
_decode = _decode or --in C
function( data ) --temp low test
	local a, b = string.find(data,'{')
	if a then
		local fn = string.sub(data,1,a-1)
		local args = load('return '..string.sub(data, b, -1) )()
		return fn, args
	end
end
_encode = _encode or --in C
function( rpc, data ) --temp low test
	local s
	if rpc then
		s = rpc..table.tostr(data)
	else
		s = table.tostr(data)
	end
	return s, #s
end
_callout = _callout or --in C
if not _callout( net ) then
	_callout( net, function( net, rpc, args, data, len )
		local data,len = _encode(rpc,args)
		net:send(string.from32l(len))
		net:send(data,len)
	end, 0 )
end
_G._callout = _callout or function(o,onCallout)
	local mt = getmetatable(o)
	local _index = mt and mt.__index
	if _index then
		if onCallout then
			assert(mt.__callout~=_index,'"already _callout with a different function'..tostring(_index))
		else
			return mt.__callout==_index
		end
	end
	local _rpcs = {}
	local callout = function(o,k)
		local l = string.sub(k,1,1)
		if l>='A' and l<='Z' then
			local cc = _rpcs[o]
			if not cc then
				cc = {}
				_rpcs[o] = cc
			end
			local c = cc[k]
			if not c then
				c = function(t)
					return onCallout(o,k,t,_encode(k,t))
				end
				cc[k] = c
			end
			return c
		end
		if type(_index)=='table' then
			return _index[k]
		elseif type(_index)=='function' then
			return _index(o,k)
		end
	end
	if mt then
		mt.__index = callout
		mt.__callout = callout
	else
		mt = {__index=callout,__callout=callout}
		setmetatable(o,mt)
	end
	return o
end
--]]

function dev()
	local Login_C = {}
	local Login_C_meta = {
		keys = {
			[1] = {'varint',1,'protoId'},
			[2] = {'openId',2},
			[3] = {'protoId',3},
		},
		__index = {
			protoId = 91,
			Encode = function(t)
				
			end,
			Decode = function(b)
				local t = Login_C{}
			end,
		},
	}
	Login_C_meta.__call = function(self,t)
		return setmetatable(t,Login_C_meta)
	end,
	setmetatable(Login_C,Login_C_meta)
	
	local t = Login_C{uid=123}
	local b = t:Encode()
	local b = Login_C.Encode(t)
	local t = Login_C.Decode(b)

end

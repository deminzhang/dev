#pragma once

#include "LuaScript.h"

/*��ѡһ��*/
/*��ֱ��ע�ᵽ_G[name]=��*/
LUAEXTEND_API int luaopen_protobuf_G(lua_State* L, const char*name);
/*��=require("ע��Ŀ���")*/
LUAEXTEND_API int luaopen_protobuf(lua_State* L);

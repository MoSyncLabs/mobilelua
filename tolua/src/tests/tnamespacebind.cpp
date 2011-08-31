/*
** Lua binding: tnamespace
** Generated automatically by tolua 5.1.4 on Mon Apr 18 14:55:59 2011.
*/

#include "tolua.h"

#ifndef __cplusplus
#include <stdlib.h>
#endif
#ifdef __cplusplus
 extern "C" int tolua_bnd_takeownership (lua_State* L); // from tolua_map.c
#else
 int tolua_bnd_takeownership (lua_State* L); /* from tolua_map.c */
#endif
#include <string.h>

/* Exported function */
TOLUA_API int tolua_tnamespace_open (lua_State* tolua_S);
LUALIB_API int luaopen_tnamespace (lua_State* tolua_S);

#include "tnamespace.h"

/* function to register type */
static void tolua_reg_types (lua_State* tolua_S)
{
}

/* get function: A::a */
static int tolua_get_A_a(lua_State* tolua_S)
{
 tolua_pushnumber(tolua_S,(lua_Number)A::a);
 return 1;
}

/* set function: A::a */
static int tolua_set_A_a(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (!tolua_isnumber(tolua_S,2,0,&tolua_err))
 tolua_error(tolua_S,"#vinvalid type in variable assignment.",&tolua_err);
#endif
  A::a = ((int)  tolua_tonumber(tolua_S,2,0));
 return 0;
}

/* get function: A::B::b */
static int tolua_get_B_b(lua_State* tolua_S)
{
 tolua_pushnumber(tolua_S,(lua_Number)A::B::b);
 return 1;
}

/* set function: A::B::b */
static int tolua_set_B_b(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (!tolua_isnumber(tolua_S,2,0,&tolua_err))
 tolua_error(tolua_S,"#vinvalid type in variable assignment.",&tolua_err);
#endif
  A::B::b = ((int)  tolua_tonumber(tolua_S,2,0));
 return 0;
}

/* get function: A::B::C::c */
static int tolua_get_C_c(lua_State* tolua_S)
{
 tolua_pushnumber(tolua_S,(lua_Number)A::B::C::c);
 return 1;
}

/* set function: A::B::C::c */
static int tolua_set_C_c(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (!tolua_isnumber(tolua_S,2,0,&tolua_err))
 tolua_error(tolua_S,"#vinvalid type in variable assignment.",&tolua_err);
#endif
  A::B::C::c = ((int)  tolua_tonumber(tolua_S,2,0));
 return 0;
}

/* Open lib function */
LUALIB_API int luaopen_tnamespace (lua_State* tolua_S)
{
 tolua_open(tolua_S);
 tolua_reg_types(tolua_S);
 tolua_module(tolua_S,NULL,0);
 tolua_beginmodule(tolua_S,NULL);
 tolua_module(tolua_S,"A",1);
 tolua_beginmodule(tolua_S,"A");
 tolua_variable(tolua_S,"a",tolua_get_A_a,tolua_set_A_a);
 tolua_module(tolua_S,"B",1);
 tolua_beginmodule(tolua_S,"B");
 tolua_variable(tolua_S,"b",tolua_get_B_b,tolua_set_B_b);
 tolua_module(tolua_S,"C",1);
 tolua_beginmodule(tolua_S,"C");
 tolua_variable(tolua_S,"c",tolua_get_C_c,tolua_set_C_c);
 tolua_endmodule(tolua_S);
 tolua_endmodule(tolua_S);
 tolua_endmodule(tolua_S);
 tolua_endmodule(tolua_S);
 return 1;
}
/* Open tolua function */
TOLUA_API int tolua_tnamespace_open (lua_State* tolua_S)
{
 lua_pushcfunction(tolua_S, luaopen_tnamespace);
 lua_pushstring(tolua_S, "tnamespace");
 lua_call(tolua_S, 1, 0);
 return 1;
}

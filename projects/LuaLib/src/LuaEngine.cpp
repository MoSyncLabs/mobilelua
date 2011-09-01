/*
 * Copyright (c) 2010 MoSync AB
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "toluabindings/tolua.h"
#include "inc/SystemAPI.h"
}

#include <maapi.h>
#include <MAUtil/Geometry.h>
#include <conprint.h>

#include "inc/LuaEngine.h"

// #include <tolua/tolua.h>

// This function loads the tolua generated bindings to MoSync.
extern "C" TOLUA_API int tolua_lua_maapi_open (lua_State* tolua_S);

namespace MobileLua
{

// ========== Helper functions ==========

/**
 * Set the user data object at the given key.
 */
static void setUserData(lua_State *L, const char* key, void* data)
{
	// Push key.
	// lua_pushlightuserdata(L, (void*)&key);  // Use a C pointer as a key
	lua_pushstring(L, key);

	// Push value.
	lua_pushlightuserdata(L, data);

	// Store in register.
	lua_settable(L, LUA_REGISTRYINDEX);
}

/**
 * Get the user data object at the given key.
 */
static void* getUserData(lua_State *L, const char* key)
{
	// Push key.
	lua_pushstring(L, key);

	// Get value.
	lua_gettable(L, LUA_REGISTRYINDEX);

	// Return value.
	void* data = (void*) lua_topointer(L, -1);

	// Pop value before returning it.
	lua_pop(L, 1);

	return data;
}

/**
 * Returns true if the stack element is an integer.
 */
static bool isinteger(lua_State *L, int narg)
{
	lua_Integer d = lua_tointeger(L, narg);
	if (d == 0 && !lua_isnumber(L, narg))
	{
		return false;
	}
	else
	{
		return true;
	}
}

static LuaEngine* getLuaEngineInstance(lua_State *L)
{
    // Get pointer to engine instance from global Lua register.
    return (LuaEngine*) getUserData(L, "LuaEngineInstance");
}


/**
 * Define a global table if it does not exist.
 */
static void ensureThatGlobalTableExists(
	lua_State *L,
	const char* tableName)
{
	// Push global or nil onto the stack.
	lua_getglobal(L, tableName);

	// Does the global variable exist?
	if (lua_isnoneornil(L, -1))
	{
		// It does not exist. Push new table onto stack.
		lua_newtable(L);

		// Define it as a global variable. This pops the table off the stack.
		lua_setglobal(L, tableName);
	}

	// Important to pop the initial global element.
	lua_pop(L, 1);
}

static void RegTableFun(
	lua_State* L,
	const char* tableName,
	const char* funName,
	lua_CFunction funPointer)
{
	ensureThatGlobalTableExists(L, tableName);

	// Push table onto stack.
	lua_getglobal(L, tableName);

	// Push table key.
	lua_pushstring(L, funName);

	// Push value.
	lua_pushcfunction(L, funPointer);

	// Set table entry. Pops value and key.
	lua_rawset(L, -3);

	// Pop table off the stack.
	lua_pop(L, 1);
}

static void RegFun(
	lua_State* L,
	const char* funName,
	lua_CFunction funPointer)
{
	lua_pushcfunction(L, funPointer);
	lua_setglobal(L, funName);
}

// ========== Implementation of Lua primitives ==========

/**
 * Print to console, e.g. the logcat output on Android.
 */
static int luaLog(lua_State *L)
{
	const char* message = luaL_checkstring(L, 1);
	lprintfln("%s", message);
	return 0; // Number of results
}

/**
 * Print to the device screen (and also to the console on e.g. Android).
 */
static int luaPrint(lua_State *L)
{
	const char* message = luaL_checkstring(L, 1);
	printf("%s", message);
	return 0; // Number of results
}

/**
 * Convert the contents of a string pointer (char*) to a Lua string.
 */
static int luaToString(lua_State *L)
{
	// First param is pointer to text buffer, must not
	// be nil and must be light user data.
	if (!lua_isnoneornil(L, 1) && lua_islightuserdata(L, 1))
	{
		char* text = (char*) lua_touserdata(L, 1);
		if (NULL != text)
		{
			// This copies the text.
			lua_pushstring(L, text);
		}
	}

	return 1; // Number of results
}

static void registerNativeFunctions(lua_State* L)
{
	RegFun(L, "print", luaPrint);
	RegFun(L, "log", luaLog);
	RegFun(L, "SysBufferToString", luaToString);
}

// ========== Constructor/Destructor ==========

/**
 * Constructor.
 */
LuaEngine::LuaEngine() :
	mLuaState(NULL),
	mLuaErrorListener(NULL)
{
}

/**
 * Destructor.
 */
LuaEngine::~LuaEngine()
{
	shutdown();
}

// ========== Methods ==========

///**
// * High-level entry point for executing a Lua script.
// * Initializes the Lua interpreter, then evaluates the code
// * in the script and enters the event loop. Cleans up after
// * the event loop exits.
// * @param script String with Lua code.
// * @return Non-zero if successful, zero on error.
// */
//int LuaEngine::run(const char* script)
//{
//	if (!initialize())
//	{
//		return -1;
//	}
//
//	// Load Lua library functions in the first resource handle.
//	if (!eval(1))
//	{
//		return -1;
//	}
//
//	// Load and run the application.
//	if (!eval(script))
//	{
//		return -1;
//	}
//
//	// TODO: Enter main event loop.
//}
//
///**
// * High-level entry point for executing a Lua script contained
// * in a resource handle.
// * Initializes the Lua interpreter, then evaluates the code
// * in the script and enters the event loop. Cleans up after
// * the event loop exits.
// * @param scriptResourceId Handle to data object with Lua code,
// * typically a resource id.
// * @return Non-zero if successful, zero on error.
// */
//int LuaEngine::run(MAHandle scriptResourceId)
//{
//	// TODO: Implement.
//}

/**
 * Initialize the Lua engine.
 * @return Non-zero if successful, zero on error.
 */
int LuaEngine::initialize()
{
	lua_State* L = (lua_State*) mLuaState;

	// Deallocate previous Lua state, if it exists.
	if (L)
	{
		lua_close(L);
		mLuaState = NULL;
	}

	// Create Lua state.
	L = lua_open();
	mLuaState = L;
	if (!L)
	{
		return 0;
	}

	luaL_openlibs(L);

	tolua_lua_maapi_open(L);

	registerNativeFunctions(L);

	// Now we save a pointer to the engine instance in the
	// global Lua register.
	setUserData(L, "LuaEngineInstance", (void*) this);

	return 1;
}

/**
 * Shutdown the Lua engine.
 */
void LuaEngine::shutdown()
{
	lua_State* L = (lua_State*) mLuaState;

	if (L)
	{
		lua_close(L);
		mLuaState = NULL;
	}

	// TODO: Free function closures.
	// We can skip this as we close the entire interpreter, but
	// remember to free old functions when new ones are set.
}

/**
 * Evaluate a Lua script.
 * @param script String with Lua code.
 * @return Non-zero if successful, zero on error.
 */
int LuaEngine::eval(const char* script)
{
	lua_State* L = (lua_State*) mLuaState;

	// Evaluate Lua script.
	int result = luaL_dostring(L, script);

	// Was there an error?
	if (0 != result)
	{
		MAUtil::String errorMessage;

    	if (lua_isstring(L, -1))
    	{
    		errorMessage = lua_tostring(L, -1);

            // Pop the error message.
        	lua_pop(L, 1);
    	}
    	else
    	{
    		errorMessage =
    			"There was a Lua error condition, but no error message.";
    	}

        lprintfln("Lua Error: %s\n", errorMessage.c_str());

    	// Print size of Lua stack (debug info).
    	lprintfln("Lua stack size: %i\n", lua_gettop(L));

    	reportLuaError(errorMessage.c_str());
	}

	return result == 0;
}

/**
 * Helper method that evaluates a Lua script contained in
 * a resource handle.
 * @param scriptResourceId Handle to data object with Lua code,
 * typically a resource id.
 * @return Non-zero if successful, zero on error.
 */
int LuaEngine::eval(MAHandle handle)
{
	char* script = SysLoadStringResource(handle);
	if (script)
	{
		int result = eval(script);
		free(script);
		return result;
	}
	else
	{
		return 0;
	}
}

/**
 * Set a listener that will get notified when there is a
 * Lua error.
 */
void LuaEngine::setLuaErrorListener(LuaErrorListener* listener)
{
	mLuaErrorListener = listener;
}

/**
 * Called to report a Lua error (for private use, really).
 */
void LuaEngine::reportLuaError(const char* errorMessage)
{
	if (NULL != mLuaErrorListener)
	{
		mLuaErrorListener->onError(errorMessage);
	}
}

}


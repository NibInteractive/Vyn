#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdio.h>
#include <stdlib.h>

// Function to create a window (example)
int l_createWindow(lua_State *L) {
    // Arguments from Lua
    const char* title = luaL_checkstring(L, 1);
    int width = luaL_checkinteger(L, 2);
    int height = luaL_checkinteger(L, 3);

    // Here you would normally create a real window
    printf("Window Created: %s (%dx%d)\n", title, width, height);

    // Return a value to Lua
    lua_pushstring(L, "Window created successfully!");
    return 1; // number of return values
}

// Register functions
int luaopen_Window(lua_State *L) {
    static const luaL_Reg funcs[] = {
        {"Create", l_createWindow},
        {NULL, NULL}
    };

    luaL_register(L, "Window", funcs);
    return 1;
}

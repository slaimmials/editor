define("ace/mode/glua_with_lua_worker", [
    "require", "exports", "module",
    "ace/mode/lua",
    "ace/mode/glua_highlight_rules",
    "ace/lib/oop"
], function (require, exports, module) {
    var LuaMode = require("ace/mode/lua").Mode;
    var GLuaHighlightRules = require("ace/mode/glua_highlight_rules").GLuaHighlightRules;
    var oop = require("ace/lib/oop");

    var Mode = function () {
        LuaMode.call(this);
        this.HighlightRules = GLuaHighlightRules;
    };
    oop.inherits(Mode, LuaMode);
    exports.Mode = Mode;
});
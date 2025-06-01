#!/bin/bash
# Run lua-language-server checks on the project

LUA_LS="/home/camlorn/.vscode-server/extensions/sumneko.lua-3.14.0-linux-x64/server/bin/lua-language-server"

if [ ! -x "$LUA_LS" ]; then
    echo "Error: lua-language-server not found at $LUA_LS"
    exit 1
fi

echo "Running lua-language-server checks..."
"$LUA_LS" --check . --checklevel=Information --logpath=/tmp/lua-ls-log 2>&1 | grep -E "^\[|Warning|Error|Information" | grep -v "Initializing"
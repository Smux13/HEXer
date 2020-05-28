#!/usr/bin/env lua

--[[

  HEXer - hex viewer 

  Use the -v command line switch for license or see the LICENSE file.

  Usage: lue5.3 hex_viewer.lua filename

  Displays the file's bytes as hexadecimal. The output is big-endian.

--]]

local LICENSE = [[
MIT License

Copyright (c) 2020 Törteli Imre

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local VERSION = "1.0"

if package.config:sub(1, 1) ~= "/" then
  io.write("Warning: HEXer is written for Linux\n\n")
  io.read() -- wait for enter
end

local COLORS       = {}
COLORS.RESET       = "\x1B[0m"
COLORS.RED         = "\x1B[31m"
COLORS.GREEN       = "\x1B[32m"
COLORS.YELLOW      = "\x1B[33m"
COLORS.BLUE        = "\x1B[34m"
COLORS.MAGENTA     = "\x1B[35m"
COLORS.CYAN        = "\x1B[36m"
COLORS.B_GREEN     = "\x1B[92m"
COLORS.B_BLUE      = "\x1B[94m"
COLORS.B_CYAN      = "\x1B[96m"
COLORS.B_WHITE     = "\x1B[97m"

local STYLES       = {}
STYLES.RESET       = COLORS.RESET
STYLES.BOLD        = "\x1B[1m"
STYLES.DIM         = "\x1B[2m"
STYLES.ITALIC      = "\x1B[3m"
STYLES.UNDERLINE   = "\x1B[4m"

-- the frame is built from these characters
local LINE_CHARS          = {}
LINE_CHARS.TOP_L          = COLORS.B_WHITE.."┌"..COLORS.RESET
LINE_CHARS.TOP_R          = COLORS.B_WHITE.."┐"..COLORS.RESET
LINE_CHARS.BOT_R          = COLORS.B_WHITE.."┘"..COLORS.RESET
LINE_CHARS.BOT_L          = COLORS.B_WHITE.."└"..COLORS.RESET
LINE_CHARS.HORIZONTAL     = COLORS.B_WHITE.."─"..COLORS.RESET
LINE_CHARS.TOP_T          = COLORS.B_WHITE.."┬"..COLORS.RESET
LINE_CHARS.BOT_T          = COLORS.B_WHITE.."┴"..COLORS.RESET
LINE_CHARS.VERTICAL       = COLORS.B_WHITE.."|"..COLORS.RESET
LINE_CHARS.VERTICAL_SEP   = COLORS.B_WHITE.."┆"..COLORS.RESET


local FRAME_TOP     = LINE_CHARS.TOP_L..
                      string.rep(LINE_CHARS.HORIZONTAL, 10)..
                      LINE_CHARS.TOP_T..
                      string.rep(LINE_CHARS.HORIZONTAL, 25)..
                      LINE_CHARS.TOP_T..
                      string.rep(LINE_CHARS.HORIZONTAL, 25)..
                      LINE_CHARS.TOP_R..
                      "\n"

local FRAME_BOTTOM = LINE_CHARS.BOT_L..
                      string.rep(LINE_CHARS.HORIZONTAL, 10)..
                      LINE_CHARS.BOT_T..
                      string.rep(LINE_CHARS.HORIZONTAL, 25)..
                      LINE_CHARS.BOT_T..
                      string.rep(LINE_CHARS.HORIZONTAL, 25)..
                      LINE_CHARS.BOT_R..
                      "\n"

local USAGE = "Usage: "..arg[0].." filename\n"

-- check if got an argument
if not arg[1] then
  io.stderr:write(USAGE)
  os.exit(1)
end

local argo = arg[1]

-- if the argument is a command-line switch
if argo:sub(1, 1) == "-" then

  if argo == "-v" or argo == "--version" then
    io.write("HEXer "..VERSION.."\n\n"..LICENSE)

  elseif argo == "-h" or argo == "--help" then
    io.write(USAGE)

  else -- invalid switch
    io.stderr:write(USAGE)
    os.exit(5)
  end

  -- don't try to open file, just exit
  os.exit(0)
end

local FILENAME = argo
argo = nil

-- if could not open the file, print and error message
local filed, err = io.open(FILENAME, "rb")
if not filed then
  io.stderr:write("Failed to open file: "..err.."\n")
  os.exit(2)
end

-- read everything from the file
filecontent = filed:read("*a")

-- if could not read file, print an error message
if not filecontent then
  io.stderr:write("Failed to read file: "..FILENAME.."\n")
  os.exit(3)
end

-- close the file
filed:close()

io.write(COLORS.RESET)

io.write(FRAME_TOP)

local i = 1

while i <= #filecontent do
  -- get the hex representation of the current byte
  local hex_repr = string.format("%02x", filecontent:sub(i, i):byte()):upper()

  if (i % 16) == 1 then
    io.write(LINE_CHARS.VERTICAL)
    io.write(string.format(" %08x ", i-1):upper())
    io.write(LINE_CHARS.VERTICAL.." ")
  end

  -- let's color some opcodes and characters
  if     hex_repr == "20" then io.write(COLORS.GREEN)   -- space
  elseif hex_repr == "0A" then io.write(COLORS.B_GREEN) -- newline (\n)
  elseif hex_repr == "00" then io.write(STYLES.DIM)     -- null byte
  elseif hex_repr == "90" then io.write(COLORS.YELLOW)  -- NOP
  elseif hex_repr == "C2" or                            -- RETN
         hex_repr == "C3" or                            -- RETN
         hex_repr == "CA" or                            -- RETF
         hex_repr == "CB" or                            -- RETF
         hex_repr == "CF" then io.write(COLORS.CYAN)    -- IRET/IRETD
  elseif hex_repr == "06" or                            -- PUSH ES
         hex_repr == "0E" or                            -- PUSH CS
         hex_repr == "16" or                            -- PUSH SS
         hex_repr == "1E" or                            -- PUSH DS
         hex_repr == "60" or                            -- PUSHA/PUSHAD
         hex_repr == "68" or                            -- PUSH imm16/32
         hex_repr == "6A" or                            -- PUSH imm8
         hex_repr == "9C" then io.write(COLORS.BLUE)    -- PUSHF/PUSHFD
  elseif hex_repr == "07" or                            -- POP ES
         hex_repr == "17" or                            -- POP SS
         hex_repr == "1F" or                            -- POP DS
         hex_repr == "61" or                            -- POPA/POPAD
         hex_repr == "8F" or                            -- POP r/m16/32
         hex_repr == "9D" then io.write(COLORS.RED)     -- POPF Flags / POPFD EFlags
  elseif hex_repr == "0F" then io.write(STYLES.BOLD)    -- 0F prefix
  elseif hex_repr == "E9" or                            -- JMP rel16/32
         hex_repr == "EA" or                            -- JMPF ptr16:16/32
         hex_repr == "EB" then io.write(COLORS.MAGENTA) -- JMP rel8
  elseif hex_repr == "FF" then io.write(COLORS.B_CYAN)  -- 0xFF
                               io.write(STYLES.UNDERLINE)
  end

  -- write the HEX number
  io.write(hex_repr)

  -- reset the color and theme
  io.write(COLORS.RESET)

  -- the space between the numbers
  io.write(" ")

  -- line ending and separator
  if (i % 16) == 0 then io.write(LINE_CHARS.VERTICAL.."\n")
  -- separator between blocks
  elseif (i %  8) == 0 then io.write(LINE_CHARS.VERTICAL_SEP.." ") end

  -- after aprox. every page
  if (i % 1024) == 0 then
    -- wait for a keypress, so the output can be scrolled
    local exited_by = table.pack(os.execute("bash -c 'read -s -n1'"))[2]

    -- if the read command exited by pressing Ctrl-C, it has been killed, etc.
    if exited_by ~= "exit" then
      io.write("\nInterrupted!\n")
      os.exit(4) -- exit from the script
    end
  end

  i = i + 1

end

-- the length of the current line after the first block
local current_line_length = ((i-1) % 16 * 3)

if current_line_length > 0 then
  -- if there is a delimiter in the line, add the space for it
  if current_line_length > 16 then
    current_line_length = current_line_length + 2
  end

  -- fill the current line with spaces
  io.write(string.rep(" ", 65 - current_line_length - 15))
  -- put the end character
  io.write(LINE_CHARS.VERTICAL)
  
  io.write("\n")
end

-- the bottom of the frame
io.write(FRAME_BOTTOM)

-- the last newline
io.write("\n")

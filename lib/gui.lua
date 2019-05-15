-- formatting
function format_int(number)
	if number == nil then
		number = 0
	end

	local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
	-- reverse the int-string and append a comma to all blocks of 3 digits
	int = int:reverse():gsub("(%d%d%d)", "%1,")

	-- reverse the int-string back remove an optional comma and put the
	-- optional minus and fractional part back
	return minus .. int:reverse():gsub("^,", "") .. fraction
end

-- split a string by a delimiter
function split(string, delimiter)
	local result = { }
	local from = 1
	local delim_from, delim_to = string.find( string, delimiter, from )
	while delim_from do
		table.insert( result, string.sub( string, from , delim_from-1 ) )
		from = delim_to + 1
		delim_from, delim_to = string.find( string, delimiter, from )
	end
	table.insert( result, string.sub( string, from ) )
	return result
end

function splitNumber(number)
	local number1 = getInteger(number)
	local number2 = number - number1
	number2 = getInteger(number2 * (10 ^ (string.len(tostring(number2)) - 2)))
	local result = {}
	table.insert( result, number1 )
	table.insert( result, number2 )
	return result
end

--get the result value of a number under 10
function getInteger(number)
	if number < 0 then
		return 0
	end

	local divider = 1
	while divider * 10 <= number do
		divider = divider * 10
	end

	local result = 0
	while number > result and divider >= 1 do
		result = result + divider
		if number < result then
			result = result - divider
			divider = divider / 10
		end
	end
	return result
end

-- returns the modulo value of 2 integers
function getModulo(number, modulo)
	if number < 0 then
		number = number * (-1)
	end
	if modulo < 0 then
		modulo = modulo * (-1)
	end
	if number < modulo then
		return number
	end
	local divider = modulo
	while divider * modulo <= number do
		divider = divider * modulo
	end

	local result = 0
	while number > result and divider >= modulo do
	result = result + divider
		if number < result then
			result = result - divider
			divider = divider / modulo
		end
	end
	return number - result
end

-- monitor related
-- display text text on monitor, "mon" peripheral
function draw_text(mon, x, y, text, text_color, bg_color)
	mon.monitor.setBackgroundColor(bg_color)
	mon.monitor.setTextColor(text_color)
	mon.monitor.setCursorPos(x,y)
	mon.monitor.write(text)
end

-- display text text on the right side of monitor, "mon" peripheral
function draw_text_right(mon, offset, y, text, text_color, bg_color)
	mon.monitor.setBackgroundColor(bg_color)
	mon.monitor.setTextColor(text_color)
	mon.monitor.setCursorPos(mon.X-string.len(tostring(text))-offset,y)
	mon.monitor.write(text)
end

--display text text1 on the left side and text2 on the right side of monitor, "mon" peripheral
function draw_text_lr(mon, x, y, offset, text1, text2, text1_color, text2_color, bg_color)
	draw_text(mon, x, y, text1, text1_color, bg_color)
	draw_text_right(mon, offset, y, text2, text2_color, bg_color)
end

--draw horizontal line on computer terminal(mon)
function draw_line(mon, x, y, length, color)
	if length < 0 then
		length = 0
	end
	mon.monitor.setBackgroundColor(color)
	mon.monitor.setCursorPos(x,y)
	mon.monitor.write(string.rep(" ", length))
end

--draw vertical line on computer terminal(mon)
function draw_column(mon, x, y, height, color)
	if height < 0 then
		height = 0
	end
	mon.monitor.setBackgroundColor(color)
	local i = 1
	while i <= height do
		mon.monitor.setCursorPos(x,y)
		mon.monitor.write(" ")
		y = y + 1
		i = i + 1
	end
end

-- Draw six control buttons
function drawButtons(mon, x, y, color, bgcolor1, bgcolor2)
	draw_text(mon, x, y, " < ", color, bgcolor1)
	draw_text(mon, x+4, y, " <<", color, bgcolor1)
	draw_text(mon, x+8, y, "<<<", color, bgcolor1)

	draw_text(mon, x+15, y, ">>>", color, bgcolor2)
	draw_text(mon, x+19, y, ">> ", color, bgcolor2)
	draw_text(mon, x+23, y, " > ", color, bgcolor2)
end

-- Draw two big arrows on the left and right side of the screen
function drawSideButtons(mon, y, color)
	mon.monitor.setBackgroundColor(color)
	mon.monitor.setCursorPos(2, y+2)
	mon.monitor.write(" ")
	mon.monitor.setCursorPos(3, y+1)
	mon.monitor.write(" ")
	mon.monitor.setCursorPos(3, y+3)
	mon.monitor.write(" ")
	mon.monitor.setCursorPos(4, y)
	mon.monitor.write(" ")
	mon.monitor.setCursorPos(4, y+4)
	mon.monitor.write(" ")
	mon.monitor.setCursorPos(mon.X - 1, y+2)
	mon.monitor.write(" ")
	mon.monitor.setCursorPos(mon.X - 2, y+1)
	mon.monitor.write(" ")
	mon.monitor.setCursorPos(mon.X - 2, y+3)
	mon.monitor.write(" ")
	mon.monitor.setCursorPos(mon.X - 3, y)
	mon.monitor.write(" ")
	mon.monitor.setCursorPos(mon.X - 3, y+4)
	mon.monitor.write(" ")
end

--create progress bar
--draws two overlapping lines
--background line of bg_color
--main line of bar_color as a percentage of minVal/maxVal
function progress_bar(mon, x, y, length, minVal, maxVal, bar_color, bg_color)
	draw_line(mon, x, y, length, bg_color) --backgoround bar
	local barSize = math.floor((minVal/maxVal) * length)
	draw_line(mon, x, y, barSize, bar_color) --progress so far
end

--draw numbers from 0 to 9
function draw_0(mon, x, y, color)
	mon.monitor.setBackgroundColor(color)
	draw_column(mon, x, y, 5, color)
	draw_column(mon, x+2, y, 5, color)
	mon.monitor.setCursorPos(x+1,y)
	mon.monitor.write(" ")
	mon.monitor.setCursorPos(x+1,y+4)
	mon.monitor.write(" ")
end

function draw_1(mon, x, y, color)
	draw_column(mon, x+2, y, 5, color)
end

function draw_2(mon, x, y, color)
	mon.monitor.setBackgroundColor(color)
	draw_line(mon, x, y, 3, color)
	draw_line(mon, x, y+2, 3, color)
	draw_line(mon, x, y+4, 3, color)
	mon.monitor.setCursorPos(x+2,y+1)
	mon.monitor.write(" ")
	mon.monitor.setCursorPos(x,y+3)
	mon.monitor.write(" ")
end

function draw_3(mon, x, y, color)
	mon.monitor.setBackgroundColor(color)
	draw_line(mon, x, y, 3, color)
	draw_line(mon, x, y+2, 3, color)
	draw_line(mon, x, y+4, 3, color)
	mon.monitor.setCursorPos(x+2,y+1)
	mon.monitor.write(" ")
	mon.monitor.setCursorPos(x+2,y+3)
	mon.monitor.write(" ")
end

function draw_4(mon, x, y, color)
	mon.monitor.setBackgroundColor(color)
	draw_column(mon, x, y, 3, color)
	draw_column(mon, x+2, y, 5, color)
	mon.monitor.setCursorPos(x+1,y+2)
	mon.monitor.write(" ")
end

function draw_5(mon, x, y, color)
	mon.monitor.setBackgroundColor(color)
	draw_line(mon, x, y, 3, color)
	draw_line(mon, x, y+2, 3, color)
	draw_line(mon, x, y+4, 3, color)
	mon.monitor.setCursorPos(x,y+1)
	mon.monitor.write(" ")
	mon.monitor.setCursorPos(x+2,y+3)
	mon.monitor.write(" ")
end

function draw_6(mon, x, y, color)
	mon.monitor.setBackgroundColor(color)
	draw_5(mon, x, y, color)
	mon.monitor.setCursorPos(x,y+3)
	mon.monitor.write(" ")
end

function draw_7(mon, x, y, color)
	mon.monitor.setBackgroundColor(color)
	draw_column(mon, x+2, y, 5, color)
	mon.monitor.setCursorPos(x,y)
	mon.monitor.write("  ")
end

function draw_8(mon, x, y, color)
	mon.monitor.setBackgroundColor(color)
	draw_0(mon, x, y, color)
	mon.monitor.setCursorPos(x+1,y+2)
	mon.monitor.write(" ")
end

function draw_9(mon, x, y, color)
	mon.monitor.setBackgroundColor(color)
	draw_5(mon, x, y, color)
	mon.monitor.setCursorPos(x+2,y+1)
	mon.monitor.write(" ")
end

--convert number to result digit and draw it on monitor
function draw_digit(number, mon, x, y, color)
	if number == 0 then
		draw_0(mon, x, y, color)
	elseif number == 1 then
		draw_1(mon, x, y, color)
	elseif number == 2 then
		draw_2(mon, x, y, color)
	elseif number == 3 then
		draw_3(mon, x, y, color)
	elseif number == 4 then
		draw_4(mon, x, y, color)
	elseif number == 5 then
		draw_5(mon, x, y, color)
	elseif number == 6 then
		draw_6(mon, x, y, color)
	elseif number == 7 then
		draw_7(mon, x, y, color)
	elseif number == 8 then
		draw_8(mon, x, y, color)
	elseif number == 9 then
		draw_9(mon, x, y, color)
	end
end

--draw number on computer terminal
function draw_number(mon, number, offset, y, color)
	local number1 = splitNumber(number)[1]
	local number2 = splitNumber(number)[2]

	local length1 = string.len(tostring(number1))
	local length2 = string.len(tostring(number2))

	local x
	if number2 ~= 0 then
		x = mon.X - (offset + (length1 * 4) + (2 * getInteger((length1 - 1) / 3)) + (length2 * 4) + 1)
	else
		x = mon.X - (offset + (length1 * 4) + (2 * getInteger((length1 - 1) / 3)) - 1)
	end

	if length1 == 1 then
		x = x + 1
	end
	local printDot = length1
	while printDot > 3 do
		printDot = printDot - 3
	end
	local divider = 10 ^ (length1 - 1)
	for i = 1, length1 do
		draw_digit(getInteger(number1 / divider), mon, x, y, color)
		printDot = printDot - 1
		if printDot == 0 and i ~= length1 then
			mon.monitor.setCursorPos(x+4,y+4)
			mon.monitor.write(" ")
			printDot = 3
			x = x + 6
		else
			x = x + 4
		end
		number1 = number1 - (divider * getInteger(number1 / divider))
		divider = divider / 10
	end
	if number2 ~= 0 then
		mon.monitor.setCursorPos(x,y+4)
		mon.monitor.write(" ")
		mon.monitor.setCursorPos(x,y+5)
		mon.monitor.write(" ")

		x = x + 3

		local divider = 10 ^ (length2 - 1)
		for i = 1, length2 do
			draw_digit(getInteger(number2 / divider), mon, x, y, color)
			x = x + 4
			number2 = number2 - (divider * getInteger(number2 / divider))
			divider = divider / 10
		end
	end
end

--draw RF/T on computer terminal(mon)
function draw_rft(mon, offset, y, color)
	local x = mon.X - (offset + 15)

	mon.monitor.setBackgroundColor(color)
	draw_column(mon, x, y, 5, color)
	mon.monitor.setCursorPos(x+1,y)
	mon.monitor.write(" ")
	mon.monitor.setCursorPos(x+1,y+2)
	mon.monitor.write(" ")
	draw_column(mon, x+2, y, 2, color)
	draw_column(mon, x+2, y+3, 2, color)

	draw_column(mon, x+4, y, 5, color)
	mon.monitor.setCursorPos(x+5,y)
	mon.monitor.write("  ")
	mon.monitor.setCursorPos(x+5,y+2)
	mon.monitor.write(" ")

	draw_column(mon, x+8, y+3, 2, color)
	draw_column(mon, x+9, y+1, 2, color)
	mon.monitor.setCursorPos(x+10,y)
	mon.monitor.write(" ")

	mon.monitor.setCursorPos(x+12,y)
	mon.monitor.write(" ")
	draw_column(mon, x+13, y, 5, color)
	mon.monitor.setCursorPos(x+14,y)
	mon.monitor.write(" ")
end

function draw_rf(mon, offset, y, color)
	local x = mon.X - (offset + 7)

	mon.monitor.setBackgroundColor(color)
	draw_column(mon, x, y, 5, color)
	mon.monitor.setCursorPos(x+1,y)
	mon.monitor.write(" ")
	mon.monitor.setCursorPos(x+1,y+2)
	mon.monitor.write(" ")
	draw_column(mon, x+2, y, 2, color)
	draw_column(mon, x+2, y+3, 2, color)

	draw_column(mon, x+4, y, 5, color)
	mon.monitor.setCursorPos(x+5,y)
	mon.monitor.write("  ")
	mon.monitor.setCursorPos(x+5,y+2)
	mon.monitor.write(" ")
end

function draw_slash(mon, offset, y, color)
	local x = mon.X - (offset + 3)

	draw_column(mon, x, y+3, 2, color)
	draw_column(mon, x+1, y+1, 2, color)
	mon.monitor.setCursorPos(x+2,y)
	mon.monitor.write(" ")
end

function draw_SI(mon, x, y, length, color)
		mon.monitor.setBackgroundColor(color)
		draw_column(mon, x, y, 5, color)
		mon.monitor.setCursorPos(x+1,y)
		mon.monitor.write(" ")
		mon.monitor.setCursorPos(x+1,y+2)
		mon.monitor.write(" ")
		mon.monitor.setCursorPos(x+1,y+4)
		mon.monitor.write(" ")
		draw_column(mon, x+2, y, 2, color)
		draw_column(mon, x+2, y+3, 2, color)
end

function draw_tier(mon, x, y, color)
	mon.monitor.setBackgroundColor(color)
	mon.monitor.setCursorPos(x,y)
	mon.monitor.write(" ")
	draw_column(mon, x+1, y, 5, color)
	mon.monitor.setCursorPos(x+2,y)
	mon.monitor.write(" ")

	draw_column(mon, x+5, y, 5, color)

	draw_column(mon, x+8, y, 5, color)
	draw_line(mon, x+9, y, 2, color)
	draw_line(mon, x+9, y+2, 2, color)
	draw_line(mon, x+9, y+4, 2, color)

	draw_column(mon, x+12, y, 5, color)
	mon.monitor.setCursorPos(x+13,y)
	mon.monitor.write(" ")
	mon.monitor.setCursorPos(x+13,y+2)
	mon.monitor.write(" ")
	draw_column(mon, x+14, y, 2, color)
	draw_column(mon, x+14, y+3, 2, color)
end

--clear computer terminal(mon)
function clear(mon)
	term.clear()
	term.setCursorPos(1,1)
	mon.monitor.setBackgroundColor(colors.black)
	mon.monitor.clear()
	mon.monitor.setCursorPos(1,1)
end
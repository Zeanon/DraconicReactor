-- configure colors
local numberColor = colors.red
local rftColor = colors.gray
local buttonColor = colors.lightGray
local textColor = colors.white
-- lower number means higher refresh rate but also increases server load
local refresh = 1

-- program
local version = "1.4.0"
os.loadAPI("lib/gui")
os.loadAPI("lib/color")


local totalEnergy, totalMaxEnergy
local coreEnergy = {}
local coreMaxEnergy = {}

local monitors = {}

local monitorCount = 0
local connectedMonitors = {}
local coreCount = 0
local connectedCores = {}
local periList = peripheral.getNames()
local validPeripherals = {
    "draconic_rf_storage",
    "monitor"
}

-- get all connected peripherals
function checkValidity(periName)
    for n,b in pairs(validPeripherals) do
        if periName:find(b) then return b end
    end
    return false
end

for i,v in ipairs(periList) do
    local periFunctions = {
        ["draconic_rf_storage"] = function()
            coreCount = coreCount + 1
            connectedCores[coreCount] = periList[i]
        end,
    }

    local isValid = checkValidity(peripheral.getType(v))
    if isValid then periFunctions[isValid]() end
end

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

--write settings to config file
function save_config()
    local sw = fs.open("config.txt", "w")
    sw.writeLine("-- Config for Draconig Reactor Generation Overview")
    sw.writeLine("version: " .. version	)
    sw.writeLine(" ")
    sw.writeLine("-- configure the display numberColors")
    sw.writeLine("numberColor: " .. color.toString(numberColor))
    sw.writeLine("rftColor: " .. color.toString(rftColor))
    sw.writeLine("buttonColor: " ..  color.toString(buttonColor))
    sw.writeLine("textColor: " ..  color.toString(textColor))
    sw.writeLine(" ")
    sw.writeLine("-- lower number means higher refresh rate but also increases server load")
    sw.writeLine("refresh: " ..  refresh)
    sw.writeLine(" ")
    sw.writeLine("-- small font means a font size of 0.5 instead of 1")
    for i = 1, monitorCount do
        if monitors[connectedMonitors[i] .. ": smallFont"] then
            sw.writeLine(connectedMonitors[i] .. ": smallFont: true")
        else
            sw.writeLine(connectedMonitors[i] .. ": smallFont: false")
        end
    end
    sw.writeLine(" ")
    sw.writeLine("-- just some saved data")
    sw.writeLine("monitorCount: " .. monitorCount)
    for i = 1, monitorCount do
        sw.writeLine(" ")
        sw.writeLine("-- monitor: " .. connectedMonitors[i])
        for count = 1, 10 do
            sw.writeLine(connectedMonitors[i] .. ": line" .. count .. ": " .. monitors[connectedMonitors[i] .. ":line" .. count])
        end
    end
    sw.close()
end

--read settings from file
function load_config()
    local sr = fs.open("config.txt", "r")
    local curVersion
    local curMonitorCount
    local line = sr.readLine()
    while line do
        if split(line, ": ")[1] == "version" then
            curVersion = split(line, ": ")[2]
        elseif split(line, ": ")[1] == "numberColor" then
            numberColor = color.getColor(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "rftColor" then
            rftColor = color.getColor(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "buttonColor" then
            buttonColor = color.getColor(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "textColor" then
            textColor = color.getColor(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "refresh" then
            refresh = tonumber(split(line, ": ")[2])
        elseif split(line, ": ")[1] == "monitorCount" then
            curMonitorCount = tonumber(split(line, ": ")[2])
        else
            if string.find(split(line, ": ")[1], "monitor_")
                    or string.find(split(line, ": ")[1], "top")
                    or string.find(split(line, ": ")[1], "bottom")
                    or string.find(split(line, ": ")[1], "right")
                    or string.find(split(line, ": ")[1], "left")
                    or string.find(split(line, ": ")[1], "front")
                    or string.find(split(line, ": ")[1], "back") then
                for i = 1, monitorCount do
                    if connectedMonitors[i] == split(line, ": ")[1] then
                        if split(line, ": ")[2] == "smallFont" then
                            if split(line, ": ")[3] == "true" then
                                monitors[connectedMonitors[i] .. ":smallFont"] = true
                            else
                                monitors[connectedMonitors[i] .. ":smallFont"] = false
                            end
                        else
                            for count = 1, 10 do
                                if split(line, ": ")[2] == "line" .. count then
                                    monitors[connectedMonitors[i] .. ":line" .. count] = tonumber(split(line, ": ")[3])
                                end
                            end
                        end
                    end
                end
            end
        end
        line = sr.readLine()
    end
    sr.close()
    if curVersion ~= version or curMonitorCount ~= monitorCount then
        save_config()
    end
end

-- 1st time? save our settings, if not, load our settings
if fs.exists("config.txt") == false then
    save_config()
else
    load_config()
end


--Check for energycore and monitors before continuing
if coreCount == 0 then
    error("No valid energy core was found")
end

if monitorCount == 0 then
    error("No valid monitor was found")
end

function getMonitor(side)
    local mon, monitor, monX, monY
    monitor = peripheral.wrap(side)
    monX, monY = monitor.getSize()
    mon = {}
    mon.monitor,mon.X, mon.Y = monitor, monX, monY
    return mon
end


--update the monitor
function update()
    while true do
        drawLines()
        sleep(refresh)
    end
end

--draw the different lines on the screen
function drawLines()
    for i = 1, monitorCount do
        local mon = getMonitor(connectedMonitors[i])
        local amount = monitors[connectedMonitors[i] .. ":amount"]
        local drawButtons = monitors[connectedMonitors[i] .. ":drawButtons"]
        local x = monitors[connectedMonitors[i] .. ":x"]
        local y = monitors[connectedMonitors[i] .. ":y"]
        totalEnergy = getTotalEnergyStored()
        totalMaxEnergy = getTotalMaxEnergyStored()
        local energyPercent = math.ceil(totalEnergy / totalMaxEnergy * 10000)*.01
        if energyPercent == math.huge or isnan(energyPercent) then
            energyPercent = 0
        end
        gui.clear(mon)
        print("Energy Core amount: " .. gui.format_int(coreCount) .. "RF")
        print("Total total energy: " .. gui.format_int(totalEnergy) .. "RF")
        print("Total total max energy: " .. gui.format_int(totalMaxEnergy) .. "RF")
        print("Total total max energy: " .. energyPercent .. "RF")
        for i = 1, coreCount do
            coreEnergy[i] = getEnergyStored(i)
            coreMaxEnergy[i] = getMaxEnergyStored(i)
            print("Energy Core " .. i .. " Energy: " .. gui.format_int(coreEnergy[i]))
            print("Energy Core " .. i .. " max Energy: " .. gui.format_int(coreMaxEnergy[i]))
        end
        if amount >= 1 then
            drawLine(mon, x, y, monitors[connectedMonitors[i] .. ":line1"], drawButtons)
        end
        if amount >= 2 then
            gui.draw_line(mon, 0, y+7, mon.X+1, colors.gray)
            drawLine(mon, x, y + 10, monitors[connectedMonitors[i] .. ":line2"], drawButtons)
        end
        if amount >= 3 then
            drawLine(mon, x, y + 18, monitors[connectedMonitors[i] .. ":line3"], drawButtons)
        end
        if amount >= 4 then
            drawLine(mon, x, y + 26, monitors[connectedMonitors[i] .. ":line4"], drawButtons)
        end
        if amount >= 5 then
            drawLine(mon, x, y + 34, monitors[connectedMonitors[i] .. ":line5"], drawButtons)
        end
        if amount >= 6 then
            drawLine(mon, x, y + 42, monitors[connectedMonitors[i] .. ":line6"], drawButtons)
        end
        if amount >= 7 then
            drawLine(mon, x, y + 50, monitors[connectedMonitors[i] .. ":line7"], drawButtons)
        end
        if amount >= 8 then
            drawLine(mon, x, y + 58, monitors[connectedMonitors[i] .. ":line8"], drawButtons)
        end
        if amount >= 9 then
            drawLine(mon, x, y + 66, monitors[connectedMonitors[i] .. ":line9"], drawButtons)
        end
        if amount >= 10 then
            drawLine(mon, x, y + 74, monitors[connectedMonitors[i] .. ":line10"], drawButtons)
        end
    end
end

--handle the monitor touch inputs
function buttons()
    while true do
        -- button handler
        local event, side, xPos, yPos = os.pullEvent("monitor_touch")
        if monitors[side .. ":drawButtons"] then
            if monitors[side .. ":amount"] >= 1 and yPos >= monitors[side .. ":y"] and yPos <= monitors[side .. ":y"] + 4 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line1"] = monitors[side .. ":line1"] - 1
                    if monitors[side .. ":line1"] < 1 then
                        monitors[side .. ":line1"] = coreCount + 3
                    end
                elseif xPos >= getMonitor(side, monitors[side .. ":smallFont"]).X - 5 and xPos <= getMonitor(side, monitors[side .. ":smallFont"]).X - 1 then
                    monitors[side .. ":line1"] = monitors[side .. ":line1"] + 1
                    if monitors[side .. ":line1"] > coreCount + 3 then
                        monitors[side .. ":line1"] = 1
                    end
                end
                drawLines()
                save_config()
            end

            if monitors[side .. ":amount"] >= 2 and yPos >= monitors[side .. ":y"] + 10 and yPos <= monitors[side .. ":y"] + 14 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line2"] = monitors[side .. ":line2"] - 1
                    if monitors[side .. ":line2"] < 1 then
                        monitors[side .. ":line2"] = coreCount + 3
                    end
                elseif xPos >= getMonitor(side, monitors[side .. ":smallFont"]).X - 5 and xPos <= getMonitor(side, monitors[side .. ":smallFont"]).X - 1 then
                    monitors[side .. ":line2"] = monitors[side .. ":line2"] + 1
                    if monitors[side .. ":line2"] > coreCount + 3 then
                        monitors[side .. ":line2"] = 1
                    end
                end
                drawLines()
                save_config()
            end

            if monitors[side .. ":amount"] >= 3 and yPos >= monitors[side .. ":y"] + 18 and yPos <= monitors[side .. ":y"] + 22 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line3"] = monitors[side .. ":line3"] - 1
                    if monitors[side .. ":line3"] < 1 then
                        monitors[side .. ":line3"] = coreCount + 3
                    end
                elseif xPos >= getMonitor(side, monitors[side .. ":smallFont"]).X - 5 and xPos <= getMonitor(side, monitors[side .. ":smallFont"]).X - 1 then
                    monitors[side .. ":line3"] = monitors[side .. ":line3"] + 1
                    if monitors[side .. ":line3"] > coreCount + 3 then
                        monitors[side .. ":line3"] = 1
                    end
                end
                drawLines()
                save_config()
            end

            if monitors[side .. ":amount"] >= 4 and yPos >= monitors[side .. ":y"] + 26 and yPos <= monitors[side .. ":y"] + 30 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line4"] = monitors[side .. ":line4"] - 1
                    if monitors[side .. ":line4"] < 1 then
                        monitors[side .. ":line4"] = coreCount + 3
                    end
                elseif xPos >= getMonitor(side, monitors[side .. ":smallFont"]).X - 5 and xPos <= getMonitor(side, monitors[side .. ":smallFont"]).X - 1 then
                    monitors[side .. ":line4"] = monitors[side .. ":line4"] + 1
                    if monitors[side .. ":line4"] > coreCount + 3 then
                        monitors[side .. ":line4"] = 1
                    end
                end
                drawLines()
                save_config()
            end

            if monitors[side .. ":amount"] >= 5 and yPos >= monitors[side .. ":y"] + 34 and yPos <= monitors[side .. ":y"] + 38 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line5"] = monitors[side .. ":line5"] - 1
                    if monitors[side .. ":line5"] < 1 then
                        monitors[side .. ":line5"] = coreCount + 3
                    end
                elseif xPos >= getMonitor(side, monitors[side .. ":smallFont"]).X - 5 and xPos <= getMonitor(side, monitors[side .. ":smallFont"]).X - 1 then
                    monitors[side .. ":line5"] = monitors[side .. ":line5"] + 1
                    if monitors[side .. ":line5"] > coreCount + 3 then
                        monitors[side .. ":line5"] = 1
                    end
                end
                drawLines()
                save_config()
            end

            if monitors[side .. ":amount"] >= 6 and yPos >= monitors[side .. ":y"] + 42 and yPos <= monitors[side .. ":y"] + 46 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line6"] = monitors[side .. ":line6"] - 1
                    if monitors[side .. ":line6"] < 1 then
                        monitors[side .. ":line6"] = coreCount + 3
                    end
                elseif xPos >= getMonitor(side, monitors[side .. ":smallFont"]).X - 5 and xPos <= getMonitor(side, monitors[side .. ":smallFont"]).X - 1 then
                    monitors[side .. ":line6"] = monitors[side .. ":line6"] + 1
                    if monitors[side .. ":line6"] > coreCount + 3 then
                        monitors[side .. ":line6"] = 1
                    end
                end
                drawLines()
                save_config()
            end

            if monitors[side .. ":amount"] >= 7 and yPos >= monitors[side .. ":y"] + 50 and yPos <= monitors[side .. ":y"] + 54 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line7"] = monitors[side .. ":line7"] - 1
                    if monitors[side .. ":line7"] < 1 then
                        monitors[side .. ":line7"] = coreCount + 3
                    end
                elseif xPos >= getMonitor(side, monitors[side .. ":smallFont"]).X - 5 and xPos <= getMonitor(side, monitors[side .. ":smallFont"]).X - 1 then
                    monitors[side .. ":line7"] = monitors[side .. ":line7"] + 1
                    if monitors[side .. ":line7"] > coreCount + 3 then
                        monitors[side .. ":line7"] = 1
                    end
                end
                drawLines()
                save_config()
            end

            if monitors[side .. ":amount"] >= 8 and yPos >= monitors[side .. ":y"] + 58 and yPos <= monitors[side .. ":y"] + 62 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line8"] = monitors[side .. ":line8"] - 1
                    if monitors[side .. ":line8"] < 1 then
                        monitors[side .. ":line8"] = coreCount + 3
                    end
                elseif xPos >= getMonitor(side, monitors[side .. ":smallFont"]).X - 5 and xPos <= getMonitor(side, monitors[side .. ":smallFont"]).X - 1 then
                    monitors[side .. ":line8"] = monitors[side .. ":line8"] + 1
                    if monitors[side .. ":line8"] > coreCount + 3 then
                        monitors[side .. ":line8"] = 1
                    end
                end
                drawLines()
                save_config()
            end

            if monitors[side .. ":amount"] >= 9 and yPos >= monitors[side .. ":y"] + 66 and yPos <= monitors[side .. ":y"] + 70 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line9"] = monitors[side .. ":line9"] - 1
                    if monitors[side .. ":line9"] < 1 then
                        monitors[side .. ":line9"] = coreCount + 3
                    end
                elseif xPos >= getMonitor(side, monitors[side .. ":smallFont"]).X - 5 and xPos <= getMonitor(side, monitors[side .. ":smallFont"]).X - 1 then
                    monitors[side .. ":line9"] = monitors[side .. ":line9"] + 1
                    if monitors[side .. ":line9"] > coreCount + 3 then
                        monitors[side .. ":line9"] = 1
                    end
                end
                drawLines()
                save_config()
            end

            if monitors[side .. ":amount"] >= 10 and yPos >= monitors[side .. ":y"] + 74 and yPos <= monitors[side .. ":y"] + 78 then
                if xPos >= 1 and xPos <= 5 then
                    monitors[side .. ":line10"] = monitors[side .. ":line10"] - 1
                    if monitors[side .. ":line10"] < 1 then
                        monitors[side .. ":line10"] = coreCount + 3
                    end
                elseif xPos >= getMonitor(side, monitors[side .. ":smallFont"]).X - 5 and xPos <= getMonitor(side, monitors[side .. ":smallFont"]).X - 1 then
                    monitors[side .. ":line10"] = monitors[side .. ":line10"] + 1
                    if monitors[side .. ":line10"] > coreCount + 3 then
                        monitors[side .. ":line10"] = 1
                    end
                end
                drawLines()
                save_config()
            end
        end
    end
end

--draw line with information on the monitor
function drawLine(mon, localX, localY, line, drawButtons)
    if line == 1 then
        gui.draw_integer(mon, totalEnergy, localX, localY, numberColor, rftColor, "rf", "")
        if drawButtons then
            gui.drawSideButtons(mon, localY, buttonColor)
            gui.draw_text_lr(mon, 2, localY + 2, 0, "DR" .. coreCount .. " ", " Gen", textColor, textColor, buttonColor)
        end
    elseif line == 2 then
        gui.draw_integer(mon, totalMaxEnergy, localX, localY, numberColor, rftColor, "rf", "")
        if drawButtons then
            gui.drawSideButtons(mon, localY, buttonColor)
            gui.draw_text_lr(mon, 2, localY + 2, 0, "Out ", "Back", textColor, textColor, buttonColor)
        end
    elseif line == 3 then
        gui.draw_integer(mon, energyPercent , localX, localY, numberColor, rftColor, "rf", "")
        if drawButtons then
            gui.drawSideButtons(mon, localY, buttonColor)
            gui.draw_text_lr(mon, 2, localY + 2, 0, "Gen ", " DR1", textColor, textColor, buttonColor)
        end
    elseif line == 4 then
        local energyPercent = math.ceil(totalEnergy / totalMaxEnergy * 10000)*.01
        if energyPercent == math.huge or isnan(energyPercent) then
            energyPercent = 0
        end
        local energyColor = colors.red
        if energyPercent >= 70 then
            energyColor = colors.green
        elseif energyPercent < 70 and energyPercent > 30 then
            energyColor = colors.orange
        end
        gui.progress_bar(mon, localX, localY, 48, totalEnergy, totalMaxEnergy, energyColor, colors.lightGray)
        gui.progress_bar(mon, localX, localY, 48, totalEnergy, totalMaxEnergy, energyColor, colors.lightGray)
        gui.progress_bar(mon, localX, localY, 48, totalEnergy, totalMaxEnergy, energyColor, colors.lightGray)
        gui.progress_bar(mon, localX, localY, 48, totalEnergy, totalMaxEnergy, energyColor, colors.lightGray)
        gui.progress_bar(mon, localX, localY, 48, totalEnergy, totalMaxEnergy, energyColor, colors.lightGray)
        if drawButtons then
            gui.drawSideButtons(mon, localY, buttonColor)
            gui.draw_text_lr(mon, 2, localY + 2, 0, "Gen ", " DR1", textColor, textColor, buttonColor)
        end
    elseif line == 5 then
        local energyPercent = math.ceil(totalEnergy / totalMaxEnergy * 10000)*.01
        if energyPercent == math.huge or isnan(energyPercent) then
            energyPercent = 0
        end
        gui.draw_integer(mon, energyPercent , localX, localY, numberColor, rftColor, "%", "")
        if drawButtons then
            gui.drawSideButtons(mon, localY, buttonColor)
            gui.draw_text_lr(mon, 2, localY + 2, 0, "Gen ", " DR1", textColor, textColor, buttonColor)
        end
    else
        for i = 1, coreCount * 4 do
            if line == i + 6 then

                gui.draw_integer(mon, coreEnergy[i], localX, localY, numberColor, rftColor, "rf", "")
                if drawButtons then
                    gui.drawSideButtons(mon, localY, buttonColor)
                    if line == 7 and line == coreCount + 7 then
                        gui.draw_text_lr(mon, 2, localY + 2, 0, "Back", " Out", textColor, textColor, buttonColor)
                    elseif line == 7 then
                        gui.draw_text_lr(mon, 2, localY + 2, 0, "Back", "EC" .. i + 1 .. " ", textColor, textColor, buttonColor)
                    elseif line == coreCount + 7 then
                        gui.draw_text_lr(mon, 2, localY + 2, 0, "EC" .. i - 1 .. " ", " Out", textColor, textColor, buttonColor)
                    else
                        gui.draw_text_lr(mon, 2, localY + 2, 0, "EC" .. i - 1 .. " ", "EC" .. i + 1 .. " ", textColor, textColor, buttonColor)
                    end
                end
            end
        end
    end
end


function getTotalMaxEnergyStored()
    local totalMaxEnergy = 0
    for i = 1, coreCount do
        totalMaxEnergy = totalMaxEnergy + getMaxEnergyStored(i)
    end
    return totalMaxEnergy
end

function getTotalEnergyStored()
    local totalEnergy = 0
    for i = 1, coreCount do
        totalEnergy = totalEnergy + getEnergyStored(i)
    end
    return totalEnergy
end

function getMaxEnergyStored(number)
    local core = peripheral.wrap(connectedCores[number])
    return core.getMaxEnergyStored()
end

function getEnergyStored(number)
    local core = peripheral.wrap(connectedCores[number])
    return core.getEnergyStored()
end

-- check that every line displays something
function checkLines()
    if line1 > coreCount + 3 then
        line1 = coreCount + 3
    end
    if line2 > coreCount + 3 then
        line2 = coreCount + 3
    end
    if line3 > coreCount + 3 then
        line3 = coreCount + 3
    end
    if line4 > coreCount + 3 then
        line4 = coreCount + 3
    end
    if line5 > coreCount + 3 then
        line5 = coreCount + 3
    end
    if line6 > coreCount + 3 then
        line6 = coreCount + 3
    end
    if line7 > coreCount + 3 then
        line7 = coreCount + 3
    end
    if line8 > coreCount + 3 then
        line8 = coreCount + 3
    end
    if line9 > coreCount + 3 then
        line9 = coreCount + 3
    end
    if line10 > coreCount + 3 then
        line10 = coreCount + 3
    end
    save_config()
end

--run
checkLines()

if mon.Y >= 16 then
    local localY = mon.Y - 2
    local count = 0
    local i = 8
    while i <= localY do
        i = i + 8
        count = count + 1
    end
    amount = count
    y = gui.getInteger((mon.Y + 3 - (8 * count)) / 2)
end

if mon.X >= 57 then
    drawButtons= true
    if mon.Y < 16 then
        amount = 1
        y = gui.getInteger((mon.Y - 3) / 2)
        parallel.waitForAny(buttons, update)
    else
        parallel.waitForAny(buttons, update)
    end
else
    drawButtons= false
    if mon.Y < 16 then
        amount = 1
        y = gui.getInteger((mon.Y - 3) / 2)
        update()
    else
        update()
    end
end
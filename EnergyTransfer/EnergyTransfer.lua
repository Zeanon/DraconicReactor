-- configure colors
local numberColor = colors.red
local unitColor = colors.gray
-- lower number means higher refresh rate but also increases server load
local refresh = 1

-- program
local version = "1.0.0"
-- peripherals
local core, fluxgate, y
local lastEnergy = {}
-- monitor
local mon, monitor, monX, monY
os.loadAPI("lib/gui")
os.loadAPI("lib/color")

--write settings to config file
function save_config()
	local sw = fs.open("config.txt", "w")
	sw.writeLine("-- Config for Draconig Reactor Generation Overview")
	sw.writeLine("version: " .. version	)
	sw.writeLine(" ")
	sw.writeLine("-- configure the display numberColors")
	sw.writeLine("numberColor: " .. color.toString(numberColor))
	sw.writeLine("unitColor: " .. color.toString(unitColor))
	sw.writeLine(" ")
	sw.writeLine("-- lower number means higher refresh rate but also increases server load")
	sw.writeLine("refresh: " ..  refresh)
	sw.close()
end

--read settings from file
function load_config()
	local sr = fs.open("config.txt", "r")
	local line = sr.readLine()
	while line do
		if gui.split(line, ": ")[1] == "numberColor" then
			numberColor = color.getColor(gui.split(line, ": ")[2])
		elseif gui.split(line, ": ")[1] == "unitColor" then
			unitColor = color.getColor(gui.split(line, ": ")[2])
		elseif gui.split(line, ": ")[1] == "refresh" then
			refresh = tonumber(gui.split(line, ": ")[2])
		end
		line = sr.readLine()
	end
	sr.close()
	save_config()
end

--initialize the tables for stability checking
function initTables()
	local i = 1
	while i <= 10 do
		lastEnergy[i] = 0
		i = i + 1
	end
end


-- 1st time? save our settings, if not, load our settings
if fs.exists("config.txt") == false then
	save_config()
	initTables()
else
	load_config()
	initTables()
end

core = peripheral.find("draconic_rf_storage")
monitor = peripheral.find("monitor")
fluxgate = peripheral.find("flux_gate")

if core == null then
	error("No valid energy core was found")
end

if monitor == null then
	error("No valid monitor was found")
end

if fluxgate == null then
	error("No valid flux gate was found")
end

monX, monY = monitor.getSize()
mon = {}
mon.monitor,mon.X, mon.Y = monitor, monX, monY

function update()
	updateEnergy()
	if checkEnergy() then
		if core.getEnergyStored() < (core.getMaxEnergyStored() / 8) - 20 then
			fluxgate.setSignalLowFlow(fluxgate.getSignalLowFlow() + 10000)
			fluxgate.setSignalHighFlow(fluxgate.getSignalLowFlow())
		elseif core.getEnergyStored() < (core.getMaxEnergyStored() / 4) - 20 then
			fluxgate.setSignalLowFlow(fluxgate.getSignalLowFlow() + 1000)
			fluxgate.setSignalHighFlow(fluxgate.getSignalLowFlow())
		elseif core.getEnergyStored() < (3 * (core.getMaxEnergyStored() / 8)) - 20 then
			fluxgate.setSignalLowFlow(fluxgate.getSignalLowFlow() + 100)
			fluxgate.setSignalHighFlow(fluxgate.getSignalLowFlow())
		elseif core.getEnergyStored() < (core.getMaxEnergyStored() / 2) - 20 then
			fluxgate.setSignalLowFlow(fluxgate.getSignalLowFlow() + 10)
			fluxgate.setSignalHighFlow(fluxgate.getSignalLowFlow())
		elseif core.getEnergyStored() > (7 * (core.getMaxEnergyStored() / 8)) + 20 then
			if fluxgate.getSignalLowFlow() - 10000 < 0 then
				fluxgate.setSignalLowFlow(0)
				fluxgate.setSignalHighFlow(0)
			else
				fluxgate.setSignalLowFlow(fluxgate.getSignalLowFlow() - 10000)
				fluxgate.setSignalHighFlow(fluxgate.getSignalLowFlow())
			end
		elseif core.getEnergyStored() > (3 * (core.getMaxEnergyStored() / 4)) + 20 then
			if fluxgate.getSignalLowFlow() - 1000 < 0 then
				fluxgate.setSignalLowFlow(0)
				fluxgate.setSignalHighFlow(0)
			else
				fluxgate.setSignalLowFlow(fluxgate.getSignalLowFlow() - 1000)
				fluxgate.setSignalHighFlow(fluxgate.getSignalLowFlow())
			end
		elseif core.getEnergyStored() > (5 * (core.getMaxEnergyStored() / 8)) + 20 then
			if fluxgate.getSignalLowFlow() - 100 < 0 then
				fluxgate.setSignalLowFlow(0)
				fluxgate.setSignalHighFlow(0)
			else
				fluxgate.setSignalLowFlow(fluxgate.getSignalLowFlow() - 100)
				fluxgate.setSignalHighFlow(fluxgate.getSignalLowFlow())
			end
		elseif core.getEnergyStored() > (core.getMaxEnergyStored() / 2) + 20 then
			if fluxgate.getSignalLowFlow() - 10 < 0 then
				fluxgate.setSignalLowFlow(0)
				fluxgate.setSignalHighFlow(0)
			else
				fluxgate.setSignalLowFlow(fluxgate.getSignalLowFlow() - 10)
				fluxgate.setSignalHighFlow(fluxgate.getSignalLowFlow())
			end
		else
			updateGUI(fluxgate.getSignalLowFlow())
		end
	else
		if core.getEnergyStored() < (core.getMaxEnergyStored() / 2) - 20 then
			fluxgate.setSignalLowFlow(fluxgate.getSignalLowFlow() + 10)
			fluxgate.setSignalHighFlow(fluxgate.getSignalLowFlow())
		elseif core.getEnergyStored() > (core.getMaxEnergyStored() / 2) + 20 then
			if fluxgate.getSignalLowFlow() - 10 < 0 then
				fluxgate.setSignalLowFlow(0)
				fluxgate.setSignalHighFlow(0)
			else
				fluxgate.setSignalLowFlow(fluxgate.getSignalLowFlow() - 10)
				fluxgate.setSignalHighFlow(fluxgate.getSignalLowFlow())
			end
		else
			updateGUI(fluxgate.getSignalLowFlow())
		end
	end
end

function updateGUI(number)
	gui.clear(mon)
	print("|# Transfer: " .. number .. "RF/t")
	local length = string.len(tostring(number))
	local offset = (length * 4) + (2 * gui.getInteger((length - 1) / 3)) + 16
	local x = (mon.X - offset) / 2
	gui.draw_number(mon, number, x + 16, y, numberColor)
	gui.draw_rft(mon, x, y, unitColor)
end


function updateEnergy()
	local i = 1
	while i < 10 do
		lastEnergy[i] = lastEnergy[i + 1]
		i = i + 1
	end
	lastEnergy[10] = core.getEnergyStored()
end

function checkEnergy()
	local leastEnergy = lastEnergy[1]
	local mostEnergy = lastEnergy[1]
	local i = 1
	while i <= 10 do
		if lastEnergy[i] < leastEnergy then
			leastEnergy = lastEnergy[i]
		end
		if lastEnergy[i] > mostEnergy then
			mostEnergy = lastEnergy[i]
		end
		if leastEnergy + 100 < lastEnergy[i] or mostEnergy - 100 > lastEnergy [i] then
			return false
		end
		i = i + 1
	end
	return true
end

fluxgate.setSignalHighFlow(fluxgate.getSignalLowFlow())
y = (mon.Y - 5) / 2
updateGUI(0)

while true do
	update()
	sleep(refresh)
end
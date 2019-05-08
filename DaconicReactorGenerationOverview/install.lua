-- Installer for GenerationOverview by Zeanon
-- get it with pastebin get VT6ezUgB install
-- pastebin link: https://pastebin.com/VT6ezUgB
local libURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/lib/gui.lua"
local startupURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/DaconicReactorGenerationOverview/startup.lua"
local runURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/DaconicReactorGenerationOverview/run.lua"
local generationOverviewURL = "https://raw.githubusercontent.com/Zeanon/ComputerCraft/master/DaconicReactorGenerationOverview/DaconicReactorGenerationOverview.lua"
local lib, startup, run, generationOverview
local libFile, startupFile, runFile, generationOverviewFile

fs.makeDir("lib")

lib = http.get(libURL)
libFile = lib.readAll()

local file1 = fs.open("lib/gui", "w")
file1.write(libFile)
file1.close()


startup = http.get(startupURL)
startupFile = startup.readAll()

local file2 = fs.open("startup", "w")
file2.write(startupFile)
file2.close()


run = http.get(runURL)
runFile = run.readAll()

local file3 = fs.open("run", "w")
file3.write(runFile)
file3.close()


generationOverview = http.get(generationOverviewURL)
generationOverviewFile = generationOverview.readAll()

local file4 = fs.open("DraconicReactorGenerationOverview", "w")
file4.write(generationOverviewFile)
file4.close()

if fs.exists("update") then
	shell.run("delete update")
end
shell.run("pastebin get HZ7ffzMn update")

if os.getComputerLabel() == null then
    os.setComputerLabel("Reactor-Generation-Overview")
end

shell.run("reboot")

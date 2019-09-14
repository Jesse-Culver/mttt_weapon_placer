-- Allows you to place, export, and import item setups for MTTT maps
-- NOTE: mtttEntity[][] is declared in the autorun file as a global which is why we can access here

TOOL.Category = "Modified Trouble in Terrorist Town"
TOOL.Name = "MTTT Weapon Placer"

TOOL.ClientConVar["item"] = "weapon_zm_pistol"
TOOL.ClientConVar["replacespawns"] = "0"

cleanup.Register("mttt_items")

-- special colours for certain ents
local colors = {
  ttt_random_weapon = Color(255, 255, 0),
  ttt_random_ammo = Color(0, 255, 0),
  item_ammo_revolver_ttt = Color(255, 100, 100),
  ttt_playerspawn = Color(0, 255, 0)
};

-- Send the MTTT Entity table to users when they join
if SERVER then
  util.AddNetworkString("mtttEntityTable")
  hook.Add("PlayerInitialSpawn","SendMTTTents",function(ply)
    print("Sending "..ply:GetName().." the MTTT ent table\n")
    net.Start("mtttEntityTable")
    net.WriteTable(mtttEntity)
    net.Send(ply)
    print("Sent "..ply:GetName().." the MTTT ent table\n")
  end)
end

-- We make all of our item entities Dummy Ents so that they can be placed like props
local function DummyInit(s)
  if colors[s:GetClass()] then
     local c = colors[s:GetClass()]
     s:SetColor(c)
  end

  s:SetCollisionGroup(COLLISION_GROUP_WEAPON)
  s:SetSolid(SOLID_VPHYSICS)
  s:SetMoveType(MOVETYPE_VPHYSICS)

  if s:GetClass() == "ttt_playerspawn" then
     s:PhysicsInitBox(Vector(-18, -18, -0.1), Vector(18, 18, 66))
     s:SetPos(s:GetPos() + Vector(0, 0, 1))
  else
     s:PhysicsInit(SOLID_VPHYSICS)
  end

  s:SetModel(mtttEntity[s:GetClass()]["Model"])
end

-- Register all entities in the table as dummy ents
function DummyEntityRegister()
  for k, v in pairs(mtttEntity) do
    local tbl = {
      Type = "anim",
      Model = mtttEntity[k]["Model"],
      Initialize = DummyInit
    };
    scripted_ents.Register(tbl, k, false)
  end
end

-- Run at least once here
if SERVER then
  DummyEntityRegister()
end

-- Precache all the models that we are going to use
function PrecacheMTTTItemModels()
  for idnum, item in pairs(mtttEntity) do
    util.PrecacheModel(Model(mtttEntity[idnum]["Model"]))
    print(Format("%s has been precached!",mtttEntity[idnum]["Model"]))
  end
  DummyEntityRegister()
end

-- Client specific things, like recieving the MTTT entity table from the server
if CLIENT then
  language.Add("tool.mtttweaponplacer.name", "MTTT Weapon Placer" )
  language.Add("tool.mtttweaponplacer.desc", "Spawn MTTT item dummies and export their placement" )
  language.Add("tool.mtttweaponplacer.0", "Left click to spawn entity." )
  language.Add("Cleanup_Mttt_items", "MTTT Dummy Weapons/ammo/spawns")
  language.Add("Undone_MTTTItems", "Undone MTTT item" )
  net.Receive("mtttEntityTable", function()
    print("New MTT Table recieved")
    table.CopyFromTo(net.ReadTable(),mtttEntity)
    PrintTable(mtttEntity)
    PrecacheMTTTItemModels()
  end)
end

-- This is the setup for the options in game on the tool
function TOOL.BuildCPanel(panel)
  panel:AddControl( "Header", { Text = "tool.mtttweaponplacer.name", Description = language.GetPhrase("tool.mtttweaponplacer.desc")})
  local itemChoices = {}
  for idnum, item in pairs(mtttEntity) do
    itemChoices[mtttEntity[idnum]["PrintName"]] = {mtttweaponplacer_item = mtttEntity[idnum]["ClassName"]}
  end
  panel:AddControl("ListBox", { Label = "Items", Height = "200", Options = itemChoices } )
  panel:AddControl("Button", {Label="Report counts", Command="mtttweaponplacer_count", Text="Count"})
  panel:AddControl( "Button",  { Label	= "Export to file", Command = "mtttweaponplacer_export", Text = "Export"})
  panel:AddControl( "Button",  { Label	= "Import from file", Command = "mtttweaponplacer_import", Text = "Import"})
  panel:AddControl("Button", {Label="Remove all existing weapon/ammo", Command = "mtttweaponplacer_removeall", Text="Remove all existing items"})
end

function TOOL:LeftClick(trace)
  -- Get ClientConvar for currently selected weapon
  if CLIENT and game.SinglePlayer() ~= true then return true end
  local clientItem = self:GetClientInfo("item")
  local mdl = mtttEntity[clientItem]["Model"]
  if util.IsValidModel(mdl) ~= true then return end
  local ent = ents.Create(clientItem)
  ent:SetModel(mdl)
  ent:SetPos(trace.HitPos)
  local tr = util.TraceEntity({start=trace.StartPos, endpos=trace.HitPos, filter=self:GetOwner()}, ent)
   if tr.Hit then
      ent:SetPos(tr.HitPos)
   end
   ent:Spawn()

   ent:PhysWake()

   undo.Create("MTTTItem")
   undo.AddEntity(ent)
   undo.SetPlayer(self:GetOwner())
   undo.Finish()

   self:GetOwner():AddCleanup("mttt_items", ent)
end

function TOOL:RightClick(tr)
  return
end

-- Print to the players chat the count of each item in use
local function PrintCount(ply)
  if not IsValid(ply) then return end
  ply:ChatPrint("**ITEMS PLACED**")
  for idnum, item in pairs(mtttEntity) do
    local num = 0
    for k, ent in pairs(ents.FindByClass(mtttEntity[idnum]["ClassName"])) do
      num = num + 1
    end
    if num ~= 0 then
      ply:ChatPrint(mtttEntity[idnum]["PrintName"]..": ".. tostring(num))
    end
  end
  ply:ChatPrint("**You may need to open chat and scroll up to see full list**")
end
concommand.Add("mtttweaponplacer_count", PrintCount)

-- Export placement of items to a text file for import later
-- If server or singleplayer then we save locally
-- Clients can't cause server to export, command must be run from rcon or server terminal
local function Export(ply)
  if SERVER or game.SinglePlayer() then
    local map = string.lower(game.GetMap())
    if not map then return end
    local buf =  "# Modified Trouble in Terrorist Town weapon/ammo placement overrides\n"
    buf = buf .. "# For map: " .. map .. "\n"
    buf = buf .. "# Exported by: " .. GetHostName() .. "\n"
    buf = buf .. "setting:\treplacespawns 0\n"

    local num = 0
    for cls, mdl in pairs(mtttEntity) do
      print("Checking for "..mtttEntity[cls]["ClassName"])
      for _, ent in pairs(ents.FindByClass(mtttEntity[cls]["ClassName"])) do
        print("Found "..mtttEntity[cls]["ClassName"])
        if IsValid(ent) then
          num = num + 1
          buf = buf .. Format("%s\t%s\t%s\n", cls, tostring(ent:GetPos()), tostring(ent:GetAngles()))
        end
      end
    end

    local fname = "mttt/maps/" .. map .. "_ttt.txt"
    file.Write(fname,buf)
    if not file.Exists(fname, "DATA") then
      ErrorNoHalt("Exported file not found. Bug?\n")
   end
   PrintMessage(HUD_PRINTTALK, num .." placements saved to /garrysmod/data/".. fname)
  else
    if not IsValid(ply) then return end
    local map = string.lower(game.GetMap())
    if not map then return end
    local buf =  "# Modified Trouble in Terrorist Town weapon/ammo placement overrides\n"
    buf = buf .. "# For map: " .. map .. "\n"
    buf = buf .. "# Exported by: " .. GetHostName() .. "\n"
    buf = buf .. "setting:\treplacespawns 0\n"

    local num = 0
    for cls, mdl in pairs(mtttEntity) do
      print("Checking for "..mtttEntity[cls]["ClassName"])
      for _, ent in pairs(ents.FindByClass(mtttEntity[cls]["ClassName"])) do
        print("Found "..mtttEntity[cls]["ClassName"])
        if IsValid(ent) then
          num = num + 1
          buf = buf .. Format("%s\t%s\t%s\n", cls, tostring(ent:GetPos()), tostring(ent:GetAngles()))
        end
      end
    end

    local fname = "mttt/maps/" .. map .. "_ttt.txt"
    file.Write(fname,buf)
    if not file.Exists(fname, "DATA") then
      ErrorNoHalt("Exported file not found. Bug?\n")
   end
   ply:ChatPrint(num .." placements saved to /garrysmod/data/".. fname .. " locally. To save on server use the command mtttweaponplacer_export from the server terminal or rcon")
  end
end
concommand.Add("mtttweaponplacer_export", Export)

-- Used to spawn dummy ents after an import
local function SpawnDummyItem(cls, pos, ang)
  if SERVER then
    if not cls or not pos or not ang then return false end

    local mdl = mtttEntity[cls]["Model"]
    if not mdl then return end

    local ent = ents.Create(cls)
    ent:SetModel(mdl)
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    ent:SetSolid(SOLID_VPHYSICS)
    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:PhysicsInit(SOLID_VPHYSICS)

    ent:Spawn()

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
      phys:SetAngles(ang)
    end
  end
end

-- Imports entities from a text file and loads them into the map
local function Import()
  if SERVER then
    local map = string.lower(game.GetMap())
    if not map then return end

    local fname = "mttt/maps/" .. map .. "_ttt.txt"

    if not file.Exists(fname, "DATA") then
      PrintMessage(HUD_PRINTTALK,fname .. " not found!")
      return
    end

    local buf = file.Read(fname, "DATA")
    local lines = string.Explode("\n", buf)
    local num = 0
    for k, line in ipairs(lines) do
      if not string.match(line, "^#") and line ~= "" then
          local data = string.Explode("\t", line)

          local fail = true -- pessimism

          if #data > 0 then
            if data[1] == "setting:" and tostring(data[2]) then
                local raw = string.Explode(" ", data[2])
                RunConsoleCommand("mtttweaponplacer_" .. raw[1], tonumber(raw[2]))

                fail = false
                num = num - 1
            elseif #data == 3 then
                local cls = data[1]
                local ang = nil
                local pos = nil

                local posraw = string.Explode(" ", data[2])
                pos = Vector(tonumber(posraw[1]), tonumber(posraw[2]), tonumber(posraw[3]))

                local angraw = string.Explode(" ", data[3])
                ang = Angle(tonumber(angraw[1]), tonumber(angraw[2]), tonumber(angraw[3]))

                fail = SpawnDummyItem(cls, pos, ang)
            end
          end

          if fail then
            ErrorNoHalt("Invalid line " .. k .. " in " .. fname .. "\n")
          else
            num = num + 1
          end
      end
    end

    PrintMessage(HUD_PRINTTALK,"Spawned " .. tostring(num) .. " dummy ents")
  end
end
concommand.Add("mtttweaponplacer_import", Import)

local function RemoveAll()
  if SERVER then
    local num = 0
    local delete = function(ent)
                      if not IsValid(ent) then return end
                      print("\tRemoving", ent, ent:GetClass())
                      ent:Remove()
                      num = num + 1
                  end
    for idnum, item in pairs(mtttEntity) do
      for k, ent in pairs(ents.FindByClass(mtttEntity[idnum]["ClassName"])) do
        delete(ent)
      end
    end
    PrintMessage(HUD_PRINTTALK,"Removed " .. tostring(num) .. " weapon/ammo ents")
  end
end
concommand.Add("mtttweaponplacer_removeall", RemoveAll)

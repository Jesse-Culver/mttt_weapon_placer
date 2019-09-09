-- Allows you to place, export, and import item setups for MTTT maps
-- NOTE: mtttEntity[][] is declared in the autorun file as a global which is why we can access here

TOOL.Category = "Modified Trouble in Terrorist Town"
TOOL.Name = "MTTT Weapon Placer"

TOOL.ClientConVar["item"] = "weapon_zm_pistol"
TOOL.ClientConVar["replacespawns"] = "0"

cleanup.Register("mttt_items")

if CLIENT then
  language.Add("tool.mtttweaponplacer.name", "MTTT Weapon Placer" )
  language.Add("tool.mtttweaponplacer.desc", "Spawn MTTT item dummies and export their placement" )
  language.Add("tool.mtttweaponplacer.0", "Left click to spawn entity." )
  language.Add("Cleanup_Mttt_items", "MTTT Dummy Weapons/ammo/spawns")
  language.Add("Undone_MTTTItems", "Undone MTTT item" )
end

-- special colours for certain ents
local colors = {
  ttt_random_weapon = Color(255, 255, 0),
  ttt_random_ammo = Color(0, 255, 0),
  item_ammo_revolver_ttt = Color(255, 100, 100),
  ttt_playerspawn = Color(0, 255, 0)
};

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
for k, v in pairs(mtttEntity) do
  local tbl = {
     Type = "anim",
     Model = mtttEntity[k]["Model"],
     Initialize = DummyInit
  };
  scripted_ents.Register(tbl, k, false)
end

-- This is the setup for the options in game on the tool
function TOOL.BuildCPanel(panel)
  panel:AddControl( "Header", { Text = "tool.mtttweaponplacer.name", Description = language.GetPhrase("tool.mtttweaponplacer.desc")})
  local itemChoices = {}
  for idnum, item in pairs(mtttEntity) do
    itemChoices[mtttEntity[idnum]["PrintName"]] = {mtttweaponplacer_item = mtttEntity[idnum]["ClassName"]}
  end
  panel:AddControl("ListBox", { Label = "Items", Height = "200", Options = itemChoices } )
  --panel:AddControl("Button", {Label="Report counts", Command="mtttweaponplacer_count", Text="Count"})
  --panel:AddControl("Label", {Text="Export", Description="Export weapon placements"})
  --panel:AddControl("CheckBox", {Label="Replace existing player spawnpoints", Command="mtttweaponplacer_replacespawns", Text="Replace spawns"})
  panel:AddControl( "Button",  { Label	= "Export to file", Command = "mtttweaponplacer_export", Text = "Export"})
  --panel:AddControl("Label", {Text="Import", Description="Import weapon placements"})
  --panel:AddControl( "Button",  { Label	= "Import from file", Command = "mtttweaponplacer_queryimport", Text = "Import"})
  --panel:AddControl("Button", {Label="Convert HL2 entities", Command = "mtttweaponplacer_replacehl2", Text="Convert"})
  --panel:AddControl("Button", {Label="Remove all existing weapon/ammo", Command = "mtttweaponplacer_removeall", Text="Remove all existing items"})
end

function TOOL:SpawnItem(clientItem,trace)
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

function TOOL:LeftClick(tr)
  -- Get ClientConvar for currently selected weapon
  local clientItem = self:GetClientInfo("item")
  self:SpawnItem(clientItem,tr)
end

function TOOL:RightClick(tr)
  return
end

local function Export()
  if SERVER then
    local map = string.lower(game.GetMap())
    if not map then return end
    local buf =  "# Modified Trouble in Terrorist Town weapon/ammo placement overrides\n"
    buf = buf .. "# For map: " .. map .. "\n"
    buf = buf .. "# Exported by: " .. GetHostName() .. "\n"
    -- Write settings ("setting: <name> <value>")
    local rspwns = GetConVar("mtttweaponplacer_replacespawns"):GetBool() and "1" or "0"
    buf = buf .. "setting:\treplacespawns " .. rspwns .. "\n"

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
   PrintMessage(HUD_PRINTTALK, num .." placements saved to /garrysmod/data/".. fname .. " on the server")
  end
end
concommand.Add("mtttweaponplacer_export", Export)


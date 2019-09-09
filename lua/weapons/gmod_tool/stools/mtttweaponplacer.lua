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

-- This is the setup for the options in game on the tool
function TOOL.BuildCPanel(panel)
  panel:AddControl( "Header", { Text = "tool.mtttweaponplacer.name", Description = language.GetPhrase("tool.mtttweaponplacer.desc")})
  local itemChoices = {}
  for idnum, item in pairs(mtttEntity) do
    itemChoices[mtttEntity[idnum]["PrintName"]] = {mtttweaponplacer_item = mtttEntity[idnum]["ClassName"]}
  end
  panel:AddControl("ListBox", { Label = "Items", Height = "200", Options = itemChoices } )
  panel:AddControl("Button", {Label="Report counts", Command="mtttweaponplacer_count", Text="Count"})
  --panel:AddControl("Label", {Text="Export", Description="Export weapon placements"})
  --panel:AddControl("CheckBox", {Label="Replace existing player spawnpoints", Command="mtttweaponplacer_replacespawns", Text="Replace spawns"})
  panel:AddControl( "Button",  { Label	= "Export to file", Command = "mtttweaponplacer_queryexport", Text = "Export"})
  --panel:AddControl("Label", {Text="Import", Description="Import weapon placements"})
  --panel:AddControl( "Button",  { Label	= "Import from file", Command = "mtttweaponplacer_queryimport", Text = "Import"})
  --panel:AddControl("Button", {Label="Convert HL2 entities", Command = "mtttweaponplacer_replacehl2", Text="Convert"})
  --panel:AddControl("Button", {Label="Remove all existing weapon/ammo", Command = "mtttweaponplacer_removeall", Text="Remove all existing items"})
end

-- function TOOL:SpawnItem(clientItem,trace)
--   local model = 
-- end

function TOOL:LeftClick(tr)
  -- Get ClientConvar for currently selected weapon
  -- local clientItem = self:GetClientInfo("item")
  -- self:SpawnItem(clientItem,tr)
end

function TOOL:RightClick(tr)
  return
end

end
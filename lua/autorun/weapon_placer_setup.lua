-- This script runs at the start and makes sure that you have the proper files created for the
-- weapon placer tool, it also generates the table that holds all the information
if engine.ActiveGamemode() ~= 'sandbox' then return end
-- Structure - CSV
-- entity_name,print name,model
local contents = 
[[ttt_random_weapon,Random weapon,models/weapons/w_shotgun.mdl
ttt_random_ammo,Random ammo,models/Items/battery.mdl
ttt_playerspawn,Player spawn,models/editor/playerstart.mdl
weapon_zm_pistol,Pistol,models/weapons/w_pist_fiveseven.mdl
weapon_zm_shotgun,Shotgun,models/weapons/w_shot_xm1014.mdl
weapon_zm_mac10,MAC10,models/weapons/w_smg_mac10.mdl
weapon_zm_revolver,Deagle,models/weapons/w_pist_deagle.mdl
weapon_zm_rifle,Rifle,models/weapons/w_snip_scout.mdl
weapon_zm_sledge,HUGE249,models/weapons/w_mach_m249para.mdl
weapon_zm_molotov,Fire nade,models/weapons/w_eq_flashbang.mdl
weapon_ttt_confgrenade,Discombobulator,models/weapons/w_eq_fraggrenade.mdl
weapon_ttt_smokegrenade,Smoke Grenade,models/weapons/w_eq_smokegrenade.mdl
weapon_ttt_m16,M16,models/weapons/w_rif_m4a1.mdl
weapon_ttt_glock,Glock,models/weapons/w_pist_glock18.mdl
item_ammo_357_ttt,Ammo 357,models/items/357ammo.mdl
item_ammo_pistol_ttt,Ammo pistol,models/items/boxsrounds.mdl
item_ammo_revolver_ttt,Ammo revolver,models/items/357ammo.mdl
item_ammo_smg1_ttt,Ammo SMG,models/items/boxmrounds.mdl
item_ammo_box_buckshot_ttt,Ammo shotgun,models/items/boxbuckshot.mdl]]

mtttEntity = {{
}};
-- Check if the mttt directory even exists in the data folder
if file.IsDir("mttt", "DATA") ~= true then
  file.CreateDir("mttt")
end
-- Check if the mttt/maps directory even exists in the data folder
if file.IsDir("mttt/maps", "DATA") ~= true then
  file.CreateDir("mttt/maps")
end
-- Check if the file exists
if file.Read("mttt/itemplacer.txt") == nil then
  file.Write("mttt/itemplacer.txt", contents)
end

function PrecacheMTTTItemModels()
  for idnum, item in pairs(mtttEntity) do
    util.PrecacheModel(Model(mtttEntity[idnum]["Model"]))
    print(Format("%s has been precached!",mtttEntity[idnum]["Model"]))
  end
end

function FillMTTTEntTable()
  local itemFile = file.Read("mttt/itemplacer.txt")
  local allItemsTableTemp = string.Explode("\n", itemFile)
  for key, val in pairs(allItemsTableTemp) do
    local itemTableTemp = string.Explode(",", val)
    local valTableTemp = {}
    for j, k in pairs(itemTableTemp) do
      if j == 1 then
        valTableTemp["ClassName"] = k
      elseif j == 2 then
        valTableTemp["PrintName"] = k
      elseif j == 3 then
        valTableTemp["Model"] = k
      end
    end
    -- Insert by classname
    mtttEntity[itemTableTemp[1]] = valTableTemp
  end
  -- We have to remove the last line because it's always blank thanks to inserts
  table.remove(mtttEntity,1)
  -- Precache everything
  PrecacheMTTTItemModels()
  print("Entities loaded for MTTT Placer: \n")
  PrintTable(mtttEntity)
end

FillMTTTEntTable()
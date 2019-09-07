-- This script runs at the start and makes sure that you have the proper files created for the
-- weapon placer tool, it also generates the table that holds all the information

-- Structure - CSV
-- entity_name,print name,ammo,model
local contents = 
[[ttt_random_weapon,Random weapon,ttt_random_ammo,models/weapons/w_shotgun.mdl
ttt_random_ammo,Random ammo,none,models/Items/battery.mdl
ttt_playerspawn,Player spawn,none,models/player.mdl
weapon_zm_pistol,Pistol,item_ammo_pistol_ttt,models/weapons/w_pist_fiveseven.mdl
weapon_zm_shotgun,Shotgun,item_box_buckshot_ttt,models/weapons/w_shot_xm1014.mdl
weapon_zm_mac10,MAC10,item_ammo_smg1_ttt,models/weapons/w_smg_mac10.mdl
weapon_zm_revolver,Deagle,item_ammo_revolver_ttt,models/weapons/w_pist_deagle.mdl
weapon_zm_rifle,Rifle,item_ammo_357_ttt,models/weapons/w_snip_scout.mdl
weapon_zm_sledge,HUGE249,none,models/weapons/w_mach_m249para.mdl
weapon_zm_molotov,Fire nade,none,models/weapons/w_eq_flashbang.mdl
weapon_ttt_confgrenade,Discombobulator,none,models/weapons/w_eq_fraggrenade.mdl
weapon_ttt_smokegrenade,Smoke Grenade,models/weapons/w_eq_smokegrenade.mdl
weapon_ttt_m16,M16,item_ammo_pistol_ttt,models/weapons/w_rif_m4a1.mdl
weapon_ttt_glock,Glock,item_ammo_pistol_ttt,models/weapons/w_pist_glock18.mdl]]

mtttEntity = {{
}};
-- Check if the mttt directory even exists in the data folder
if file.IsDir("mttt", "DATA") ~= true then
  file.CreateDir("mttt")
end
-- Check if the file exists
if file.Read("mttt/itemplacer.txt") == nil then
  file.Write("mttt/itemplacer.txt", contents)
end

function FillMTTTEntTable()
  local itemFile = file.Read("mttt/itemplacer.txt")
  local allItemsTableTemp = string.Explode("\n", itemFile)
  for key, val in pairs(allItemsTableTemp) do
    local itemTableTemp = string.Explode(",", val)
    local valTableTemp = {}
    for j, k in pairs(itemTableTemp) do
      if j == 1 then --Skip val 1 because we are using it as the key for the entire row
        valTableTemp["ClassName"] = k
      elseif j == 2 then
        valTableTemp["PrintName"] = k
      elseif j == 3 then
        valTableTemp["Ammo"] = k
      elseif j == 4 then
        valTableTemp["Model"] = k
      end
    end
    -- Insert by classname
    mtttEntity[itemTableTemp[1]] = valTableTemp
  end
  -- We have to remove the last line because it's always blank thanks to inserts
  table.remove(mtttEntity,1)
  print("Entities loaded for MTTT Placer: \n")
  PrintTable(mtttEntity)
end

FillMTTTEntTable()
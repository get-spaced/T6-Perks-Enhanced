#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\zombies\_zm_perks;
#include maps\mp\zombies\_zm_perk_divetonuke;
#include maps\mp\_visionset_mgr;
#include maps\mp\zombies\_zm_power;
#include maps\mp\zombies\_zm;

#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_weapon_locker;
#include maps\mp\zm_transit;
#include maps\mp\zm_transit_standard_station;
#include maps\mp\zombies\_zm_race_utility;
#include maps\mp\zombies\_zm_magicbox;
#include maps\mp\gametypes_zm\_zm_gametype;

#include scripts\zm\_utils;

is_transit() {
  if (getdvar("mapname") != "zm_transit")
    return false;

  location = getdvar("ui_zm_mapstartlocation");
  mode = getdvar("ui_zm_gamemodegroup");

  if (isdefined(level.scr_zm_map_start_location))
    location = level.scr_zm_map_start_location;

  if (isdefined(level.scr_zm_ui_gametype_group))
    mode = level.scr_zm_ui_gametype_group;

  return (location == "town" && mode == "zsurvival") || (location == "transit" && mode == "zclassic");
}

main() {
  if (!is_transit())
    return;

  safe_replacefunc("maps/mp/zombies/_zm_tombstone", "tombstone_laststand", ::tombstone_laststand_override);
  safe_replacefunc("maps/mp/zombies/_zm_tombstone", "tombstone_spawn", ::tombstone_spawn_override);
}

tombstone_spawn_override() {

}

tombstone_laststand_override() {
  if (!self hasperk("specialty_scavenger"))
    return;

  self.tombstone_saved_perks = get_tombstone_saved_perks();

  if (self hasperk("specialty_additionalprimaryweapon"))
    self tombstone_save_mulekick_weapon();
  else
    self tombstone_clear_mulekick_weapon();

  if (self.tombstone_saved_perks.size <= 0)
    return;

  self thread tombstone_wait_for_revive();
}

get_tombstone_saved_perks() {
  perks = [];

  if (self hasperk("specialty_armorvest"))
    perks[perks.size] = "specialty_armorvest";

  if (self hasperk("specialty_deadshot"))
    perks[perks.size] = "specialty_deadshot";

  if (self hasperk("specialty_fastreload"))
    perks[perks.size] = "specialty_fastreload";

  if (self hasperk("specialty_flakjacket"))
    perks[perks.size] = "specialty_flakjacket";

  if (self hasperk("specialty_longersprint"))
    perks[perks.size] = "specialty_longersprint";

  if (self hasperk("specialty_rof"))
    perks[perks.size] = "specialty_rof";

  if (self hasperk("specialty_additionalprimaryweapon"))
    perks[perks.size] = "specialty_additionalprimaryweapon";

  if (self hasperk("specialty_finalstand"))
    perks[perks.size] = "specialty_finalstand";

  if (self hasperk("specialty_grenadepulldeath"))
    perks[perks.size] = "specialty_grenadepulldeath";

  if (self hasperk("specialty_nomotionsensor"))
    perks[perks.size] = "specialty_nomotionsensor";

  if (self hasperk("specialty_scavenger"))
    perks[perks.size] = "specialty_scavenger";

  return perks;
}

tombstone_save_mulekick_weapon() {
  self tombstone_clear_mulekick_weapon();

  weapons = self getweaponslistprimaries();

  if (!isdefined(weapons))
    return;

  if (weapons.size < 3)
    return;

  weapon = weapons[2];

  if (!isdefined(weapon))
    return;

  if (weapon == "none")
    return;

  self.tombstone_mulekick_weapon = weapon;
  self.tombstone_mulekick_clip = self getweaponammoclip(weapon);
  self.tombstone_mulekick_stock = self getweaponammostock(weapon);
}

tombstone_clear_mulekick_weapon() {
  self.tombstone_mulekick_weapon = undefined;
  self.tombstone_mulekick_clip = undefined;
  self.tombstone_mulekick_stock = undefined;
}

tombstone_wait_for_revive() {
  self endon("disconnect");
  level endon("end_game");

  result = self waittill_any_return(
    "player_revived",
    "spawned_player",
    "disconnect"
  );

  if (result != "player_revived") {
    self.tombstone_saved_perks = undefined;
    self tombstone_clear_mulekick_weapon();
    return;
  }

  self iprintln("returning ^1" + self.tombstone_saved_perks.size + " ^7perks from tombstone!");

  wait_network_frame();
  self tombstone_restore_random_perks();
}

tombstone_restore_random_perks() {
  if (!isdefined(self.tombstone_saved_perks))
    return;

  perks = self.tombstone_saved_perks;
  self.tombstone_saved_perks = undefined;

  if (perks.size <= 0) {
    self tombstone_clear_mulekick_weapon();
    return;
  }

  amount = int(perks.size / 2);

  if ((perks.size % 2) == 1 && randomint(2))
    amount++;

  restored_mulekick = false;

  for (i = 0; i < amount && perks.size > 0; i++) {
    index = randomint(perks.size);
    perk = perks[index];

    perks = array_remove(perks, index);

    if (!isdefined(perk))
      continue;

    if (self hasperk(perk))
      continue;

    self maps\mp\zombies\_zm_perks::give_perk(perk, 0);

    if (perk == "specialty_additionalprimaryweapon")
      restored_mulekick = true;
  }

  if (restored_mulekick) {
    wait_network_frame();
    self tombstone_restore_mulekick_weapon();
    return;
  }
  
  self tombstone_clear_mulekick_weapon();
}

tombstone_restore_mulekick_weapon()
{
  if (!self hasperk("specialty_additionalprimaryweapon"))
  {
    self tombstone_clear_mulekick_weapon();
    return;
  }

  if (!isdefined(self.tombstone_mulekick_weapon))
    return;

  weapon = self.tombstone_mulekick_weapon;

  if (weapon == "none")
  {
    self tombstone_clear_mulekick_weapon();
    return;
  }

  if (self hasweapon(weapon))
  {
    self tombstone_clear_mulekick_weapon();
    return;
  }

  primaries = self getweaponslistprimaries();

  if (isdefined(primaries) && primaries.size >= 3)
  {
    self tombstone_clear_mulekick_weapon();
    return;
  }

  self giveweapon(weapon);

  if (isdefined(self.tombstone_mulekick_clip))
    self setweaponammoclip(
      weapon,
      self.tombstone_mulekick_clip
    );

  if (isdefined(self.tombstone_mulekick_stock))
    self setweaponammostock(
      weapon,
      self.tombstone_mulekick_stock
    );

  self tombstone_clear_mulekick_weapon();
}

array_remove(arr, remove_index) {
  result = [];

  for (i = 0; i < arr.size; i++) {
    if (i == remove_index)
      continue;

    result[result.size] = arr[i];
  }

  return result;
}
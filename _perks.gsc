#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\zombies\_zm_perks;
#include maps\mp\zombies\_zm_perk_divetonuke;
#include maps\mp\zombies\_zm_perk_electric_cherry;
#include maps\mp\zombies\_zm_perk_vulture;
#include maps\mp\_visionset_mgr;
#include maps\mp\zombies\_zm_power;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_laststand;

#include scripts\zm\_utils;

main() {
  safe_replacefunc("maps/mp/zombies/_zm", "actor_damage_override", ::actor_damage_override_override);
} 

init() {
  level.player_too_many_weapons_monitor_func = ::player_too_many_weapons_monitor;
  level.player_out_of_playable_area_monitor = false;
  level.perk_purchase_limit = 12;

  set_dvar_default("stam_ignores_lava", 0);
  set_dvar_default("refill_player_banks", 1);
  set_dvar_default("use_perk_waypoints", 1);

  onplayerconnect_callback(::on_player_connected);
}

on_player_connected() {
  self endon("disconnect");

  self waittill("spawned_player");

  flag_wait("initial_blackscreen_passed");

  // store og username incase server changes
  self.original_name = self.name;

  self thread staminup_handler();
  self thread speed_cola_handler();
  self thread record_fill_bank();
  self thread mule_kick_weapon_hud();
  self thread phd_grenade_watch();

  // self thread give_all_perks();
}

// give_all_perks() {
//   wait 3;

//   level.zombiemode_using_vulture_perk = 1;

//   if (isdefined(level.zombiemode_using_revive_perk) && level.zombiemode_using_revive_perk)
//     self maps\mp\zombies\_zm_perks::give_perk("specialty_quickrevive", false);

//   if (isdefined(level.zombiemode_using_juggernaut_perk) && level.zombiemode_using_juggernaut_perk)
//     self maps\mp\zombies\_zm_perks::give_perk("specialty_armorvest", false);

//   if (isdefined(level.zombiemode_using_sleightofhand_perk) && level.zombiemode_using_sleightofhand_perk)
//     self maps\mp\zombies\_zm_perks::give_perk("specialty_fastreload", false);

//   if (isdefined(level.zombiemode_using_doubletap_perk) && level.zombiemode_using_doubletap_perk)
//     self maps\mp\zombies\_zm_perks::give_perk("specialty_rof", false);

//   if (isdefined(level.zombiemode_using_marathon_perk) && level.zombiemode_using_marathon_perk)
//     self maps\mp\zombies\_zm_perks::give_perk("specialty_longersprint", false);

//   if (isdefined(level.zombiemode_using_additionalprimaryweapon_perk) && level.zombiemode_using_additionalprimaryweapon_perk)
//     self maps\mp\zombies\_zm_perks::give_perk("specialty_additionalprimaryweapon", false);

//   if (isdefined(level.zombiemode_using_deadshot_perk) && level.zombiemode_using_deadshot_perk)
//     self maps\mp\zombies\_zm_perks::give_perk("specialty_deadshot", false);

//   if (isdefined(level.zombiemode_using_chugabud_perk) && level.zombiemode_using_chugabud_perk)
//     self maps\mp\zombies\_zm_perks::give_perk("specialty_finalstand", false);

//   if (isdefined(level.zombiemode_using_divetonuke_perk) && level.zombiemode_using_divetonuke_perk)
//     self maps\mp\zombies\_zm_perks::give_perk("specialty_flakjacket", false);

//   if (isdefined(level.zombiemode_using_electric_cherry_perk) && level.zombiemode_using_electric_cherry_perk)
//     self maps\mp\zombies\_zm_perks::give_perk("specialty_grenadepulldeath", false);

//   if (isdefined(level.zombiemode_using_vulture_perk) && level.zombiemode_using_vulture_perk)
//     self maps\mp\zombies\_zm_perks::give_perk("specialty_nomotionsensor", false);

//    if (isdefined(level.zombiemode_using_tombstone_perk) && level.zombiemode_using_tombstone_perk)
//     self maps\mp\zombies\_zm_perks::give_perk("specialty_scavenger", false);
// }

player_too_many_weapons_monitor() {
  if (getdvar("mapname") != "zm_prison")
    return;

  self notify("stop_player_too_many_weapons_monitor");
  self endon("stop_player_too_many_weapons_monitor");
  self endon("disconnect");
  level endon("end_game");

  scalar = self.characterindex;

  if (!isdefined(scalar))
    scalar = self getentitynumber();

  wait 0.15 * scalar;

  for (;;) {
    if (
      self has_powerup_weapon() ||
      self maps\mp\zombies\_zm_laststand::player_is_in_laststand() ||
      self.sessionstate == "spectator"
    ) {
      wait get_player_too_many_weapons_monitor_wait_time();
      continue;
    }

    weapon_limit = get_player_weapon_limit(self);
    primary_weapons = self getweaponslistprimaries();

    if (primary_weapons.size > weapon_limit) {
      self maps\mp\zombies\_zm_weapons::take_fallback_weapon();
      primary_weapons = self getweaponslistprimaries();
    }

    weapons_to_take = [];

    foreach (weapon in primary_weapons) {
      if (
        maps\mp\zombies\_zm_weapons::is_weapon_included(weapon) ||
        maps\mp\zombies\_zm_weapons::is_weapon_upgraded(weapon)
      ) {
        weapons_to_take[weapons_to_take.size] = weapon;
      }
    }

    if (weapons_to_take.size > weapon_limit) {
      should_take = true;

      if (isdefined(level.player_too_many_weapons_monitor_callback))
        should_take = self [[level.player_too_many_weapons_monitor_callback]](weapons_to_take);

      if (should_take) {
        self maps\mp\zombies\_zm_stats::increment_map_cheat_stat("cheat_too_many_weapons");
        self maps\mp\zombies\_zm_stats::increment_client_stat("cheat_too_many_weapons", 0);
        self maps\mp\zombies\_zm_stats::increment_client_stat("cheat_total", 0);
        weapon = weapons_to_take[weapons_to_take.size - 1];

        if (isdefined(weapon))
          self takeweapon(weapon);
      }
    }

    wait get_player_too_many_weapons_monitor_wait_time();
  }
}

sync_speed_cola_bonus(perk, added, enabled) {
  if (!enabled && added) {
    self unsetperk(perk);
    return false;
  }

  if (!enabled || self hasperk(perk))
    return added;

  self setperk(perk);

  return true;
}


speed_cola_handler() {
  self endon("disconnect");
  level endon("game_ended");

  added_switch = false;
  added_ads = false;
  added_toss = false;

  for (;;) {
    enabled = self hasperk("specialty_fastreload");

    added_switch = self sync_speed_cola_bonus("specialty_fastweaponswitch", added_switch, enabled);
    added_ads = self sync_speed_cola_bonus("specialty_fastads", added_ads, enabled);
    added_toss = self sync_speed_cola_bonus("specialty_fasttoss", added_toss, enabled);

    wait 0.25;
  }
}


staminup_handler() {
  self endon("disconnect");

  had_staminup = false;
  ignore_lava = get_dvar_default("stam_ignores_lava", 0, "int");

  for (;;) {
    has_staminup = self hasperk("specialty_longersprint");

    if (has_staminup == had_staminup) {
      wait 0.25;
      continue;
    }

    had_staminup = has_staminup;
    sprint_value = "0";

    if (has_staminup)
      sprint_value = "1";

    self setclientdvar("player_sprintunlimited", sprint_value);

    if (ignore_lava)
      self.ignore_lava_damage = has_staminup;

    wait 0.25;
  }
}


record_fill_bank() {
  self endon("disconnect");
  level endon("end_game");

  flag_wait("initial_blackscreen_passed");

  should_refill = get_dvar_default("refill_player_banks", 0, "int");

  if (!should_refill)
    return;

  self.account_value = int(level.bank_account_max);
  self maps\mp\zombies\_zm_stats::set_map_stat("depositBox", self.account_value, level.banking_map);
}

actor_damage_override_override( inflictor, attacker, damage, flags, meansofdeath, weapon, vpoint, vdir, shitloc, psoffsettime, boneindex ) {
  if ( !isdefined( self ) || !isdefined( attacker ) )
    return damage;

  if ( weapon == "tazer_knuckles_zm" || weapon == "jetgun_zm" )
    self.knuckles_extinguish_flames = 1;
  else if ( weapon != "none" )
    self.knuckles_extinguish_flames = undefined;

  if ( isdefined( attacker.animname ) && attacker.animname == "quad_zombie" )
  {
    if ( isdefined( self.animname ) && self.animname == "quad_zombie" )
      return 0;
  }

  if ( !isplayer( attacker ) && isdefined( self.non_attacker_func ) )
  {
    if ( isdefined( self.non_attack_func_takes_attacker ) && self.non_attack_func_takes_attacker )
      return self [[ self.non_attacker_func ]]( damage, weapon, attacker );
    else
      return self [[ self.non_attacker_func ]]( damage, weapon );
  }

  if ( !isplayer( attacker ) && !isplayer( self ) )
    return damage;

  if ( !isdefined( damage ) || !isdefined( meansofdeath ) )
    return damage;

  if ( meansofdeath == "" )
    return damage;

  old_damage = damage;
  final_damage = damage;

  if ( isdefined( self.actor_damage_func ) )
    final_damage = [[ self.actor_damage_func ]]( inflictor, attacker, damage, flags, meansofdeath, weapon, vpoint, vdir, shitloc, psoffsettime, boneindex );

  if ( attacker.classname == "script_vehicle" && isdefined( attacker.owner ) )
    attacker = attacker.owner;

  if ( isdefined( self.in_water ) && self.in_water )
  {
    if ( int( final_damage ) >= self.health )
      self.water_damage = 1;
  }

  attacker thread maps\mp\gametypes_zm\_weapons::checkhit( weapon );

  if (
    isplayer( attacker ) &&
    attacker hasperk( "specialty_deadshot" ) &&
    is_headshot( weapon, shitloc, meansofdeath )
  )
  {
    if ( is_deadshot_sniper( weapon ) )
      final_damage *= 2.0;
    else
      final_damage *= 1.5;
  }

  if ( attacker maps\mp\zombies\_zm_pers_upgrades_functions::pers_mulit_kill_headshot_active() && is_headshot( weapon, shitloc, meansofdeath ) )
    final_damage = final_damage * 2;

  if ( isdefined( level.headshots_only ) && level.headshots_only && isdefined( attacker ) && isplayer( attacker ) )
  {
    if ( meansofdeath == "MOD_MELEE" && ( shitloc == "head" || shitloc == "helmet" ) )
      return int( final_damage );

    if ( is_explosive_damage( meansofdeath ) )
      return int( final_damage );
    else if ( !is_headshot( weapon, shitloc, meansofdeath ) )
      return 0;
  }

  return int(final_damage);
}

is_deadshot_sniper( weapon )
{
  switch ( weapon )
  {
    case "dsr50_zm":
    case "dsr50_upgraded_zm":
    case "barretm82_zm":
    case "barretm82_upgraded_zm":
    case "ballista_zm":
    case "ballista_upgraded_zm":
    case "svu_zm":
    case "svu_upgraded_zm":
      return true;
  }

  return false;
}

mule_kick_weapon_hud() {
  self endon("disconnect");
  level endon("game_ended");
  level endon("end_game");

  hud = self create_mule_kick_hud();

  self.mule_third_weapon = undefined;

  for (;;) {
    owned = self hasperk("specialty_additionalprimaryweapon");
    primaries = self getweaponslistprimaries();

    if (!owned || primaries.size < 3) {
      hud.alpha = 0;
      self.mule_third_weapon = undefined;

      wait 0.15;
      continue;
    }

    if (!self is_active_player()) {
      hud.alpha = 0;

      wait 0.15;
      continue;
    }

    if (!isdefined(self.mule_third_weapon) || !self hasweapon(self.mule_third_weapon))
      self.mule_third_weapon = primaries[2];

    hud.alpha = 0;

    if (self getcurrentweapon() == self.mule_third_weapon)
      hud.alpha = 0.95;

    wait 0.15;
  }
}

create_mule_kick_hud() {
  hud_x = -96;
  hud_y = 12;

  if (isdefined(level.mule_icon_x))
    hud_x = level.mule_icon_x;

  if (isdefined(level.mule_icon_y))
    hud_y = level.mule_icon_y;

  hud = self createicon("specialty_additionalprimaryweapon_zombies", 24, 24);
  hud setpoint("BOTTOM_RIGHT", "BOTTOM_RIGHT", hud_x, hud_y);

  hud.foreground = 1;
  hud.sort = 30;
  hud.alpha = 0;
  hud.archived = 0;
  hud.hidewheninmenu = 1;

  return hud;
}

is_active_player() {
  if (!isdefined(self) || !isplayer(self) || self.health <= 0)
    return false;

  if (self.sessionstate == "dead" || self.sessionstate == "spectator")
    return false;

  if (isdefined(self.is_zombie) && self.is_zombie)
    return false;

  return !self maps\mp\zombies\_zm_laststand::player_is_in_laststand();
}


phd_grenade_watch() {
  self endon("disconnect");
  level endon("game_ended");

  self.phd_pullback = false;
  self thread phd_grenade_pullback_watch();

  for (;;) {
    self waittill("grenade_fire", grenade, weapon_name);

    valid_throw = self.phd_pullback;
    self.phd_pullback = false;

    if (!isdefined(grenade) || !valid_throw)
      continue;

    if (!self hasperk("specialty_flakjacket"))
      continue;

    if (weapon_name != "frag_grenade_zm" && weapon_name != "sticky_grenade_zm")
      continue;

    if (isdefined(grenade.phd_processed))
      continue;

    grenade.phd_processed = true;
    grenade thread phd_multiply_grenades(weapon_name);
  }
}

phd_grenade_pullback_watch() {
  self endon("disconnect");
  level endon("game_ended");

  for (;;) {
    self waittill("grenade_pullback", weapon_name);

    self.phd_pullback = weapon_name == "frag_grenade_zm" || weapon_name == "sticky_grenade_zm";
  }
}

phd_multiply_grenades(weapon_name) {
  self endon("death");

  wait 1;

  if (!isdefined(self))
    return;

  origin = self.origin;

  for (i = 0; i < 5; i++) {
    spawn_offset = (randomfloatrange(-24, 24), randomfloatrange(-24, 24), randomfloatrange(4, 24));
    velocity = (randomfloatrange(-220, 220), randomfloatrange(-220, 220), randomfloatrange(220, 420));
    fuse_time = randomfloatrange(2.0, 3.5);

    grenade = self magicgrenadetype(weapon_name, origin + spawn_offset, velocity, fuse_time);

    if (isdefined(grenade))
      grenade.phd_processed = true;
  }
}
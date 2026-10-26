#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_weapon_locker;
#include maps\mp\zm_buried;
#include maps\mp\_visionset_mgr;

#include scripts\zm\_utils;

is_buried() {
  return getdvar("mapname") == "zm_buried";
}

main() {
  if (!is_buried())
    return;

  safe_replacefunc("maps/mp/zombies/_zm_perk_vulture", "give_vulture_perk", ::give_vulture_perk_override);
  safe_replacefunc("maps/mp/zombies/_zm_perk_vulture", "take_vulture_perk", ::take_vulture_perk_override);
  safe_replacefunc("maps/mp/zombies/_zm_perk_vulture", "_vulture_perk_think", ::vulture_perk_think_override);
}

give_vulture_perk_override() {
  if (!isdefined(self.perk_vulture))
    self.perk_vulture = spawnstruct();

  self.perk_vulture.active = 1;

  self maps\mp\zombies\_zm_perk_vulture::vulture_vision_toggle(1);
  self maps\mp\zombies\_zm_perk_vulture::vulture_clientfield_toplayer_set(
    "vulture_perk_active"
  );

  self thread vulture_perk_think_override();
  self thread vulture_perk_ir_think();

  use_waypoints = get_dvar_default("use_perk_waypoints", 0, "int");

  if (use_waypoints)
    self thread vulture_perk_machine_waypoint();
}

vulture_perk_machine_waypoint() {
  self endon("disconnect");

  if (
    !isdefined(self.perk_vulture) ||
    !isdefined(self.perk_vulture.active) ||
    !self.perk_vulture.active
  ) {
    return;
  }

  self clear_vulture_perk_waypoints();
  self.vulture_perk_waypoints = [];

  machines = getentarray("zombie_vending", "targetname");

  foreach (machine in machines) {
    if (!isdefined(machine.script_noteworthy))
      continue;

    shader = self get_vulture_perk_waypoint_shader(machine.script_noteworthy);

    if (shader == "")
      continue;

    waypoint = spawnstruct();
    waypoint.machine = machine;
    waypoint.visible = 0;
    waypoint.hud = newclienthudelem(self);

    waypoint.hud setshader(shader, 14, 14);
    waypoint.hud setwaypoint(false, shader);
    waypoint.hud.x = machine.origin[0];
    waypoint.hud.y = machine.origin[1];
    waypoint.hud.z = machine.origin[2] + 80;
    waypoint.hud.alpha = 0;
    waypoint.hud.foreground = 1;
    waypoint.hud.sort = 10;
    waypoint.hud.hidewheninmenu = 1;
    waypoint.hud.archived = 0;

    self.vulture_perk_waypoints[
      self.vulture_perk_waypoints.size
    ] = waypoint;
  }

  for (;;) {
    if (
      !isdefined(self.perk_vulture) ||
      !isdefined(self.perk_vulture.active) ||
      !self.perk_vulture.active
    ) {
      self clear_vulture_perk_waypoints();
      return;
    }

    foreach (waypoint in self.vulture_perk_waypoints) {
      if (
        !isdefined(waypoint.machine) ||
        !isdefined(waypoint.hud)
      ) {
        continue;
      }

      distance_to_machine = distance(
        self.origin,
        waypoint.machine.origin
      );

      should_show = distance_to_machine >= 100 &&
        distance_to_machine <= 2000;

      waypoint.hud.x = waypoint.machine.origin[0];
      waypoint.hud.y = waypoint.machine.origin[1];
      waypoint.hud.z = waypoint.machine.origin[2] + 80;

      if (should_show && !waypoint.visible) {
        waypoint.visible = 1;
        waypoint.hud fadeovertime(0.15);
        waypoint.hud.alpha = 0.85;
      } else if (!should_show && waypoint.visible) {
        waypoint.visible = 0;
        waypoint.hud fadeovertime(0.15);
        waypoint.hud.alpha = 0;
      }
    }

    wait 0.25;
  }
}

clear_vulture_perk_waypoints() {
  if (!isdefined(self.vulture_perk_waypoints))
    return;

  foreach (waypoint in self.vulture_perk_waypoints) {
    if (isdefined(waypoint) && isdefined(waypoint.hud))
      waypoint.hud destroy();
  }

  self.vulture_perk_waypoints = [];
}

get_vulture_perk_waypoint_shader(perk) {
  switch (perk) {
    case "specialty_armorvest":
      return "specialty_juggernaut_zombies";

    case "specialty_quickrevive":
      return "specialty_quickrevive_zombies";

    case "specialty_fastreload":
      return "specialty_fastreload_zombies";

    case "specialty_rof":
      return "specialty_doubletap_zombies";

    case "specialty_longersprint":
      return "specialty_marathon_zombies";

    case "specialty_additionalprimaryweapon":
      return "specialty_additionalprimaryweapon_zombies";

    case "specialty_deadshot":
      return "specialty_ads_zombies";

    case "specialty_finalstand":
      return "specialty_chugabud_zombies";

    case "specialty_flakjacket":
      return "specialty_divetonuke_zombies";

    case "specialty_grenadepulldeath":
      return "specialty_electric_cherry_zombie";

    case "specialty_nomotionsensor":
      return "specialty_vulture_zombies";

    case "specialty_scavenger":
      return "specialty_tombstone_zombies";

    case "specialty_weapupgrade":
      return "";
  }

  if (getsubstr(perk, 0, 10) == "specialty_")
    return perk + "_zombies";

  return "specialty_" + perk + "_zombies";
}

take_vulture_perk_override() {
  if (
    isdefined(self.perk_vulture) &&
    isdefined(self.perk_vulture.active) &&
    self.perk_vulture.active
  ) {
    self.perk_vulture.active = 0;
    self clear_vulture_perk_waypoints();

    if (!self maps\mp\zombies\_zm_laststand::player_is_in_laststand())
      self.ignoreme = 0;

    self maps\mp\zombies\_zm_perk_vulture::vulture_vision_toggle(0);
    self maps\mp\zombies\_zm_perk_vulture::vulture_clientfield_toplayer_clear(
      "vulture_perk_active"
    );
    self maps\mp\zombies\_zm_perk_vulture::set_vulture_overlay(0);

    self.vulture_stink_value = 0;
    self setclientfieldtoplayer("vulture_perk_disease_meter", 0);
    self notify("vulture_perk_lost");
  }
}

vulture_perk_ir_think() {
  self endon("disconnect");
  self endon("vulture_perk_lost");

  prev_val = 1;

  for (;;) {
    val = self vulture_perk_ir_is_valid();

    if (prev_val != val) {
      prev_val = val;

      wait 0.05;

      if (val)
        self clientnotify("vulture_perk_ir_enable");
      else
        self clientnotify("vulture_perk_ir_disable");

      continue;
    }

    wait 0.05;
  }
}

vulture_perk_ir_is_valid() {
  if (isdefined(self.vulture_stink_value) && self.vulture_stink_value > 0)
    return 0;

  return 1;
}

vulture_perk_think_override() {
  self endon("death");
  self endon("disconnect");
  self endon("vulture_perk_lost");

  prev_speed = 0;
  next_time = gettime();

  for (;;) {
    in_stink = 0;

    speed = self getvelocity();
    speed = length(speed);

    slowing_down = (speed - prev_speed) <= -10;

    prev_speed = speed;
    time = gettime();

    if (time < next_time) {
      wait 0.05;
      continue;
    }

    if (speed != 0 && !slowing_down) {
      wait 0.05;
      continue;
    }

    next_time = time + randomintrange(250, 500);

    if (!isdefined(level.perk_vulture.zombie_stink_array))
      level.perk_vulture.zombie_stink_array = [];

    if (level.perk_vulture.zombie_stink_array.size > 0) {
      close_points = arraysort(
        level.perk_vulture.zombie_stink_array,
        self.origin,
        1,
        300
      );

      if (close_points.size > 0) {
        in_stink =
          self maps\mp\zombies\_zm_perk_vulture::_is_player_in_zombie_stink(
            close_points
          );
      }
    }

    self maps\mp\zombies\_zm_perk_vulture::_handle_zombie_stink(
      in_stink
    );

    wait 0.05;
  }
}
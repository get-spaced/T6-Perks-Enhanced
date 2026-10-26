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

safe_replacefunc(path, name, replacement) {
  func = getfunction(path, name);

  if (!isdefined(func))
    return false;

  if (!isdefined(level.old_funcs))
    level.old_funcs = [];

  level.old_funcs[name] = func;
  replacefunc(func, replacement);

  return true;
}

set_dvar_default(name, value) {
  if (getdvar(name) != "")
    return;

  setdvar(name, value);
}

get_dvar_default(dvar, def, type) {
  if (!isdefined(dvar) || dvar == "" || getdvar(dvar) == "")
    return def;
  if (!isdefined(type))
    type = "string";

  switch (tolower(type)) {
    case "int":
      return getdvarint(dvar);

    case "float":
      return getdvarfloat(dvar);

    case "bool":
      return getdvarint(dvar) != 0;

    case "string":
    default:
      return getdvar(dvar);
  }
}

is_bank_map() {
  return getdvar("mapname") == "zm_transit" || map == "zm_highrise" || map == "zm_buried";
}
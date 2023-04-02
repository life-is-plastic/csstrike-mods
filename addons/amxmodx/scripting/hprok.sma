// Health (and armor) restore on kill.
//
// Restoration follows the formula `y = m*x + b` where:
//  y is the final health
//  x is the initial health
//  m is some slope
//  b is some intercept
//
// The default (slope, intercept) values of (0.625, 50) ensures that a lower
// initial health results in more health being restored than a higher initial
// health. To make kills restore the same amount of health regardless of initial
// health, set slope to 1 and intercept to the desired amount-restored-per-kill.
// To make kills always restore players to full health, set slope to a
// non-negative number and intercept to 100.
#include <amxmodx>
#include <amxconst> // for print_console
#include <core> // for min
#include <cstrike> // for cs_*
#include <float> // for floatround
#include <fun> // for set_user_health

const MAX_HP = 100
const MAX_AP = 100

new cvar_enable
new cvar_debuglog
new cvar_slope
new cvar_intercept

public plugin_init() {
    register_plugin("HP Restore on Kill (HPRoK)", "1.0", "life-is-plastic")
    cvar_enable = register_cvar("hprok_enable", "1")
    cvar_debuglog = register_cvar("hprok_debuglog", "0")
    cvar_slope = register_cvar("hprok_slope", "0.625")
    cvar_intercept = register_cvar("hprok_intercept", "50")
    if (get_pcvar_num(cvar_enable) <= 0) {
        return
    }

    register_event("DeathMsg", "hook", "a", "1!0")
}

public hook() {
    new killer = read_data(1)
    new victim = read_data(2)
    if (killer == victim) {
        return PLUGIN_CONTINUE
    }

    new Float:slope = get_pcvar_float(cvar_slope)
    new Float:intercept = get_pcvar_float(cvar_intercept)

    new old_hp = get_user_health(killer)
    new new_hp = min(MAX_HP, floatround(old_hp * slope + intercept, floatround_floor))
    set_user_health(killer, new_hp)

    new CsArmorType:at
    new old_ap = cs_get_user_armor(killer, at)
    new new_ap = min(MAX_AP, floatround(old_ap * slope + intercept, floatround_floor))
    cs_set_user_armor(killer, new_ap, at)

    if (get_pcvar_num(cvar_debuglog) > 0 && (old_hp != new_hp || old_ap != new_ap)) {
        log(killer, old_hp, new_hp, old_ap, new_ap)
    }
    return PLUGIN_CONTINUE
}

log(index, old_hp, new_hp, old_ap, new_ap) {
    const max_name_len = 32
    new client_name[max_name_len]
    get_user_name(index, client_name, max_name_len)
    client_print(0, print_console, "[HPRoK] %s restored health(%d -> %d) and armor(%d -> %d)", client_name, old_hp, new_hp, old_ap, new_ap)
}

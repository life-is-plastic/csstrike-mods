// Health (and armor) regeneration.
#include <amxmodx>
#include <amxconst> // for print_console
#include <core> // for min
#include <cstrike> // for cs_*
#include <engine>
#include <fun> // for set_user_health

const MAX_NAME_LEN = 32
const MAX_PLAYER_COUNT = 32
const MAX_HP = 100
const MAX_AP = 100

new Float:g_last_damaged[MAX_PLAYER_COUNT + 1] // player indices start at 1

new cvar_enable
new cvar_debuglog
new cvar_delay // how much time must pass after taking damage before regen begins
new cvar_interval // time between regen ticks
new cvar_amount // health restored per regen tick

public plugin_end() {
    for (new i = 0; i < sizeof g_last_damaged; i++) {
        g_last_damaged[i] = 0.0
    }
}

public plugin_init() {
    register_plugin("HP Regen", "1.0", "life-is-plastic")
    cvar_enable = register_cvar("hpregen_enable", "1")
    cvar_debuglog = register_cvar("hpregen_debuglog", "0")
    cvar_delay = register_cvar("hpregen_delay", "4.0")
    cvar_interval = register_cvar("hpregen_interval", "0.1")
    cvar_amount = register_cvar("hpregen_amount", "3")
    if (get_pcvar_num(cvar_enable) <= 0) {
        return
    }

    register_event("Damage", "damage_hook", "b", "2>0")

    new const clsname[] = "hpregen_ent"
    new regen_ent = create_entity("info_target")
    entity_set_string(regen_ent, EV_SZ_classname, clsname)
    register_think(clsname, "regen_think")
    regen_think(regen_ent)
}

public damage_hook(index) {
    new Float:now = get_gametime()
    g_last_damaged[index] = now
    if (get_pcvar_num(cvar_debuglog) > 0) {
        log_damage(index, now)
    }
}

log_damage(index, Float:time) {
    new client_name[MAX_NAME_LEN]
    get_user_name(index, client_name, MAX_NAME_LEN)
    client_print(0, print_console, "[HP Regen] %s took damage at %f", client_name, time)
}

public regen_think(id) {
    new Float:now = get_gametime()
    new Float:interval = get_pcvar_float(cvar_interval)
    entity_set_float(id, EV_FL_nextthink, now + interval)

    static players[MAX_PLAYER_COUNT]
    new len
    get_players(players, len, "a")

    new Float:delay = get_pcvar_float(cvar_delay)
    new regen_amount = get_pcvar_num(cvar_amount)
    new bool:debuglog = get_pcvar_num(cvar_debuglog) > 0
    for (new i = 0; i < len; i++) {
        new p = players[i]
        if (now - g_last_damaged[p] > delay) {
            restore_player(p, regen_amount, debuglog)
        }
    }
}

// Executes a single "regen tick" on a specific player.
restore_player(index, regen_amount, bool:debuglog) {
    new old_hp = get_user_health(index)
    new new_hp = min(MAX_HP, old_hp + regen_amount)
    set_user_health(index, new_hp)

    new CsArmorType:at
    new old_ap = cs_get_user_armor(index, at)
    new new_ap = min(MAX_AP, old_ap + regen_amount)
    cs_set_user_armor(index, new_ap, at)

    if (debuglog && (old_hp != new_hp || old_ap != new_ap)) {
        log_restore(index, old_hp, new_hp, old_ap, new_ap)
    }
}

log_restore(index, old_hp, new_hp, old_ap, new_ap) {
    new client_name[MAX_NAME_LEN]
    get_user_name(index, client_name, MAX_NAME_LEN)
    client_print(0, print_console, "[HP Regen] %s restored health(%d -> %d) and armor(%d -> %d)", client_name, old_hp, new_hp, old_ap, new_ap)
}

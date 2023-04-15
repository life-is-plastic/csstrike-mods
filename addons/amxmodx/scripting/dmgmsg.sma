// Display amount of damage dealt.
#include <amxmodx>

const MAX_PLAYER_COUNT = 32

new g_hudsync
new g_last_victim[MAX_PLAYER_COUNT + 1]
new g_last_victim_total_dmg[MAX_PLAYER_COUNT + 1]
new Float:g_last_victim_hit_ts[MAX_PLAYER_COUNT + 1]

new cvar_enable
new cvar_fadetime

public plugin_init() {
    register_plugin("Damage Message", "1.0", "life-is-plastic")
    cvar_enable = register_cvar("dmgmsg_enable", "1")
    cvar_fadetime = register_cvar("dmgmsg_fadetime", "2.0")
    if (get_pcvar_num(cvar_enable) <= 0) {
        return
    }

    g_hudsync = CreateHudSyncObj()
    register_event("Damage", "hook", "b", "2>0")
}

public hook(victim) {
    new attacker = get_user_attacker(victim)
    if (attacker < 1 || attacker > MAX_PLAYER_COUNT) {
        return
    }
    new Float:now = get_gametime()
    new Float:fadetime = get_pcvar_float(cvar_fadetime)
    new damage = read_data(2)
    if (g_last_victim[attacker] == victim && now - g_last_victim_hit_ts[attacker] < fadetime) {
        damage += g_last_victim_total_dmg[attacker]
    }
    set_hudmessage(150, 70, 0, -1.0, 0.55, 0, 6.0, fadetime)
    ShowSyncHudMsg(attacker, g_hudsync, "%d", damage)

    g_last_victim[attacker] = victim
    g_last_victim_hit_ts[attacker] = now
    if (is_user_alive(victim) == 1) {
        g_last_victim_total_dmg[attacker] = damage
    } else {
        g_last_victim_total_dmg[attacker] = 0
    }
}

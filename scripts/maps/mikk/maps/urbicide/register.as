// #include '../../ammo_custom'

#include '../../config_classic_mode'
#include '../../config_map_cvars'

// #include '../../env_bloodpuddle'
// #include '../../env_effects'
// #include '../../env_fade_custom'

#include '../../game_debug'
#include '../../game_text_custom'
// #include '../../game_zone_entity'

#include '../../info_commentary'

#include '../../pev_effects'

#include '../../player_command'
#include '../../player_data'

#include '../../trigger_autosave'
#include '../../trigger_manager'
#include '../../trigger_multiple_custom'

// #include '../../../ins2/handg/weapon_ins2usp'

void Register()
{
}
/*
namespace ULIFE
{
    void BossHealth( CBaseEntity@ pboss, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
    {
        if( pboss !is null && pboss.IsMonster() )
        {
            float maxhealth = ( pboss.pev.health / 3 * g_PlayerFuncs.GetNumPlayers() + pboss.pev.health );
            pboss.pev.health = maxhealth;
            pboss.pev.max_health = maxhealth;
            g_Util.Debug( 'Update Boss health to "'+string( maxhealth )+'"' );
        }
    }

    void BossThink( CBaseEntity@ self )
    {
        CBaseMonster@ Boss = cast<CBaseMonster@>( g_EntityFuncs.FindEntityByTargetname( Boss, self.pev.target ) );

        if( Boss is null || !Boss.IsAlive() )
        {
            return;
        }

        if( Boss.GetTargetname() == 'boss_0' )
        {
        }
        else if( Boss.GetTargetname() == 'boss_1' )
        {
        }
        else if( Boss.GetTargetname() == 'boss_2' )
        {
        }
    }
}*/
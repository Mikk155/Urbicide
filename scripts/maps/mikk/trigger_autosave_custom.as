// https://github.com/Outerbeast/Entities-and-Gamemodes/blob/master/respawndead_keepweapons.as
#include "../beast/respawndead_keepweapons"

#include 'utils/CUtils'
#include 'utils/CGetInformation'
#include 'utils/Reflection'
#include "utils/ScriptBaseCustomEntity"

namespace trigger_autosave_custom
{
    CScheduledFunction@ fnRemoveHook = g_Scheduler.SetTimeout( "vRemoveHook", 1.0f );

    void vRemoveHook()
    {
        g_Hooks.RemoveHook( Hooks::Player::PlayerKilled, RESPAWNDEAD_KEEPWEAPONS::PlayerKilled );
    }

    void Register()
    {
        g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @trigger_autosave_custom::playerconnect );
        g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @trigger_autosave_custom::playerdie );
        g_CustomEntityFuncs.RegisterCustomEntity( "trigger_autosave_custom::trigger_autosave_custom", "trigger_autosave_custom" );

        g_ScriptInfo.SetInformation
        ( 
            g_ScriptInfo.ScriptName( 'trigger_autosave_custom' ) +
            g_ScriptInfo.Description( 'Attempt to create the mechanic of trigger_autosave with co-op in mind.' ) +
            g_ScriptInfo.Wiki( 'trigger_autosave_custom' ) +
            g_ScriptInfo.Author( 'Mikk' ) +
            g_ScriptInfo.GetDiscord() +
            g_ScriptInfo.GetGithub()
        );
    }

    dictionary g_PlayersID;

    string GetSteamID( CBasePlayer@ pPlayer )
    {
        return string( g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() ) );
    }

    HookReturnCode playerconnect( CBasePlayer@ pPlayer )
    {
        if( pPlayer !is null )
        {
            if( g_PlayersID.exists( GetSteamID( pPlayer ) ) )
            {
                return HOOK_CONTINUE;
            }

            g_PlayersID[ GetSteamID( pPlayer ) ] = '1';
        }
        return HOOK_CONTINUE;
    }

    void SetSaves( CBasePlayer@ pPlayer, int&in iMode = 0 )
    {
        int iValue = atoi( string( g_PlayersID[ GetSteamID( pPlayer ) ] ) );

        if( iMode == 1 )
        {
            iValue = iValue + 1;
        }
        else if( iMode == -1 && g_SurvivalMode.IsEnabled() && g_SurvivalMode.IsActive() )
        {
            iValue = iValue - 1;
        }
        g_PlayersID[ GetSteamID( pPlayer ) ] = string( iValue );
    }

    HookReturnCode playerdie( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
    {
        if( pPlayer !is null )
        {
            int iValue = atoi( string( g_PlayersID[ GetSteamID( pPlayer ) ] ) );

            if( iValue > 0 )
            {
                g_Scheduler.SetTimeout( "LoadStatus", 1.0f, @pPlayer );
            }
        }
        return HOOK_CONTINUE;
    }

    class trigger_autosave_custom : ScriptBaseEntity, ScriptBaseCustomEntity
    {
        void Touch( CBaseEntity@ pOther )
        {
            Save( pOther );
        }

        void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float fldelay )
        {
            Save( pActivator );
        }

        private array<string> m_iszSteamIDs;

        bool KeyValue( const string& in szKey, const string& in szValue )
        {
            ExtraKeyValues( szKey, szValue );
            return BaseClass.KeyValue( szKey, szValue );
        }

        bool HasBeenSaved( CBasePlayer@ pPlayer )
        {
            for( uint i = 0; i < m_iszSteamIDs.length(); i++ )
            {
                if( m_iszSteamIDs[i] == GetSteamID( pPlayer ) )
                {
                    return true;
                }
            }
            return false;
        }

        void Save( CBaseEntity@ pTarget )
        {
            CBasePlayer@ pPlayer = cast<CBasePlayer@>( pTarget );

            if( pPlayer !is null && !HasBeenSaved( pPlayer ) )
            {
                m_iszSteamIDs.insertLast( GetSteamID( pPlayer ) );
                SaveStatus( pPlayer );
                g_Util.Trigger( string( self.pev.target ), pPlayer, self, USE_TOGGLE, 0.0f );
            }
        }

        void Spawn()
        {
            self.pev.solid = SOLID_TRIGGER;
            g_Util.NoDraw( self );
            self.pev.movetype = MOVETYPE_NONE;

            SetBoundaries();

            BaseClass.Spawn();
        }
    }

    void SaveStatus( CBasePlayer@ pPlayer )
    {
        SetSaves( pPlayer, 1 );

        g_Util.SetCKV( pPlayer, '$s_tas_origin', pPlayer.pev.origin.ToString() );
        g_Util.SetCKV( pPlayer, '$s_tas_angles', pPlayer.pev.angles.ToString() );
        g_Util.SetCKV( pPlayer, '$s_tas_health', string( pPlayer.pev.health ) );
        g_Util.SetCKV( pPlayer, '$s_tas_armorvalue', string( pPlayer.pev.armorvalue ) );
        RESPAWNDEAD_KEEPWEAPONS::DICT_PLAYER_LOADOUT[pPlayer.entindex()] = RESPAWNDEAD_KEEPWEAPONS::GetPlayerLoadout( pPlayer );
    }

    void LoadStatus( CBasePlayer@ pPlayer )
    {
        int iValue = atoi( string( g_PlayersID[ GetSteamID( pPlayer ) ] ) );

        if( iValue > 1 )
        {
            g_PlayerFuncs.RespawnPlayer( pPlayer, false, true );
            SetSaves( pPlayer, -1 );
            pPlayer.pev.origin = g_Util.StringToVec( g_Util.GetCKV( pPlayer, '$s_tas_origin' ) );
            pPlayer.pev.angles = g_Util.StringToVec( g_Util.GetCKV( pPlayer, '$s_tas_angles' ) );
            pPlayer.pev.health = atof( g_Util.GetCKV( pPlayer, '$s_tas_health' ) );
            pPlayer.pev.armorvalue = atof( g_Util.GetCKV( pPlayer, '$s_tas_armorvalue' ) );
            RESPAWNDEAD_KEEPWEAPONS::ReEquipCollected( @pPlayer, true );
            RESPAWNDEAD_KEEPWEAPONS::DICT_PLAYER_LOADOUT[pPlayer.entindex()] = RESPAWNDEAD_KEEPWEAPONS::GetPlayerLoadout( pPlayer );
        }
    }
}

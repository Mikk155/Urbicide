/*
DOWNLOAD:

scripts/maps/mikk/game_level_end.as
scripts/maps/mikk/utils.as


INSTALL:

#include "mikk/game_level_end"

void MapInit()
{
    game_level_end::Register();
}
*/

#include "utils"

namespace game_level_end
{
    enum game_level_end_flags
    {
        SF_GLE_AUTOMATIC = 1 << 0,
        SF_GLE_KEEPVECTS = 1 << 1,
        SF_GLE_DONTFADES = 1 << 2
    }

    bool blReloadLevel = false;

    EHandle EHSelf = null;

    dictionary g_ChangeLevel;

    class game_level_end : ScriptBaseEntity, UTILS::MoreKeyValues
    {
        private float messagetime = 1.0f, duration = 2.0f, holdtime = 0.0f, loadtime = 5.0f;
        private int keep_inventory = 1;
        private string map = "";

        bool KeyValue( const string& in szKey, const string& in szValue ) 
        {
            ExtraKeyValues(szKey, szValue);
            if( szKey == "map" ) map = szValue;
            else if( szKey == "keep_inventory" ) keep_inventory = atoi( szValue );
            else if( szKey == "messagetime" ) messagetime = atof( szValue );
            else if( szKey == "loadtime" ) loadtime = atof( szValue );
            else if( szKey == "holdtime" ) holdtime = atof( szValue );
            else if( szKey == "duration" ) duration = atof( szValue );
            else return BaseClass.KeyValue( szKey, szValue );
            return true;
        }

        void Spawn()
        {
            if( self.pev.SpawnFlagBitSet( SF_GLE_AUTOMATIC ) )
            {
                SetThink( ThinkFunction( this.TriggerThink ) );
                self.pev.nextthink = g_Engine.time + 1.5f;
            }
            BaseClass.Spawn();
        }

        void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
        {
            if( multisource() )
            {
                return;
            }

            for( int iPlayer = 1; iPlayer <= g_PlayerFuncs.GetNumPlayers(); ++iPlayer )
            {
                CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

                if( pPlayer is null )
                {
                    continue;
                }

                if( !self.pev.SpawnFlagBitSet( SF_GLE_DONTFADES ) )
                {
                    g_PlayerFuncs.ScreenFade( pPlayer, self.pev.rendercolor, duration, holdtime, int( self.pev.renderamt ), int( self.pev.health ) );
                }

                UTILS::Trigger( self.pev.message, pPlayer, self, useType, messagetime );
            }

            if( map == string( g_Engine.mapname ) )
            {
                g_ChangeLevel [ "holdtime" ] = "0";
                g_ChangeLevel [ "duration" ] = "0";
                g_ChangeLevel [ "loadtime" ] = "0";
                blReloadLevel = true;
                /*
                
                "void CSurvivalMode::EndRound()": {
                    "prefix": "EndRound",
                    "body" : [ "EndRound()" ],
                    "description" : "Can be used to end a round and force a retry to be used."
                */
            }
            else
            {
                g_ChangeLevel [ "spawnflags" ] = "3";
                g_ChangeLevel [ "map" ] = ( g_EngineFuncs.IsMapValid( map ) ) ? map : string( g_MapCycle.GetNextMap() );
                g_ChangeLevel [ "keep_inventory" ] = string( keep_inventory );
                blReloadLevel = false;
            }
            g_ChangeLevel [ "targetname" ] = string( self.pev.classname ) + self.entindex();

            if( EHSelf.GetEntity() is null )
            {
                EHSelf = self;
            }

            g_Scheduler.SetTimeout( "LoadDelayTime", loadtime );

            if( int( delay ) > 0 )
            {
                g_Scheduler.SetTimeout( "SVC_INTERMISSION", delay );
            }
        }

        void TriggerThink()
        {
            if( multisource() || g_PlayerFuncs.GetNumPlayers() == 0 )
            {
                self.pev.nextthink = g_Engine.time + 1.5f;
                return;
            }

            int Alive = 0, Dead = 0;

            for( int iPlayer = 1; iPlayer <= g_PlayerFuncs.GetNumPlayers(); ++iPlayer )
            {
                CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

                if( pPlayer is null )
                {
                    continue;
                }

                if( pPlayer.IsAlive() )
                    Alive += 1;

                if( !pPlayer.IsAlive() )
                    Dead += 1;
            }
            
            if( Alive == 0 && Dead > 0 )
            {
                self.Use( self, self, USE_TOGGLE, 0.0f );
                SetThink( null );
            }

            self.pev.nextthink = g_Engine.time + 1.5f;
        }
    }

    void LoadDelayTime()
    {
        CBaseEntity@ pChangeLevel = g_EntityFuncs.CreateEntity( ( blReloadLevel ) ? "player_loadsaved" : "trigger_changelevel", g_ChangeLevel, true );

        pChangeLevel.Use( EHSelf.GetEntity(), EHSelf.GetEntity(), USE_TOGGLE, 1.0f );
    }

    void SVC_INTERMISSION()
    {
        NetworkMessage message( MSG_ALL, NetworkMessages::SVC_INTERMISSION );
        message.End();
    }

    void Register()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "game_level_end::game_level_end", "game_level_end" );
    }
}// end namespace
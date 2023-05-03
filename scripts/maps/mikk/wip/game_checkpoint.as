/*
	Rework of the point_checkpoint. please don't just replace this. Check the entity or the FGD first.

INSTALL:

#include "mikk/entities/game_checkpoint"

void MapInit()
{
	RegisterTriggerCheckpoint( "game_checkpoint", true);
}

*/

#include "../../respawndead_keepweapons"
#include "utils"

void RegisterTriggerCheckpoint
(
	const string ClassName = "game_checkpoint",
	const bool KeepSpawns = true,
	const bool ShowMessages = true
){
    g_CustomEntityFuncs.RegisterCustomEntity( "game_checkpoint", ClassName );

	g_Scheduler.SetInterval( "GlobalThink", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES);

    g_Game.PrecacheOther( ClassName );
    
    if( KeepSpawns )
    {
        g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @ClientDisconnect );
        g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );
    }

	if( ShowMessages )
	{
		UTILS::LoadRipentFile( "scripts/maps/mikk/game_checkpoint.ent" );
	}
}

HookReturnCode ClientDisconnect( CBasePlayer@ pPlayer )
{
	if(pPlayer is null)
		return HOOK_CONTINUE;

    string SteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

    PlayerKeepSpawnsData pData;
	pData.spawn = UTILS::GetCKV( pPlayer, "$i_checkpoints" );
	g_PlayerKeepSpawns[SteamID] = pData;   

    return HOOK_CONTINUE;
}

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
{
	if(pPlayer is null)
		return HOOK_CONTINUE;

	string SteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

	if( g_PlayerKeepSpawns.exists(SteamID) )
	{
        PlayerLoadSpawns( g_EngineFuncs.IndexOfEdict(pPlayer.edict()), SteamID );
	}
    else
    {
		PlayerKeepSpawnsData pData;
		pData.spawn = UTILS::GetCKV( pPlayer, "$i_checkpoints" );
		g_PlayerKeepSpawns[SteamID] = pData;
    }
	return HOOK_CONTINUE;
}

void PlayerLoadSpawns( int &in iIndex, string &in SteamID )
{
	CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(iIndex);

	if( pPlayer is null )
		return;

	PlayerKeepSpawnsData@ pData = cast<PlayerKeepSpawnsData@>(g_PlayerKeepSpawns[SteamID]);

	pPlayer.GetCustomKeyvalues().SetKeyvalue("$i_checkpoints", int(pData.spawn) );
}

dictionary g_PlayerKeepSpawns;

class PlayerKeepSpawnsData
{
	int spawn;
}

void GlobalThink()
{
	for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

		if( pPlayer is null or pPlayer.IsAlive() or !pPlayer.GetObserver().IsObserver() )
			continue;

	}
}

enum trigger_checkpoint_flags
{
    SF_TCP_KEEP_VECT = 1 << 0,
    SF_TCP_INSTA_RES = 1 << 1,
    SF_TCP_KEEP_AMMO = 1 << 2,
    SF_TCP_COUNT_ONE = 1 << 3,
    SF_TCP_EUSE_ONLY = 1 << 4
}

class trigger_checkpoint : ScriptBaseEntity
{
    private int SpawnWithButton = 32;
    bool KeyValue( const string& in szKey, const string& in szValue ) 
    {
        if( szKey == "music" )
        {
            music = szValue;
            return true;
        }
        else if( szKey == "spawnkey" )
        {
            SpawnWithButton = atoi( szValue );
            return true;
        }
        else
        {
            return BaseClass.KeyValue( szKey, szValue );
        }
    }

    void Precache()
    {
        if( string( self.pev.model ).IsEmpty() )
            g_Game.PrecacheModel( "models/common/lambda.mdl" );
        else
            g_Game.PrecacheModel( self.pev.model );

        g_SoundSystem.PrecacheSound( music );

        BaseClass.Precache();
	}

    void Spawn()
    {
        self.pev.solid = SOLID_NOT;
        self.pev.effects |= EF_NODRAW;
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.rendermode = kRenderTransAlpha;
        self.pev.framerate = 1.0f;

        UTILS::SetSize( self, false );
        if( string( self.pev.model ).StartsWith ( "*" ) && self.IsBSPModel() )
        {
            g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
        }
        else
        {
            g_EntityFuncs.SetModel( self, "models/common/lambda.mdl" );

            if( self.pev.vuser1 != g_vecZero && self.pev.vuser2 != g_vecZero )
            {
                g_EntityFuncs.SetSize( self.pev, self.pev.vuser1, self.pev.vuser2 );
            }
            else
            {
                g_EntityFuncs.SetSize( self.pev, Vector( -64, -64, -36 ), Vector( 64, 64, 36 ) );
            }
        }
        g_EntityFuncs.SetModel( self, self.pev.model );

        SetThink( ThinkFunction( this.TriggerThink ) );
        self.pev.nextthink = g_Engine.time + 0.1f;

        BaseClass.Spawn();
    }

    void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
    {
    }

    void TriggerThink()
    {
        for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

            if( pPlayer is null )
                continue;

            if( !g_SurvivalMode.IsActive() )
            {
                self.pev.renderamt = 0;
                self.pev.nextthink = g_Engine.time + 0.1f;
                return;
            }
            else if( self.pev.renderamt < 255 )
            {
                self.pev.renderamt = 255;
            }

            if( UTILS::InsideZone( pPlayer, self ) )
            {
                Activation( pPlayer );
                UTILS::TriggerMode( "GAME_CHECKPOINT_ACTIVATED", pPlayer, 0.0f );
            }
        }

        for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
        {
            CBasePlayer@ pDeadPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

            if( pDeadPlayer is null || !pDeadPlayer.IsConnected() || pDeadPlayer.IsAlive() )
                continue;

            if( pDeadPlayer.GetObserver().IsObserver() )
            {
                Messager( pDeadPlayer, 1, null );

                if( pDeadPlayer.GetCustomKeyvalues().GetKeyvalue("$i_checkpoints").GetInteger() > 0 )
                {
                    if( self.pev.health == 0 )
                    {
                        Messager( pDeadPlayer, 2, null );

                        if( pDeadPlayer.m_afButtonLast & SpawnWithButton != 0  )
                        {
                            pDeadPlayer.GetCustomKeyvalues().SetKeyvalue("$i_checkpoints", pDeadPlayer.GetCustomKeyvalues().GetKeyvalue("$i_checkpoints").GetInteger() - 1 );

                            Resurrect( pDeadPlayer );

                            if( !string( self.pev.netname ).IsEmpty() )
                            {
                                g_EntityFuncs.FireTargets( self.pev.netname, pDeadPlayer, pDeadPlayer, USE_TOGGLE );
                            }

                            if( !string( self.pev.message ).IsEmpty() )
                            {
                                CBaseEntity@ pXenMaker = g_EntityFuncs.FindEntityByTargetname( pXenMaker, string( self.pev.message ) );

                                g_EntityFuncs.SetOrigin( pXenMaker, pDeadPlayer.Center() );
                                g_EntityFuncs.FireTargets( string( self.pev.message ), pDeadPlayer, pDeadPlayer, USE_TOGGLE );
                            }
                        }
                    }
                }
            }
        }
        self.pev.nextthink = g_Engine.time + 0.1f;
    }

    void Activation( CBasePlayer@ pPlayer )
    {        
        for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
        {
            CBasePlayer@ pAllPlayers = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

            if( pAllPlayers is null || !pAllPlayers.IsConnected() )
                continue;

            Messager( pAllPlayers, 0, pPlayer );

            if( self.pev.SpawnFlagBitSet( SF_TCP_INSTA_RES ) )
            {
                Resurrect( pAllPlayers );
            }
            else if( !self.pev.SpawnFlagBitSet( SF_TCP_COUNT_ONE ) )
            {
                AddSpawn( pAllPlayers );
            }
        }

        if( !string( music ).IsEmpty() )
            g_SoundSystem.EmitSound(self.edict(), CHAN_STATIC, music, 1.0f, ATTN_NONE);

        if( self.pev.SpawnFlagBitSet( SF_TCP_COUNT_ONE ) )
        {
            AddSpawn( pPlayer );
        }

        UTILS::TriggerMode( string(self.pev.target), pPlayer, 0.0f );
    }

    void AddSpawn( CBasePlayer@ pPlayer )
    {
        CustomKeyvalues@ ckvSpawns = pPlayer.GetCustomKeyvalues();
        int kvSpawnIs = ckvSpawns.GetKeyvalue("$i_chkpoint").GetInteger();
        ckvSpawns.SetKeyvalue("$i_chkpoint", kvSpawnIs + 1 );
    }

    void Resurrect( CBasePlayer@ pPlayer )
    {
        if( self.pev.SpawnFlagBitSet( SF_TCP_KEEP_VECT ) )
        {
            pPlayer.GetObserver().RemoveDeadBody();
            pPlayer.SetOrigin( ( self.IsBSPModel() )  ? self.Center() : self.pev.origin );
            //g_EntityFuncs.SetOrigin( pPlayer, sVector );
            pPlayer.Revive();
        }
        else
        {
            // This way prevent players from get stuck when the map does a forced teleport -Mikk
            g_PlayerFuncs.RespawnPlayer( pPlayer, false, true );

            // Must include https://github.com/Outerbeast/Entities-and-Gamemodes/blob/master/respawndead_keepweapons.as
            RESPAWNDEAD_KEEPWEAPONS::ReEquipCollected( pPlayer, self.pev.SpawnFlagBitSet( SF_TCP_KEEP_AMMO ) );
        }
    }

    void Messager( CBasePlayer@ pPlayer, int imode, CBasePlayer@ pActivator )
    {
        if( iLanguage == 1 )
        {
            if( imode == 1 ) g_PlayerFuncs.HudMessage( pPlayer, Textparams, "Vidas: " + kvSpawnIs );
            if( imode == 2 ) g_PlayerFuncs.PrintKeyBindingString(pPlayer, 'Presiona +'+ bustr +' para re-aparecer');
            if( imode == 3 ) g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "Este punto de control no puede ser activado.\n");
            if( imode == 4 ) g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "Este punto de control no esta activo aun.\n");
            if( imode == 5 ) g_PlayerFuncs.PrintKeyBindingString(pPlayer, 'Presiona +use para activarlo');
        }
        else
        {
            if( imode == 1 ) g_PlayerFuncs.HudMessage( pPlayer, Textparams, "Spawns: " + kvSpawnIs );
            if( imode == 2 ) g_PlayerFuncs.PrintKeyBindingString(pPlayer, 'Press +'+ bustr +' to re-spawn');
            if( imode == 3 ) g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "This checkpoint can't be activated.\n");
            if( imode == 4 ) g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "This checkpoint is not active yet.\n");
            if( imode == 5 ) g_PlayerFuncs.PrintKeyBindingString(pPlayer, 'Press +use to activate');
        }
    }
}


namespace GCP
{
    int GetCKV( CBasePlayer@ pPlayer )
    {
        return int( pPlayer.GetCustomKeyvalues().GetKeyvalue ( "$i_checkpoints" ).GetFloat() );
    }
}
// End of namespace
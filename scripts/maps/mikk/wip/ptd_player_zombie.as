#include "utils"
namespace ptd_player_zombie
{
	bool blPlayerKilled = g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @ptd_player_zombie::PlayerKilled );
	bool blPlayerTakeDamage = g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @ptd_player_zombie::PlayerTakeDamage );
	int Precache = g_Game.PrecacheOther( 'monster_zombie' );

    HookReturnCode PlayerTakeDamage( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
    {
        CBaseEntity@ pInflictor = ( pDamageInfo.pInflictor !is null ) ? cast<CBaseEntity@>( pDamageInfo.pInflictor ) : null;

        if( pPlayer !is null && pInflictor !is null && pInflictor.pev.ClassNameIs( 'monster_headcrab' ) && IsInTheHead(pPlayer, pAttacker) )
		{
			pPlayer.Killed( pInflictor.pev, 4);
		}

        return HOOK_CONTINUE;
    }

    HookReturnCode PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
    {
        if( pPlayer is null || pAttacker is null )
        {
            return HOOK_CONTINUE;
        }

		if( pAttacker.pev.ClassNameIs( 'monster_headcrab' ) && IsInTheHead(pPlayer, pAttacker) || iGib == 4 )
		{
			if( iGib != GIB_ALWAYS )
			{
				pPlayer.GibMonster();
				pPlayer.pev.deadflag = DEAD_DEAD;
				pPlayer.pev.effects |= EF_NODRAW;
			}

			g_EntityFuncs.Remove( pAttacker );

			dictionary g_Scripted;

			g_Scripted [ "bloodcolor" ] = "1";
			g_Scripted [ "freeroam" ] = "2";
			g_Scripted [ "displayname" ] = string( pPlayer.pev.netname ) + " Zombified";
			g_Scripted [ "angles" ] = string( pPlayer.pev.angles.x ) + ' ' + string( pPlayer.pev.angles.y ) + string( pPlayer.pev.angles.z );
			g_Scripted [ "spawnflags" ] = "512";
			g_Scripted [ "health" ] = "200";
			g_Scripted [ "targetname" ] = "ptd_zombie_" + string( pPlayer.pev.netname );
			g_Scripted [ "origin" ] = string( pPlayer.pev.origin.x ) + ' ' + string( GetPlayerInGroundOrigin( pPlayer ) ) + string( pPlayer.pev.origin.z );

			g_EntityFuncs.CreateEntity( "monster_zombie", g_Scripted, true );
		}
        
        return HOOK_CONTINUE;
    }

    float GetPlayerInGroundOrigin( CBasePlayer@ pPlayer )
    {
        TraceResult tr;
        Vector vecSrc = pPlayer.pev.origin;
        Vector vecEnd = -g_Engine.v_up;

        g_Utility.TraceLine( vecSrc, vecSrc + vecEnd * 8192, ignore_monsters, pPlayer.edict(), tr );

        return tr.vecEndPos.y; //Este seria el origin "y" del suelo donde el jugador esta parado
    }

    bool IsInTheHead( CBaseEntity@ pPlayer, CBaseEntity@ pHeadCrab )
    {
        Vector PointA = Vector(pPlayer.pev.origin.x + pPlayer.pev.maxs.x, pPlayer.pev.origin.y + pPlayer.pev.maxs.y, pPlayer.pev.origin.z + pPlayer.pev.maxs.z);
        Vector PointB = Vector(pPlayer.pev.origin.x - pPlayer.pev.maxs.x, pPlayer.pev.origin.y - pPlayer.pev.maxs.y, pPlayer.pev.origin.z + pPlayer.pev.maxs.z);

        bool a = true;
        a = a && PointA.x + 6 >= pHeadCrab.pev.origin.x + pHeadCrab.pev.mins.x;
        a = a && PointA.y + 6 >= pHeadCrab.pev.origin.y + pHeadCrab.pev.mins.y;
        a = a && PointA.z + 6 >= pHeadCrab.pev.origin.z + pHeadCrab.pev.mins.z;
        a = a && PointB.x - 6 <= pHeadCrab.pev.origin.x + pHeadCrab.pev.maxs.x;
        a = a && PointB.y - 6 <= pHeadCrab.pev.origin.y + pHeadCrab.pev.maxs.y;
        a = a && PointB.z - 6 <= pHeadCrab.pev.origin.z + pHeadCrab.pev.maxs.z;

        return a;
    }
}
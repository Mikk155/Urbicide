void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor( 'Mikk' );
    g_Module.ScriptInfo.SetContactInfo( 'github.com/Mikk155' );
    g_Scheduler.SetInterval( "HWGRUNTTHINK", 0.5f, g_Scheduler.REPEAT_INFINITE_TIMES );
}

void HWGRUNTTHINK()
{
    CBaseEntity@ pEntity = null;

    while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_hwgrunt" ) ) !is null )
    {
        CBaseMonster@ pMonster = cast<CBaseMonster@>(pEntity);

        if( pMonster !is null
        and pMonster.pev.deadflag == DEAD_NO )
        {
            for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
            {
                CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

                if( pPlayer !is null
                and pPlayer.IsAlive()
                and pPlayer.pev.button & IN_DUCK != 0
                and ( pMonster.pev.origin - pPlayer.pev.origin ).Length() <= 64 )
                {
                    pPlayer.TakeDamage( pMonster.pev, pMonster.pev, 5, DMG_BULLET );
                }
            }
        }
    }
}
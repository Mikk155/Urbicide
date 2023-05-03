#include "utils"
namespace ptd_fire
{
	bool blPlayerTakeDamage = g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @ptd_fire::PlayerTakeDamage );

    HookReturnCode PlayerTakeDamage( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
    {
        if( pPlayer !is null && pInflictor !is null && pInflictor.pev.ClassNameIs( 'trigger_hurt' ) )
		{
			if( pDamageInfo.bitsDamageType == DMG_BURN
			|| pDamageInfo.bitsDamageType == DMG_SLOWBURN )
			{
				for( int i = 0; i < 20; ++i )
				{
					CBaseEntity@ pEnt = g_EntityFuncs.Create('ptd_enviroment_flames', pPlayer.pev.origin, Vector(0, 0, 0), false);
					pEnt.pev.velocity.x = Math.RandomFloat(-30.0f, 30.0f);
					pEnt.pev.velocity.y = Math.RandomFloat(-30.0f, 30.0f);
					pEnt.pev.velocity.z = Math.RandomFloat( 10.0f, 100.0f);
				}

				g_Util.DebugMessage( 'Player ' + pPlayer.pev.netname + ' is on flames!\n' );
			}
		}

        return HOOK_CONTINUE;
    }
}
        g_CustomEntityFuncs.RegisterCustomEntity( 'player_take_damage::ptd_enviroment_flames', 'ptd_enviroment_flames' );
		
    // Code taken from Cubemath: https://github.com/CubeMath/UCHFastDL2/blob/master/svencoop/scripts/maps/cubemath/item_airbubble.as
    class ptd_enviroment_flames : ScriptBaseEntity
    {
        private float lifeTime;

        void Precache() 
        {
            BaseClass.Precache();

            g_Game.PrecacheModel( "sprites/fire.spr" );

            g_Game.PrecacheGeneric( 'sound/' + "ambience/flameburst1.wav" );
            g_SoundSystem.PrecacheSound( "ambience/flameburst1.wav" );
        }

        void Spawn()
        {
            self.pev.movetype         = MOVETYPE_FLY;
            self.pev.solid             = SOLID_TRIGGER;
            self.pev.rendermode        = 5;
            self.pev.renderamt        = 255;
            self.pev.scale             = 0.5;

            g_EntityFuncs.SetOrigin( self, self.pev.origin );
            g_EntityFuncs.SetModel( self, "sprites/fire.spr" );
            g_EntityFuncs.SetSize( self.pev, Vector(-8, -8, -8), Vector(8, 8, 8) );
            
            lifeTime = g_Engine.time + 1.0f;
            SetThink( ThinkFunction( this.ownThink ) );
            self.pev.nextthink = g_Engine.time + 0.05f;

            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, "ambience/flameburst1.wav", 0.09, ATTN_NORM, 0, PITCH_HIGH );
        }
        
        void ownThink()
        {
            if( lifeTime < g_Engine.time + 1.0f )
            {
                if( lifeTime < g_Engine.time )
                {
                    g_EntityFuncs.Remove( self );
                }
                self.pev.renderamt = ( lifeTime - g_Engine.time ) * 255.0f;
            }
            self.pev.nextthink = g_Engine.time + 0.01f;
        }
    }
		
        // If a player receive ( bullsquit split / gonome split / hornet ) then poison him
        // If a player receive shock then shake its screen
        // If a player receive fall damage then slow him
        // If a player receive items fade its screen orange
        // If a player receive health from trigger_hurt fade its screen light blue
        // If a player receive drown dmg fade its screen blue
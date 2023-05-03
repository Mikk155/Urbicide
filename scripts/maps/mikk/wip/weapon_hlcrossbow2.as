/* 
* The original Half-Life version of the crossbow
*/

#include "../proj/proj_bolt"

const int BOLT_AIR_VELOCITY = 2000;
const int BOLT_WATER_VELOCITY = 1000;

const int CROSSBOW_DEFAULT_GIVE = 5;
const int CROSSBOW_MAX_CARRY = 20;
const int CROSSBOW_MAX_CLIP = 5;
const int CROSSBOW_WEIGHT = 10;

enum crossbow_e
{
	CROSSBOW_IDLE1 = 0,	// full
	CROSSBOW_IDLE2, 	// empty
	CROSSBOW_FIDGET1, 	// full
	CROSSBOW_FIDGET2, 	// empty
	CROSSBOW_FIRE1,	 	// full
	CROSSBOW_FIRE2,	 	// reload
	CROSSBOW_FIRE3, 	// empty
	CROSSBOW_RELOAD, 	// from empty
	CROSSBOW_DRAW1, 	// full
	CROSSBOW_DRAW2, 	// empty
	CROSSBOW_HOLSTER1, 	// full
	CROSSBOW_HOLSTER2 	// empty
};

class weapon_hlcrossbow : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/hlclassic/w_crossbow.mdl" );
		
		self.m_iDefaultAmmo = CROSSBOW_DEFAULT_GIVE;

		self.FallInit(); // get ready to fall down.
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( "models/mikk/ofhl/wpn/v_crossbow.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/w_crossbow.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/p_crossbow.mdl" );

		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );

		g_SoundSystem.PrecacheSound( "weapons/xbow_fire1.wav" );
		g_SoundSystem.PrecacheSound( "weapons/xbow_reload1.wav" );
		
		g_Game.PrecacheOther( "hlcrossbow_bolt" );
		
		g_SoundSystem.PrecacheSound( "hl/weapons/357_cock1.wav" );
		
		g_Game.PrecacheGeneric( "sprites/hl_weapons/weapon_hlcrossbow.txt" );
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer( pPlayer ) )
		{
			NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				message.WriteLong( self.m_iId );
			message.End();
			
			@m_pPlayer = pPlayer;
			
			return true;
		}
		
		return false;
	}
	
	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl/weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CROSSBOW_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CROSSBOW_MAX_CLIP;
		info.iSlot 		= 2;
		info.iPosition 	= 6;
		info.iFlags 	= 0;
		info.iWeight 	= CROSSBOW_WEIGHT;

		return true;
	}
	
	bool Deploy()
	{
		if ( self.m_iClip > 0 )
			return self.DefaultDeploy( self.GetV_Model( "models/mikk/ofhl/wpn/v_crossbow.mdl" ), self.GetP_Model( "models/hlclassic/p_crossbow.mdl" ), CROSSBOW_DRAW1, "bow" );
		return self.DefaultDeploy( self.GetV_Model( "models/mikk/ofhl/wpn/v_crossbow.mdl" ), self.GetP_Model( "models/hlclassic/p_crossbow.mdl" ), CROSSBOW_DRAW2, "bow" );
	}
	
	void Holster( int skipLocal /* = 0 */ )
	{
		self.m_fInReload = false; // cancel any reload in progress.
		
		if ( self.m_fInZoom )
		{
			SecondaryAttack();
		}
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5;
		if ( self.m_iClip > 0 )
			self.SendWeaponAnim( CROSSBOW_HOLSTER1 );
		else
			self.SendWeaponAnim( CROSSBOW_HOLSTER2 );
		
		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if ( self.m_fInZoom )
		{
			FireSniperBolt();
			return;
		}
		
		FireBolt();
	}

	void FireSniperBolt()
	{
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.80; // GetNextAttackDelay???
		
		if ( self.m_iClip == 0 )
		{
			PlayEmptySound();
			return;
		}
		
		TraceResult tr;
		m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;
		self.m_iClip--;
		
		if ( self.m_iClip > 0 )
		{
			self.SendWeaponAnim( CROSSBOW_FIRE1, 0, 0 );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/xbow_fire1.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xF ) );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_BODY, "weapons/xbow_reload1.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xF ) );
		}
		else
		{
			self.SendWeaponAnim( CROSSBOW_FIRE3, 0, 0 );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/xbow_fire1.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xF ) );
		}
		
		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		Vector anglesAim = m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle;
		g_EngineFuncs.MakeVectors( anglesAim );
		Vector vecSrc = m_pPlayer.GetGunPosition() - g_Engine.v_up * 2;
		Vector vecDir = g_Engine.v_forward;
		
		g_Utility.TraceLine( vecSrc, vecSrc + vecDir * 8192, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		CBaseEntity@ hit = g_EntityFuncs.Instance( tr.pHit );
		if ( hit.pev.takedamage > 0 )
		{
			g_WeaponFuncs.ClearMultiDamage();
			CBaseEntity@ entity = g_EntityFuncs.Instance( tr.pHit );
			entity.TraceAttack( m_pPlayer.pev, 82, vecDir, tr, DMG_BULLET | DMG_NEVERGIB );
			g_WeaponFuncs.ApplyMultiDamage( self.pev, m_pPlayer.pev );
		}
		else
		{
			// Silly stuff to play a sound at the other side, if it hit the world instead of a player/monster
			
			CBaseEntity@ bolt = g_EntityFuncs.Create( "info_target", tr.vecEndPos, g_vecZero, false, null );
			g_EntityFuncs.SetModel( bolt, "models/crossbow_bolt.mdl" );
			
			g_SoundSystem.EmitSoundDyn( bolt.edict(), CHAN_BODY, "weapons/xbow_hit1.wav", Math.RandomFloat( 0.95, 1.00 ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 7 ) );
			
			if ( g_EngineFuncs.PointContents( bolt.pev.origin ) != CONTENTS_WATER )
			{
				g_Utility.Sparks( bolt.pev.origin );
			}
			
			g_EntityFuncs.Remove( bolt );
		}
	}
	
	void FireBolt()
	{
		TraceResult tr;
		
		if ( self.m_iClip == 0 )
		{
			PlayEmptySound();
			return;
		}
		
		m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;
		self.m_iClip--;
		
		if ( self.m_iClip > 0 )
		{
			self.SendWeaponAnim( CROSSBOW_FIRE1, 0, 0 );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/xbow_fire1.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xF ) );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_BODY, "weapons/xbow_reload1.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xF ) );
		}
		else
		{
			self.SendWeaponAnim( CROSSBOW_FIRE3, 0, 0 );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/xbow_fire1.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xF ) );
		}
		
		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		Vector anglesAim = m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle;
		g_EngineFuncs.MakeVectors( anglesAim );
		
		anglesAim.x = -anglesAim.x;
		Vector vecSrc = m_pPlayer.GetGunPosition() - g_Engine.v_up * 2;
		Vector vecDir = g_Engine.v_forward;
		
		CCrossbowBolt@ pBolt = BoltCreate();
		pBolt.pev.origin = vecSrc;
		pBolt.pev.angles = anglesAim;
		@pBolt.pev.owner = m_pPlayer.edict();
		
		if ( m_pPlayer.pev.waterlevel == 3 )
		{
			pBolt.pev.velocity = vecDir * BOLT_WATER_VELOCITY;
			pBolt.pev.speed = BOLT_WATER_VELOCITY;
		}
		else
		{
			pBolt.pev.velocity = vecDir * BOLT_AIR_VELOCITY;
			pBolt.pev.speed = BOLT_AIR_VELOCITY;
		}
		pBolt.pev.avelocity.z = 10;
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.95; // GetNextAttackDelay?
		
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.95;
		
		if ( self.m_iClip != 0 )
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 5.0;
		else
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.95;
	}
	
	void SecondaryAttack()
	{
		if ( m_pPlayer.pev.fov != 0 )
		{
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0; // 0 means reset to default fov
			m_pPlayer.m_szAnimExtension = "bow";
			self.m_fInZoom = false;
		}
		else if ( m_pPlayer.pev.fov != 20 )
		{
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 20;
			m_pPlayer.m_szAnimExtension = "bowscope";
			self.m_fInZoom = true;
		}
		
		self.pev.nextthink = WeaponTimeBase() + 0.1;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 1.0;
	}

	void Reload()
	{
		if ( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			return;
		
		if ( self.m_iClip == 5 )
			return;
		
		if ( m_pPlayer.pev.fov != 0 )
		{
			SecondaryAttack();
		}
		
		if ( self.DefaultReload( 5, CROSSBOW_RELOAD, 4.5 ) )
		{
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "weapons/xbow_reload1.wav", Math.RandomFloat( 0.95, 1.00 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xF ) );
		}
		
		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle < WeaponTimeBase() )
		{
			float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0, 1 );
			if ( flRand <= 0.75 )
			{
				if ( self.m_iClip > 0 )
				{
					self.SendWeaponAnim( CROSSBOW_IDLE1 );
				}
				else
				{
					self.SendWeaponAnim( CROSSBOW_IDLE2 );
				}
				self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
			}
			else
			{
				if ( self.m_iClip > 0 )
				{
					self.SendWeaponAnim( CROSSBOW_FIDGET1 );
					self.m_flTimeWeaponIdle = WeaponTimeBase() + 90.0 / 30.0;
				}
				else
				{
					self.SendWeaponAnim( CROSSBOW_FIDGET2 );
					self.m_flTimeWeaponIdle = WeaponTimeBase() + 80.0 / 30.0;
				}
			}
		}
	}
}

string GetHLCrossbowName()
{
	return "weapon_hlcrossbow";
}

void RegisterHLCrossbow()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CCrossbowBolt", "hlcrossbow_bolt" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_hlcrossbow", GetHLCrossbowName() );
	g_ItemRegistry.RegisterWeapon( GetHLCrossbowName(), "hl_weapons", "bolts" );
}

/*
    Script original: https://github.com/baso88/SC_AngelScript/blob/SC_AngelScript/samples/scripts/maps/weapon_hlcrowbar/weapon_hlcrowbar.as


INSTALL:

#include "mikk/weapons/crowbar"

void MapInit()
{
	RegisterCrowbar( "myfolder/myconfig" );
}

*/

dictionary g_fileload;

void RegisterCrowbar( const string ConstConfigFile )
{
	string StringConfigFile = ConstConfigFile;
	if( StringConfigFile == "" ) StringConfigFile = "mikk/weapons/crowbar";

	string line, key, value;

	File@ pFile = g_FileSystem.OpenFile( "scripts/maps/" + StringConfigFile + ".txt", OpenFile::READ );

	if( pFile is null or !pFile.IsOpen() )
		return;

	while( !pFile.EOFReached() )
	{
		pFile.ReadLine( line );

		if( line.Length() < 1 or line[0] == '/' and line[1] == '/' )
			continue;

		key = line.SubString( 0, line.Find( '" "') );
		key.Replace( '"', '' );

		value = line.SubString( line.Find( '" "'), line.Length() );
		value.Replace( '" "', '' );
		value.Replace( '"', '' );

		g_fileload[ key ] = value;
	}
	pFile.Close();

	g_CustomEntityFuncs.RegisterCustomEntity( "BaseWeaponCrowbarCustom", string( g_fileload[ "classname" ] ) );
	g_ItemRegistry.RegisterWeapon( string( g_fileload[ "classname" ] ), string( g_fileload[ "sprite" ] ) );
}

enum crowbar_e
{
	CROWBAR_IDLE = 0,
	CROWBAR_DRAW,
	CROWBAR_HOLSTER,
	CROWBAR_ATTACK1HIT,
	CROWBAR_ATTACK1MISS,
	CROWBAR_ATTACK2MISS,
	CROWBAR_ATTACK2HIT,
	CROWBAR_ATTACK3MISS,
	CROWBAR_ATTACK3HIT
};

class BaseWeaponCrowbarCustom : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	
	int m_iSwing;
	TraceResult m_trHit;
	
	void Spawn()
	{
		self.Precache();

		g_EntityFuncs.SetModel( self, self.GetW_Model( ( g_ClassicMode.IsEnabled() ) ? string( g_fileload[ "models/hlclassic/w_crowbar.mdl" ] ) : string( g_fileload[ "models/w_crowbar.mdl" ] ) ) );
		self.m_iClip			= -1;
		self.m_flCustomDmg		= int( g_fileload[ "damage" ] );

		self.FallInit();// get ready to fall down.
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( ( g_ClassicMode.IsEnabled() ) ? string( g_fileload[ "models/hlclassic/v_crowbar.mdl" ] ) : string( g_fileload[ "models/v_crowbar.mdl" ] ) );
		g_Game.PrecacheModel( ( g_ClassicMode.IsEnabled() ) ? string( g_fileload[ "models/hlclassic/w_crowbar.mdl" ] ) : string( g_fileload[ "models/w_crowbar.mdl" ] ) );
		g_Game.PrecacheModel( ( g_ClassicMode.IsEnabled() ) ? string( g_fileload[ "models/hlclassic/p_crowbar.mdl" ] ) : string( g_fileload[ "models/p_crowbar.mdl" ] ) );

		g_SoundSystem.PrecacheSound( string( g_fileload[ "weapons/cbar_hit1.wav" ] ) );
		g_SoundSystem.PrecacheSound( string( g_fileload[ "weapons/cbar_hit2.wav" ] ) );
		g_SoundSystem.PrecacheSound( string( g_fileload[ "weapons/cbar_hitbod1.wav" ] ) );
		g_SoundSystem.PrecacheSound( string( g_fileload[ "weapons/cbar_hitbod2.wav" ] ) );
		g_SoundSystem.PrecacheSound( string( g_fileload[ "weapons/cbar_hitbod3.wav" ] ) );
		g_SoundSystem.PrecacheSound( string( g_fileload[ "weapons/cbar_miss1.wav" ] ) );
		g_Game.PrecacheGeneric( "sprites/" + string( g_fileload[ "sprite" ] ) + "/" + string( g_fileload[ "classname" ] ) + ".txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= 0;
		info.iPosition		= 5;
		info.iWeight		= 0;
		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
			
		@m_pPlayer = pPlayer;

		return true;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( ( g_ClassicMode.IsEnabled() ) ? string( g_fileload[ "models/hlclassic/v_crowbar.mdl" ] ) : string( g_fileload[ "models/v_crowbar.mdl" ] ) ), self.GetP_Model( ( g_ClassicMode.IsEnabled() ) ? string( g_fileload[ "models/hlclassic/p_crowbar.mdl" ] ) : string( g_fileload[ "models/p_crowbar.mdl" ] ) ), CROWBAR_DRAW, "crowbar" );
	}

	void Holster( int skiplocal /* = 0 */ )
	{
		self.m_fInReload = false;// cancel any reload in progress.

		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5; 

		m_pPlayer.pev.viewmodel = 0;
	}
	
	void PrimaryAttack()
	{
		if( !Swing( 1 ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}
	
	void Smack()
	{
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}


	void SwingAgain()
	{
		Swing( 0 );
	}

	bool Swing( int fFirst )
	{
		bool fDidHit = false;

		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 32;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if ( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if ( tr.flFraction < 1.0 )
			{
				// Calculate the point of intersection of the line (or hull) and the object we hit
				// This is and approximation of the "best" intersection
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if ( pHit is null || pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
				vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
			}
		}

		if ( tr.flFraction >= 1.0 )
		{
			if( fFirst != 0 )
			{
				// miss
				switch( ( m_iSwing++ ) % 3 )
				{
				case 0:
					self.SendWeaponAnim( CROWBAR_ATTACK1MISS ); break;
				case 1:
					self.SendWeaponAnim( CROWBAR_ATTACK2MISS ); break;
				case 2:
					self.SendWeaponAnim( CROWBAR_ATTACK3MISS ); break;
				}
				self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
				// play wiff or swish sound
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, string( g_fileload[ "weapons/cbar_miss1.wav" ] ), 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );

				// player "shoot" animation
				m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
			}
		}
		else
		{
			// hit
			fDidHit = true;
			
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			switch( ( ( m_iSwing++ ) % 2 ) + 1 )
			{
			case 0:
				self.SendWeaponAnim( CROWBAR_ATTACK1HIT ); break;
			case 1:
				self.SendWeaponAnim( CROWBAR_ATTACK2HIT ); break;
			case 2:
				self.SendWeaponAnim( CROWBAR_ATTACK3HIT ); break;
			}

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 

			// AdamR: Custom damage option
			float flDamage = 10;
			if ( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;
			// AdamR: End

			g_WeaponFuncs.ClearMultiDamage();
			/*if ( self.m_flNextPrimaryAttack + 1 < g_Engine.time )
			{*/
				// first swing does full damage
				pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB );  
			/*}
			else
			{
				// subsequent swings do 50% (Changed -Sniper) (Half)
				pEntity.TraceAttack( m_pPlayer.pev, flDamage * 0.5, g_Engine.v_forward, tr, DMG_CLUB );  
			}*/
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			//m_flNextPrimaryAttack = gpGlobals->time + 0.30; //0.25

			// play thwack, smack, or dong sound
			float flVol = 1.0;
			bool fHitWorld = true;

			if( pEntity !is null )
			{
				self.m_flNextPrimaryAttack = g_Engine.time + 0.30; //0.25

				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
	// aone
					if( pEntity.IsPlayer() )		// lets pull them
					{
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
					}
	// end aone
					// play thwack or smack sound
					switch( Math.RandomLong( 0, 2 ) )
					{
					case 0:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, string( g_fileload[ "weapons/cbar_hitbod1.wav" ] ), 1, ATTN_NORM ); break;
					case 1:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, string( g_fileload[ "weapons/cbar_hitbod2.wav" ] ), 1, ATTN_NORM ); break;
					case 2:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, string( g_fileload[ "weapons/cbar_hitbod3.wav" ] ), 1, ATTN_NORM ); break;
					}
					m_pPlayer.m_iWeaponVolume = 128; 
					if( !pEntity.IsAlive() )
						return true;
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			// play texture hit sound
			// UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR );
				
				self.m_flNextPrimaryAttack = g_Engine.time + 0.25; //0.25
				
				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.

				fvolbar = 1;

				// also play crowbar strike
				switch( Math.RandomLong( 0, 1 ) )
				{
				case 0:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, string( g_fileload[ "weapons/cbar_hit1.wav" ] ), fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
					break;
				case 1:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, string( g_fileload[ "weapons/cbar_hit2.wav" ] ), fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
					break;
				}
			}

			// delay the decal a bit
			m_trHit = tr;
			SetThink( ThinkFunction( this.Smack ) );
			self.pev.nextthink = g_Engine.time + 0.2;

			m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
		}
		return fDidHit;
	}
}
// Usage suited for Insurgency Weapons in Sven Co-op
// Author: KernCore, Firemodes Sprite function by D.N.I.O. 071, Speed modifier and bodygroup calculation by GeckoN

namespace INS2BASE
{ //Namespace start

bool ShouldUseCustomAmmo = true; // true = Uses custom ammo values; false = Uses SC's default ammo values.

//default Ammo
const string DF_AMMO_URAN	= "uranium";
const int DF_MAX_CARRY_URAN	= 100;


const string EMPTY_SHOOT_S = "ins2/wpn/empty.ogg"; //Default Empty shoot sound, if your weapons doesn't have any empty sound, it will use this
const string AMMO_PICKUP_S = "ins2/wpn/ammo.ogg"; //Default ammo pickup sound
const string BIPODMOD_SPRT = "sprites/expanded_arsenal/bipod.spr";
const string WEAP_SPRT_S01 = "sprites/expanded_arsenal/wpn1024.spr"; //Sprite file that the weapon will precache



// For Deploy Sounds
const array<string> DeployFirearmSounds = {
	"ins2/wpn/fdraw1.ogg",
	"ins2/wpn/fdraw2.ogg",
	"ins2/wpn/fdraw3.ogg",
	"ins2/wpn/fdraw4.ogg",
	"ins2/wpn/fdraw5.ogg",
	"ins2/wpn/fdraw6.ogg"
};


// Precaches an array of sounds
void PrecacheSound( const array<string> pSound )
{
	for( uint i = 0; i < pSound.length(); i++ )
	{
		g_SoundSystem.PrecacheSound( pSound[i] );
		g_Game.PrecacheGeneric( "sound/" + pSound[i] );
		g_Game.AlertMessage( at_console, "Precached: sound/" + pSound[i] + "\n" );
	}
}

mixin class WeaponBase
{
	private Vector2D FiremodesPos( -5, -60 );
	private Vector2D BipodStatePos( -85, -50 ); //Bipod test
	
	// Geckon end

	void PlayDeploySound( int weapontype )
	{
		switch( weapontype )
		{
			case 0: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_VOICE, DeployFirearmSounds[ Math.RandomLong( 0, DeployFirearmSounds.length() - 1 )], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
				break;
		}
	}

	void CommonPrecache()
	{

		// Sprites
		g_Game.PrecacheModel( BIPODMOD_SPRT );
		g_Game.PrecacheModel( WEAP_SPRT_S01 );

		// Strings
		g_SoundSystem.PrecacheSound( EMPTY_SHOOT_S );
		g_Game.PrecacheGeneric( "sound/" + EMPTY_SHOOT_S );
		g_SoundSystem.PrecacheSound( AMMO_PICKUP_S );
		g_Game.PrecacheGeneric( "sound/" + AMMO_PICKUP_S );
	}

	void CommonSpawn( const string worldModel, const int GiveDefaultAmmo ) // things that are commonly executed in spawn
	{
		g_EntityFuncs.SetModel( self, self.GetW_Model( worldModel ) );
		self.m_iDefaultAmmo = GiveDefaultAmmo;
		self.pev.scale = 1.3;

		self.FallInit();
	}

	bool CommonAddToPlayer( CBasePlayer@ pPlayer ) // adds a weapon to the player
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;

		NetworkMessage weapon( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			weapon.WriteLong( g_ItemRegistry.GetIdForName( self.pev.classname ) );
		weapon.End();

		return true;
	}

	bool CommonPlayEmptySound( const string emptySound = EMPTY_SHOOT_S ) // plays a empty sound when the player has no ammo left in the magazine
	{
		if( self.m_bPlayEmptySound )
		{
			//self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STREAM, emptySound, 0.9, 1.5, 0, PITCH_NORM );
		}

		return false;
	}

	float WeaponTimeBase() // map time
	{
		return g_Engine.time;
	}

	protected bool m_fDropped;
	CBasePlayerItem@ DropItem() // drops the item
	{
		m_fDropped = true;
		self.pev.scale = 1.3;
		SetThink( null );
		return self;
	}

	bool Deploy( string vmodel, string pmodel, int iAnim, string pAnim, int iBodygroup, float deployTime ) // deploys the weapon
	{
		m_fDropped = false;
		self.pev.scale = 0;
		self.DefaultDeploy( self.GetV_Model( vmodel ), self.GetP_Model( pmodel ), iAnim, pAnim, 0, iBodygroup );
		self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = WeaponTimeBase() + deployTime;
		return true;
	}

	void CommonHolster() // things that plays on holster
	{
		SetThink( null );
		m_pPlayer.ResetVModelPos();
		m_pPlayer.pev.fuser4 = 0;
	}
}

mixin class AmmoBase
{
	void CommonPrecache()
	{
		g_SoundSystem.PrecacheSound( AMMO_PICKUP_S );
		g_Game.PrecacheGeneric( "sound/" + AMMO_PICKUP_S );
	}
	
	bool CommonAddAmmo( CBaseEntity& inout pOther, int& in iAmmoClip, int& in iAmmoCarry, string& in iAmmoType )
	{
		if( pOther.GiveAmmo( iAmmoClip, iAmmoType, iAmmoCarry ) != -1 )
		{
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, AMMO_PICKUP_S, 1, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 0xa ) );
			return true;
		}
		return false;
	}
}

mixin class ExplosiveBase
{	
	void SmokeMsg( const Vector& in origin, float scale, int framerate, string spr_path = "sprites/steam1.spr" )
	{
		NetworkMessage smk_msg( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin, null );
			smk_msg.WriteByte( TE_SMOKE ); //MSG type enum
			smk_msg.WriteCoord( origin.x ); //pos
			smk_msg.WriteCoord( origin.y ); //pos
			smk_msg.WriteCoord( origin.z ); //pos
			smk_msg.WriteShort( g_Game.PrecacheModel( spr_path ) );
			smk_msg.WriteByte( int(scale) ); //scale
			smk_msg.WriteByte( framerate ); //framerate
		smk_msg.End();
	}

	void Smoke()
	{
		int iContents = g_EngineFuncs.PointContents( self.GetOrigin() );
		if( iContents == CONTENTS_WATER || iContents == CONTENTS_SLIME || iContents == CONTENTS_LAVA )
		{
			g_Utility.Bubbles( self.GetOrigin() - Vector( 64, 64, 64 ), self.GetOrigin() + Vector( 64, 64, 64 ), 100 );
		}
		else
		{
			NetworkMessage smk_msg( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
				smk_msg.WriteByte( TE_SMOKE ); //MSG type enum
				smk_msg.WriteCoord( self.GetOrigin().x ); //pos
				smk_msg.WriteCoord( self.GetOrigin().y ); //pos
				smk_msg.WriteCoord( self.GetOrigin().z ); //pos
				smk_msg.WriteShort( g_Game.PrecacheModel( "sprites/steam1.spr" ) );
				smk_msg.WriteByte( int((self.pev.dmg - 50) * 0.50) ); //scale
				smk_msg.WriteByte( 15 ); //framerate
			smk_msg.End();
		}
	}
}

}// Namespace end
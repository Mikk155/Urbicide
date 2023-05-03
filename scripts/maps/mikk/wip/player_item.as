#include "utils"
namespace player_item
{
    void Register()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "player_item::entity", "player_item" );
	    g_ItemRegistry.RegisterWeapon( "player_item", "player_item" );

        g_Util.ScriptAuthor.insertLast
        (
            "Script: https://github.com/Mikk155/Sven-Co-op#player_item\n"
            "Author: Gaftherman\n"
            "Github: github.com/Gaftherman\n"
            "Author: Mikk\n"
            "Github: github.com/Mikk155\n"
            "Description: .\n"
        );
    }

    enum BASE_ANIMATIONS
    {
        BASE_DEPLOY = 0,
    };

    string BASE_V_MODEL;
    string BASE_W_MODEL;
    string BASE_P_MODEL;

    string BASE_ANIMATION = "mp5";

    int BASE_MAX_CLIP = 0;
    int BASE_CLIP = 0;
    int BASE_PRIMARY_AMMO_MAX = 0;
    int BASE_SECONDARY_AMMO_MAX = 0;
    int BASE_SLOT = 0;
    int BASE_POSITION = 0;
    int BASE_FLAGS = 0;
    int BASE_WEIGHT = 0;

    class weapon_base : ScriptBasePlayerWeaponEntity
    {

		private string
			attack1,
			attack2,
			attack3,
			deploy;

		private float
        attack1_wait,
        attack2_wait,
        attack3_wait,
        onhold_delay;

        bool KeyValue( const string& in szKey, const string& in szValue )
        {
            if( szKey == "attack1" )
            {
                attack1 = szValue;
            }
            else if( szKey == "attack1_wait" )
            {
                attack1_wait = atof( szValue );
            }
            else if( szKey == "attack2" )
            {
                attack2 = szValue;
            }
            else if( szKey == "attack2_wait" )
            {
                attack2_wait = atof( szValue );
            }
            else if( szKey == "attack3" )
            {
                attack3 = szValue;
            }
            else if( szKey == "attack3_wait" )
            {
                attack3_wait = atof( szValue );
            }
            else if( szKey == "deploy" )
            {
                deploy = szValue;
            }
            else if( szKey == "onhold" )
            {
                onhold = szValue;
            }
            else if( szKey == "onhold_delay" )
            {
                onhold_delay = atof( szValue );
            }
            else
            {
                return BaseClass.KeyValue( szKey, szValue );
            }
                
            return true;
        }

        private CBasePlayer@ m_pPlayer
        {
            get const	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
            set       	{ self.m_hPlayer = EHandle( @value ); }
        }

        float WeaponTimeBase()
        {
            return g_Engine.time;
        }

        void Spawn()
        {
            Precache();
            g_EntityFuncs.SetModel( self, self.GetW_Model( BASE_W_MODEL ) );

            self.m_iDefaultAmmo = -1;
            self.m_iClip = -1;

            self.FallInit();
        }   

        void Precache()
        {
            self.PrecacheCustomModels();
        }

        bool GetItemInfo( ItemInfo& out info )
        {
            info.iMaxAmmo1  = BASE_PRIMARY_AMMO_MAX;
            info.iMaxAmmo2	= BASE_SECONDARY_AMMO_MAX;
            info.iMaxClip   = WEAPON_NOCLIP;
            info.iSlot      = BASE_SLOT;
            info.iPosition  = BASE_POSITION;
            info.iFlags     = BASE_FLAGS;
            info.iWeight    = BASE_WEIGHT;

            return true;
        }

        bool AddToPlayer( CBasePlayer@ pPlayer )
        {
            if( !BaseClass.AddToPlayer( pPlayer ) )
                return false;
                
            @m_pPlayer = pPlayer;
                
            NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
                message.WriteLong( self.m_iId );
            message.End();
        }

        bool Deploy()
        {
			g_Util.Trigger( deploy, m_pPlayer, self, USE_TOGGLE, 0.0f );
            return self.DefaultDeploy( self.GetV_Model( BASE_V_MODEL ), self.GetP_Model( BASE_P_MODEL ), BASE_DEPLOY, BASE_ANIMATION );
        }

        void PrimaryAttack()
        {
			g_Util.Trigger( attack1, m_pPlayer, self, USE_TOGGLE, 0.0f );

            self.m_flNextPrimaryAttack = WeaponTimeBase() + attack1_wait;
        }

        void SecondaryAttack()
        {
			g_Util.Trigger( attack2, m_pPlayer, self, USE_TOGGLE, 0.0f );

            self.m_flNextSecondaryAttack = WeaponTimeBase() + attack2_wait;
        }

        void TertiaryAttack()
        {
			g_Util.Trigger( attack3, m_pPlayer, self, USE_TOGGLE, 0.0f );

            self.m_flNextTertiaryAttack = WeaponTimeBase() + attack3_wait;
        }

        void WeaponIdle()
        {
            self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
        }
    }
}
// End of namespace
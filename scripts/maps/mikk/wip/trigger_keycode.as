#include "utils"
namespace trigger_keycode
{
    class trigger_keycode : ScriptBaseEntity, ScriptBaseCustomEntity, ScriptBaseLanguages
    {
		private int m_icodelength;
		private string m_iszcode;

        // Menus need to be defined globally when the plugin is loaded or else paging doesn't work.
        // Each player needs their own menu or else paging breaks when someone else opens the menu.
        // These also need to be modified directly (not via a local var reference). - Wootguy
        array<CTextMenu@> g_VoteMenu = 
        {
            null, null, null, null, null, null, null, null,
            null, null, null, null, null, null, null, null,
            null, null, null, null, null, null, null, null,
            null, null, null, null, null, null, null, null,
            null
        };

        bool KeyValue(const string& in szKey, const string& in szValue)
        {
            ExtraKeyValues(szKey, szValue);
            Languages( szKey, szValue );
            return true;
        }

        void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
        {
            if( master()
			or pActivator is null
			or !pActivator.IsPlayer()
			or int( self.pev.max_health ) <= 0
			or !g_Utility.IsWholeNumber( self.pev.max_health, self.pev.max_health ) )
            {
                return;
            }

			CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );

            if( pPlayer !is null )
            {
				m_iszcode = string( int( self.pev.max_health ) );
				m_icodelength = m_iszcode.Length();
                OpenMenu( pPlayer );
            }
        }

		void OpenMenu( CBasePlayer@ pPlayer )
		{

			int eidx = pPlayer.entindex();

			if( g_VoteMenu[eidx] is null )
			{
				@g_VoteMenu[eidx] = CTextMenu( TextMenuPlayerSlotCallback( this.MainCallback ) );
				g_VoteMenu[eidx].SetTitle( SetLanguages( pPlayer, 'title' ) + ' ' );

				int NumPads = 1;
				while( NumPads < 10 )
				{
					g_VoteMenu[eidx].AddItem( 'Number ' + string( NumPads ) );
					++NumPads;
				}
				g_VoteMenu[eidx].AddItem( 'Number 0' );

				g_VoteMenu[eidx].Register();
			}
			g_VoteMenu[eidx].Open( ( self.pev.health <= 5 ) ? 25 : int( self.pev.health ), 0, pPlayer );
		}

		void MainCallback( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
		{
			if( pItem !is null )
			{
				if( atoi( g_Util.GetCKV( pPlayer, "$i_trigger_keycode_input" ) ) == 0 )
				{
					g_Util.SetCKV( pPlayer, "$i_trigger_keycode_input", m_icodelength );
				}

				string Choice = pItem.m_szName;

				g_Util.SetCKV( pPlayer, "$i_trigger_keycode_code", g_Util.GetCKV( pPlayer, "$i_trigger_keycode_code" ) + Choice.Replace( 'Number ', '' ) );
				g_Util.SetCKV( pPlayer, "$i_trigger_keycode_input", atoi( g_Util.GetCKV( pPlayer, "$i_trigger_keycode_input" ) ) -1 );
				
				if( atoi( g_Util.GetCKV( pPlayer, "$i_trigger_keycode_input" ) ) == 0 )
				{
					if( atoi( g_Util.GetCKV( pPlayer, "$i_trigger_keycode_code" ) ) == m_iszcode )
					{
						g_Util.Trigger( self.pev.target, pPlayer, self, USE_TOGGLE, delay );
					}
					else
					{
						g_Util.Trigger( self.pev.netname, pPlayer, self, USE_TOGGLE, delay );
					}
					g_Util.SetCKV( pPlayer, "$i_trigger_keycode_code", 0 );
					return;
				}
				g_Scheduler.SetTimeout( @this, "OpenMenu", 1.0f, @pPlayer );
			}
		}

        string SetLanguages( CBasePlayer@ pActivator, const string& in iszMessage )
        {
			string ReturnMessage;

            if( iszMessage == 'title' )
            {
                self.pev.message = 'Select number for code input %input%. Pages';
                message_spanish = '';
                message_spanish2 = '';
                message_portuguese = '';
                message_german = '';
                message_french = '';
                message_italian = '';
                message_esperanto = '';
                message_czech = '';
                message_dutch = '';
                message_indonesian = '';
                message_romanian = '';
                message_turkish = '';
                message_albanian = '';
            }
            else if( iszMessage == '' )
            {
            }

            if( pActivator !is null )
            {
				ReturnMessage = g_Util.StringReplace
                (
                    ReadLanguages( pActivator ),
                    {
                        { "%input%", g_Util.GetCKV( pActivator, "$i_trigger_keycode_input" ) }
                    }
                );
            }
			return ReturnMessage;
        }
    }
	bool Register = g_Util.CustomEntity( 'trigger_keycode::trigger_keycode','trigger_keycode' );
}
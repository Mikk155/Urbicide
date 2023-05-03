// Default music : "mikk/music/cof/game_over.mp3"
#include "utils"
namespace config_map_saveload
{
    void Register()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( 'config_map_saveload::config_map_saveload','config_map_saveload' );

        g_ScriptInfo.SetInformation
        ( 
            g_ScriptInfo.ScriptName( 'config_map_saveload' ) +
            g_ScriptInfo.Description( 'Allow to configurate save system to your campaigns' ) +
            g_ScriptInfo.Wiki( 'config_map_saveload' ) +
            g_ScriptInfo.Author( 'Mikk' ) +
            g_ScriptInfo.GetDiscord() +
            g_ScriptInfo.GetGithub()
        );
    }

    class config_map_saveload : ScriptBaseEntity, ScriptBaseCustomEntity
    {
        private string m_iszFirstMap;
        private int m_iPlayersLifes;
        bool KeyValue( const string& in szKey, const string& in szValue )
        {
            if( szKey == "m_iszFirstMap" )
            {
                m_iszFirstMap = szValue;
            }
            if( szKey == "m_iPlayersLifes" )
            {
                m_iPlayersLifes = atoi( szValue );
            }
            return true;
        }

        void Think()
        {
            
        }
    }
}

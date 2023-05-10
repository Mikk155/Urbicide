#include 'utils/CUtils'
#include 'utils/CGetInformation'
#include 'utils/Reflection'
#include "utils/ScriptBaseCustomEntity"

namespace trigger_saveload
{
    void Register()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "trigger_saveload::trigger_saveload", "trigger_saveload" );

        g_ScriptInfo.SetInformation
        ( 
            g_ScriptInfo.ScriptName( 'trigger_saveload' ) +
            g_ScriptInfo.Description( '' ) +
            g_ScriptInfo.Wiki( 'trigger_saveload' ) +
            g_ScriptInfo.Author( 'Gaftherman' ) +
            g_ScriptInfo.GetDiscord( 'Gaftherman' ) +
            g_ScriptInfo.GetGithub()
        );
    }

    enum trigger_saveload_mode
    {
        MODE_READ = 0,
        MODE_WRITE = 1
    }

    class trigger_saveload : ScriptBaseEntity, ScriptBaseCustomEntity
    {
        private int m_iMode;
        private string
        m_iszReadString,
        m_iszLabelRead,
        m_iszFireOnFalse,
        m_iszFireOnTrue,
        m_iszConfigFile;

        bool KeyValue( const string& in szKey, const string& in szValue )
        {
            ExtraKeyValues( szKey, szValue );
            if( szKey == "m_iMode" )
            {
                m_iMode = atoi( szValue );
            }
            else if( szKey == "m_iszLabelRead" )
            {
                m_iszLabelRead = szValue;
            }
            else if( szKey == "m_iszReadString" )
            {
                m_iszReadString = szValue;
            }
            else if( szKey == "m_iszFireOnTrue" )
            {
                m_iszFireOnTrue = szValue;
            }
            else if( szKey == "m_iszFireOnFalse" )
            {
                m_iszFireOnFalse = szValue;
            }
            else if( szKey == 'm_iszConfigFile' )
            {
                m_iszConfigFile = szValue;
            }
            else
            {
                return BaseClass.KeyValue( szKey, szValue );
            }
            return true;
        }

        void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
        {
            if( !IsLockedByMaster() && !m_iszConfigFile.IsEmpty() )
            {
                if( m_iMode == MODE_READ )
                {
                    //  Leer
                }
                else if( m_iMode == MODE_WRITE )
                {
                    // Escribir
                }
            }
        }

        void fileidk()
        {
            string file = 'scripts/maps/' + m_iszConfigFile;
        }
    }
}
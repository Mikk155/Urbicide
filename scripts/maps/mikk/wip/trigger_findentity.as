
    "CBaseEntity@ CEntityFuncs::FindEntityByString(CBaseEntity@ pStartEntity,const string& in szKeyword, const string& in szValue)": {
        "prefix": "FindEntityByString",
        "body" : [ "FindEntityByString( ${1:CBaseEntity@ pStartEntity,const string& in szKeyword}, ${2:const string& in szValue} )" ],
        "description" : "Finds an entity based on a key value pair"
    },
    "CBaseEntity@ CEntityFuncs::FindEntityByClassname(CBaseEntity@ startEntity, const string& in name)": {
        "prefix": "FindEntityByClassname",
        "body" : [ "FindEntityByClassname( ${1:CBaseEntity@ startEntity}, ${2:const string& in name} )" ],
        "description" : "Finds an entity by class name"
    },
    "CBaseEntity@ CEntityFuncs::FindEntityByTargetname(CBaseEntity@ startEntity, const string& in name)": {
        "prefix": "FindEntityByTargetname",
        "body" : [ "FindEntityByTargetname( ${1:CBaseEntity@ startEntity}, ${2:const string& in name} )" ],
        "description" : "Finds an entity by target name"
    },
	
	while MAX ENTITIES -> custom keyvalue
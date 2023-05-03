void weapon_grapple()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_grapple" ); //weapon name
		message.WriteByte(-1); //ammotype1
		message.WriteLong(-1); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(0); //slot
		message.WriteByte(3); //position
		message.WriteShort(22); //ID
		message.WriteByte(128); //flag
}

void weapon_pipewrench()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_pipewrench" ); //weapon name
		message.WriteByte(-1); //ammotype1
		message.WriteLong(-1); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(0); //slot
		message.WriteByte(1); //position
		message.WriteShort(20); //ID
		message.WriteByte(128); //flag
}

void weapon_medkit()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_medkit" ); //weapon name
		message.WriteByte(1); //ammotype1
		message.WriteLong(100); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(0); //slot
		message.WriteByte(2); //position
		message.WriteShort(18); //ID
		message.WriteByte(128); //flag
}

void weapon_crowbar()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_crowbar" ); //weapon name
		message.WriteByte(-1); //ammotype1
		message.WriteLong(-1); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(0); //slot
		message.WriteByte(0); //position
		message.WriteShort(1); //ID
		message.WriteByte(128); //flag
}

void weapon_eagle()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_eagle" ); //weapon name
		message.WriteByte(3); //ammotype1
		message.WriteLong(36); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(1); //slot
		message.WriteByte(2); //position
		message.WriteShort(27); //ID
		message.WriteByte(0); //flag
}

void weapon_uzi()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_uzi" ); //weapon name
		message.WriteByte(2); //ammotype1
		message.WriteLong(250); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(1); //slot
		message.WriteByte(3); //position
		message.WriteShort(17); //ID
		message.WriteByte(32); //flag
}

void weapon_357()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_357" ); //weapon name
		message.WriteByte(3); //ammotype1
		message.WriteLong(36); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(1); //slot
		message.WriteByte(1); //position
		message.WriteShort(3); //ID
		message.WriteByte(0); //flag
}

void weapon_9mmhandgun()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_9mmhandgun" ); //weapon name
		message.WriteByte(2); //ammotype1
		message.WriteLong(250); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(1); //slot
		message.WriteByte(0); //position
		message.WriteShort(2); //ID
		message.WriteByte(0); //flag
}

void weapon_displacer()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_displacer" ); //weapon name
		message.WriteByte(9); //ammotype1
		message.WriteLong(100); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(5); //slot
		message.WriteByte(3); //position
		message.WriteShort(29); //ID
		message.WriteByte(0); //flag
}

void weapon_sporelauncher()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_sporelauncher" ); //weapon name
		message.WriteByte(16); //ammotype1
		message.WriteLong(30); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(5); //slot
		message.WriteByte(2); //position
		message.WriteShort(26); //ID
		message.WriteByte(0); //flag
}

void weapon_m249()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_m249" ); //weapon name
		message.WriteByte(6); //ammotype1
		message.WriteLong(600); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(5); //slot
		message.WriteByte(1); //position
		message.WriteShort(24); //ID
		message.WriteByte(0); //flag
}

void weapon_sniperrifle()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_sniperrifle" ); //weapon name
		message.WriteByte(15); //ammotype1
		message.WriteLong(15); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(5); //slot
		message.WriteByte(0); //position
		message.WriteShort(23); //ID
		message.WriteByte(0); //flag
}

void weapon_crossbow()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_crossbow" ); //weapon name
		message.WriteByte(5); //ammotype1
		message.WriteLong(50); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(2); //slot
		message.WriteByte(2); //position
		message.WriteShort(6); //ID
		message.WriteByte(0); //flag
}

void weapon_m16()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_m16" ); //weapon name
		message.WriteByte(6); //ammotype1
		message.WriteLong(600); //max ammo 1
		message.WriteByte(7); //ammotype2
		message.WriteLong(10); //max ammo 2
		message.WriteByte(2); //slot
		message.WriteByte(3); //position
		message.WriteShort(25); //ID
		message.WriteByte(0); //flag
}

void weapon_9mmAR()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_9mmAR" ); //weapon name
		message.WriteByte(2); //ammotype1
		message.WriteLong(250); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(2); //slot
		message.WriteByte(0); //position
		message.WriteShort(4); //ID
		message.WriteByte(0); //flag
}

void weapon_shotgun()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_shotgun" ); //weapon name
		message.WriteByte(4); //ammotype1
		message.WriteLong(125); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(2); //slot
		message.WriteByte(1); //position
		message.WriteShort(7); //ID
		message.WriteByte(0); //flag
}

void weapon_hornetgun()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_hornetgun" ); //weapon name
		message.WriteByte(10); //ammotype1
		message.WriteLong(100); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(3); //slot
		message.WriteByte(3); //position
		message.WriteShort(11); //ID
		message.WriteByte(6); //flag
}

void weapon_egon()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_egon" ); //weapon name
		message.WriteByte(9); //ammotype1
		message.WriteLong(100); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(3); //slot
		message.WriteByte(2); //position
		message.WriteShort(10); //ID
		message.WriteByte(0); //flag
}

void weapon_gauss()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_gauss" ); //weapon name
		message.WriteByte(9); //ammotype1
		message.WriteLong(100); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(3); //slot
		message.WriteByte(1); //position
		message.WriteShort(9); //ID
		message.WriteByte(0); //flag
}

void weapon_rpg()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_rpg" ); //weapon name
		message.WriteByte(8); //ammotype1
		message.WriteLong(5); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(3); //slot
		message.WriteByte(0); //position
		message.WriteShort(8); //ID
		message.WriteByte(0); //flag
}

void weapon_snark()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_snark" ); //weapon name
		message.WriteByte(14); //ammotype1
		message.WriteLong(15); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(4); //slot
		message.WriteByte(3); //position
		message.WriteShort(15); //ID
		message.WriteByte(26); //flag
}

void weapon_tripmine()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_tripmine" ); //weapon name
		message.WriteByte(13); //ammotype1
		message.WriteLong(5); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(4); //slot
		message.WriteByte(2); //position
		message.WriteShort(13); //ID
		message.WriteByte(24); //flag
}

void weapon_satchel()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_satchel" ); //weapon name
		message.WriteByte(12); //ammotype1
		message.WriteLong(5); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(4); //slot
		message.WriteByte(1); //position
		message.WriteShort(14); //ID
		message.WriteByte(25); //flag
}

void weapon_handgrenade()
{
	NetworkMessage message( MSG_ALL, NetworkMessages::WeaponList );
		message.WriteString( "weapon_handgrenade" ); //weapon name
		message.WriteByte(11); //ammotype1
		message.WriteLong(10); //max ammo 1
		message.WriteByte(-1); //ammotype2
		message.WriteLong(-1); //max ammo 2
		message.WriteByte(4); //slot
		message.WriteByte(0); //position
		message.WriteShort(12); //ID
		message.WriteByte(24); //flag
}


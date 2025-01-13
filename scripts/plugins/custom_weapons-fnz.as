//#include "../maps/fournines/weapon_dxnanosword"
#include "../maps/fournines/item_utarmor"


void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor("Four-Nines");
    g_Module.ScriptInfo.SetContactInfo("Discord: fournines");
}

void MapInit()
{
//    DX_NANOSWORD::Register();
	UT_ARMOR::Register();
}
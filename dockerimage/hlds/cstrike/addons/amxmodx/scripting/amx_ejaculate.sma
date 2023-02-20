#include <amxmodx> 

new count_ejaculate[33]
new bool:EjaculateFlag[33]
new bool:aim[33]
new counter[33]
#if !defined NO_CS_CZ
new player_origins[33][3]
#endif

public ejaculate_on_player(id) 
{
    
    if (get_cvar_num("amx_maxejaculations")==0) 
        return PLUGIN_HANDLED 
    if (!is_user_alive(id)) 
        return PLUGIN_HANDLED 
    if ( (get_cvar_num("amx_ejaculate_admin")==1) && !(get_user_flags(id) & ADMIN_LEVEL_A) )
    {
        client_print(id,print_console,("Bu Komutu kullanamazsin."))
        return PLUGIN_HANDLED
    }
    if(EjaculateFlag[id])
        return PLUGIN_HANDLED
    
    //#if !defined NO_CS_CZ
    new player_origin[3], players[32], inum=0 
	
    get_user_origin(id,player_origin,0) 
    get_players(players,inum,"b") 
        
    new maxtimes = get_cvar_num("amx_maxejaculations")
        
    if (count_ejaculate[id] > get_cvar_num("amx_maxejaculations")) { 
        client_print(id,print_chat,"Bir oyuncu maksimum %d saniye bosalabilir !", maxtimes)
        return PLUGIN_CONTINUE 
    }
    new player_name[32] 
    get_user_name(id, player_name, 31)
    client_print(0,print_chat,"%s Attiriyor", player_name)
    count_ejaculate[id]=0
    new ids[1]
    ids[0]=id
    EjaculateFlag[id]=true
    aim[id]=false
    counter[id]=0
    emit_sound(id, CHAN_VOICE, "ejaculate/ejaculate.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) 
    set_task(1.0,"make_ejaculate",4210+id,ids,1,"a",10)
    return PLUGIN_HANDLED
}

public sqrt(num) 
{ 
    new div = num 
    new result = 1 
    while (div > result) { 
        div = (div + result) / 2 
        result = num / div 
    } 
    return div 
} 

public make_ejaculate(ids[]) 
{ 
    new id=ids[0]
    new vec[3] 
    new aimvec[3] 
    new velocityvec[3] 
    new length 
    get_user_origin(id,vec) 
    get_user_origin(id,aimvec,3) 
    new distance = get_distance(vec,aimvec) 
    new speed = floatround(distance*1.9)
    
    velocityvec[0]=aimvec[0]-vec[0] 
    velocityvec[1]=aimvec[1]-vec[1] 
    velocityvec[2]=aimvec[2]-vec[2] 
    
    length=sqrt(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2]) 
    
    velocityvec[0]=velocityvec[0]*speed/length 
    velocityvec[1]=velocityvec[1]*speed/length 
    velocityvec[2]=velocityvec[2]*speed/length 
    
    message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(101)
    write_coord(vec[0])
    write_coord(vec[1])
    write_coord(vec[2])
    write_coord(velocityvec[0]) 
    write_coord(velocityvec[1]) 
    write_coord(velocityvec[2]) 
    write_byte(6) // color
    write_byte(3000) // speed
    message_end()
    
    counter[id]++
    if(counter[id]==10)
        EjaculateFlag[id]=false
} 

public death_event() 
{ 
    new victim = read_data(2)
    #if !defined NO_CS_CZ      
    get_user_origin(victim,player_origins[victim],0) 
    #endif
    
    if(EjaculateFlag[victim]) 
        reset_ejaculate(victim)
    
    return PLUGIN_CONTINUE 
}

public reset_ejaculate(id) 
{
    if(task_exists(4210+id))
        remove_task(4210+id)
    emit_sound(id,CHAN_VOICE,"ejaculate/ejaculate.wav", 0.0, ATTN_NORM, 0, PITCH_NORM) 
    EjaculateFlag[id]=false
    
    return PLUGIN_CONTINUE 
}

public reset_hud(id)
{
    if(task_exists(4210+id))
        remove_task(4210+id)
    emit_sound(id,CHAN_VOICE,"ejaculate/ejaculate.wav", 0.0, ATTN_NORM, 0, PITCH_NORM) 
    EjaculateFlag[id]=false
    
    count_ejaculate[id]=1
    
    return PLUGIN_CONTINUE 
} 

public ejaculate_help(id) 
{
    client_print(id, print_chat, ("Sunucumuza girerken otomatik bosalma tusu Z'dir"))
    client_print(id, print_chat, ("Degistirmek icin konsola assagidakini yazin"))
    client_print(id, print_chat, ("Ornek: bind ^"z^" ^"bosalma^""))
    
    return PLUGIN_CONTINUE
}

public handle_say(id) 
{
    new said[192]
    read_args(said,192)
    remove_quotes(said)
    
    if( ((containi(said, "ejaculate") != -1) && !(containi(said, "/ejaculate") != -1))
    || ((containi(said, "ejaculer") != -1) && !(containi(said, "/ejaculer") != -1)) ) 
    {
        client_print(id, print_chat, ("Bosalma Yardim Icin say /bosalma Yazin"))
    }

    return PLUGIN_CONTINUE
}

public plugin_precache() 
{ 
    if (file_exists("sound/ejaculate/ejaculate.wav"))
    precache_sound("ejaculate/ejaculate.wav")    
    
    return PLUGIN_CONTINUE 
}

public client_connect(id)
{
    EjaculateFlag[id]=false
    count_ejaculate[id]=1
    
    return PLUGIN_CONTINUE
}

public client_disconnected(id)
{
    reset_hud(id)
    
    return PLUGIN_CONTINUE
}

public plugin_init() 
{ 
    register_plugin("AMX Ejaculate","0.1","KRoTaL") 
    register_clcmd("ejaculate","ejaculate_on_player",0,"- Ejaculate on a dead player") 
    register_clcmd("ejaculer","ejaculate_on_player",0,"- Ejaculate on a dead player")
    register_clcmd("bosalma","ejaculate_on_player",0,"- Ejaculate on a dead player")
    register_clcmd("say /ejaculate","ejaculate_help",0,"- Displays Ejaculate help")
    register_clcmd("say /bosalma","ejaculate_help",0,"- Displays Ejaculate help")
    register_clcmd("say /ejaculer","ejaculate_help",0,"- Displays Ejaculate help")
    register_clcmd("say","handle_say")
    register_cvar("amx_maxejaculations","999")
    register_cvar("amx_ejaculate_admin","0")
    register_event("DeathMsg","death_event","a") 
    register_event("ResetHUD", "reset_hud", "be")
}

--[[
* Ashita - Copyright (c) 2014 - 2022 atom0s [atom0s@live.com]
*
* This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or send a letter to
* Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
*
* By using Ashita, you agree to the above license and its terms.
*
*      Attribution - You must give appropriate credit, provide a link to the license and indicate if changes were
*                    made. You must do so in any reasonable manner, but not in any way that suggests the licensor
*                    endorses you or your use.
*
*   Non-Commercial - You may not use the material (Ashita) for commercial purposes.
*
*   No-Derivatives - If you remix, transform, or build upon the material (Ashita), you may not distribute the
*                    modified material. You are, however, allowed to submit the modified works back to the original
*                    Ashita project in attempt to have it added to the original project.
*
* You may not apply legal terms or technological measures that legally restrict others
* from doing anything the license permits.
*
* No warranties are given.
]]--

_addon.author   = 'Almavivaconte';
_addon.name     = 'kitetrack';
_addon.version  = '0.0.3';

require 'common'

local mobname = "";
local assist_blocked = false;
local kiteindex = -1;
local playername = "";
local current_target = "";
local first_run = true;
local call_on = false;
local party_on = false;
local partycmd = "/p " .. mobname .. "'s target has changed. Now on " .. playername
local passthrough = false;
local tracking = false;
local chatmode = "party";

local function SendAssistPacket(mobIndex)
    local mobId = AshitaCore:GetDataManager():GetEntity():GetServerId(mobIndex);
    local assistPacket = struct.pack('bbHIhhhhiii', 0x1A, 0x0E, 0, mobId, mobIndex, 0x0C, 0x00, 0x00, 0x00, 0x00, 0x00):totable();
    if not passthrough then
        AddOutgoingPacket(0x1A, assistPacket);
    end
end

local function assist_unblocker()
    assist_blocked = false;
    first_run = false;
end

local function assist_blocker()
    assist_blocked = true;
    ashita.timer.once(1, assist_unblocker)
end

local function reset_passthrough()
    passthrough = false;
end

local kitetrack_config =
{
    font =
    {
        family      = 'Arial',
        size        = 7,
        color       = 0xFFFFFFFF,
        position    = { 640, 360 },
        bgcolor     = 0xC8000000,
        bgvisible   = true
    },
    call_on = true,
    party_on = true
};

----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Event called when the addon is being loaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
    -- Attempt to load the configuration..
    kitetrack_config = ashita.settings.load_merged(_addon.path .. 'settings/settings.json', kitetrack_config);

    -- Create our font object..
    local f = AshitaCore:GetFontManager():Create('__kitetrack_addon');
    f:SetColor(kitetrack_config.font.color);
    f:SetFontFamily(kitetrack_config.font.family);
    f:SetFontHeight(kitetrack_config.font.size);
    f:SetBold(true);
    f:SetPositionX(kitetrack_config.font.position[1]);
    f:SetPositionY(kitetrack_config.font.position[2]);
    f:SetVisibility(true);
    f:GetBackground():SetColor(kitetrack_config.font.bgcolor);
    f:GetBackground():SetVisibility(kitetrack_config.font.bgvisible);
    party_on = kitetrack_config.party_on;
    call_on = kitetrack_config.call_on;
    print("\30\201[\30\82kitetrack\30\201]\31\255 Type /setkite help for commands.")
    if party_on then
        print("\30\201[\30\82kitetrack\30\201]\31\255 Party chat messages are enabled.")
    else
        print("\30\201[\30\82kitetrack\30\201]\31\255 Party chat messages are disabled.")
    end
    if call_on then
        print("\30\201[\30\82kitetrack\30\201]\31\255 Calls in chat messages are enabled.")
    else
        print("\30\201[\30\82kitetrack\30\201]\31\255 Calls in chat messages are disabled.")
    end
end);

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Event called when the addon is being unloaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
    local f = AshitaCore:GetFontManager():Get('__kitetrack_addon');
    kitetrack_config.font.position = { f:GetPositionX(), f:GetPositionY() };
    kitetrack_config.party_on = party_on;
    kitetrack_config.call_on = call_on;
    -- Save the configuration..
    ashita.settings.save(_addon.path .. 'settings/settings.json', kitetrack_config);
    
    -- Unload the font object..
    AshitaCore:GetFontManager():Delete('__kitetrack_addon');
end );

---------------------------------------------------------------------------------------------------
-- func: Render
-- desc: Called when our addon is rendered.
---------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
    
    local f = AshitaCore:GetFontManager():Get('__kitetrack_addon');
    
    f:SetVisibility(true)
    
    if kiteindex >= 1 then
        if not assist_blocked and tracking then
            if GetEntity(kiteindex) ~= nil then
                SendAssistPacket(kiteindex)
                assist_blocker()
                f:SetText(mobname .. "'s target: " .. playername)
                if current_target ~= playername and current_target ~= "" and playername ~= "" then
                    if party_on then
                        local partycmd;
                        if chatmode == "linkshell" then
                            partycmd = "/l " .. mobname .. "'s target has changed. Now on " .. playername
                        elseif chatmode == "party" then
                            partycmd = "/p " .. mobname .. "'s target has changed. Now on " .. playername
                        end
                        if call_on then
                            partycmd = partycmd .. " <call21>"
                        end
                        AshitaCore:GetChatManager():QueueCommand(partycmd, 1);
                    end
                    current_target = playername
                elseif current_target == "" then
                    current_target = playername;
                end
            end
        else
            passthrough = false;
        end
        if GetEntity(kiteindex).HealthPercent <= 0 or GetEntity(kiteindex) == nil then
            kiteindex = -1
            mobname = ""
            f:SetText("")
            f:SetVisibility(false)
            first_run = true;
            tracking = false;
        end
    end
    
    return;
end);

----------------------------------------------------------------------------------------------------
-- func: command
-- desc: Event called when a command was entered.
----------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    -- Ensure we should handle this command..
    local args = command:args();
    if (args[1] == '/setkite') then
        if #args > 1 then
            if (args[2] == 'call' or args[2] == 'calls') then
                call_on = not call_on;
                if call_on then
                    print("\30\201[\30\82kitetrack\30\201]\31\255 Calls enabled in party chat messages.")
                else
                    print("\30\201[\30\82kitetrack\30\201]\31\255 Calls disabled in party chat messages.")
                end
            elseif (args[2] == 'party') then
                party_on = not party_on;
                if party_on then
                    print("\30\201[\30\82kitetrack\30\201]\31\255 Party chat messages enabled; when hate changes on your target, you'll send a party message.")
                else
                    print("\30\201[\30\82kitetrack\30\201]\31\255 Party chat messages disabled.")
                end
            elseif (args[2] == 'clear') then
                print("\30\201[\30\82kitetrack\30\201]\31\255 kite target cleared.")
                local f = AshitaCore:GetFontManager():Get('__kitetrack_addon');
                kiteindex = -1
                mobname = ""
                if f ~= nil then
                    f:SetText("")
                    f:SetVisibility(false)
                end
            elseif (args[2] == 'mode') then
                if (args[3] == 'ls' or args[3] == 'l' or args[3] == 'linkshell') then
                    chatmode = "linkshell"
                    print("\30\201[\30\82kitetrack\30\201]\31\255 Message mode set to Linkshell.")
                elseif (args[3] == 'party' or args[3] == 'p' or args[3] == 'pt') then
                    chatmode = "party"
                    print("\30\201[\30\82kitetrack\30\201]\31\255 Message mode set to Party.")
                end
            else
                print("\30\201[\30\82kitetrack\30\201]\31\255 Kitetrack usage: Target the enemy (or player) whose assist target you want to track and type /setkite.")
                print("\30\201[\30\82kitetrack\30\201]\31\255 Type /kiteid to see current enemy (or player) tracked.")
                print("\30\201[\30\82kitetrack\30\201]\31\255 use /setkite party to toggle sending of /party messages when hate changes.")
                print("\30\201[\30\82kitetrack\30\201]\31\255 use /setkite call to toggle <call21> in /party messages.")
            end
        else
            kiteindex = AshitaCore:GetDataManager():GetTarget():GetTargetIndex();
            if kiteindex <= 0 then
                print("\30\201[\30\82kitetrack\30\201]\31\255 Error: no valid target found. Target the mob you're kiting and type /setkite again.")
            else
                mobname = GetEntity(kiteindex).Name
                print("\30\201[\30\82kitetrack\30\201]\31\255 Current assist target is \30\82" .. mobname .. "\31\255 (index is \30\82" .. kiteindex .. "\31\255).")
                playername = ""
                tracking = true;
            end
        end
    elseif (args[1] == '/kiteid' or args[1] == '/printid') then
        if kiteindex <= 0 or kiteindex == nil then
            print("\30\201[\30\82kitetrack\30\201]\31\255 Error: no valid target found. Target the mob you're kiting and type /setkite again.")
        else
            print("\30\201[\30\82kitetrack\30\201]\31\255 Current kitetrack target is " .. mobname .. " (Mob's index is " .. kiteindex .. ").")
        end
    elseif (args[1] == '/unsetkite') then
        print("\30\201[\30\82kitetrack\30\201]\31\255 kite target cleared.")
        kiteindex = -1
        mobname = ""
        playername = ""
    elseif (args[1] == '/kitetarget') then
        local mymessage;
        if chatmode == "linkshell" then
            mymessage = "/l " .. mobname .. "'s target is " .. playername
        elseif chatmode == "party" then
            mymessage = "/p " .. mobname .. "'s target is " .. playername
        end
        if call_on then
            mymessage = mymessage .. " <call21>"
        end
        AshitaCore:GetChatManager():QueueCommand(mymessage, 1);
    end
    
    return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, data, modified, blocked)
    
    if (id == 0x058) then
        if tracking then
            local response_index = struct.unpack('H', data, 0x0F);
            if response_index <= 0 or response_index == kiteindex then
                playername = ""
                return false
            else
                playername = GetEntity(response_index).Name
                return true;
            end
        end
    end
    
    return false;
    
end);
---------------------------------------------------------------------------------------------------
-- func: outgoing_packet
-- desc: Called when our addon receives an outgoing packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('outgoing_packet', function(id, size, packet)
	-- Action or Equipment Changed packet
	if (id == 0x1A) then
        passthrough = true;
    end
	return false;
end);
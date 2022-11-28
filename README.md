An Ashita FFXI addon for keeping track of which player has hate (or alternatively, what mob your tank or another player is targeting).

How to use: Target the mob you want to track and type `/setkite` to set a kite target. A chat message will appear indicating you've set a tracking target, and there will be a text object showing your tracked target's current target.

You can set the addon to print a chat message using `/setkite party` (toggles on and off). To change mode from party to linkshell, you can type `/setkite mode ls`, `/setkite mode l`, or `/setkite mode linkshell` to set the message to linkshell chat, or `/setkite mode pt`, `/setkite mode p`, or `/setkite mode pt` to set it to party chat. If you're in party mode, you can add a <call21> with `/setkite call` or `calls`. 

Normally the party message will only be sent when the target actually changes; you can manually trigger sending a message with the current hate target by typing `/kitetarget`. You can print your current kite target locally by typing `/printid` or `/kiteid`.

The kite target should clear automatically when it dies (i.e. its HP goes to 0); you can also clear it manually with `/setkite clear` or `/unsetkite`.

List of commands:

`/setkite` - Sets current target as kite tracking target

`/setkite party` - Toggles party messages on and off

`/setkite call` or `/setkite calls` - adds a call to chat messages

`/setkite mode` - Changes chat mode for messages. `/setkite mode ls`, `l`, or `linkshell` will set the chat mode to linkshell; `pt`, `p`, or `party` for party

`/kitetarget` - manually prints your current kite target (if one is set)

`/setkite clear` or `/unsetkite` - Clears current kite target (will clear automatically when your kite target dies)

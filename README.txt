SimpleCalc - Copyright (c) 2017

--[ Description ]--

SimpleCalc is a simple mathematical calculator addon for World of Warcraft.
In essence, it's a slash-based utility which allows you to do maths!

Example usage and response:

/calc 10415 - 9843 + 12
[SimpleCalc] 10415 - 9843 + 12 = 584

A selection of in-game values has been added to make life easier when doing certain calculations. You can use keywords in place of numbers for the following values:

* honour / honor - Honor points at current level
* maxhonor / maxhonour - Honor required to reach next level
* achieves - Your total achieve points
* health (or hp) - Your maximum Health points
* mana (or power) - Your maximum Mana, Rage, Focus, Energy, or Runic Power
* gold - Total gold (1g 50s would be displayed as 1.5 gold)
* silver - Total silver (1g 50s would be displayed as 150 silver)
* copper - Total copper (1g 50s would be displayed as 15,000 copper)
* garrison - Garrison resources (WoD)
* orderhall - Order Hall resources (Legion)
* resources - War resources (BfA)
* maxxp - XP required to level
* xp - Current XP

For example:

/calc 1650 + 2200 - honour
[SimpleCalc] 1650 + 2200 - honour = 3078

SimpleCalc utilizes an expression evaluator written by computer scientist, John Pormann. The expression evaluator is a Lua interpretation of the shunting yard algorithm.
This allows you to use advanced math expressions.

For example: (Assume you have 100,000 gold)
/calc 

Comments, suggestions and bug reports are most welcome!


--[ License ]--

SimpleCalc is provided under the MIT license. In essence, do what you will
with this software, but please give credit to the original author, guildworks [https://mods.curse.com/members/guildworks].
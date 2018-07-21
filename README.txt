SimpleCalc - Copyright (c) 2018

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

Support for user defined variables was added in version 0.4. Variables persist across sessions, so you can save values for later use really easily.
To save a value or calculation: /calc addvar x = 1024 or /calc addvar x = 32*2+64

Comments, suggestions and bug reports are most welcome!

--[ License ]--

SimpleCalc is provided under the MIT license. In essence, do what you will
with this software, but please give credit to the original author, skylerh15
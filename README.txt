SimpleCalc - Copyright (c) 2019

--[ Description ]--

SimpleCalc is a simple mathematical calculator addon for World of Warcraft.
In essence, it's a slash-based utility which allows you to do maths!

Example usage and response:

/calc 10415 - 9843 + 12
[SimpleCalc] 10415 - 9843 + 12 = 584

A selection of in-game values has been added to make life easier when doing certain calculations. You can use keywords in place of numbers for the following values:

* health (or hp) - Your maximum Health points
* mana (or power) - Your maximum Mana, Rage, Focus, Energy, or Runic Power
* gold - Total gold (1g 50s would be displayed as 1.5 gold)
* silver - Total silver (1g 50s would be displayed as 150 silver)
* copper - Total copper (1g 50s would be displayed as 15,000 copper)
* maxxp - XP required to level
* xp - Current XP
* str, agi, stam, int, spirit, armor - Your character's stats

For example:

/calc 1650 + 2200 - mana
[SimpleCalc] 1650 + 2200 - mana = 3078

Support for user defined variables was added in version 0.4. Variables persist across sessions, so you can save values for later use really easily.
To save a value or calculation: /calc addvar x = 1024 or /calc addvar x = 32*2+64

Comments, suggestions and bug reports are most welcome!

--[ License ]--

SimpleCalc is provided under the MIT license. In essence, do what you will
with this software, but please give credit to the original author, skylerh15

SimpleCalc - Copyright (c) 2008 GuildWorks.co.uk

--[ Description ]--

SimpleCalc is a simple mathematical calculator addon for World of Warcraft.
In essence, it's a slash-based utility which allows you to do maths!

Example usage and response:

/calc 10415 - 9843 + 12
[SimpleCalc] 10415 - 9843 + 12 = 584

A selection of in-game values has been added to make life easier when doing certain calculations. You can use keywords in place of numbers for the following values:

* honour / honor - Total honour points available to spend
* justice (or jp) - Total justice points available to spend
* valor (or vp) - Total valor points available to spend
* conquest (or cp) - Total conquest points available to spend
* vpcap - Amount of valor that can be earned that week
* cpcap - Amount of conquest that can be earned that week
* achieves (or ap) - Your total achieve points
* health - Your maximum Health points
* mana (or power) - Your maximum Mana, Rage, Focus, Energy, or Runic Power
* gold - Total gold (1g 50s would be displayed as 1.5 gold)
* silver - Total silver (1g 50s would be displayed as 150 silver)
* copper - Total copper (1g 50s would be displayed as 15,000 copper)

For example:

/calc 1650 + 2200 - honour
[SimpleCalc] 1650 + 2200 - honour = 3078

SimpleCalc works on equations left to right, so '10 * 3 + 2' would be broken
down into two sums: '10 * 3', then '30 + 2'. Support for brackets is not yet
in place, but this shouldn't affect every day calculations.

Comments, suggestions and bug reports are most welcome!


--[ License ]--

SimpleCalc is provided under the MIT license. In essence, do what you will
with this software, but please give credit to the original author, guildworks [https://mods.curse.com/members/guildworks].

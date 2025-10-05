# Description
*Event: https://ldjam.com/events/ludum-dare/58*
*Starts: Saturday October 4th; starts at 1:00 AM EEST*
*Ends: Monday at 1:00 AM EEST*
*Theme: Collector*
*Format: The Compo - 48 hour deadline, solo, from scratch (as much as is reasonable), and share your source code.*

## Used resources:
* Imprima-Regular.ttf from https://www.1001freefonts.com/imprima.font
* mazes from https://www.mazegenerator.net/

## Ideas:
* walk around maze(s) (mario, sokoban, flappybird, pacman, keen, wolfenstain/doom ?)
* collect items
* shoot monsters
* jump over pits and on platforms?
* a timer expires (remaining time gives bonus points)?
* until the player hits some dangerous objects/pits/monsters?
* each item gives some ability/score

## Alternative idea:
Goal: collect all the garbage items from a garden/forest into different bins.
A time bar gradually fills up, when it is full, or when all items are cleared,
the game round ends and stats are shown. After a click on the stats, another level loads up,
and the game continues.

Soft ambient forest sounds/music is played in the background the whole time.
Sounds can be toggled on/off with the `m` key, or by clicking a button, next to the bins.

Each level has a different background picture. The picture has transparent zones (mainly ground).
Those will be the places, where the items will be placed.
All items are randomly placed on the screen (but only in the transparent zones).
Each item has a bar at the top, that gradually shrinks.
Items gradually become transparent, after their bars shrink, until they disappear completely.
Different items last for longer (the bars are the same length, but shrink at a different rate).
4 bins at the bottom of the screen, each selectable by clicking, or by the 1,2,3,4 keys.
Each item has to be clicked, while the matching bin at the bottom is selected -> + points.
If the wrong item is put in a bin, -> - points.
Different sounds are played when items are matched to the bins, like "nice", "yesss", "Yippee" etc.
Different sounds are played when items are misplaced, like "nooo", "tz", "nope" etc.

On level change, the difficulty increases by increasing the amount of initial items, and reducing the amount of available time.

## Collectable items:
* seeds
* nuts
* garbage (recycle bin/trash bag/pile)
* money (coins/wads of cache/diamonds)
* stamps
* cars (vintage/racing/supercars)
* comics
* badges
* likes
* songs
* books
* souls

## TODO:
* Gameplay
* Sound/effects

## DONE:
* Music

# MagnetDipole

---

### Copyright 2015 ME !

### IF YOU HAPPEN TO FIND REUPLOADS WITH DIFFERENT ORIGIN REPORT THEM TO ME IMMIDEATELY !!!

![MagnetDipole][ref-screen]

### Description

This addon can give you the ability to have have an entity that
simulates real magnets with real north and south poles not like
the old magnetize tool. The simulation is calculated according to
[Gilbert's model][ref-gilbert] when both poles are small enough to be represented
as single points in space where the fore equation is used from the
classical mechanics to improve overall `TOOL:Think()` hook performance.

#### What is this thing really for ?
This is a tool that can turn entities to a real magnets with south and north pole,
not like the magnetize tool.

#### It won't spawn dude, help !
Emm, Use right click to select a model filter

#### What are those OBB Offsets?
Local vector defining the positions of the poles relative to the OBB centre.

#### I get the other things, but what is that search radius all about?
When this thing is greater than `0`, you have active magnet, which means that it is searching
for other [`entities`][ref-ent] of the same [`class`][ref-entclass] and calculating some
[`forces`][ref-force] on its [`poles`][ref-poles], set this to `0` to get a passive
( non-searching magnet dipole). *Beware, that the active dipoles will still find the
`passive` AND `active` ones **IF THEY ARE WITHIN** their `search radius`, dependent by their own data.*

#### HUD color legend provides player with current trace model status:

1. **Cross**
      1. ![][ref-gr] `Trace model is enabled  for a magnet`
      2. ![][ref-ye] `Trace model is disabled for a magnet`
      3. ![][ref-cy] `Model filter is not selected`
2. **Circle**
      1. ![][ref-mg] `Trace is a magnet`
      2. ![][ref-gr] `Trace is a prop`
      3. ![][ref-ye] `Trace is world`
      4. ![][ref-cy] `Trace is nether of above`

[ref-screen]: https://raw.githubusercontent.com/dvdvideo1234/MagneticDipole/master/data/magnetdipole/tools/pictures/secreenshot.jpg
[ref-gilbert]: http://en.wikipedia.org/wiki/Force_between_magnets
[ref-ent]: https://developer.valvesoftware.com/wiki/Entity
[ref-entclass]: https://wiki.facepunch.com/gmod/Entity:GetClass
[ref-force]: https://en.wikipedia.org/wiki/Force_between_magnets
[ref-magnet]: https://en.wikipedia.org/wiki/Magnet
[ref-poles]: https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/VFPt_cylindrical_magnet_thumb.svg/330px-VFPt_cylindrical_magnet_thumb.svg.png
[ref-cy]: https://via.placeholder.com/18x18.png/00ffff/000000?text=%20
[ref-mg]: https://via.placeholder.com/18x18.png/ff00ff/000000?text=%20
[ref-ye]: https://via.placeholder.com/18x18.png/ffff00/000000?text=%20
[ref-gr]: https://via.placeholder.com/18x18.png/00ff00/000000?text=%20

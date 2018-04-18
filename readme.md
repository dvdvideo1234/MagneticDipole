# MagnetDipole

---

#### Copyright 2015 ME !

#### IF YOU HAPPEN TO FIND REUPLOADS WITH DIFFERENT ORIGIN REPORT THEM TO ME IMMIDEATELY !!!

![MagnetDipole](https://raw.githubusercontent.com/dvdvideo1234/MagneticDipole/master/secreenshot.jpg)

#### On the Steam WS: https://steamcommunity.com/sharedfiles/filedetails/?id=363567027

#### Got sick of the boring Magnetize tool ( Yeah me to, it can't repel stuff ... ), this is for you !

#### This tool is used to create Magnetic dipole SENTs. What are those, you can see right here:

http://en.wikipedia.org/wiki/Force_between_magnets ( Gilbert Model )

#### When the two poles are insanely small, that they can be represented as a single points in space, so you get this thing :)

#### **SUPPORTS WIRE !**

#### What is this thing really for ?
This is a tool that can turn entities to a real magnets with south and north pole,
not like the crappy Magnetise tool.

#### It won't spawn dude, help !
Emm, Use right click to select a model filter

#### What are those OBB Offsets?
Local vector defining the positions of the poles relative to the OBB centre.

#### I get the other things, but what is that search radius all about?
When this thing is greater than 0, you have active magnet, which means that it is searching
for other SENTs of the same class and calculating some forces on its poles,
set this to 0 to get a passive ( non-searching magnet dipole).
*Beware, that the active dipoles will still find the `passive` AND `active` ones
**IF THEY ARE WITHIN** their `search radius`, dependent by their own data.*

HUD Color Legend:

Cross:
* Green  - trModel is enabled  for a magnet
* Yellow - trModel is disabled for a magnet
* Cyan   - We do not have model selected

Circle:
* Margenta - Trace is a magnet
* Green    - Trace is a prop
* Yellow   - Trace is world
* Cyan     - Trace is nether of above

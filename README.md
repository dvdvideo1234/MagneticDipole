MagnetDipole
===============

<br>Copyright 2015 ME !

<br>IF YOU HAPPEN TO FIND REUPLOADS WITH DIFFERENT ORIGIN REPORT THEM TO ME IMMIDEATELY !!! 

![MagnetDipole](https://raw.githubusercontent.com/dvdvideo1234/MagneticDipole/master/secreenshot.jpg)

<br>
<br> On the Steam WS: https://steamcommunity.com/sharedfiles/filedetails/?id=363567027
<br>

Got sick of the boring Magnetize tool ( Yeah me to, it can't repel stuff ... ), this is for you ! 

This tool is used to create Magnetic diopole SENTs. What are those, you can see right here: 

http://en.wikipedia.org/wiki/Force_between_magnets ( Gilbert Model ) 

When the two poles are insanely small, that they can be represented as a single points in space, so you get this thing :) 

SUPPORTS WIRE ! 
```
Q: What is this thing really for ?
A: This is a tool that can turn entities to a real magnets with south and north pole,
   not like the crappy Magnetise tool.

Q: It won't spawn dude, help ! 
A: Emm, Use right click to select a model filter 

Q: What are those OBB Offsets? 
A: Local vector defining the positions of the poles relative to the OBB centre. 

Q: I get the other things, but what is that search radius all about? 
A: When this thing is greater than 0, you have active magnet, which means that it is searching
   for other SENTs of the same class and calculating some forces on its poles,
   set this to 0 to get a passive ( non-searching magnet dipole). 
N: Beware, that the active dipoles will still find the passive AND active ones
   IF THEY ARE WITHIN their search radius, dependant by their own data. 
```
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

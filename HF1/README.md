# vizulab
A házifeladat nekem nagyon lassan futott, úgyhogy erre tessék felkészülni! :D 
Minden optimalizálási javaslatot szívesen fogadok akár a határidőn túl is.

# Módok
A házifeladat egyes pontjainak implementációi és további más megoldások között a megfelelő számok lenyomásaival lehet váltogatni.

0: Box
A sugár csak a befoglaló kockában lépked, ezért ezzel kellett két metszé pontot számolni.
Nekem a tér úgy van transzformálva, hogy a box a (0,0,0) -> (1,1,1) térben legyen.
A számolt metszéspontokat az első és hátsó metszéspont, mint szín fele-fele arányos kombinációjával szemléltetem.

1: Metszés
A következő lépés az agy metszése volt.
Egy színnel jelöltem, ha a sugár metszi az agyat.

2: Metszés helye
Egy pontosabb módszerrel vizsgálom, hogy a metszés pont hol található.
Itt is a metszés pont koordinátáival, mint színnel szemléltetem.

3: Gradiens
Ha elég pontos már a metszésünk, akkor a gradiens is az lesz.
A gradienst több féle képpen is számítottam, de végül megmaradtam a hat irányú vizsgálatnál. 
(volt 27-es és 3-mas is, ezek bent maradtak a kódban kikommentelve)
A kapott gradiens normalizálva is van, ezt használjuk szín ként.

4: Phong irányított fénnyel
Az alap phong árnyalás ambiens, diffúz és spekuláris komponenssel.
A fény az (1,1,1) irányból érkező fehér fény.
A többi paraméter fellelhető a shader elején.

5: Phong pontszerű fényforrással
Az alap phong árnyalás ambiens, diffúz és spekuláris komponenssel.
A fényforrás a (3,3,3) pontban van, fénye 6 erős és távolsággal négyzetesen gyengül.
A többi paraméter fellelhető a shader elején.

6: MatCap
A textúrát a megfelelő mappában helyeztem el.
Egy alapvető fémes felület színei.
Mivel már kör vetülete ként töltöttem le, ezért könnyű dolgom volt:
A gradiens x, y koordinátáit elfeleztem és eltoltam 0,5-tel.
Ezzel címeztem meg a textúrát.

7: Onion
A három intenzzitás határom a 0.2, 0.4 és a 0.6 voltak, ezek osztották a teret 4 részre.
Őket sorrendben r, g, b -vel színeztem.
Egy integer számlálóval mértem, hogy éppen melyik térben vagyok és ha váltottam, 
akkor a két tér közül a kisebb intenzitásúnak megfelelő színt választottam.


8:Önárnyalás
Miután meg van az aggyal a metszéspont, elindítottam egy sugarat a fény felé.
Amint újra metszi az agyat visszatérek fekete színnel.
Ha nem metszi, akkor az irányított fényes phong modellel számítok.

9: Üres
Nem ábrázol semmit, de nem bírtam ki, hogy kihagyjam a kilences gombot.
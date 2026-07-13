Mijn project (Mprjv65)[/category/mprjv65] is inmiddels toe aan Observability. Ik heb daar allerlei dingen voor uitgezocht, en ik heb zelfs als wat dashboards gemaakt in Grafana voor onderwerpen die mij interesseren. Denk aan ingress data over bezoekers aantallen, en daar aan gerelateerd zoekmachines die mij bezoeken. Ik zit namelijk met een stille frustratie dat Google mij tot nu toe lijkt te negeren, mijn site wordt in iedergeval niet geindexeerd.

Dat daar gelaten: ik heb ook het project (MySite)[/category/mysite]. De categorie waar dit artikel voor geschreven is. MySite is een workload van het Mprjv65 cluster. MySite is een Perl applicatie die het framword Dancer2 gebruikt en dBIC als database ORM. En aangezien ik het zelf maak heb ik dus invloed op wat het aan logging doet.

Afhankelijk van het level logt het Dancer framework zelf ook dingen. Tijdens ontwikkeling maak ik daar dankbaar gebruik van. Ik heb dan zelfs een uitbreiding om het log netjes in te kleuren zodat ik sneller weet waar ik naar kijk. Maar dit soort logs zijn forensisch van aard. Ze vertellen je over fouten, route afhandeling, dergelijke zaken. Onmisbaar als er iets fout gaan.

Observabilaty kun je op hooflijnen opdelen in drie domeinen:
- De klassieke syslog achtige meldingen. Zoals ondermeer de logging van het Dancer 2 framework, maar ook logging die je zelf genereert. Het liefst naar stdout als JSON zodat Loki ze kan oppikken.
- Dan heb je metrics. Dit is het domein van Prometheus. Je moet dan denken aan hoeveel requests zijn er en hoe lang doet het systeem erover om een request (of een deel ervan) af te handelen. Deze metrics deel je met Prometheus via een route handler die de counters en histogrammen deelt.
- Dan heb je nog iets wat traces genoemd wordt. Ik moet bekennen dat ik mij hier nog niet mee bezig gehouden heb.

## HTTP Requests
De meest voor de hand liggende event die je kun monitoren en metrics voor kunt maken is de request. Dancer2 voorziet hiervoor in met een aantal hooks die je kun gebruiken. Er zijn hooks om code uit te voergen voor en na het request, maar ook voor en na het renderen van een template. 

In de before hook stel ik 2 dingen in:
- een nauwkeurige timestamp (het gaat om miliseconden)
- en een UUID als request_id.

In de after hook zijn deze 2 waarden bekend, maar ook:
- het tijdstip waarop de request afgehandeld is, dus kun je de duur berekenen.
- de result code (200, 301, 404 enz)
- de UserAgent
- het IP van de client
- enz

Deze gegevens stop ik in een JSON en geef ik als event door aan een object wat ik gemaakt heb voor de afhandeling.

## Observability.pm
Dit is een Moo object wat de event afhandeld. Het weet niets van Dancer2, is daar volledig onafhankelijk van . Het ontvangt een event en handelt dat af, meer niet. De instantie wordt wel binnen een Dancer2 context gemaakt, daarbij heb je dingen als de config dus wel beschikbaar.

Voor Loki, of welke log lees methode je ook gebruikt, gaat dit complete JSON object in eerste instantie naar stdout. Loke kan dit lezen in Kubernetes en er allerlei leuk dingen mee doen. Je kun er dashboards mee maken, of LogQL gebruiken voor ad-hoc analyse. 

Voor metrics, in mijn geval Prometheus, werkt dit anders. Die verwacht allerlei counters en histogrammen, die dan via een route opgehaald kunnen worden. Counters zijn tellers als hoeveel requests zijn er geweest. Bij histogrammen moet je denken aan:
- hoeveel requests duurde korten dan 1 ms
- hoeveel requests duurde korten dan 10 ms
- enz.

Daarvoor had ik het Moo object wat data strucuren gegeven. 2 Public methods:
- event: voor het ontvangen van een event
- prometheus_export: voor het uitvoeren van counters en histogrammen, gekoppeld aan een route handler.

In memory, lekker snel. Lekker snel inderdaad, maar niet betrouwbaar zoals bleek.

Dat metrics endpoint kun je uiteraard ook gewoon in de browser bekijken. En elke request voor de metrics is gelijk ook een request wat geteld wordt. Na een tijdje F5 drukken viel mij op dat het aantal request steeds opnieuw begon te tellen. In eerste instantie verbazing, maar al snel drong het tot mij door dat er blijkbaar bij elke reset van de counter een nieuwe worker thread begon. Niet echt betrouwbaar dus.

## Store::Memcached
Nu gebruik ik Memcached om persistent sessions te krijgen. En ik bedacht mij dat dit ook bruikbaar zou zijn voor de semi persistent opslag van counters en histogrammen. In Engines->Sessions->Memcached heb ik al een complete configuratie beschibaar om deze te kunnen gebruiken. Het enige wat ik toe heb moeten voegen is een nieuwe namespace voor observability. Niet helemaal zuiver omdat in de configuratie van de session engine te zetten, maar het alternatief was 2x nagenoeg hetzelfde configureren. De keuze was snel gemaakt.

Vervolgens heb ik het Moo object Store::Memcached gemaakt. Een instantie van dit object wordt meegegeven in de constructor van Observability.pm Dit object heeft de volgende methods als interface:
- get: om een counter te lezen
- set: om een counter te schrijven
- inc: om een counter te verhogen
- add: om op te tellen bij een counter

De laatste method, add, is omdat Memchached bij een inc niet goed omgaat met floats. Dan krijg je rare resultaten.

Door een instantie van  Store::Memcached aan Observability.pm te geven hoeft deze laatste niet te weten welke backend er nu eigenlijk gebruikt wordt. Als ik volgende maand beslis om Redis te gaan gebruiken dan maak ik een Store::Redis. Zolang deze maar dezelfde interface heeft (get, set, inc en add) hoef ik verder niets te veranderen.

## The usual suspects.
Via Memcached kreeg ik wel betrouwbare counters voor de requests. En dan ga je, ik wel, gelijk neuzen natuurlijk. Sommige request duurden wel erg lang. Ik heb tijden gezien van 2,5 seconden, wat een eeuwigheid is. Omdat ik sqlite gebruik als database backend was dit mijn eerste verdachte, hier ging ik induiken.

## dBIC debug
Nu praat ik niet direct tegen sqlite, daar is DBI voor. Sterker nog: ik gebruik dBIC als ORM. Een extra abstractie. En dBIC heeft niet een mechanisme met hooks zoals Dancer2 die heeft.

Na wat, heel wat, googlen vond ik echter een alternatief: elke query in dBIC komt langs wat ze de storage noemen, en aan de storage kun je een debug object hangen die je zelf kunt schrijven. Hierna zet je debug voor de storage aan en vervolgens worden er voor elke query de methodes query_start en query_query aangroepen in het de zelf geschreven object. 

Dat zelf gemaakte object extends 'DBIx::Class::Storage::Statistics' en krijgt in zijn constructor een instantie mee van Observability.pm.
In query_start stel je vervolgens de start tijd in. En in query_end kun je de duur van de query berekenen. Eventueel kun je nog uitzoeken wat voor soort query het was om vervolgens via de even methode van de  instantie van Observability te laten verwerken. Jammer genoeg is de request_id uit de Dancer2 hook before niet beschikbaar, dat zou voor correlatie heel prettig zijn.

Als dit complex klinkt? Dat begrijp ik. Toen ik het systeem eenmaal doorhad koste de implementatie ervan mij minder tijd dat de zoektocht op google. Neem anders even een kijkje in mijn GitHup repo. Ik geef op het einde van dit artikel nog een overzicht van de betrokken bestanden.

## Guilthy as charged?
Nou nee. Toen ik eenmaal de cijfers beschikbaar had bleek de tijd die ik spendeerde aan queries een fractie te zijn van de totale reques tijd. Sqlite presteerde een stuk beter dan ik op de voorhand voorspeld zou hebben. Sqlite was zelfs zo snel dat ik mijn Observability object aan moest passen: SQlite was orders van grootte sneller dan een HTTP request. Ik moest voor database queries een andere tijdschaal instellen voor het histogram.

Maar ik wist nog altijd niet wat dan WEL zoveel tijd op slokt.

## Markdown parsing.
Het is een ontwerp besluit van mij om artikelen (en pagina's) op te slaan als markdown. Ik vind markdown een prettig formaat om in te schrijven, en door op te slaan als markdown blijf ik zo dicht mogelijk bij de bron. 
Voordat je dit in een browser toon moet het dus wel gerendered worden als HTML. En de beste optie die ik daarvoor kan vinden is PanDoc. En dat heeft één heel groot nadeel: ik ken geen Perl module die dit kan. Er zelf een schrijven ging mij te ver, best next thing was een nieuwe thread starten en de Pandoc binairy dit laten oplossen. En dit kost natuurlijk tijd... dacht ik.

Het implementeren van observability rond het renderen was een eitje. Er is één enkele functie die dit doet, door aan de start van de functie de start tijd op te nemen zodat ik aan het einde de duur kon berekenen was zo gedaan. Resultaten via de inmiddels bekende event methode van Observability.pm later verwerken.

Er vielden 2 dingen op:
- Het renderen ging redelijk snel: zeg 10% van de request tijd per render job.
- Er waren héél veel render jobs.

Dat zorgde voor enige verbazing bij mij, tot ik mij realiseerde welke pagina's het betrof: 
- artikel lijst
- een categorie overzicht

Dat zijn allemaal pagina's die de meta data tonen van een aantal, soms groot aantal, artikelen. En als die artikelen hebben allemaal een abstract die ik toon. En elk abstract ging door de Pandoc rendering, ook al is het voor 99% platte tekst. 

## Conclusie
Wat vandaag begon als "ik wil wat test data voor observability hebben" eindigde dus in "waaron render ik in vredesnaam platte tekst". Met andere woorden "Meten is weten". Het kubernetes aware maken van MySite betaalde zich onmiddelijk uit. 

Vanaf nu render ik geen abstracten meer. Ik moet nog wel iets verzinnen om die platte tekste enigzins redelijk weer te geven. HTML trekt zich nu eenmaal niet veel aan van end of lines.

## Hoe nu verder
Dit gaat een vervolg hebben in mijn Mprjv65 project. Daar moeten Grafana dashboards gemaakt worden voor de gegevens die ik nu kan gaan verzamelen uit MySite. Prometheus moet daar zelfs nog geinstalleerd worden. 

Wat is mij verder afvraag is dit: MySite heb ik 100% controlle over, die maak ik immers zelf. Maar ik heb ook een Wordpress site in dat cluster staan. Een magneet voor scrapper en hackers. Ideaal om te analyseren. Maar hoe krijg ik data uit een framework wat geschreven is 10 jaar voor Kubernetes uberhaupt bestond? Ik heb al wat hints gevonden, maar dat komt zeker een vervolg op.

## So as seit is
Hierbij nog een lijstje van bestanden die ik gewijzigd heb om MySite kubernetes aware te krijgen.
|/lib/MySite.pm| Initialisatie van het $obs object en het dBIC debug object|

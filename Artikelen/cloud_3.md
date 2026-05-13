## En hoe vul ik dat allemaal in

## Intro
Tot nu toe heb ik Mprjv65 benaderd vanuit een abstract perspectief: wat bedoelen we eigenlijk met “de cloud”, en hoe is die omgeving gelaagd opgebouwd. In dit artikel maak ik de stap van denkmodel naar invulling.

Niet door een ideale architectuur te presenteren, maar door te laten zien hoe ik die lagen zelf concreet invul binnen de context van Mprjv65. Laag voor laag, met expliciete keuzes en duidelijke beperkingen.

De schaal is bewust klein. Dat maakt het mogelijk om dingen zelf te doen en zichtbaar te houden wat in grotere omgevingen vaak uit het zicht verdwijnt. Tegelijkertijd houd ik steeds in het achterhoofd wat schaalbaarheid zou betekenen, ook als die hier niet direct nodig is.

Dit artikel beschrijft dus geen blauwdruk, maar een praktische invulling van het eerder geschetste model: hoe dat abstracte raamwerk er in mijn geval daadwerkelijk uitziet.

Vanaf dit punt wordt het abstracte model concreet en geef ik per laag invulling met de middelen die ik ter beschikking heb.


## Laag 0: data centrum
Hier kan ik kort over zijn: dit is de oude slaapkamer van mijn dochter. Kantoor annex datacentrum. Stroomvoorziening is mijn huisnet, voor koeling kan ik het raam open zetten.
Absoluut geen productie omgeving dus, maar voor mijn testen met Mprjv65 volstaat het.

## Laag 1: Compute opslag en netwerk
Dit is de laag met CPU, RAM en opslag. Ik zet hier mijn thuisnetwerk voor in en een oude desktop. Waarschijnlijk gaat mijn SAN nog een rol spelen voor opslag, maar voorlopig doe ik het met de opslag die in de desktop aanwezig is. Op de desktop is een hypervisor aanwezig zodat ik niet "op het ijzer" hoef te werken.

In een productieomgeving worden deze lagen vrijwel altijd uitbesteed. Dat is logisch: schaal, beschikbaarheid en beheer zijn beter en efficiënter georganiseerd bij gespecialiseerde aanbieders dan in een eigen omgeving.

Binnen Mprjv65 maak ik hier bewust een andere keuze. Door deze laag zelf in te vullen, blijven de onderliggende details zichtbaar en ligt de verantwoordelijkheid volledig bij mij. Dat is geen uitspraak over wat beter is, maar een bewuste keuze om inzicht en eigenaarschap te behouden.

In deze invulling van laag 1 is schaalvergroting geen eigenschap van de oplossing zelf. Die beperking is bewust: het doel is hier niet groeien, maar begrijpen.

Schaalbaarheid blijft daarmee een eigenschap van het model, niet van deze specifieke implementatie.


## Laag 2: infrastructuur en abstractie

Op de oude desktop draaien meerdere virtuele machines. Home Assistant leeft daar, en tot voor kort ook een Apache‑server voor mijn website. Die server is inmiddels vervangen door een opzet waarin Kubernetes wordt gebruikt. Daar draait nu mijn website: een Perl/Dancer2‑applicatie.

Het containerizen van die applicatie was de directe aanleiding voor Mprjv65. Door de applicatie in een container onder te brengen, werd de scheiding tussen applicatielogica en infrastructuur expliciet.

Bij het werken met meerdere containers liep ik echter tegen een beperking aan. Bepaalde containers konden niet starten zolang andere containers nog niet draaiden. Deze impliciete afhankelijkheden maakten het geheel fragiel en vroegen om handmatige volgorde en interventie. Op dat punt werd duidelijk dat containerisatie alleen niet voldoende was.

Die frustratie was de aanleiding om orkestratie te onderzoeken. Zowel Docker Swarm als Kubernetes kwamen daarbij in beeld. Uiteindelijk heb ik gekozen voor Kubernetes, omdat het afhankelijkheden en levenscycli **expliciet beschrijft** in plaats van veronderstelt.

In de praktijk gebruik ik hiervoor MicroK8s, de lichtgewicht Kubernetes‑distributie van Canonical. Die keuze past bij de schaal van de omgeving en de beschikbare hardware, terwijl het onderliggende Kubernetes‑model hetzelfde blijft.

Met deze stap verschuift de aandacht van systemen naar beschrijvingen. Niet langer *wat staat waar*, maar *wat moet er draaien*, onder welke voorwaarden en met welke afhankelijkheden. Daarmee wordt deze laag in hoge mate onafhankelijk van de onderliggende hardware.

In dit artikel blijft het bij deze overgang. Wat Kubernetes verder mogelijk maakt — zoals herstartlogica, schaalmechanismen en clustering — vraagt om een aparte verdieping en komt later aan bod.

### Laag 3: diensten en applicaties

Wanneer het over containers en Kubernetes gaat, wordt de discussie vaak teruggebracht tot tooling: Docker of Kubernetes. Die framing mist waar het in deze laag eigenlijk om draait.

Containers zijn geen doel op zich, maar een verpakkingsvorm voor applicatielogica. Orkestratie — zoals die in laag 2 wordt aangeboden — zorgt ervoor dat deze containerized applicaties op een samenhangende en voorspelbare manier kunnen draaien. Laag 3 bouwt daarop voort.

In deze laag ontstaan de diensten die voor gebruikers zichtbaar en herkenbaar zijn. Niet als losse containers, maar als samenhangende functionaliteit: het kunnen verzenden en ontvangen van e‑mail, het opslaan en bewerken van documenten, en het samenwerken met anderen. Dit is de laag die gebruikers ervaren als “de cloud”.

Dat deze diensten zo worden ervaren, is het gevolg van de onderliggende abstractie. Infrastructuur en orkestratie blijven buiten beeld; de complexiteit wordt niet verwijderd, maar verborgen. Laag 3 is daarmee het punt waar abstractie waarde krijgt: waar techniek transformeert in bruikbare functionaliteit.

Veelgebruikte samenwerkingsplatformen zoals Microsoft 365 en Google Docs passen precies in deze laag. Het zijn krachtige, ver ontwikkelde omgevingen waarin applicaties, data en identiteit diep geïntegreerd zijn. Juist die integratie maakt ze productief en aantrekkelijk in het dagelijks gebruik.

Tegelijkertijd maakt diezelfde integratie deze diensten niet cloud‑agnostisch. Ze zijn onlosmakelijk verbonden met het onderliggende platform waarop ze draaien. Dat is geen tekortkoming, maar een bewuste ontwerpkeuze, met als consequentie een sterke afhankelijkheid van één leverancier.

Binnen Mprjv65 is het doel niet om die keuze te bekritiseren of te ontkrachten. De vraag die hier centraal staat is een andere: wat betekent het wanneer deze samenwerkingslaag wegvalt, verandert of niet langer beschikbaar is? Veel samenwerkingsfunctionaliteit rust op aannames waar gebruikers nooit expliciet over nadenken, zoals wie een document mag openen, wie dat juist niet mag, en hoe die beslissingen tot stand komen.

Het bestaan van dominante platformen betekent bovendien niet dat er geen alternatieven zijn ontwikkeld. In dezelfde periode zijn tal van andere samenwerkings‑, document‑ en identity‑oplossingen volwassen geworden — niet als één integraal platform, maar als los koppelbare componenten. Dat vertegenwoordigt geen achterstand, maar een andere architecturale benadering.

Mprjv65 onderzoekt die benadering. Niet als vervanging van bestaande platforms, maar als referentiekader: om te begrijpen waar afhankelijkheden ontstaan, en om zichtbaar te maken dat deze laag ook anders ingevuld kan worden — met andere afwegingen en andere consequenties.
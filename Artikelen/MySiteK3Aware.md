# Observability, SQLite en de verkeerde verdachte

Mijn project (Mprjv65)[/category/mprjv65] begint inmiddels volwassen te worden. Een van de onderdelen die nog grotendeels ontbrak was observability.
Dat klinkt ingewikkelder dan het is. Eigenlijk wilde ik antwoord kunnen geven op een paar eenvoudige vragen:

- Hoeveel requests verwerkt mijn site?
- Hoe lang duren die requests?
- Waar gaat die tijd eigenlijk naartoe?

Voor een hobbyproject zijn dat misschien geen levensbelangrijke vragen, maar ik merk dat ik steeds vaker tegen situaties aanloop waarbij mijn gevoel iets zegt, terwijl ik geen enkele meting heb om dat gevoel te bevestigen.
Daar komt nog iets bij. Een van de workloads in het cluster is MySite, mijn zelfgeschreven CMS op basis van Perl, Dancer2 en dBIC. Omdat ik de applicatie zelf bouw, heb ik volledige controle over wat er gemeten wordt. Dat maakt het een ideaal speelveld om observability in de praktijk te brengen.

## Drie vormen van observability

Observability wordt meestal opgesplitst in drie onderdelen:

- Logs
- Metrics
- Traces

Logs zijn de klassieke syslog-achtige meldingen. Dancer2 produceert die zelf al en ik voeg er ook eigen logging aan toe. Tijdens ontwikkeling zijn ze onmisbaar. Ze vertellen wat er gebeurt, welke route afgehandeld wordt en waar fouten optreden.

Metrics zijn iets anders. Daar gaat het niet om losse gebeurtenissen, maar om aantallen en trends. Hoeveel requests zijn er geweest? Hoeveel leverden een foutmelding op? Hoe lang duurde een request gemiddeld?
Prometheus is hier de bekende speler. Via een endpoint stelt een applicatie counters en histogrammen beschikbaar. Grafana kan die vervolgens visualiseren.

Het derde onderdeel zijn traces. Daar heb ik mij voorlopig nog niet serieus mee bezig gehouden. Waarschijnlijk wordt dat een toekomstig project.

## HTTP requests meten

De meest logische plek om te beginnen is het meten van HTTP requests.
Dancer2 biedt hiervoor een aantal hooks waarmee code vóór en na een request uitgevoerd kan worden.
In de before hook leg ik twee zaken vast:

- een tijdstip met hoge nauwkeurigheid
- een unieke request-id

Wanneer de request klaar is, zijn aanvullende gegevens beschikbaar:

- de totale duur
- de HTTP statuscode
- het IP-adres
- de User-Agent
- en nog wat andere metadata

Van die gegevens maak ik een JSON-event dat vervolgens wordt doorgegeven aan een apart object dat verantwoordelijk is voor de verwerking.

## Een aparte observability-laag

Voor de verwerking van die events heb ik een Moo-object geschreven: Observability.pm. Dat object weet niets van Dancer2. Het ontvangt een event en doet daar vervolgens iets mee.

Voor logging is dat eenvoudig. Het volledige JSON-object wordt naar stdout geschreven zodat Kubernetes en Loki het kunnen oppikken. Daardoor kan ik later zoeken, filteren en dashboards bouwen.

Metrics werken anders.
Prometheus verwacht counters en histogrammen.
Een counter houdt bijvoorbeeld bij hoeveel requests verwerkt zijn.
Een histogram verdeelt metingen over buckets, bijvoorbeeld:

- korter dan 1 ms
- korter dan 10 ms
- korter dan 100 ms
- enzovoort

Om die gegevens beschikbaar te maken kreeg het object twee publieke methodes:

- event
- prometheus_export

De eerste verwerkt gebeurtenissen. De tweede levert de counters en histogrammen aan Prometheus.

Dat werkte verrassend snel.

Totdat ik het metrics-endpoint gewoon eens in mijn browser begon te bekijken.

## Metrics die verdwenen

Iedere keer dat ik het endpoint ververste zag ik iets vreemds.
De counters leken weer opnieuw te beginnen.
Mijn eerste reactie was verbazing. De tweede was het besef dat ik eigenlijk precies zag wat er gebeurde. De metrics werden in geheugen opgeslagen.

Dat is snel.

Maar in een omgeving met meerdere workers blijkt dat niet bepaald betrouwbaar. Zodra een nieuwe worker actief wordt, krijg je ook een nieuwe set tellers.
Mijn mooie metrics waren dus niet zo persistent als ik dacht.

## Memcached als opslaglaag

Voor sessies gebruikte ik al Memcached.
Daarmee ontstond een voor de hand liggende gedachte:
Waarom niet dezelfde techniek gebruiken voor counters en histogrammen?
Daarvoor heb ik een aparte opslaglaag gemaakt met een eenvoudige interface:

- get
- set
- inc
- add

Observability weet daardoor niet of de gegevens in Memcached, Redis of iets anders terechtkomen.

Het enige wat telt is dat de opslaglaag dezelfde interface aanbiedt. Dat maakt het verwisselen van de backend later eenvoudig.

Belangrijker nog: mijn metrics werden opeens betrouwbaar.

## De gebruikelijke verdachten

En natuurlijk begon ik meteen te neuzen in de cijfers.
Sommige requests duurden meer dan twee seconden. Dat is een eeuwigheid.
Mijn eerste verdachte was SQLite.

SQLite heeft geen geweldige reputatie zodra mensen het woord "performance" laten vallen. Bovendien gebruik ik daar ook nog een ORM-laag bovenop. De kans dat daar tijd verloren ging leek groot.

## SQLite onder de loep

Om dat uit te zoeken moest ik weten hoe lang individuele databasequeries duurden.
Gelukkig bleek dBIC daarvoor een uitbreidingspunt te hebben. Door een eigen Statistics-object aan de storage te koppelen kon ik de duur van iedere query meten.

Binnen korte tijd verschenen ook databasequeries als metrics in Prometheus. Het resultaat was verrassend. SQLite bleek vrijwel onschuldig. Sterker nog: databasequeries bleken zó snel dat ik voor database-histogrammen een andere schaalverdeling moest gebruiken dan voor HTTP requests.

De database kostte slechts een fractie van de totale requesttijd.

SQLite mocht weer naar huis.

## Op zoek naar een nieuwe verdachte

Maar de requests waren nog steeds traag. Iets anders moest de tijd opslokken. Mijn aandacht verschoof naar markdown-rendering.

Alle artikelen en pagina's worden binnen MySite opgeslagen als markdown. Dat vind ik een prettig formaat om in te schrijven en het houdt de inhoud dicht bij de bron. Voordat een browser daar iets mee kan moet die markdown uiteraard eerst naar HTML worden omgezet. Daarvoor gebruik ik Pandoc.

Omdat ik geen goede Perl-oplossing ken betekent dat in de praktijk dat er voor iedere render een extern proces gestart wordt. Dat leek een uitstekende verdachte.

## Pandoc blijkt redelijk onschuldig

Het meten van renderacties was eenvoudig.

Er is precies één functie die voor de rendering verantwoordelijk is. Door daar dezelfde observability-logica toe te voegen kreeg ik vrijwel direct cijfers terug.
Ook hier was het resultaat niet wat ik verwachtte.

Pandoc kostte inderdaad tijd.Maar niet zoveel tijd. Sterker nog: de meeste renderacties waren verrassend snel.

Er viel echter iets anders op. Er waren véél meer renderacties dan ik had verwacht.

## Waarom render ik platte tekst?
Pas toen ik keek naar welke pagina's betrokken waren viel het kwartje.
Het ging steeds om:

- artikeloverzichten
- categoriepagina's

Pagina's dus die niet de volledige artikelen tonen, maar alleen een samenvatting.En precies daar zat het probleem. Iedere samenvatting werd door dezelfde markdown-rendering gestuurd als een volledig artikel.

Op zich logisch. Maar in de praktijk bleken vrijwel alle samenvattingen gewoon platte tekst te bevatten.

Met andere woorden:
Ik was tientallen renderjobs aan het uitvoeren voor content die in feite helemaal niet gerenderd hoefde te worden.

## Conclusie
Wat begon als een poging om wat testdata voor observability te verzamelen eindigde met een heel andere vraag:

**Waarom render ik in vredesnaam platte tekst?**

Dat is precies waarom observability nuttig is.
Mijn eerste vermoeden wees naar SQLite. Daarna keek ik naar dBIC. Vervolgens kwam Pandoc in beeld. Geen van die verdachten bleek schuldig.

De werkelijke oorzaak lag in een ontwerpbeslissing van mijzelf. Zonder metingen had ik waarschijnlijk uren besteed aan het optimaliseren van databasequeries of het analyseren van SQLite. De cijfers wezen echter een compleet andere richting op.

Observability loste het probleem niet op. Observability liet zien waar het probleem zat. En dat is misschien nog wel waardevoller.

## Hoe nu verder?

Voor MySite betekent dit dat abstracten niet langer gerenderd worden. Dat levert direct winst op zonder dat er functionaliteit verloren gaat. Waarschijnlijk ga ik ook het template renderen nog meten. Afhankelijk van toekomstige inzichten nog wat andere metrics.

Daarnaast moet de infrastructuurkant nog verder uitgewerkt worden. Prometheus draait op dit moment nog niet in het cluster, terwijl de applicatie inmiddels wel metrics kan aanbieden. Daar liggen dus nog genoeg vervolgacties.

## Ook WordPress begint interessant te worden

In hetzelfde cluster draait namelijk een WordPress-installatie die een constante stroom bots, scrapers en andere automatische bezoekers aantrekt. Vanuit observability-oogpunt is dat een dankbaar doelwit voor experimenten.

MySite heb ik volledig onder controle. WordPress niet.

Juist daarom ben ik benieuwd hoeveel inzicht ik uit zo'n bestaand framework kan halen zonder de applicatie zelf te herschrijven.

Dat wordt waarschijnlijk het onderwerp van een volgend artikel.

## Appendix: betrokken bronbestanden

Voor lezers die geïnteresseerd zijn in de implementatie heb ik hieronder de belangrijkste bestanden opgenomen die betrokken zijn bij de observability-functionaliteit van MySite. Deze bestanden kun je vinden in mijn (GitHup repo)[https://github.com/peter-kaagman/mysite]

| Bestand | Omschrijving |
|----------|----------|
| lib/MySite.pm | Initialisatie van Observability en koppeling met de dBIC debuglaag |
| lib/MySite/Observability.pm | Verwerking van events, logging, counters en histogrammen |
| lib/MySite/Store/Memcached.pm | Opslaglaag voor metrics in Memcached |
| lib/MySite/Schema/Debug/Metrics.pm | Verzamelen van query-metrics vanuit dBIC |
| lib/MySite/Utils.pm | Metingen rond markdown-rendering |
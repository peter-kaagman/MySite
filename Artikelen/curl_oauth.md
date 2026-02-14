Mijn uiteindelijke doel is om MS Graph werkend te krijgen met LWP en Perl. Om het beter te begrijpen, ben ik begonnen met experimenteren op de command line met curl. Dit vanuit de overtuiging dat als het op de command line werkt, het overal werkt.

**Waarom [curl](https://curl.se/)?**

Nou:

- Het is goed gedocumenteerd.
- Het bestaat al heel lang.
- Het is dé standaard voor HTTP (en vele andere) requests vanaf de command line. Er zijn zelfs libraries om curl vanuit een Perl-script te gebruiken.

**Waarom de client credentials flow?**  

Deze OAuth2-flow is bedoeld voor server-to-server authenticatie, waarbij geen eindgebruiker direct inlogt. Je gebruikt deze flow als je applicatie zelf (en niet een gebruiker) toegang nodig heeft tot resources, bijvoorbeeld voor geautomatiseerde taken of backend-integraties. Voor scenario’s waarbij een gebruiker moet inloggen, zijn andere flows zoals de authorization code flow geschikter.

Ik heb het volgende bash-script gemaakt om dit te doen:

```bash
#! /usr/bin/bash

token=`curl \
    -d grant_type=client_credentials \
    -d client_id=[client_id] \
    -d client_secret=[client_secret] \
    -d scope=https://graph.microsoft.com/.default \
    -d resource=https://graph.microsoft.com \
    https://login.microsoftonline.com/[tenant_id]/oauth2/token \
    | jq -j .access_token`

curl -X GET \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    https://graph.microsoft.com/v1.0/groups \
    | jq .
```

Ik heb dus twee curl-commando’s in een bash-script gezet:

1. De eerste is een request voor een token, dat wordt opgeslagen in een variabele.
2. Met dit token doe ik een tweede request om een lijst van groepen uit de tenant op te halen.

Je moet uiteraard zelf de ontbrekende gegevens invullen, zoals [client_secret]. De output van curl wordt via [jq](https://stedolan.github.io/jq/) geparsed (om het JSON-resultaat leesbaar te maken). Het ophalen van een lijst met groepen is slechts een voorbeeld.
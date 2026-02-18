# Inleiding
Mijn uiteindelijke doel is om MS Graph werkend te krijgen met LWP en Perl. Om het beter te begrijpen, ben ik begonnen met experimenteren op de command line met curl. Dit vanuit de overtuiging dat als het op de command line werkt, het overal werkt. En dat blijkt ook te werken. 

**Waarom [curl](https://curl.se/)?**

Nou:

- Het is goed gedocumenteerd.
- Het bestaat al heel lang.
- Het is dé standaard voor HTTP (en vele andere) requests vanaf de command line. Er zijn zelfs libraries om curl vanuit een Perl-script te gebruiken.

# Wat gaan we doen, de opdacht
De opdracht die ik mijzelf gesteld heb is het ophalen van een lijst van groepen uit onze tenant. Dit had heel goed iets anders kunnen zijn, een lijst van Azure joined devices bijvoorbeel, maar dit lijkt mij voor een demonstratie een leuk doel.

# De uitvoering

## Waarom de client credentials flow?  

Deze OAuth2-flow is bedoeld voor server-to-server authenticatie, waarbij geen eindgebruiker direct inlogt. Je gebruikt deze flow als je applicatie zelf (en niet een gebruiker) toegang nodig heeft tot resources, bijvoorbeeld voor geautomatiseerde taken of backend-integraties. Voor scenario’s waarbij een gebruiker moet inloggen, zijn andere flows zoals de authorization code flow geschikter.

## De app registratie

Om deze client credentials flow te kunnen doen heb je toegang nodig. In Azure regel je dat met een applicatie registratie. Deze registratie kun je maken in de Azure portal van jouw omgeving. Je krijgt dan een aantal identifiers die je nodig hebt om requests te kunnen maken:
- De id van de registratie: **[client_id]**
- De secret (zeg maar wachtwoord): **[client_secret]**
- De id van jouw Azure omgeving: **[tenant_id]**

Verder regel je in de registratie welke gegevens de applicatie kan opvragen. In het voorbeeld haal ik een lijst met groepen op, ik heb de applicatie dan ook het recht gegeven om deze gegevens te kunnen **lezen**. Zou ik de groep informatie willen wijzigen, groepen willen aanmaken, dan zou ik **lezen/schrijven** rechten instellen. Verder is voor de client_credentials flow belangrijk dat het een **Microsoft Graph** recht is met **toepassingsmachtigingen**

## Het verkrijgen van het token.

Je kunt niet zomaar een request naar de MS Graph API sturen. Je moet eerst laten blijken dat jouw applicatie het recht heeft gekregen om gegevens op te kunnen vragen. Dit doe je door een zogenaamd **token** op te vragen. Deze kun je zien als een sleutel om verdere vragen te stellen. De MS Graph API is een REST API, dit wil ondermeer zeggen dat de API **stateless** is. Na elke request is de API jou weer vergeten. Je hebt die token, met daarin beschreven jouw rechten, dan ook nodig om verdere vragen te kunnen stellen. Je vraag een token met de volgende HTTP request:

```bash
client_id=[client_id]
client_secret=[client_secret]
tenant_id=[tenant_id]

curl -X POST -sS \
    -d grant_type=client_credentials \
    -d client_id=$client_id \
    -d client_secret=$client_secret \
    -d scope=https://graph.microsoft.com/.default \
    -d resource=https://graph.microsoft.com \
    https://login.microsoftonline.com/$tenant_id/oauth2/token
```

**NB** De placeholders [client_id],[client_secret] en [tenant_id] zul je moeten vervangen door echte waardes. Ik zet hier uiteraard niet de echte waarden neer vanuit mijn tenant.

Ik gebruik de volgende parameters in de `curl`-aanroep:
- `-X POST` omdat het een POST request moet zijn.
- `-sS` ik wil geen progress bar, maar wel fouten zien.
- `-d [iets]` een aantal data velden.
- **URI** de URL waar ik de POST request naar toe stuur. 

Het resultaat van deze request is een stukje JSON:
```json
{
    "token_type": "Bearer",
    "expires_in": "3599",
    "ext_expires_in": "3599",
    "expires_on": "1771407119",
    "not_before": "1771403219",
    "resource": "https://graph.microsoft.com",
    "access_token": "een_hele_lang_stuk_tekst"
}
```
Naast wat algemene gegevens over de geldigheidduur en zo staat hierin het access_token, dit access_token is een JSON Web Token ([JWT](https://nl.wikipedia.org/wiki/JSON_Web_Token)).

## Het token "isoleren"

Eigenlijk hebben we voor ons doel alleen het token nodig. In andere toepassingen is het misschien handig om te weten hoe lang het token geldig is, maar in ons geval doet dat er niet echt toe. Ik wil dan ook het token uit de response halen. Dit blijkt heel gemakkelijk te kunnen met de tool [**JS**](https://stedolan.github.io/jq/). Ik pas daarvoor het script aan:

```bash
client_id=[client_id]
client_secret=[client_secret]
tenant_id=[tenant_id]

token=`curl -sS \
    -d grant_type=client_credentials \
    -d client_id=$client_id \
    -d client_secret=$client_secret \
    -d scope=https://graph.microsoft.com/.default \
    -d resource=https://graph.microsoft.com \
    https://login.microsoftonline.com/$tenant_id/oauth2/token
    | jq -r .access_token`

echo $token
```
De reply die je krijgt van de `curl` request wordt gepiped naar een `jq` commando, met de flag `-r .access_token` haal je de property waarde van `.access_token` uit de JSON-structuur. De output van dit geheel, het token dus, wordt toegewezen aan de variabele `token`. De `echo $token` zal deze dan ook tonen.

## Het token parsen, gewoon omdat het leuk is.

Even een intermezzo, gewoon omdat het leuk is. Alhoewel het voor ons doel, een lijst van groepen opvragen, niet echt noodzakelijk is gaan we het token nader bekijken. Het ziet er nogal cryptisch uit, maar je kunt de inhoud parsen... leesbaar maken. We hebben na de vorige stap het token beschikbaar in een variabele, deze kunnen we parsen met ook weer `jq`:

```bash
client_id=[client_id]
client_secret=[client_secret]
tenant_id=[tenant_id]

token=`curl -X POST -sS \
    -d grant_type=client_credentials \
    -d client_id=$client_id \
    -d client_secret=$client_secret \
    -d scope=https://graph.microsoft.com/.default \
    -d resource=https://graph.microsoft.com \
    https://login.microsoftonline.com/$tenant_id/oauth2/token \
    | jq -r '.access_token'`

echo $token| jq -R 'split(".") | .[1] | @base64d | fromjson'
```

En dan blijkt het token gewoon weer een JSON structure te zijn:

```json
{
  "aud": "https://graph.microsoft.com",
  "iss": "https://sts.windows.net/[tenant_id]/",
  "iat": 1771406730,
  "nbf": 1771406730,
  "exp": 1771410630,
  "aio": "[een identifier]",
  "appid": "[client_id]",
  "appidacr": "1",
  "idp": "https://sts.windows.net/[tenant_id]/",
  "idtyp": "app",
  "oid": "[een identifier]",
  "rh": "[een identifier]",
  "roles": [
    "Group.Read.All"
  ],
  "sub": "[een identifier]",
  "tenant_region_scope": "EU",
  "tid": "[tenant_id]",
  "uti": "[een identifier]",
  "ver": "1.0",
  "wids": [
    "[een identifier]"
  ],
  "xms_acd": 1771406923,
  "xms_act_fct": "3 9",
  "xms_ftd": "[een identifier]",
  "xms_idrel": "18 7",
  "xms_rd": "[een identifier]",
  "xms_sub_fct": "3 9",
  "xms_tcdt": 1452535134,
  "xms_tdbr": "EU",
  "xms_tnt_fct": "16 3"
}
```

Je zou dit kunnen gebruiken om te controleren of de applicatie de juiste rechten wel heeft. In die geval is de role Group.Read.All aangegeven, wat inderdaad het recht is wat ik deze applicatie gegeven heb. Maar we gaan weer verder met de oorspronkelijke opdracht: een lijst met groepen opvragen.

## De groepen opvragen

Het token hebben we dus opgeslagen in een variabele, deze kunnen we nu gebruiken om een volgend request te maken. Dit is een tweede curl opdracht:
```bash
client_id=[client_id]
client_secret=[client_secret]
tenant_id=[tenant_id]

token=`curl -X POST -sS \
    -d grant_type=client_credentials \
    -d client_id=$client_id \
    -d client_secret=$client_secret \
    -d scope=https://graph.microsoft.com/.default \
    -d resource=https://graph.microsoft.com \
    https://login.microsoftonline.com/$tenant_id/oauth2/token \
    | jq -r '.access_token'`

curl -X GET -sS \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    https://graph.microsoft.com/v1.0/groups \
    | jq .

```

In dit geval geef ik met `-H` een tweetal header-velden op: het `token` en de `Content-Type`. De URL is het [MS Graph endpoint](https://learn.microsoft.com/en-us/graph/api/resources/groups-overview?view=graph-rest-1.0&tabs=http) om iets met groepen te kunnen doen. Een `GET` request zal resulteren in een lijst van de groepen:
```json
{
  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#groups",
  "@odata.nextLink": "https://graph.microsoft.com/v1.0/groups?$skiptoken={skip token}",
  "value": [
    {
      "id": "[group id]",
      "deletedDateTime": null,
      "classification": null,
      "createdDateTime": "2019-12-13T10:31:18Z",
      "creationOptions": [],
      "description": "[group description]",
      "displayName": "[group displayname]",
      "expirationDateTime": "2026-05-26T08:28:55Z",
      "groupTypes": [
        "Unified"
      ],
      "isAssignableToRole": null,
      "mail": "[group email]",
      "mailEnabled": true,
      "mailNickname": "[group mailnickname]",
      "membershipRule": null,
      "membershipRuleProcessingState": null,
      "onPremisesDomainName": null,
      "onPremisesLastSyncDateTime": null,
      "onPremisesNetBiosName": null,
      "onPremisesSamAccountName": null,
      "onPremisesSecurityIdentifier": null,
      "onPremisesSyncEnabled": null,
      "preferredDataLocation": null,
      "preferredLanguage": null,
      "proxyAddresses": [
        "[group SPO]",
        "[group SMTP]",
        "[group smtp]"
      ],
      "renewedDateTime": "2025-05-26T08:28:54Z",
      "resourceBehaviorOptions": [],
      "resourceProvisioningOptions": [
        "Team"
      ],
      "securityEnabled": false,
      "securityIdentifier": "[security identifier]",
      "theme": null,
      "uniqueName": null,
      "visibility": "Private",
      "onPremisesProvisioningErrors": [],
      "serviceProvisioningErrors": []
    },
  ]
}
```

# Hoe nu verder

## `@odata.nextLink`
Het default aantal items wat maximaal in één request opgehaald kan worden is 1000. Omdat wij meer dan 1000 groepen hebben ontving ik er dan ook 1000 (waarvan ik er maar één laat zien). Ik heb ook een link ontvangen in de property `@odata.nextLink` om de volgende "pagina" op te halen. Hoe je daar mee kunt dealen ga ik hier niet laten zien. Dat komt ter sprake in de de toepassing die ik hiervoor gemaakt heb

## Perl
De methode die ik hier demonstreer heb ik inmiddels toegepast in een aantal Perl modules die ik geschreven heb om MS Teams te kunnen beheren voor mijn werkgever. Hier zal ik een aantal artikelen aan wijden. (De link volgt tzt).

## Powershell
Deze methode bleek ook heel goed bruikbaar te zijn in Powershell. Deze methode wordt weer gebruikt in ons Identity Management Systeem `HelloID`. Ook hier zal ik over schrijven.

## Andere tools?
Eigenlijk is deze methode toepasbaar in elke tool waarin je HTTP request kunt maken. Het komt allemaal op hetzelfde neer. Alleen je eigen fantasie is de beperking.

# Ter afsluiting.
Alhoewel dit artikel geschreven is vanuit de gedachte "als ik het kan uitleggen dan snap ik het zelf ook" hoop ik oprecht dat dit artikel jou ook helpt bij het begrijpen van OAuth2 en het maken van MS Graph requests. Veel succes met je eigen integratie!
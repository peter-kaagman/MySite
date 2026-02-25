
# Vernieuwingen op de site: editor & inloggen

Deze site is continu in ontwikkeling. Nieuwe content verschijnt direct, maar soms zijn er grotere technische vernieuwingen. In dit artikel lees je over twee recente verbeteringen: een nieuwe Markdown-editor en uitgebreidere inlogmogelijkheden.

## Een nieuwe, uitbreidbare editor


[SimpleMDE](https://simplemde.com/){:target="_blank"} (de eerste JS Markdown-editor die ik vond). SimpleMDE bleek echter beperkt en wordt niet meer onderhouden. Een drop-in replacement zou [EasyMDE](https://easy-markdown-editor.github.io/){:target="_blank"} zijn geweest, maar ik wilde meer flexibiliteit en uitbreidbaarheid.



Daarom ben ik overgestapt op [Toast UI Editor](https://ui.toast.com/tui-editor){:target="_blank"}. Deze editor biedt standaard al veel meer functionaliteit (zoals een preview-tab en WYSIWYG-modus) en is bovendien goed uit te breiden. Zo wil ik in de toekomst bijvoorbeeld een eigen gallery integreren voor het invoegen van afbeeldingen.
Deze site is een hobbyproject. Het doel: leren werken met [Dancer2](https://perldancer.org/){:target="_blank"} (Perl webframework), [DBIC](https://metacpan.org/pod/DBIx::Class){:target="_blank"} (ORM voor databases), moderne JavaScript-modules en webstandaarden. Verwacht dus geen groot platform, maar een plek waar ik experimenteer en kennis deel.

## OAuth2: veilig en privacybewust inloggen
Authenticatie op deze site verloopt via [OAuth2](https://oauth.net/2/){:target="_blank"}. Momenteel kun je inloggen met Google (GitHub volgt nog). OAuth2 betekent dat je veilig via een externe provider (zoals Google) kunt inloggen, zonder dat deze site je wachtwoord ooit ziet.

Om dit mogelijk te maken, moest ik een privacy-pagina opstellen die voldoet aan de eisen van Google. Hierin staat precies welke gegevens ik opvraag (zo min mogelijk!) en wat ik daarmee doe (alleen voor authenticatie, nooit voor advertenties of tracking).

Sinds kort staat de Google-app in productie en kan iedereen met een Google-account inloggen.

## Wat kun je straks met een account?
Op dit moment heeft inloggen nog weinig nut: alleen de beheerder kan artikelen schrijven. Maar op de roadmap staan features als reageren op artikelen, een eigen profielpagina en notificaties. Inloggen is dus vooral een voorbereiding op toekomstige interactie.

## Waarom deze site?
Deze site is een hobbyproject. Het doel: leren werken met Dancer2, DBIC, moderne JavaScript-modules en webstandaarden. Verwacht dus geen groot platform, maar een plek waar ik experimenteer en kennis deel.

## Feedback of ideeën?
Wil je meedenken, reageren of heb je suggesties? Laat gerust van je horen via mijn e-mail of via de [GitHub-pagina van MySite](https://github.com/peter-kaagman/MySite){:target="_blank"}. Alle feedback is welkom!
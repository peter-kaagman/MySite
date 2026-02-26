# Overwegingen voor Session Storage: Memcached vs Redis

**Datum:** 2026-02-26

## Context
Voor het opslaan van sessies in een Dancer2 webapplicatie zijn er verschillende opties. In productie is het belangrijk om een balans te vinden tussen performance, eenvoud, beheerlast en (semi-)persistentie.

## Opties
### 1. Memcached
- **Voordelen:**
  - Zeer lichtgewicht (kleine container, weinig resources)
  - In-memory: razendsnel voor reads/writes
  - Eenvoudig te deployen als standaard Docker-container (geen eigen build nodig)
  - Sessies blijven behouden zolang de Memcached-container draait
  - Geschikt voor single-server en eenvoudige multi-server setups
- **Nadelen:**
  - Niet persistent: bij herstart van de Memcached-container zijn alle sessies weg
  - Geen geavanceerde datastructuren of persistence-opties

### 2. Redis
- **Voordelen:**
  - In-memory én optioneel persistent (sessies kunnen over container-restarts heen bewaard blijven)
  - Ondersteunt meer datastructuren en features
  - Ook als standaard Docker-container beschikbaar
- **Nadelen:**
  - Iets zwaarder dan Memcached (meer features, meer resources)
  - Meer configuratie-opties, dus iets complexer

## Overwegingen voor dit project
- **Performance:** Memcached is snel genoeg voor een klein tot middelgroot blog of CMS.
- **Beheer:** Een Memcached-container is eenvoudig te starten en vereist weinig onderhoud.
- **Persistentie:** Voor deze site is het geen probleem als sessies verloren gaan bij een (zeldzame) herstart van de Memcached-container. Persistentie zoals Redis biedt is niet noodzakelijk.
- **Ervaring:** Memcached is eerder gebruikt en bekend terrein.
- **Schaalbaarheid:** Zolang de site niet horizontaal schaalt over veel servers, is Memcached ruim voldoende.

## Conclusie
Memcached in een eigen container is een pragmatische, lichte en snelle oplossing voor session storage in deze situatie. Redis biedt meer mogelijkheden, maar is voor deze use-case niet nodig.

**Tip:** Documenteer deze keuze en heroverweeg bij groei of veranderende eisen.

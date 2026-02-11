# Issue: Verbeterpunten User.pm (OAuth)

## Beschrijving
Na een heranalyse van de OAuth-implementatie in User.pm zijn er nog enkele verbeterpunten overgebleven:

- Security: Veilige redirect URL (return_url) afdwingen
- Logging van mislukte loginpogingen
- Configuratievalidatie bij opstarten
- Extensibiliteit user-info mapping
- Session management optimaliseren
- Code cleanup (oude, uitgeschakelde code verwijderen)

## Actiepunten
Zie het bestand ProjectDoc/TODO_oauth_userpm.md voor details en concrete taken.

---
Deze issue is aangemaakt om de resterende verbeterpunten te verzamelen en op te volgen.

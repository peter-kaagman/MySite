# TODO: Overgebleven verbeterpunten User.pm (OAuth)

1. **Security: Veilige redirect URL**
   - Controleer of de return_url altijd veilig is (geen open redirect).

2. **Logging van mislukte loginpogingen**
   - Log mislukte OAuth-logins voor monitoring en security.

3. **Configuratievalidatie bij opstarten**
   - Valideer provider-configuratie bij applicatie-start om misconfiguraties vroeg te detecteren.

4. **Extensibiliteit user-info mapping**
   - Maak user-info mapping per provider configureerbaar of via aparte mapping-functie.

5. **Session management**
   - Sla alleen relevante user-data op in de sessie (bijv. session->write('user', ...)).

6. **Code cleanup**
   - Verwijder oude, uitgeschakelde code (zoals uit-gecommentarieerde _profile sub) als deze niet meer nodig is.

---
Deze punten zijn geïdentificeerd na een heranalyse van User.pm en kunnen als losse issues worden opgepakt.

- [ ] Bij het maken van page CRUD functionaliteit ook een meta_description veld toevoegen aan pages, zodat deze in de header als meta description kan worden gebruikt (net als bij artikelen).

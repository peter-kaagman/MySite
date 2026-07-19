Stel je hebt een provioning systeem (HelloId) en je wil dat dit systeem rechten/lidmaatschappen gaat uitdelen gebasseerd op eigenschappen van personen. Dan kun je dit als volgt modeleren:
```pseudo
Als user="docent" en werkt_op="school A" voeg dan toe aan groep/team "Docenten school A"
```
of iets als
```pseudo
Als user="oop" en werkt_op="school B" en "school C" maar rol<>"vrijwilleger" maar is  voeg dan toe aan groep/team "OOPers school B en C"
```

Deze logica kun je loslaten op de omschrijving van een persoon. En zo ben ik ook begonnen... om er al snel achter te komen dat ik al heel snel een wanhoop aan code kreeg. En ik wil de code zo simpel mogelijk houden, anders snap ik het niet meer, kan ik het niet meer onderhouden.

De persoon kreeg van het upstream proces aangereik als een JSON object, en ik kreeg het idee om de voorwaarde ook als een JSON object te modeleren. Ik kwam uiteindelijk hier op uit:
```json
$rules = @{
    conditions = @(
        @{ 
            level = @("person", "type")
            operator = "Equals"
            check = "Employee"
        },
        @{
            level = @("person", "department")
            operator = "Equals"
            check = "Finance"
        }
    )
    result = "Finance Employee Matched!"
}```
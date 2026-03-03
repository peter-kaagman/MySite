# Perl Richtlijnen

Afspraken en conventies voor Perl code in dit project.

## Module structuur
- Altijd eerst de `package`-regel, gevolgd door alle `use`/`require`-statements, en daarna pas de subroutines.
- Zet nooit subroutines of code vóór de `package`-regel of vóór de imports.
- Hulpfuncties altijd ná de package en imports, niet erboven.

## Voorbeeld
```perl
package MySite::ImageUpload;
use v5.20;
use utf8;
use Dancer2 appname => 'MySite', with => {};
# ...
# subroutines hieronder
sub foo { ... }
sub bar { ... }
```

## Best practices
- DRY, duidelijke naamgeving, single responsibility
- Gebruik waar mogelijk CPAN-modules
- Security: altijd authorization checks op write endpoints

# JSON-LD Structuur voor MySite

Deze notitie beschrijft een pragmatische JSON-LD implementatie voor MySite.

## Overzicht

| Paginatype | Schema.org type |
|------------|----------------|
| Homepage | `WebSite` (+ optioneel `ItemList`) |
| Categorie-overzicht | `CollectionPage` + `ItemList` |
| Artikellijst / archief | `CollectionPage` + `ItemList` |
| Artikel | `BlogPosting` |
| Statische pagina | `WebPage` |
| About | `AboutPage` |
| Contact | `ContactPage` |
| Zoekpagina | `SearchResultsPage` |

---

# 1. Homepage

Type: `WebSite`

```json
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "@id": "https://mysite.prjv.nl/#website",
  "url": "https://mysite.prjv.nl/",
  "name": "MySite",
  "description": "Persoonlijke blog over IT, onderwijs, open source en digitale soevereiniteit.",
  "publisher": {
    "@type": "Person",
    "name": "Peter Kaagman"
  }
}
```

## Properties

### Verplicht / aanbevolen

- ⭐ `@context`
- ⭐ `@type`
- ⭐ `url`
- ✅ `name`
- ✅ `description`
- ✅ `publisher`

### Optioneel

- ➕ `sameAs`
- ➕ `potentialAction` (`SearchAction`)

---

# 2. Categoriepagina / Artikellijst

Type: `CollectionPage`

```json
{
  "@context": "https://schema.org",
  "@type": "CollectionPage",
  "@id": "https://mysite.prjv.nl/category/mprjv65",
  "url": "https://mysite.prjv.nl/category/mprjv65",
  "name": "Mprjv65",
  "description": "Artikelen over het Mprjv65 platform.",
  "mainEntity": {
    "@type": "ItemList",
    "numberOfItems": 3,
    "itemListElement": [
      {
        "@type": "ListItem",
        "position": 1,
        "url": "https://mysite.prjv.nl/article/123"
      },
      {
        "@type": "ListItem",
        "position": 2,
        "url": "https://mysite.prjv.nl/article/124"
      },
      {
        "@type": "ListItem",
        "position": 3,
        "url": "https://mysite.prjv.nl/article/125"
      }
    ]
  }
}
```

## CollectionPage Properties

### Verplicht / aanbevolen

- ⭐ `@context`
- ⭐ `@type`
- ⭐ `url`
- ✅ `name`
- ✅ `description`
- ✅ `mainEntity`

## ItemList Properties

### Verplicht / aanbevolen

- ⭐ `itemListElement`
- ⭐ `position`
- ⭐ `url`

### Optioneel

- ➕ `numberOfItems`

Gebruik ditzelfde schema voor:

- `/category/*`
- `/archive`
- `/articles`
- `/tag/*`
- `/search`

---

# 3. Artikel

Type: `BlogPosting`

```json
{
  "@context": "https://schema.org",
  "@type": "BlogPosting",
  "@id": "https://mysite.prjv.nl/article/123",
  "url": "https://mysite.prjv.nl/article/123",
  "headline": "Waarom ik Mprjv65 bouw",
  "description": "Over digitale soevereiniteit en reproduceerbare infrastructuur.",
  "datePublished": "2026-06-29",
  "dateModified": "2026-06-29",
  "author": {
    "@type": "Person",
    "name": "Peter Kaagman"
  },
  "publisher": {
    "@type": "Person",
    "name": "Peter Kaagman"
  },
  "mainEntityOfPage": {
    "@type": "WebPage",
    "@id": "https://mysite.prjv.nl/article/123"
  }
}
```

## Properties

### Verplicht / aanbevolen

- ⭐ `@context`
- ⭐ `@type`
- ⭐ `headline`
- ⭐ `datePublished`
- ⭐ `author`
- ✅ `url`
- ✅ `description`
- ✅ `dateModified`
- ✅ `publisher`
- ✅ `mainEntityOfPage`

### Extra aanbevolen

- ✅ `image`
- ✅ `keywords`
- ✅ `articleSection`

Voorbeeld:

```json
"keywords": [
  "kubernetes",
  "open source",
  "digitale soevereiniteit"
]
```

```json
"articleSection": "Mprjv65"
```

---

# 4. Statische pagina

Type: `WebPage`

```json
{
  "@context": "https://schema.org",
  "@type": "WebPage",
  "@id": "https://mysite.prjv.nl/license",
  "url": "https://mysite.prjv.nl/license",
  "name": "Licentie",
  "description": "Licentievoorwaarden van deze website."
}
```

## Properties

### Verplicht / aanbevolen

- ⭐ `@context`
- ⭐ `@type`
- ⭐ `url`
- ✅ `name`
- ✅ `description`

---

# Specialisaties

## About

```json
"@type": "AboutPage"
```

## Contact

```json
"@type": "ContactPage"
```

## Zoekpagina

```json
"@type": "SearchResultsPage"
```

## Privacy / License

```json
"@type": "WebPage"
```

---

# Advies voor MySite

Maak vier generieke functies:

```perl
jsonld_website()
jsonld_collection()
jsonld_article()
jsonld_webpage()
```

Daarmee kun je vrijwel alle pagina's van MySite afdekken zonder extra complexiteit.

// Wykład 2: Style architektoniczne — monolit, mikroserwisy, modularny monolit
// PSR · Semestr letni 2025/26 · Politechnika Poznańska

#import "@preview/typslides:1.3.2": *
#import "psr-theme.typ": *

#show: typslides.with(
  ratio: "16-9",
  theme: kolor-pp,
  font: "Arial",
  font-size: 20pt,
  show-progress: true,
  show-page-numbers: true,
)

#front-slide(
  title: "Style architektoniczne",
  subtitle: [Monolit · Mikroserwisy · Modularny monolit],
  authors: "mgr inż. Jakub Woźniak",
  info: [Politechnika Poznańska · Instytut Informatyki · Semestr letni 2025/26],
)

#title-slide[Plan wykładu]

#slide(title: [Agenda])[

  - Monolit — kiedy wystarczy?
  - Modularny monolit — kompromis
  - Mikroserwisy — korzyści i koszty
  - Domain-Driven Design i Bounded Contexts
  - Distributed Monolith — anti-pattern
  - Case study: Segment.io
  - ☁️ Cloud-native vs cloud-hosted
]

// ── Monolit ──────────────────────────────────────────────────

#title-slide[Monolit]

#slide(title: [Klasyczny monolit])[

  #defblock[Definicja][
    Jedna aplikacja, jeden proces, jedna baza danych, jeden deployment.
  ]

  #cols[
    *Zalety:*
    - Prosty development i deploy
    - Proste debugowanie
    - Brak opóźnień sieciowych
    - Transakcje ACID „za darmo"
  ][
    *Wady:*
    - Cały system = jeden punkt awarii
    - Skaluje się _cały_, nie części
    - Duży zespół = konflikty scalania
    - Długie buildy, wolne testy
  ]
]

#slide(title: [Majestic Monolith])[

  #exblock[DHH (Basecamp / 37signals)][
    _„Mikroserwisy to architektura dla dużych organizacji z dużymi problemami. Większość firm nie ma tych problemów."_
  ]

  Basecamp / HEY.com — miliony użytkowników, monolit w Rails.

  - Mały zespół (~20 osób) — niska koordynacja
  - Dobrze zdefiniowane warstwy w kodzie
  - Agresywne cachowanie
  - Pionowe skalowanie (potężne serwery)
]

// ── Modularny monolit ────────────────────────────────────────

#title-slide[Modularny monolit]

#slide(title: [Idea])[

  #defblock[Modularny monolit][
    Monolit podzielony na *moduły z jasnymi granicami*. Komunikacja przez publiczne interfejsy, nie przez współdzieloną bazę.
  ]

  - Granice modułów = przyszłe granice serwisów
  - Jeden deploy, ale niezależne zespoły
  - Brak kosztu sieci między modułami
]

#slide(title: [Case study: Shopify])[

  #exblock[Shopify Engineering — „Deconstructing the Monolith"][
    Monolit w Rails, ~3 mln LoC. Zamiast migracji do mikroserwisów:
  ]

  + Zdefiniowali *bounded contexts* w istniejącym kodzie
  + Wymusili granice narzędziem _Packwerk_
  + Komunikacja między modułami przez *zdarzenia*
  + Rezultat: szybkość dev jak w mikroserwisach, prostota ops monolitu

  #alertblock[Uwaga][
    Modularny monolit wymaga *dyscypliny* — bez niej granice się rozmywają.
  ]
]

// ── Mikroserwisy ─────────────────────────────────────────────

#title-slide[Mikroserwisy]

#slide(title: [Definicja])[

  #defblock[Mikroserwisy][
    System składający się z *małych, niezależnie wdrażanych serwisów*, każdy realizuje jedną zdolność biznesową.
  ]

  Kluczowe cechy (Sam Newman):
  - *Niezależne wdrożenie* — zmiana jednego nie wymaga wdrożenia innych
  - *Modelowanie wokół domeny* — serwis = bounded context
  - *Własność danych* — każdy serwis ma swoją bazę
]

#slide(title: [Korzyści mikroserwisów])[

  + *Niezależne skalowanie* — skaluj tylko wąskie gardło
  + *Izolacja awarii* — awaria jednego nie zabija całości
  + *Technologiczna różnorodność* — Python do ML, Go do API
  + *Szybsze cykle wydawnicze* — mniejszy zakres zmian
  + *Autonomia zespołu* — team per service (prawo Conwaya)
]

#slide(title: [Koszty mikroserwisów])[

  #alertblock[Ukryte koszty][
    - *Opóźnienia sieciowe* — ~1ms+ zamiast nanosekund
    - *Rozproszona diagnostyka* — request przechodzi 10 serwisów
    - *Spójność danych* — koniec z ACID między serwisami
    - *Narzut operacyjny* — 100 serwisów × monitoring, deploys, dyżury
  ]
]

#slide(title: [Kiedy mikroserwisy mają sens?])[

  #cols[
    #exblock[TAK, gdy...][
      - Duży zespół (50+ devów)
      - Różne komponenty skalują się inaczej
      - Dojrzały DevOps
      - Dobrze zrozumiana domena
    ]
  ][
    #alertblock[NIE, gdy...][
      - Mały zespół (< 10 devów)
      - Niezrozumiana domena
      - Brak dojrzałości operacyjnej
      - „Bo tak robią w Netflixie"
    ]
  ]
]

// ── Domain-Driven Design ─────────────────────────────────────

#title-slide[Domain-Driven Design]

#slide(title: [Bounded Contexts])[

  #defblock[Bounded Context (Eric Evans, 2003)][
    Granica, w której model domeny jest spójny. Ten sam termin (np. „klient") może znaczyć co innego w kontekście sprzedaży i supportu.
  ]

  - Bounded Context → naturalny kandydat na granicę serwisu
  - *Context Map* — diagram relacji między kontekstami
  - *Ubiquitous Language* obowiązuje _w obrębie_ kontekstu
]

#slide(title: [Context Map — relacje])[

  #align(center)[
    #table(
      columns: 2,
      align: (left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Relacja],
        text(fill: white, weight: "bold")[Opis],
      ),
      [*Partnership*],           [Dwa zespoły razem ewoluują oba konteksty],
      [*Customer-Supplier*],     [Odbiorca zależy od dostawcy, negocjują kontrakt],
      [*Anti-Corruption Layer*], [Odbiorca tłumaczy model dostawcy na swój],
      [*Shared Kernel*],         [Współdzielony fragment modelu (ryzyko!)],
      [*Open Host Service*],     [Dostawca publikuje API dla wszystkich],
    )
  ]
]

// ── Anti-patterns ────────────────────────────────────────────

#title-slide[Anti-patterns]

#slide(title: [Distributed Monolith])[

  #alertblock[Najgorsze z dwóch światów][
    Mikroserwisy, które muszą być wdrażane *razem*, dzielą *jedną bazę* i synchronicznie się wywołują. Wszystkie koszty, żadne korzyści.
  ]

  Sygnały ostrzegawcze:
  - Deploy jednego wymaga deployu trzech innych
  - Zmiana schematu DB = koordynacja wielu zespołów
  - Jedna zmiana biznesowa = modyfikacja 5+ serwisów
]

#slide(title: [Jak unikać?])[

  + *Jasne granice danych* — każdy serwis = własna baza
  + *Asynchroniczna komunikacja* gdzie to możliwe
  + *Unikanie współdzielonych bibliotek z logiką biznesową*
  + *Test niezależności*: czy mogę wdrożyć ten serwis _sam_?
]

// ── Case study: Segment ──────────────────────────────────────

#title-slide[Case study: Segment]

#slide(title: [Segment.io — podróż tam i z powrotem])[

  #exblock[Goodbye Microservices (2018)][
    *Faza 1*: Monolith — prosty pipeline, wszystko działa. \
    *Faza 2*: ~100 mikroserwisów (1 per integracja) — powtórzony kod, N × te same bugi, koszmar operacyjny. \
    *Faza 3*: Powrót do zunifikowanego pipeline'u.
  ]
]

#slide(title: [Lekcje z Segment])[

  + *Granice wzdłuż domen*, nie wzdłuż integracji
  + Wspólna logika = biblioteka, nie 100 kopii
  + Mikroserwisy nie rozwiązują *złej dekompozycji*
  + *Poznaj domenę*, zanim pokroisz system
]

// ── Porównanie ───────────────────────────────────────────────

#title-slide[Porównanie]

#slide(title: [Monolit vs Modularny monolit vs Mikroserwisy])[

  #align(center)[
    #sm[#table(
      columns: 4,
      align: (left, center, center, center),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Aspekt],
        text(fill: white, weight: "bold")[Monolit],
        text(fill: white, weight: "bold")[Modularny],
        text(fill: white, weight: "bold")[Mikroserwisy],
      ),
      [Złożoność deployu],     [Niska],   [Niska],     [Wysoka],
      [Niezależne skalowanie], [Nie],     [Nie],       [Tak],
      [Izolacja awarii],       [Brak],    [Częściowa], [Wysoka],
      [Opóźnienie wewnętrzne], [~ns],     [~ns],       [~ms],
      [Spójność danych],       [ACID],    [ACID],      [Eventual],
      [Narzut operacyjny],     [Niski],   [Niski],     [Wysoki],
      [Cloud deploy],          [PaaS / VM], [PaaS / kontener], [K8s / ECS],
    )]
  ]
]

// ── Cloud-native vs Cloud-hosted ─────────────────────────────

#title-slide[Cloud-native vs Cloud-hosted]

#slide(title: [Dwa podejścia do chmury])[

  #cols[
    #defblock[Cloud-hosted][
      Przenieś aplikację „jak jest" na VM / kontener w chmurze.
      - Lift & shift
      - Minimum zmian w kodzie
      - Nie korzystasz z platformy
    ]
  ][
    #alertblock[Cloud-native][
      Projektuj z myślą o chmurze od dnia pierwszego.
      - Stateless, kontenery, CI/CD
      - Managed services zamiast self-hosted
      - Autoscaling, resilience by design
    ]
  ]
]

#slide(title: [12-Factor App])[

  #defblock[Heroku / Adam Wiggins, 2011][
    Metodologia budowania aplikacji SaaS — naturalnie pasuje do chmury i kontenerów.
  ]

  #align(center)[
    #sm[#table(
      columns: 2,
      align: (left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Czynnik],
        text(fill: white, weight: "bold")[Zasada],
      ),
      [*Codebase*],         [Jedno repo, wiele deployów],
      [*Config*],           [Konfiguracja w zmiennych środowiskowych],
      [*Backing services*], [Bazy, kolejki jako podpinane zasoby],
      [*Processes*],        [Bezstanowe procesy (stateless)],
      [*Port binding*],     [Aplikacja eksportuje HTTP jako usługę],
      [*Disposability*],    [Szybki start i graceful shutdown],
    )]
  ]

  #src[12factor.net — Adam Wiggins (Heroku)]
]

#slide(title: [Architektury w chmurze — PaaS i kontenery])[

  #align(center)[
    #sm[#table(
      columns: 3,
      align: (left, left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Styl],
        text(fill: white, weight: "bold")[Deployment w chmurze],
        text(fill: white, weight: "bold")[Przykłady serwisów],
      ),
      [*Monolit*],           [1 kontener / VM, PaaS],      [App Service, Cloud Run, Elastic Beanstalk],
      [*Modularny monolit*], [1 kontener, managed DB],     [ECS / Cloud Run + RDS / Cloud SQL],
      [*Mikroserwisy*],      [N kontenerów, orkiestracja], [EKS / GKE / AKS, ECS, Cloud Run per svc],
    )]
  ]

  #exblock[Ważne][
    Chmura nie wymusza mikroserwisów — monolit na Cloud Run to *valid architecture*.
  ]
]

// ── Dyskusja ─────────────────────────────────────────────────

#focus-slide[
  Startup z *5-osobowym zespołem* chce zacząć od mikroserwisów, „żeby się _później łatwiej skalować_".

  Jakie argumenty im przedstawisz?

  Kiedy byłby dobry moment na *pierwszą dekompozycję*?
]

// ── Podsumowanie ─────────────────────────────────────────────

#title-slide[Podsumowanie]

#slide(title: [Kluczowe wnioski])[

  + *Monolit to nie wstyd* — dla wielu firm optymalna architektura
  + *Modularny monolit* — korzyści organizacyjne, brak kosztów sieciowych
  + *Mikroserwisy* wymagają dojrzałości i zrozumienia domeny
  + *Bounded Contexts* — najlepsze narzędzie do definiowania granic
  + *Poznaj domenę, zanim pokroisz system*
  + *Cloud-native ≠ mikroserwisy* — 12-Factor App stosuj niezależnie od stylu
]

#slide(title: [Źródła i lektury])[

  - S. Newman — _Building Microservices_, 2nd ed., rozdz. 1–3
  - E. Evans — _Domain-Driven Design_, rozdz. 14–15
  - Segment — _Goodbye Microservices_ (blog)
  - Shopify — _Deconstructing the Monolith_ (blog)
  - M. Fowler — _Monolith First_
  - 12factor.net — Adam Wiggins (Heroku)
]

#slide(title: [Następny wykład])[

  #defblock[Wykład 3: Komunikacja w systemach rozproszonych][
    REST · gRPC · Message Brokers · API Gateway
  ]
]

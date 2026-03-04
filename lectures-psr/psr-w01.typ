// Wykład 1: Anatomia systemu rozproszonego — od wymagań do architektury
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
  title: "Anatomia systemu rozproszonego",
  subtitle: [Od wymagań do architektury],
  authors: "mgr inż. Jakub Woźniak",
  info: [Politechnika Poznańska · Instytut Informatyki · Semestr letni 2025/26],
)

#title-slide[Plan wykładu]

#slide(title: [Agenda])[

  - Co to znaczy _projektować_ system rozproszony?
  - Wymagania funkcjonalne vs niefunkcjonalne
  - Back-of-the-envelope estimation
  - Modele architektoniczne
  - SLA / SLO / SLI
  - Skalowanie: pionowe vs poziome
]

// ── Projektowanie vs Operowanie ──────────────────────────────

#title-slide[Projektowanie vs Operowanie]

#slide(title: [Rola architekta vs rola operatora])[

  #cols[
    #defblock[Architekt (PSR)][
      - *Jakie* komponenty?
      - *Jak* się komunikują?
      - *Gdzie* dane?
      - *Dlaczego* ten trade-off?
    ]
  ][
    #defblock[Operator (ZSR)][
      - *Jak* wdrożyć na K8s?
      - *Jak* monitorować?
      - *Jak* zautomatyzować CI/CD?
      - *Jak* reagować na awarie?
    ]
  ]
]

#slide(title: [Czym jest system rozproszony?])[

  #defblock[Definicja][
    Zbiór niezależnych komputerów, które dla użytkownika wyglądają jak jeden spójny system.
  ]

  Kluczowe konsekwencje:
  - Brak współdzielonej pamięci
  - Komunikacja przez sieć (zawodną!)
  - Brak globalnego zegara
  - Częściowe awarie (_partial failures_)

  #src[A. Tanenbaum, M. van Steen — _Distributed Systems_, 3rd ed.]
]

// ── Wymagania ────────────────────────────────────────────────

#title-slide[Wymagania]

#slide(title: [Wymagania funkcjonalne vs niefunkcjonalne])[

  #cols[
    #defblock[Funkcjonalne][
      _Co_ system ma robić?
      - Złożenie zamówienia
      - Wysłanie potwierdzenia
      - Historia transakcji
    ]
  ][
    #alertblock[Niefunkcjonalne][
      _Jak dobrze_ ma to robić?
      - *Reliability* — mimo awarii
      - *Scalability* — mimo wzrostu
      - *Maintainability* — łatwość zmian
    ]
  ]
]

#slide(title: [Trzy filary (Kleppmann)])[

  #defblock[Designing Data-Intensive Applications, rozdz. 1][
    + *Reliability* — system działa poprawnie nawet gdy coś idzie nie tak
    + *Scalability* — radzi sobie ze wzrostem obciążenia
    + *Maintainability* — ludzie mogą efektywnie z nim pracować
  ]

  #src[M. Kleppmann — _Designing Data-Intensive Applications_, O'Reilly, 2017]
]

// ── Back-of-the-Envelope ─────────────────────────────────────

#title-slide[Back-of-the-Envelope Estimation]

#slide(title: [Szacowanie „na serwetce"])[

  Zanim projektujesz — #hl[policz].

  #exblock[Pytania na start][
    - Ilu mamy użytkowników? (DAU)
    - Ile żądań/s? (QPS)
    - Ile danych dziennie / rocznie?
    - Stosunek odczytów do zapisów?
    - Akceptowalne opóźnienie? (p50, p99)
  ]
]

#slide(title: [Rzędy wielkości — opóźnienia])[

  #align(center)[
    #table(
      columns: 2,
      align: (left, right),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Operacja],
        text(fill: white, weight: "bold")[Opóźnienie],
      ),
      [Odczyt z RAM], [~100 ns],
      [Odczyt z SSD], [~100 μs],
      [Odczyt z dysku (HDD)], [~10 ms],
      [Round-trip w DC], [~0.5 ms],
      [Round-trip transatlantycki], [~150 ms],
    )
  ]
]

#slide(title: [Rzędy wielkości — przepustowość])[

  #align(center)[
    #table(
      columns: 2,
      align: (left, right),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[System],
        text(fill: white, weight: "bold")[QPS],
      ),
      [1 serwer webowy], [1K–10K],
      [1 instancja PostgreSQL (odczyty)], [5K–20K],
      [1 instancja Redis], [~100K],
      [Kafka (1 partycja)], [~100K msg/s],
    )
  ]
]

#slide(title: [Przykład: system powiadomień push])[

  #exblock[Dane wejściowe][
    10 mln użytkowników, średnio 5 powiadomień/dzień.
  ]

  Szacunki:
  - Powiadomień/dzień: 10M × 5 = *50M*
  - Średnio na sekundę: 50M / 86 400 ≈ *~580/s*
  - Szczyt (10× średniej): *~5 800/s*
  - Storage (100B × 30 dni): *~150 GB*
]

#slide(title: [Estimation w chmurze — ile to kosztuje?])[
  #defblock[Cloud pricing = nowy wymiar estimation][
    Oprócz QPS i storage — w chmurze liczymy *koszt*.
  ]

  #align(center)[
    #sm[#table(
      columns: 3,
      align: (left, right, right),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Zasób],
        text(fill: white, weight: "bold")[Cena (orient.)],
        text(fill: white, weight: "bold")[Nasz system/mies.],
      ),
      [Lambda (1M req)],   [\$0.20],   [50M × 30 ≈ \$300],
      [S3 storage (GB)],   [\$0.023],  [150 GB ≈ \$3.50],
      [SQS (1M msg)],      [\$0.40],   [1.5B ≈ \$600],
    )]
  ]
]

// ── Modele architektoniczne ──────────────────────────────────

#title-slide[Modele architektoniczne]

#slide(title: [Client-Server i Peer-to-Peer])[

  #cols[
    #defblock[Client-Server][
      Serwer odpowiada na żądania.
      - Prostota, centralna kontrola
      - Single point of failure
      - Np. REST API + SPA
    ]
  ][
    #defblock[Peer-to-Peer][
      Każdy węzeł = klient i serwer.
      - Brak centralnej awarii
      - Trudna spójność danych
      - Np. BitTorrent, blockchain
    ]
  ]
]

#slide(title: [Event-Driven i Hybrid])[

  #cols[
    #defblock[Event-Driven][
      Komunikacja przez zdarzenia.
      - Luźne powiązanie
      - Asynchroniczność
      - Np. Kafka + mikroserwisy
    ]
  ][
    #defblock[Hybrid][
      Łączenie modeli.
      - REST — API publiczne
      - Eventy — wewnętrznie
      - P2P — CDN/edge
    ]
  ]
]

// ── SLA / SLO / SLI ─────────────────────────────────────────

#title-slide[SLA / SLO / SLI]

#slide(title: [Kontrakt niezawodności])[

  #defblock[Definicje][
    - *SLI* — metryka: np. opóźnienie p99, error rate
    - *SLO* — cel: p99 opóźnienia < 200ms w 99.9% czasu
    - *SLA* — kontrakt z konsekwencjami (SLO + kary)
  ]

  #src[Google SRE Book — _Service Level Objectives_, rozdz. 4]
]

#slide(title: [„Dziewiątki" dostępności])[

  #align(center)[
    #table(
      columns: 3,
      align: (left, center, center),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Dostępność],
        text(fill: white, weight: "bold")[Downtime/rok],
        text(fill: white, weight: "bold")[Downtime/mies.],
      ),
      [99% (dwie 9)],      [3.65 dni],   [7.31 h],
      [99.9% (trzy 9)],    [8.77 h],     [43.83 min],
      [99.99% (cztery 9)], [52.60 min],  [4.38 min],
      [99.999% (pięć 9)],  [5.26 min],   [26.30 s],
    )
  ]
]

// ── Skalowanie ───────────────────────────────────────────────

#title-slide[Skalowanie]

#slide(title: [Pionowe vs Poziome])[

  #cols[
    #defblock[Scale Up (pionowe)][
      Większy serwer.
      - ✅ Brak zmian w kodzie
      - ❌ Fizyczne limity
      - ❌ Single point of failure
    ]
  ][
    #defblock[Scale Out (poziome)][
      Więcej serwerów.
      - ✅ Nieograniczone (teoria)
      - ✅ Redundancja
      - ❌ Wymaga stateless design
    ]
  ]
]

#slide(title: [Stateless vs Stateful])[

  #alertblock[Zasada nr 1 skalowania poziomego][
    Serwisy powinny być *bezstanowe* (stateless) — cały stan w zewnętrznym systemie (baza, cache, object storage).
  ]

  Gdy stan jest nieunikniony:
  - *Sticky sessions* — ten sam user → ta sama instancja
  - *Zewnętrzny session store* — np. Redis
  - *Consistent hashing* — deterministyczne przypisanie
]

#slide(title: [Skalowanie w chmurze — managed services])[
  #exblock[Nie skaluj sam — daj chmurze skalować za Ciebie][
    Managed services przejmują operacyjną złożoność skalowania.
  ]

  #cols[
    *Self-managed:*
    - Ręczne repliki DB
    - Własny Redis cluster
    - Konfiguracja LB + health checks
    - Budzenie się o 3 w nocy
  ][
    *Cloud-managed:*
    - RDS Multi-AZ + Read Replicas
    - ElastiCache / Cloud Memorystore
    - ALB / Cloud Load Balancing
    - Autoscaling + alerting
  ]
]

// ── Scale From Zero To Millions ──────────────────────────────

#title-slide[Przykład: Scale From Zero To Millions]

#slide(title: [Ewolucja architektury (A. Xu)])[

  #exblock[System Design Interview, rozdz. 1][
    Etapy wzrostu typowej aplikacji webowej:
  ]

  + *1 serwer* — web + DB na jednej maszynie
  + *Separacja DB* — dedykowany serwer bazodanowy
  + *Load balancer* — 2+ serwery web, repliki DB
  + *Cache* — Redis/Memcached dla gorących danych
]

#slide(title: [Ewolucja — kolejne etapy])[

  + *CDN* — statyczne zasoby bliżej użytkownika
  + *Kolejka wiadomości* — asynchroniczne zadania
  + *Sharding bazy* — podział danych na partycje
]

#slide(title: [Kiedy co wprowadzać?])[

  #align(center)[
    #table(
      columns: 2,
      align: (left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Sygnał],
        text(fill: white, weight: "bold")[Rozwiązanie],
      ),
      [CPU DB > 80%],                   [Repliki odczytu],
      [Opóźnienie rośnie z ruchem],     [Load balancer + instancje],
      [Te same dane czytane 100×],      [Redis / Memcached],
      [Użytkownicy w innych regionach], [CDN + multi-region],
      [Timeouty przy wysyłce mail/SMS], [Kolejka wiadomości],
    )
  ]
]

// ── Dyskusja ─────────────────────────────────────────────────

#focus-slide[
  Projektujesz system powiadomień push dla aplikacji z *10 mln użytkowników*.

  Jakie metryki oszacujesz na samym początku?

  Jakie *SLO* zaproponujesz — i _komu_?
]

// ── Podsumowanie ─────────────────────────────────────────────

#title-slide[Podsumowanie]

#slide(title: [Kluczowe wnioski])[

  + *Projektowanie ≠ operowanie* — decyzje _przed_ wdrożeniem
  + *Wymagania niefunkcjonalne* kształtują architekturę
  + *Policz zanim projektujesz* — estimation na serwetce
  + *SLO definiuj od dnia pierwszego*
  + *Scale out > scale up* — wymaga stateless design
]

#slide(title: [Źródła i lektury])[

  - M. Kleppmann — _DDIA_, rozdz. 1
  - A. Xu — _System Design Interview_, rozdz. 1–3
  - Google SRE Book, rozdz. 4
  - M. Takada — _Distributed Systems for Fun and Profit_, rozdz. 1
]

#slide(title: [Następny wykład])[

  #defblock[Wykład 2: Style architektoniczne][
    Monolit · Mikroserwisy · Modularny monolit
  ]
]

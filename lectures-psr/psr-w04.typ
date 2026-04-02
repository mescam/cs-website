// Wykład 4: Wzorce architektoniczne — Event-Driven Architecture, CQRS, Event Sourcing
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
  title: "Wzorce architektoniczne",
  subtitle: [EDA · CQRS · Event Sourcing · Saga],
  authors: "mgr inż. Jakub Woźniak",
  info: [Politechnika Poznańska · Instytut Informatyki · Semestr letni 2025/26],
)

#title-slide[Plan wykładu]

#slide(title: [Agenda])[

  - Event-Driven Architecture — trzy oblicza
  - CQRS — oddzielne modele odczytu i zapisu
  - Event Sourcing — log zdarzeń jako źródło prawdy
  - Orkiestracja vs Choreografia
  - Wzorzec Sagi — transakcje rozproszone
  - #emoji.cloud Managed event/workflow services
]

// ── Event-Driven Architecture ────────────────────────────────

#title-slide[Event-Driven Architecture]

#slide(title: [Czym jest EDA?])[

  #defblock[Event-Driven Architecture][
    Architektura, w której komponenty komunikują się przez *zdarzenia*. Producent nie wie, kto konsumuje — i odwrotnie.
  ]

  Kluczowe cechy:
  - *Decoupling* — producent i konsument niezależni
  - *Asynchroniczność* — brak blokującego oczekiwania
  - *Skalowalność* — łatwe dodawanie konsumentów
  - Kafka, RabbitMQ, EventBridge jako *event backbone*
]

#slide(title: [Trzy oblicza zdarzeń (M. Fowler)])[

  #align(center)[
    #sm[#table(
      columns: 3,
      align: (left, left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Wzorzec],
        text(fill: white, weight: "bold")[Opis],
        text(fill: white, weight: "bold")[Przykład],
      ),
      [*Event Notification*],
        [„Coś się stało" — minimalna informacja],
        [`OrderPlaced { orderId }`],
      [*Event-Carried State Transfer*],
        [Zdarzenie niesie pełne dane],
        [`OrderPlaced { id, items, total }`],
      [*Event Sourcing*],
        [Log zdarzeń = źródło prawdy],
        [Pełna historia zmian konta],
    )]
  ]

  #src[M. Fowler — „What do you mean by 'Event-Driven'?" · martinfowler.com/articles/201701-event-driven.html]
]

#slide(title: [Kiedy EDA?])[

  #cols[
    #exblock[TAK, gdy...][
      - Wielu konsumentów tego samego zdarzenia
      - Potrzebujesz loose coupling
      - Operacje mogą być asynchroniczne
      - System event-heavy (logi, metryki, notyfikacje)
    ]
  ][
    #alertblock[NIE, gdy...][
      - Potrzebujesz natychmiastowej odpowiedzi
      - Prosty CRUD bez fan-outu
      - Mały system, 1-2 serwisy
      - Trudno debugować eventual consistency
    ]
  ]
]

// ── CQRS ─────────────────────────────────────────────────────

#title-slide[CQRS]

#slide(title: [Command Query Responsibility Segregation])[

  #defblock[CQRS][
    Oddzielne modele dla *zapisów* (Command) i *odczytów* (Query). Zamiast jednego modelu ORM — dwa, zoptymalizowane pod różne potrzeby.
  ]

  - *Command model* — walidacja, reguły biznesowe, zapis
  - *Query model* — zdenormalizowane widoki, szybkie odczyty
  - Modele mogą mieć *różne bazy danych*

  #src[M. Fowler — „CQRS" · martinfowler.com/bliki/CQRS.html]
]

#slide(title: [Kiedy stosować CQRS?])[

  #cols[
    #exblock[TAK, gdy...][
      - Odczyty i zapisy mają *różne wymagania*
      - Read-heavy system (100:1 read/write)
      - Potrzebujesz wielu widoków tych samych danych
      - Łączysz z Event Sourcing
    ]
  ][
    #alertblock[NIE, gdy...][
      - Prosty CRUD — overhead się nie opłaci
      - Mały zespół bez doświadczenia
      - Dane są proste i jednomodelowe
      - Silna potrzeba strong consistency
    ]
  ]
]

#slide(title: [CQRS + Event Sourcing])[

  #defblock[Jak się łączą?][
    Write model emituje *zdarzenia* → zdarzenia zapisywane w *event store* → *projekcje* budują read model → eventual consistency między modelami.
  ]

  Korzyści połączenia:
  - Write model: append-only event log — szybki zapis
  - Read model: zdenormalizowane widoki — szybki odczyt
  - Można zbudować *wiele projekcji* z tego samego strumienia

  #alertblock[Uwaga][
    Eventual consistency = użytkownik może przez chwilę widzieć stare dane. Projektuj UI z tym na uwadze.
  ]
]

// ── Event Sourcing ───────────────────────────────────────────

#title-slide[Event Sourcing]

#slide(title: [Log zdarzeń jako źródło prawdy])[

  #defblock[Event Sourcing][
    Zamiast przechowywać *aktualny stan*, przechowujesz *sekwencję zdarzeń*, które do tego stanu doprowadziły. Stan = replay wszystkich eventów.
  ]

  #exblock[Przykład: konto bankowe][
    `AccountOpened { balance: 0 }` \
    `MoneyDeposited { amount: 1000 }` \
    `MoneyWithdrawn { amount: 200 }` \
    Stan aktualny: balance = 800
  ]
]

#slide(title: [Snapshoty i odtwarzanie])[

  Problem: replay milionów eventów = wolny start.

  #defblock[Snapshot][
    Co N eventów zapisz pełny stan. Odtwarzanie: załaduj snapshot + replay eventów od snapshotu.
  ]

  #align(center)[
    #sm[#table(
      columns: 2,
      align: (left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Podejście],
        text(fill: white, weight: "bold")[Czas odtwarzania],
      ),
      [Full replay (10K eventów)],   [~200ms],
      [Full replay (1M eventów)],    [~20s],
      [Snapshot + 100 eventów],      [~5ms],
    )]
  ]
]

#slide(title: [Problemy Event Sourcing])[

  #alertblock[Realne wyzwania][
    - *GDPR* — prawo do zapomnienia vs append-only log (crypto-shredding)
    - *Schema evolution* — format eventów zmienia się w czasie
    - *Rozmiar logu* — archiwizacja, retencja, snapshoty
    - *Złożoność* — replay, projekcje, debugging
    - *Eventual consistency* — UI musi to obsługiwać
  ]

  #src[Greg Young — „CQRS and Event Sourcing" (DDD Europe 2016)]
]

// ── Orkiestracja vs Choreografia ─────────────────────────────

#title-slide[Orkiestracja vs Choreografia]

#slide(title: [Dwa podejścia do koordynacji])[

  #cols[
    #defblock[Orkiestracja][
      Centralny *koordynator* steruje przepływem.
      - Łatwe śledzenie i debugowanie
      - Single point of failure
      - Np. Temporal, Step Functions
    ]
  ][
    #defblock[Choreografia][
      Serwisy *reagują na zdarzenia* autonomicznie.
      - Loose coupling
      - Trudniejsze debugowanie
      - Np. Kafka + eventy
    ]
  ]
]

#slide(title: [Porównanie])[

  #align(center)[
    #sm[#table(
      columns: 3,
      align: (left, center, center),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Aspekt],
        text(fill: white, weight: "bold")[Orkiestracja],
        text(fill: white, weight: "bold")[Choreografia],
      ),
      [Kontrola],        [Centralna],     [Rozproszona],
      [Coupling],         [Wyższy],       [Niższy],
      [Debugowanie],      [Łatwiejsze],   [Trudniejsze],
      [Elastyczność],     [Mniejsza],     [Większa],
      [Narzędzia],        [Temporal, Step Functions], [Kafka, EventBridge],
      [Złożony przepływ], [Preferowane],  [Ryzykowne],
    )]
  ]
]

// ── Wzorzec Sagi ─────────────────────────────────────────────

#title-slide[Wzorzec Sagi]

#slide(title: [Saga — transakcje rozproszone bez locków])[

  #defblock[Saga (Garcia-Molina & Salem, 1987)][
    Sekwencja *lokalnych transakcji*. Każdy krok ma *kompensację* — operację cofającą jego efekt. Jeśli krok N padnie → wykonaj kompensacje N-1 ... 1.
  ]

  Dlaczego nie 2PC (Two-Phase Commit)?
  - 2PC = *blokujący* — wszystkie zasoby czekają na koordynatora
  - 2PC = *single point of failure* koordynatora
  - 2PC nie skaluje się w mikroserwisach

  #src[H. Garcia-Molina, K. Salem — „Sagas" (ACM SIGMOD, 1987)]
]

#slide(title: [Choreograficzna vs orkiestracyjna saga])[

  #cols[
    #defblock[Saga choreograficzna][
      Serwisy emitują eventy — kolejny krok reaguje na event poprzedniego.
      - + Brak centralnego punktu awarii
      - − Trudne śledzenie przepływu
      - − Cykliczne zależności
    ]
  ][
    #defblock[Saga orkiestracyjna][
      Saga Orchestrator koordynuje kroki i kompensacje.
      - + Jasny przepływ, łatwy monitoring
      - + Centralne zarządzanie kompensacjami
      - − Orchestrator = dodatkowy serwis
    ]
  ]

  #src[C. Richardson — _Microservices Patterns_, rozdz. 4]
]

#slide(title: [Case study: system zamówień])[

  #exblock[Przepływ][
    Zamówienie → Rezerwacja stocku → Płatność → Wysyłka
  ]

  #alertblock[Co jeśli płatność się nie powiedzie?][
    Kompensacja: *zwolnij zarezerwowany stock*. \
    Zamówienie zmienia status na „anulowane".
  ]

  #align(center)[
    #sm[#table(
      columns: 3,
      align: (left, center, center),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Cecha],
        text(fill: white, weight: "bold")[2PC],
        text(fill: white, weight: "bold")[Saga],
      ),
      [Blokowanie zasobów], [Tak], [Nie],
      [Spójność],           [Strong], [Eventual],
      [Skalowanie],         [Słabe],  [Dobre],
      [Kompensacje],        [Nie potrzebne], [Wymagane],
      [Złożoność kodu],     [Niska],  [Wyższa],
    )]
  ]
]

// ── Cloud — Managed event/workflow services ──────────────────

#title-slide[Managed event/workflow services]

#slide(title: [Managed event routing])[

  #align(center)[
    #sm[#table(
      columns: 3,
      align: (left, left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Dostawca],
        text(fill: white, weight: "bold")[Usługa],
        text(fill: white, weight: "bold")[Model],
      ),
      [*AWS*],          [EventBridge],  [Event bus + reguły routingu],
      [*Google Cloud*], [Eventarc],     [Event routing do Cloud Run / Functions],
      [*Azure*],        [Event Grid],   [Pub/Sub zdarzeniowy, reaktywny],
      [*CNCF*],         [CloudEvents],  [Standard formatu zdarzeń (portability)],
    )]
  ]

  #exblock[CloudEvents][
    Otwarty standard opisu zdarzeń (CNCF). Ujednolica format między dostawcami: `source`, `type`, `data`. Wspierany przez EventBridge, Event Grid, Eventarc.
  ]
]

#slide(title: [Managed workflow orchestration])[

  #align(center)[
    #sm[#table(
      columns: 3,
      align: (left, left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Dostawca],
        text(fill: white, weight: "bold")[Usługa],
        text(fill: white, weight: "bold")[Cechy],
      ),
      [*AWS*],      [Step Functions],    [JSON state machine, Lambda integration, saga pattern],
      [*Google*],   [Workflows],         [YAML DSL, connector library, HTTP-based],
      [*Azure*],    [Durable Functions], [Code-first (C\#/JS/Python), fan-out/fan-in],
      [*Temporal*], [Temporal Cloud],    [Code-first, replay, managed Temporal],
    )]
  ]

  #exblock[Zasada][
    Nie buduj własnego orchestratora — chyba że masz *bardzo* dobry powód.
  ]
]

// ── Dyskusja ─────────────────────────────────────────────────

#focus-slide[
  Event Sourcing brzmi świetnie w teorii — pełna historia zmian, audit trail za darmo, możliwość odtworzenia stanu.

  Ale jakie są _realne_ problemy?

  Kiedy Event Sourcing jest *overkillem*?
]

// ── Podsumowanie ─────────────────────────────────────────────

#title-slide[Podsumowanie]

#slide(title: [Kluczowe wnioski])[

  + *EDA = decoupling* — ale 3 różne wzorce, nie mylić
  + *CQRS* = oddzielne modele — nie zawsze potrzebny
  + *Event Sourcing* = audit trail + replay, ale GDPR i złożoność
  + *Saga > 2PC* w mikroserwisach — kompensacje zamiast locków
  + *Orkiestracja vs choreografia* — dobierz do złożoności przepływu
  + *Managed workflow* — Step Functions / Temporal zamiast DIY
]

#slide(title: [Źródła i lektury])[

  - C. Richardson — _Microservices Patterns_, rozdz. 4, 7
  - S. Newman — _Building Microservices_, rozdz. 6
  - M. Fowler — _Event Sourcing_, _CQRS_, _What do you mean by Event-Driven?_
  - Greg Young — _CQRS and Event Sourcing_ (DDD Europe 2016)
  - Netflix — _Conductor: a microservices orchestrator_ (blog)
  - Temporal.io — docs.temporal.io
  - H. Garcia-Molina, K. Salem — _Sagas_ (ACM SIGMOD, 1987)
]

#slide(title: [Następny wykład])[

  #defblock[Wykład 5: Dane w systemach rozproszonych][
    Database per Service · Replikacja · Partycjonowanie · CAP/PACELC
  ]
]

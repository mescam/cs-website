// Wykład 3: Komunikacja w systemach rozproszonych
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
  title: "Komunikacja w systemach rozproszonych",
  subtitle: [REST · gRPC · Message Brokers · API Gateway],
  authors: "mgr inż. Jakub Woźniak",
  info: [Politechnika Poznańska · Instytut Informatyki · Semestr letni 2025/26],
)

#title-slide[Plan wykładu]

#slide(title: [Agenda])[

  - Komunikacja synchroniczna: REST, gRPC, GraphQL
  - Komunikacja asynchroniczna: Message Brokers
  - Wzorce komunikacji
  - API Gateway i Backend for Frontend
  - Ewolucja kontraktów i idempotencja
  - ☁️ Managed messaging i managed API Gateway
]

// ── Komunikacja synchroniczna ────────────────────────────────

#title-slide[Komunikacja synchroniczna]

#slide(title: [REST])[

  #defblock[Cechy REST][
    - Zasoby identyfikowane przez URL (`/api/orders/123`)
    - Operacje przez metody HTTP (GET, POST, PUT, DELETE)
    - Bezstanowość — każdy request zawiera pełny kontekst
    - Format: najczęściej JSON
  ]
]

#slide(title: [REST — zalety i wady])[

  #cols[
    *Zalety:*
    - Uniwersalność — każdy język
    - Cacheowalność (HTTP, CDN)
    - Prostota debugowania
  ][
    *Wady:*
    - Over/under-fetching
    - Brak formalnego kontraktu (opcjonalny OpenAPI)
    - Tekstowy JSON — większy payload
  ]
]

#slide(title: [gRPC])[

  #defblock[Cechy gRPC][
    - *Protocol Buffers* — binarny format ze schematem
    - Transport: *HTTP/2* — multiplexing, kompresja nagłówków
    - Generowanie kodu z pliku `.proto`
    - Natywny streaming (unary, server, client, bidirectional)
  ]
]

#slide(title: [gRPC — zalety i wady])[

  #cols[
    *Zalety:*
    - ~10× mniejszy payload
    - ~2–5× mniejsze opóźnienie
    - Formalny kontrakt
    - Natywny streaming
  ][
    *Wady:*
    - Nie działa w przeglądarce (bez grpc-web)
    - Trudniejsze debugowanie (dane binarne)
    - Wymaga generowania kodu
  ]
]

#slide(title: [GraphQL])[

  #defblock[Cechy GraphQL][
    - Klient *definiuje kształt odpowiedzi*
    - Jeden endpoint (`/graphql`)
    - Silne typowanie, introspection
  ]

  #cols[
    *Kiedy stosować:*
    - Złożone, zagnieżdżone dane
    - Wielu klientów (mobile vs web)
    - Szybko iterujący frontend
  ][
    *Kiedy nie:*
    - Proste CRUD — REST wystarczy
    - Operacje zapisu
    - Ryzyko ciężkich zapytań
  ]
]

#slide(title: [Porównanie: REST vs gRPC vs GraphQL])[

  #align(center)[
    #sm[#table(
      columns: 4,
      align: (left, center, center, center),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Cecha],
        text(fill: white, weight: "bold")[REST],
        text(fill: white, weight: "bold")[gRPC],
        text(fill: white, weight: "bold")[GraphQL],
      ),
      [Format],       [JSON],      [Protobuf],      [JSON],
      [Transport],    [HTTP/1.1+], [HTTP/2],        [HTTP/1.1+],
      [Kontrakt],     [OpenAPI],   [`.proto`],      [Schema],
      [Streaming],    [SSE],       [Natywny],       [Subskrypcje],
      [Typowe użycie],[Publiczne], [Serwis↔serwis], [Frontend↔back.],
      [Opóźnienie],   [Średnie],   [Niskie],        [Średnie],
    )]
  ]
]

// ── Komunikacja asynchroniczna ────────────────────────────────

#title-slide[Komunikacja asynchroniczna]

#slide(title: [Message Brokers — idea])[

  #defblock[Idea][
    Producent wysyła wiadomość do *brokera*, konsument ją odbiera. Nie muszą się znać ani działać jednocześnie.
  ]

  #cols[
    #exblock[Queue (punkt-punkt)][
      Wiadomość → *jeden* konsument.
      - Podział pracy
      - SQS, RabbitMQ
    ]
  ][
    #exblock[Topic (pub/sub)][
      Wiadomość → *wszyscy* subskrybenci.
      - Powiadamianie zdarzeniami
      - Kafka, SNS, NATS
    ]
  ]
]

#slide(title: [Apache Kafka])[

  #defblock[Kluczowe koncepcje][
    - *Topic* — nazwany strumień wiadomości
    - *Partition* — shard topiku, ordering w obrębie partycji
    - *Consumer Group* — każda partycja → jeden konsument w grupie
    - *Retention* — wiadomości nie znikają po konsumpcji
  ]

  Kafka ≠ tradycyjna kolejka:
  - Konsumenci mogą „cofnąć się w czasie" (replay)
  - Append-only log — architektura oparta na logu
]

#slide(title: [RabbitMQ vs Kafka vs NATS])[

  #align(center)[
    #sm[#table(
      columns: 4,
      align: (left, center, center, center),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Cecha],
        text(fill: white, weight: "bold")[RabbitMQ],
        text(fill: white, weight: "bold")[Kafka],
        text(fill: white, weight: "bold")[NATS],
      ),
      [Model],         [Queue + Pub/Sub],  [Log (Pub/Sub)],   [Pub/Sub + Queue],
      [Ordering],      [Per queue],        [Per partition],   [Brak gwarancji],
      [Replay],        [Nie],             [Tak],             [JetStream: Tak],
      [Przepustowość], [Dziesiątki tys/s], [Setki tys/s],    [Miliony/s],
      [Złożoność ops], [Średnia],          [Wysoka],          [Niska],
    )]
  ]
]

// ── Wzorce komunikacji ──────────────────────────────────────

#title-slide[Wzorce komunikacji]

#slide(title: [Request-Response i Fire-and-Forget])[

  #cols[
    #defblock[Request-Response][
      Klient wysyła, czeka na odpowiedź.
      - REST, gRPC (unary)
      - + Prosty model
      - − Tight coupling
    ]
  ][
    #defblock[Fire-and-Forget][
      Producent wysyła, nie czeka.
      - Kolejka, zdarzenie
      - + Loose coupling
      - − Brak potwierdzenia
    ]
  ]
]

#slide(title: [Request-Reply via Queue i Event Notification])[

  #cols[
    #defblock[Request-Reply via Queue][
      Żądanie i odpowiedź przez kolejki.
      - Correlation ID łączy parę
      - + Async + odpowiedź
      - − Złożoność
    ]
  ][
    #defblock[Event Notification][
      „Coś się stało" — konsumenci decydują.
      - `OrderPlaced`, `PaymentDone`
      - + Maks. decoupling
      - − Trudne śledzenie
    ]
  ]
]

// ── API Gateway ──────────────────────────────────────────────

#title-slide[API Gateway]

#slide(title: [Funkcje API Gateway])[

  #defblock[API Gateway — bramka do systemu][
    - *Trasowanie* — kierowanie żądań do serwisów
    - *Rate limiting* — ochrona przed przeciążeniem
    - *Uwierzytelnianie* — weryfikacja tokenów na brzegu
    - *Load balancing* — rozproszenie ruchu
  ]

  Narzędzia self-hosted: Kong, Envoy, Traefik
]

#slide(title: [Backend for Frontend (BFF)])[

  #exblock[Wzorzec BFF][
    Dedykowany gateway *per typ klienta*: mobile (mniejsze payloady), web (bogatsze odpowiedzi), IoT.
  ]

  Dlaczego nie jeden gateway?
  - Różni klienci = *różne potrzeby*
  - Zespół mobilny nie blokuje zespołu webowego
  - Unikamy „God Gateway" z nadmierną logiką
]

// ── Ewolucja kontraktów ──────────────────────────────────────

#title-slide[Ewolucja kontraktów]

#slide(title: [API Versioning])[

  #cols[
    #defblock[Strategie][
      - *URL path*: `/api/v1/orders`
      - *Header*: `Accept: ...v2+json`
      - *Query*: `?version=2`
    ]
  ][
    #alertblock[Zasada nr 1][
      *Nigdy nie łam backward compatibility.*

      Dodawanie pól = OK. \
      Usuwanie/zmiana = BREAKING.
    ]
  ]
]

#slide(title: [Schema Evolution])[

  #defblock[Serializacja ze schematem][
    - *Avro* — schema w rejestrze, ewoluowalny
    - *Protocol Buffers* — pola numerowane, backward/forward compatible
    - *JSON Schema* — walidacja JSON
  ]

  Zasady:
  - Nowe pola = *opcjonalne* z wartością domyślną
  - Nigdy nie zmieniaj numeru/nazwy istniejącego pola
  - Usuwanie = `reserved`
]

// ── Idempotencja ─────────────────────────────────────────────

#title-slide[Idempotencja]

#slide(title: [Idempotencja operacji])[

  #defblock[Definicja][
    Operacja jest *idempotentna*, jeśli wykonanie jej raz daje ten sam efekt co wielokrotne wykonanie.
  ]

  #cols[
    #exblock[Z natury idempotentne][
      - `GET /orders/123`
      - `PUT /orders/123 {...}`
      - `DELETE /orders/123`
    ]
  ][
    #alertblock[NIE idempotentne][
      - `POST /orders` — nowe zamówienie
      - `POST /payments` — pobiera pieniądze!
    ]
  ]
]

#slide(title: [Klucze idempotentności])[

  #defblock[Rozwiązanie dla POST][
    Klient generuje unikalny *Idempotency-Key* w nagłówku. Serwer: sprawdza w Redis → przetworzone? zwróć zapisaną odpowiedź : przetwórz i zapisz.
  ]

  Dlaczego to krytyczne:
  - Timeout ≠ „request nie dotarł"
  - Retry bez idempotencji = *duplikaty*
  - Stripe, PayPal, AWS — wszystkie mają `Idempotency-Key`
]

// ── Sync vs Async ─────────────────────────────────────────────

#title-slide[Sync vs Async]

#slide(title: [Macierz decyzyjna])[

  #align(center)[
    #table(
      columns: 3,
      align: (left, center, center),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Scenariusz],
        text(fill: white, weight: "bold")[Sync],
        text(fill: white, weight: "bold")[Async],
      ),
      [Użytkownik czeka na odpowiedź], [Tak], [Nie],
      [Operacja trwa > 1s],            [Nie], [Tak],
      [Wielu odbiorców zdarzenia],     [Nie], [Tak],
      [Proste CRUD],                   [Tak], [Nie],
      [Event-driven workflow],         [Nie], [Tak],
    )
  ]
]

// ── Cloud messaging i managed API Gateway ────────────────────

#title-slide[Cloud messaging i managed API Gateway]

#slide(title: [Managed Message Brokers — self-hosted vs cloud])[

  #align(center)[
    #sm[#table(
      columns: 3,
      align: (left, center, center),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Cecha],
        text(fill: white, weight: "bold")[Self-hosted],
        text(fill: white, weight: "bold")[Cloud-managed],
      ),
      [*RabbitMQ / Kafka*],    [Sam zarządzasz klastrem], [Płać za użycie — zero ops],
      [*Wydajność*],          [Konfigurowalna],         [Ilimitowana wertykalnie],
      [*SLA*],                [Twoja odpowiedzialność],  [99.9%+ od dostawcy],
      [*Skalowanie*],         [Ręczne / Kafka KRaft],   [Auto-scaling],
      [*Monitoring*],         [Prometheus + Grafana],    [Wbudowane dashboardy],
      [*Koszt*],             [CapEx (serwery) + OpEx], [Pay-per-use / ryczałt],
    )]
  ]

  #exblock[Kluczowa decyzja][
    Mały zespół? Krótkoterminowy projekt? → *Managed broker*. \
    Potrzebujesz pełnej kontroli lub masz specyficzne wymagania? → *Self-hosted Kafka*.
  ]
]

#slide(title: [Managed Message Brokers — serwisy chmurowe])[

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
      [*AWS*],          [SQS (queue), SNS (pub/sub), EventBridge], [Queue + Pub/Sub],
      [*Google Cloud*], [Pub/Sub],                                   [Queue + Pub/Sub],
      [*Azure*],        [Service Bus, Event Hubs],                  [Queue + Streaming],
      [*Confluent*],    [Confluent Cloud (Kafka as a service)],     [Full Kafka],
    )]
  ]

  #alertblock[EventBridge / Pub/Sub][
    Oprócz queue — *event buses* propagują zdarzenia między kontami, serwisami, nawet partnerami. \
    EventBridge: reguły → routing bez kodu.
  ]
]

#slide(title: [Managed API Gateway — chmurowe rozwiązania])[

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
      [*AWS*],          [API Gateway],                  [REST, HTTP, WebSocket; Lambda integration],
      [*Google Cloud*], [Cloud Endpoints / Gateway],   [gRPC, REST; Spiffe authentication],
      [*Azure*],        [API Management],              [Policy-based transforms, DevPortal],
      [*Kong*],         [Kong Cloud],                  [Plugin ecosystem, multi-cloud],
    )]
  ]

  #exblock[Co dostajesz „za darmo"][
    - Certyfikaty SSL, darmowe certyfikaty
    - Wbudowany rate limiting i throttling
    - Integracja z Lambda / Cloud Functions
    - Access logs, metryki, tracing — zero konfiguracji
  ]
]

// ── Case study: Chat System ──────────────────────────────────

#title-slide[Case study: Chat System]

#slide(title: [Design a Chat System (A. Xu)])[

  #exblock[Wymagania][
    1:1 i grupy, miliony online, dostarczenie < 200ms, persistencja, statusy doręczenia.
  ]

  #cols[
    #alertblock[Polling / Long-polling][
      - HTTP co N sekund
      - Marnowanie zasobów
      - *Nie nadaje się* dla chatu
    ]
  ][
    #defblock[WebSocket][
      - Persistent, full-duplex
      - Serwer wysyła bez żądania
      - Idealne dla real-time
    ]
  ]
]

#slide(title: [Chat — architektura na skalę])[

  #defblock[Komponenty][
    - *API Gateway* — uwierzytelnianie, trasowanie
    - *Chat service* — WebSocket, sesje
    - *Kafka* — bufor wiadomości, ordering
    - *Message store* — Cassandra (write-heavy)
    - *Push notification* — dla offline użytkowników
  ]

  Dlaczego Kafka? Buforowanie szczytu, fan-out grup, replay historii.
]

// ── Dyskusja ─────────────────────────────────────────────────

#focus-slide[
  System *e-commerce*. Serwis zamówień musi powiadomić: magazyn, płatności, e-mail.

  *Synchronicznie* (REST) czy *asynchronicznie* (kolejka)?

  Uzasadnij trade-offy.
]

// ── Podsumowanie ─────────────────────────────────────────────

#title-slide[Podsumowanie]

#slide(title: [Kluczowe wnioski])[

  + *REST* — uniwersalne, API publiczne
  + *gRPC* — szybkie, typowane, serwis↔serwis
  + *Message Brokers* — decoupling, odporność, fan-out
  + *Idempotencja* — bez niej retry = katastrofa
  + *Sync vs async* — macierz decyzyjna, nie dogmat
  + *Managed brokers* — wybierz mądrze: SQS/Pub/Sub dla prostoty, Kafka dla kontroli
]

#slide(title: [Źródła i lektury])[

  - M. Kleppmann — _DDIA_, rozdz. 4
  - S. Newman — _Building Microservices_, rozdz. 4
  - J. Kreps — _The Log_ (esej, LinkedIn Engineering)
  - A. Xu — _System Design Interview_, rozdz. 12
  - AWS Docs — SQS, SNS, EventBridge
  - GCP Docs — Cloud Pub/Sub
  - Azure Docs — Service Bus, Event Hubs
]

#slide(title: [Następny wykład])[

  #defblock[Wykład 4: Wzorce architektoniczne][
    Event-Driven Architecture · CQRS · Event Sourcing · Saga
  ]
]

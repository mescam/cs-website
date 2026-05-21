// Wykład 9: Serverless, FaaS i architektura na brzegu
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
  title: "Serverless, FaaS i architektura na brzegu",
  subtitle: [Koncepcja serverless #sym.dot.c FaaS #sym.dot.c Cold starts #sym.dot.c Edge #sym.dot.c WebAssembly #sym.dot.c Koszty],
  authors: "mgr inż. Jakub Woźniak",
  info: [Politechnika Poznańska · Instytut Informatyki · Semestr letni 2025/26],
)

#title-slide[Plan wykładu]

#slide(title: [Agenda])[

  - Koncepcja serverless — ewolucja modelu odpowiedzialności
  - FaaS — model wykonania, platformy, cykl życia funkcji
  - Cold starts — anatomia, benchmarki, strategie mitygacji
  - Wzorce event-driven serverless (fan-out, orkiestracja)
  - Serverless poza FaaS — bazy danych, kontenery, orkiestratory
  - Edge computing — obliczenia na brzegu sieci
  - WebAssembly na serwerze — WASI, Spin, porównanie z kontenerami
  - Ograniczenia i kiedy serverless to zły wybór
  - #emoji.cloud Porównanie kosztów i punkt break-even
  - Case study: Design Google Drive (A. Xu, rozdz. 15)
]

// ── Koncepcja Serverless ─────────────────────────────────────

#title-slide[Koncepcja serverless]

#slide(title: [Ewolucja modelu odpowiedzialności])[
  #defblock[Serverless #sym.eq.not „bez serwera" — oznacza „bez zarządzania serwerem"][
    Dostawca przejmuje pełną odpowiedzialność za infrastrukturę, skalowanie i dostępność.
  ]

  #sm[#table(
    columns: 3,
    align: (left, left, left),
    stroke: 0.5pt + ibm-gray-30,
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
    table.header(
      text(fill: white, weight: "bold")[Model],
      text(fill: white, weight: "bold")[Zarządzasz],
      text(fill: white, weight: "bold")[Dostawca zarządza],
    ),
    [*IaaS*], [Aplikacja, dane, runtime, OS], [Wirtualizacja, sieć, dyski],
    [*CaaS*], [Aplikacja, dane, runtime], [OS, orkiestracja kontenerów],
    [*PaaS*], [Aplikacja, dane], [Runtime, OS, skalowanie],
    [*FaaS*], [Kod funkcji], [Wszystko inne + skalowanie do zera],
    [*Serverless (pełny)*], [Logika biznesowa], [Compute + storage + integracje],
  )]
]

#slide(title: [Kluczowe cechy serverless])[

  + *Brak zarządzania serwerami* — zero provisioningu, patchowania, capacity planning
  + *Płatność za użycie* — rozliczenie per wywołanie + czas wykonania (ms)
  + *Automatyczne skalowanie* — od zera do tysięcy instancji
  + *Sterowanie zdarzeniami* — funkcja reaguje na event (HTTP, kolejka, plik, timer)
  + *Bezstanowość wykonania* — każde wywołanie niezależne; stan w zewnętrznych usługach

  #alertblock[Konsekwencja architektoniczna][
    Serverless *wymusza* dobrą architekturę: dekomponowanie na małe, bezstanowe jednostki ze zdefiniowanymi kontraktami (zdarzeniami).
  ]
]

// ── FaaS ─────────────────────────────────────────────────────

#title-slide[Functions as a Service (FaaS)]

#slide(title: [Model wykonania — cykl życia funkcji (AWS Lambda)])[
  #defblock[Pięć faz wywołania][
    + *Provisioning* (50–100 ms) — alokacja microVM, sieć
    + *Pobranie kodu* (50–500 ms) — ZIP z S3 lub obraz z ECR
    + *Inicjalizacja runtime* (50–1000 ms) — start Node.js / Python / JVM
    + *Inicjalizacja użytkownika* (0–10 000 ms) — klienty SDK, połączenia DB
    + *Wykonanie handlera* — właściwa logika biznesowa
  ]

  #exblock[Warm invocation][
    Fazy 1–4 pomijane — środowisko wykonania reużywane. Koszt: ~5–50 ms.
  ]
]

#slide(title: [Platformy FaaS — przegląd (2025/26)])[
  #sm[#table(
    columns: 5,
    align: (left, left, left, left, left),
    stroke: 0.5pt + ibm-gray-30,
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
    table.header(
      text(fill: white, weight: "bold")[Cecha],
      text(fill: white, weight: "bold")[AWS Lambda],
      text(fill: white, weight: "bold")[Azure Functions],
      text(fill: white, weight: "bold")[Cloud Functions 2nd gen],
      text(fill: white, weight: "bold")[Cloudflare Workers],
    ),
    [*Timeout*], [15 min], [30 min (Flex)], [60 min], [30 s (CPU)],
    [*Pamięć*], [128 MB – 10 GB], [256 MB – 16 GB], [128 MB – 32 GB], [128 MB],
    [*Skalowanie do zera*], [Tak], [Tak (Flex)], [Tak], [Tak],
    [*Równoległość/inst.*], [1 req], [Konfig.], [Do 1000 req], [Tak (isolates)],
    [*Cold start (typowy)*], [100–700 ms], [500 ms – 2 s], [1–5 s], [< 5 ms],
    [*Billing*], [1 ms], [100 ms (Flex)], [100 ms], [Per-request],
  )]

  #src[Dane: oficjalna dokumentacja AWS/Azure/GCP/Cloudflare, 2025/26.]
]

#slide(title: [AWS Lambda — nowości 2025/26])[
  #defblock[SnapStart (Java, Python, .NET)][
    Migawka pamięci (CRIU) po inicjalizacji #sym.arrow przywrócenie zamiast ponownego startu. \
    Java: 583 ms #sym.arrow 104 ms (*5,6#sym.times szybciej*). Python: 2–3#sym.times. .NET: 3–5#sym.times.
  ]

  #defblock[Lambda Managed Instances (re:Invent 2025)][
    Wiele requestów na jedno środowisko. Stała opłata + 15% management fee. Oszczędność 30–50% vs on-demand dla stałego ruchu.
  ]

  #defblock[Durable Functions (re:Invent 2025)][
    Timeout do 1 roku. Automatyczne checkpointy stanu. Brak opłaty za `context.wait()`. Workflow z człowiekiem w pętli.
  ]
]

// ── Cold Starts ──────────────────────────────────────────────

#title-slide[Cold starts]

#slide(title: [Anatomia cold startu])[
  #defblock[Cold start = Provisioning + Pobranie kodu + Init runtime + Init użytkownika][
    Każda faza dodaje opóźnienie. Dominujący składnik zależy od języka i rozmiaru paczki.
  ]

  #alertblock[Kiedy cold start się zdarza?][
    - Pierwsze wywołanie po wdrożeniu
    - Skok współbieżności (nowe instancje)
    - Timeout nieaktywności (zwykle 5–15 min)
    - Aktualizacja konfiguracji
  ]

  #sm[Cold starty dotyczą typowo 1–5% wywołań przy stabilnym ruchu.]
]

#slide(title: [Benchmarki cold startów — P50 / P99 (512 MB, ARM64)])[
  #sm[#table(
    columns: 4,
    align: (left, right, right, left),
    stroke: 0.5pt + ibm-gray-30,
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
    table.header(
      text(fill: white, weight: "bold")[Runtime],
      text(fill: white, weight: "bold")[P50],
      text(fill: white, weight: "bold")[P99],
      text(fill: white, weight: "bold")[Uwagi],
    ),
    [*Rust* (provided.al2023)], [16 ms], [22 ms], [Najszybszy; brak GC],
    [*Go* (provided.al2023)], [38 ms], [52 ms], [Skompilowany; szybki start],
    [*Node.js 22*], [148 ms], [210 ms], [V8 startup + moduły],
    [*Python 3.13*], [171 ms], [325 ms], [Interpreter CPython],
    [*Java 21 (JVM)*], [698 ms], [1100 ms], [JVM + class loading],
    [*Java 21 + SnapStart*], [100–200 ms], [200–400 ms], [5,6#sym.times poprawa],
    [*.NET 8 (NativeAOT)*], [80–150 ms], [150–250 ms], [Kompilacja natywna],
  )]

  #src[Źródło: github.com/maxday/lambda-perf (codzienne benchmarki).]
]

#slide(title: [Strategie mitygacji cold startów])[
  #cols[
    #defblock[1. Wybór runtime][
      SLA < 50 ms? #sym.arrow Rust / Go \
      SLA < 200 ms? #sym.arrow Node.js / Python \
      Istniejący kod Java? #sym.arrow SnapStart
    ]

    #defblock[2. Optymalizacja paczki][
      Tree shaking (esbuild, webpack) \
      Selektywne importy SDK \
      Minimalne obrazy kontenerowe
    ]
  ][
    #defblock[3. Provisioned Concurrency][
      Pre-inicjalizacja N środowisk. \
      Koszt: ~\$0,015/h per unit. \
      Opłacalność: SLA < 100 ms p99.
    ]

    #defblock[4. Init poza handlerem][
      Klienty SDK, pule połączeń — twórz *raz* na poziomie modułu, nie w handlerze.
    ]
  ]
]

// ── Event-driven Serverless ──────────────────────────────────

#title-slide[Wzorce event-driven serverless]

#slide(title: [Źródła zdarzeń — trzy modele wywołania])[
  #defblock[Synchroniczne (request-response)][
    API Gateway #sym.arrow Lambda. ALB #sym.arrow Lambda. Wywołujący czeka na odpowiedź.
  ]

  #defblock[Asynchroniczne (fire-and-forget)][
    S3 #sym.arrow Lambda. SNS #sym.arrow Lambda. EventBridge #sym.arrow Lambda. Wywołujący nie czeka.
  ]

  #defblock[Event Source Mapping (polling)][
    SQS #sym.arrow Lambda. Kinesis #sym.arrow Lambda. DynamoDB Streams #sym.arrow Lambda. Kafka (MSK) #sym.arrow Lambda. \
    Lambda sama odpytuje źródło; batch size konfigurowalny (1–10 000).
  ]
]

#slide(title: [Wzorzec: Fan-out (jedno zdarzenie #sym.arrow wielu konsumentów)])[
  #defblock[Architektura][
    Źródło (np. upload do S3) #sym.arrow SNS/EventBridge #sym.arrow N kolejek SQS #sym.arrow N funkcji Lambda
  ]

  Przykład — upload pliku:
  + *Walidacja* — sprawdzenie typu, rozmiaru
  + *Thumbnail* — generowanie miniaturki
  + *Skan antywirusowy* — ClamAV w kontenerze
  + *Indeksowanie metadanych* — zapis do DynamoDB
  + *Analityka* — zdarzenie do data lake

  #exblock[Korzyści][
    Dekopling: konsumenci nie wiedzą o sobie. Awaria jednego nie blokuje reszty. Każdy skaluje się niezależnie.
  ]
]

#slide(title: [Orkiestracja: AWS Step Functions])[
  #defblock[Problem: złożone workflow z kolejnością, warunkami, kompensacjami][
    Choreografia (EventBridge) #sym.arrow trudna do debugowania przy 10+ krokach.
  ]

  #defblock[Step Functions — maszyna stanów jako JSON/YAML][
    - Parallel, Choice, Wait, Map (przetwarzanie batch)
    - Wbudowane retry + catch + timeout
    - Widoczność: wizualna mapa wykonania
    - Koszt: \$0,025 per 1000 przejść stanów (Standard); \$0,001 (Express)
  ]

  #alertblock[Kiedy orkiestracja, kiedy choreografia?][
    *Orkiestracja*: workflow z gwarancją kolejności, kompensacjami (saga) \
    *Choreografia*: luźno powiązane domeny, prostsze przepływy (nawiązanie do wykładu 4)
  ]
]

// ── Serverless poza FaaS ─────────────────────────────────────

#title-slide[Serverless poza FaaS]

#slide(title: [Bazy danych serverless])[
  #sm[#table(
    columns: 5,
    align: (left, left, left, left, left),
    stroke: 0.5pt + ibm-gray-30,
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
    table.header(
      text(fill: white, weight: "bold")[Baza],
      text(fill: white, weight: "bold")[Model],
      text(fill: white, weight: "bold")[Skalowanie do zera],
      text(fill: white, weight: "bold")[Opóźnienie],
      text(fill: white, weight: "bold")[Koszt (10M req/mies.)],
    ),
    [*DynamoDB on-demand*], [NoSQL KV], [Tak], [< 10 ms p99], [\~\$7,50],
    [*Aurora Serverless v2*], [SQL (PG/MySQL)], [Min 0,5 ACU], [< 10 ms], [\~\$155],
    [*Neon*], [Postgres (HTTP API)], [Tak], [50–200 ms], [\~\$83],
    [*PlanetScale*], [MySQL (Vitess)], [Tak], [50–200 ms], [\~\$75],
  )]

  #alertblock[Trade-off][
    DynamoDB: najtańszy, ale brak SQL i JOINów. Aurora: pełny SQL, ale zawsze min. 0,5 ACU (\~\$43/mies.). Neon/PlanetScale: HTTP API = wyższe opóźnienie.
  ]
]

#slide(title: [Kontenery serverless — Fargate, Cloud Run, Container Apps])[
  #sm[#table(
    columns: 5,
    align: (left, left, left, left, left),
    stroke: 0.5pt + ibm-gray-30,
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
    table.header(
      text(fill: white, weight: "bold")[Platforma],
      text(fill: white, weight: "bold")[Dostawca],
      text(fill: white, weight: "bold")[Skalowanie do 0],
      text(fill: white, weight: "bold")[Timeout],
      text(fill: white, weight: "bold")[Koszt (10M req, 200 ms)],
    ),
    [*Fargate*], [AWS], [Nie], [Bez limitu], [\~\$36/mies. (zawsze)],
    [*Cloud Run*], [GCP], [Tak], [60 min], [\~\$17/mies.],
    [*Container Apps*], [Azure], [Tak], [30 min], [\~\$103/mies.],
  )]

  #exblock[Cloud Run — najlepszy stosunek elastyczności do ceny][
    Skalowanie do zera + do 1000 współbieżnych requestów na instancję + 60 min timeout + prosty deployment (`gcloud run deploy`).
  ]
]

// ── Edge Computing ───────────────────────────────────────────

#title-slide[Edge computing]

#slide(title: [Obliczenia na brzegu sieci — po co?])[
  #defblock[Problem: opóźnienie fizyczne][
    Prędkość światła #sym.approx 200 km/ms w światłowodzie. Warszawa #sym.arrow Virginia #sym.approx 40 ms RTT (same opóźnienie fizyczne, bez przetwarzania).
  ]

  Rozwiązanie: przenieś logikę *bliżej użytkownika* — na serwery brzegowe (edge).

  Zastosowania:
  - *Personalizacja* — modyfikacja odpowiedzi bez RTT do originu
  - *Testy A/B* — routing na podstawie hasha/cookie
  - *Geolokalizacja* — przekierowanie do regionalnego originu
  - *Uwierzytelnianie na brzegu* — walidacja JWT przed forwarding do originu
  - *Optymalizacja obrazów* — resize/format on-the-fly
  - *Ochrona przed botami* — challenge na brzegu, origin nie widzi ataku
]

#slide(title: [Platformy edge — porównanie])[
  #sm[#table(
    columns: 5,
    align: (left, left, left, left, left),
    stroke: 0.5pt + ibm-gray-30,
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
    table.header(
      text(fill: white, weight: "bold")[Platforma],
      text(fill: white, weight: "bold")[Runtime],
      text(fill: white, weight: "bold")[Cold start],
      text(fill: white, weight: "bold")[Lokalizacje],
      text(fill: white, weight: "bold")[Wyróżnik],
    ),
    [*Cloudflare Workers*], [V8 isolates], [< 5 ms], [300+], [Durable Objects, R2, zero egress],
    [*Lambda\@Edge*], [Node.js, Python], [50–200 ms], [500+ (CloudFront)], [Pełna integracja AWS],
    [*CloudFront Functions*], [JavaScript (ES 5.1)], [< 1 ms], [450+], [Najszybsze, najtańsze, ograniczone],
    [*Vercel Edge Functions*], [V8 isolates], [\~50 ms], [40+], [Integracja z Next.js],
    [*Fastly Compute*], [WebAssembly], [\~50 #sym.mu\s], [Mniej, ale wydajne], [Najszybszy (Wasm AOT)],
  )]
]

#slide(title: [Cloudflare Workers — izolaty V8])[
  #defblock[Architektura: V8 isolates (nie kontenery)][
    Tysiące izolatów w jednym procesie. Każdy zajmuje 2–10 MB (vs 50–500 MB kontener). Start w \~5 ms. Brak cold startu w tradycyjnym sensie.
  ]

  Ekosystem storage na brzegu:
  - *Workers KV* — globalny key-value (eventually consistent)
  - *Durable Objects* — koordynacja stanowa (strong consistency, SQLite)
  - *R2* — object storage (S3-kompatybilny, *zero opłat za egress*)
  - *D1* — SQLite na brzegu
  - *Queues* — kolejki asynchroniczne

  #alertblock[Ograniczenia][
    30 s CPU time. 128 MB pamięci. Brak natywnych binarek — tylko JS/Wasm. API specyficzne dla Cloudflare (vendor lock-in).
  ]
]

// ── WebAssembly na serwerze ──────────────────────────────────

#title-slide[WebAssembly na serwerze]

#slide(title: [Wasm poza przeglądarką — po co?])[
  #defblock[WebAssembly (Wasm) = przenośny, bezpieczny, szybki format binarny][
    Izolacja (sandbox) + deterministyczne wykonanie + brak cold startu.
  ]

  #exblock[Cytat (Solomon Hykes, współtwórca Dockera, 2019)][
    „Gdyby WASI istniało w 2008, nie musielibyśmy tworzyć Dockera."
  ]

  Czym Wasm różni się od kontenerów:
  - *Sandbox na poziomie modułu* — nie wymaga jądra OS
  - *Start w mikrosekundach* — vs setki ms dla kontenerów
  - *Rozmiar obrazu* — 1–5 MB vs 50–500 MB
  - *Gęstość* — tysiące instancji na jednej maszynie
]

#slide(title: [WASI — WebAssembly System Interface])[
  #defblock[WASI = standardowy interfejs Wasm do systemu operacyjnego][
    Bytecode Alliance (Mozilla, Fastly, Intel, Microsoft). \
    WASI 0.2.1 (stabilny, 2024). WASI 0.3 (async, w trakcie). WASI 1.0 (cel: późny 2026).
  ]

  Kluczowe interfejsy (WASI 0.2):
  - `wasi:http` — klient/serwer HTTP
  - `wasi:io` — strumienie I/O
  - `wasi:filesystem` — dostęp do plików
  - `wasi:cli` — interfejs linii poleceń

  #defblock[Component Model — kompozycja między językami][
    WIT (Wasm Interface Types): deklaratywna definicja interfejsu. \
    Canonical ABI: standaryzowana konwencja wywołań. \
    Kompozycja: łącz moduły z Rusta, Go, Pythona w jedną aplikację.
  ]
]

#slide(title: [Spin (Fermyon) — framework mikroserwisów Wasm])[
  #defblock[Spin = event-driven microservices z WebAssembly][
    Projekt CNCF Sandbox. Języki: Rust, Go, JS/TS, Python.
  ]

  Kluczowe cechy:
  - *Triggery*: HTTP, Redis, Cron, MQTT
  - *Wbudowane usługi*: KV store, SQLite, outbound HTTP
  - *Serverless AI*: inferencja LLM na brzegu
  - *Deploy*: lokalnie, Kubernetes (SpinKube), Fermyon Cloud

  #exblock[Przykład konfiguracji (spin.toml)][
    ```
    [[trigger.http]]
    route = "/hello"
    component = "hello"
    ```
  ]

  #src[developer.fermyon.com/spin]
]

#slide(title: [Wasm vs kontenery — porównanie wydajności])[
  #sm[#table(
    columns: 5,
    align: (left, right, right, right, right),
    stroke: 0.5pt + ibm-gray-30,
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
    table.header(
      text(fill: white, weight: "bold")[Metryka],
      text(fill: white, weight: "bold")[Wasm (AOT)],
      text(fill: white, weight: "bold")[Wasm (JIT)],
      text(fill: white, weight: "bold")[Docker (Alpine)],
      text(fill: white, weight: "bold")[Docker (pełny)],
    ),
    [*Cold start*], [1–10 ms], [20–50 ms], [200–500 ms], [1–2 s],
    [*Rozmiar obrazu*], [1–5 MB], [1–5 MB], [5–50 MB], [100–500 MB],
    [*Pamięć / instancja*], [1–10 MB], [1–10 MB], [50–200 MB], [100–500 MB],
    [*Gęstość (1000 inst.)*], [1–10 GB], [1–10 GB], [50–200 GB], [100–500 GB],
  )]

  #cols[
    #exblock[Wasm wygrywa][
      Serverless/FaaS (start < 1 ms) \
      Edge (gęstość + start) \
      Systemy pluginów (sandbox) \
      Multi-tenant SaaS
    ]
  ][
    #alertblock[Kontenery wygrywają][
      Długo-żyjące serwisy \
      Złożone zależności (pełny OS) \
      GPU (ekosystem dojrzały) \
      Istniejąca infrastruktura K8s
    ]
  ]
]

// ── Ograniczenia ─────────────────────────────────────────────

#title-slide[Ograniczenia serverless]

#slide(title: [Kiedy serverless to zły wybór?])[
  #alertblock[1. Vendor lock-in][
    EventBridge, Step Functions, DynamoDB — API specyficzne dla AWS. Migracja = przepisanie.
  ]

  #alertblock[2. Debugowanie i obserwowalność][
    Rozproszone, efemeryczne środowiska. Brak SSH. Logi w CloudWatch (opóźnienie 1–5 s). Distributed tracing konieczny.
  ]

  #alertblock[3. Limity][
    Lambda: 15 min timeout, 10 GB RAM, 6 MB payload (sync), 256 MB /tmp. \
    Cold starty przy nieprzewidywalnym ruchu.
  ]

  #alertblock[4. Koszty przy stałym ruchu][
    Lambda #sym.approx 3–5#sym.times droższa niż Fargate/EC2 przy ciągłym obciążeniu (break-even: 3–8M req/mies.).
  ]
]

#slide(title: [Multi-cloud i przenośność])[
  #defblock[Abstrakcje serverless — próba rozwiązania lock-in][
    - *Knative* — rozszerzenie Kubernetes o serverless (scale-to-zero, eventing). CNCF incubating.
    - *Serverless Framework* — IaC (`serverless.yml`), multi-cloud deployment
    - *SST* — TypeScript-first, AWS CDK, Live Lambda Development
    - *OpenFaaS* — open-source FaaS na Kubernetes/Docker, dowolny kontener
  ]

  #alertblock[Portability vs Optimization][
    Abstrakcja = mianownik wspólny = utrata cech specyficznych (SnapStart, Durable Objects, Step Functions). \
    Realnie: większość zespołów wybiera *jednego dostawcę* i optymalizuje.
  ]
]

// ── Koszty ───────────────────────────────────────────────────

#title-slide[#emoji.cloud Porównanie kosztów]

#slide(title: [Koszt per-request: Lambda vs Fargate vs Cloud Run vs EC2])[
  #sm[Scenariusz: 512 MB pamięci, 200 ms średni czas wykonania.]

  #sm[#table(
    columns: 4,
    align: (left, right, right, right),
    stroke: 0.5pt + ibm-gray-30,
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
    table.header(
      text(fill: white, weight: "bold")[Platforma],
      text(fill: white, weight: "bold")[100K req/mies.],
      text(fill: white, weight: "bold")[10M req/mies.],
      text(fill: white, weight: "bold")[100M req/mies.],
    ),
    [*Lambda*], [\~\$1,60], [\~\$362], [\~\$3 620],
    [*Cloud Run*], [\~\$0,40], [\~\$101], [\~\$1 010],
    [*Fargate (2 taski)*], [\~\$72 (stała)], [\~\$72], [\~\$710],
    [*EC2 (RI 1-rok)*], [\~\$34 (stała)], [\~\$34], [\~\$70],
  )]

  #alertblock[Wniosek][
    Lambda wygrywa przy *niskim, nieregularnym* ruchu (płacisz za zero = \$0). \
    Przy stałym obciążeniu *EC2 z Reserved Instance* jest 50#sym.times tańsze.
  ]
]

#slide(title: [Punkt break-even — kiedy warto zmienić model?])[
  #defblock[Lambda vs Fargate][
    Break-even: *3–8M requestów/miesiąc* (zależy od czasu wykonania i pamięci). \
    Poniżej: Lambda tańsza (pay-per-use). Powyżej: Fargate tańszy (stała pojemność).
  ]

  #defblock[Cloud Run vs Lambda][
    Cloud Run tańszy w większości scenariuszy dzięki *współbieżności* (do 1000 req/instancję vs 1 req/instancję w Lambda).
  ]

  #defblock[Ukryte koszty serverless][
    - Czas inżynierów: debugowanie, observability, cold start tuning
    - Egress: Lambda w VPC + NAT Gateway = \$0,045/GB
    - Ekosystem: CloudWatch, X-Ray, Step Functions — dodatkowe pozycje na fakturze
  ]

  #sm[Badanie AWS/Deloitte (2019): 3h/mies. overhead inżynierski = \$450 — może przechylić break-even na korzyść serverless.]
]

// ── Case Study ───────────────────────────────────────────────

#title-slide[Case study: Design Google Drive]

#slide(title: [Wymagania i estymacja skali])[
  #defblock[Wymagania funkcjonalne][
    Upload/download plików. Synchronizacja między urządzeniami. Udostępnianie. Historia wersji.
  ]

  Estymacja (back-of-the-envelope):
  - 500M użytkowników, 10M DAU
  - Średnio 2 pliki/dzień/użytkownik = 20M uploadów/dzień #sym.approx 230 req/s
  - Średni rozmiar pliku: 500 KB
  - Storage: 10 TB/dzień przyrost

  #defblock[Kluczowe decyzje architektoniczne][
    - Metadane: *strong consistency* (relacyjna baza, PostgreSQL/DynamoDB)
    - Pliki: *eventual consistency* (object storage, S3/GCS)
    - Sync: *event-driven*, notification push
  ]
]

#slide(title: [Architektura serverless — upload pipeline])[
  #defblock[Event-driven pipeline: S3 #sym.arrow SNS #sym.arrow SQS #sym.arrow Lambda #sym.arrow DynamoDB][
    Upload #sym.arrow S3 Event Notification #sym.arrow SNS (fan-out) #sym.arrow 3 kolejki SQS:
  ]

  + *Walidacja* — typ pliku, rozmiar, skan antywirusowy
  + *Przetwarzanie* — generowanie miniaturek (PIL/Sharp), ekstrakcja metadanych
  + *Indeksowanie* — zapis do DynamoDB (hash pliku, rozmiar, owner, wersja)

  Dead Letter Queue (DLQ) dla każdej kolejki — awarie nie blokują pipeline.

  #exblock[Serverless tu wygrywa][
    0 req/s w nocy = \$0 kosztów. 10 000 req/s przy flash uploadsach = automatyczne skalowanie. Brak capacity planning.
  ]
]

#slide(title: [Block-level sync — synchronizacja przyrostowa])[
  #defblock[Chunking — podział pliku na bloki (4 MB)][
    Każdy blok hashowany (SHA-256). Upload: tylko bloki, których hash nie istnieje w storage. \
    Modyfikacja 1 MB w pliku 1 GB = upload *jednego* bloku zamiast 1 GB (*250#sym.times oszczędność*).
  ]

  #defblock[Deduplikacja][
    Jeśli hash bloku istnieje (inny użytkownik, inna wersja) — nie zapisujemy ponownie. \
    Dropbox: *40–50% oszczędności storage* dzięki deduplikacji.
  ]

  #defblock[Resumable upload][
    HTTP Range Requests. Sesja uploadu w DynamoDB. Przerwanie #sym.arrow wznowienie od ostatniego bloku.
  ]
]

#slide(title: [Powiadomienia o zmianach — strategie])[
  #sm[#table(
    columns: 5,
    align: (left, left, left, left, left),
    stroke: 0.5pt + ibm-gray-30,
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
    table.header(
      text(fill: white, weight: "bold")[Strategia],
      text(fill: white, weight: "bold")[Opóźnienie],
      text(fill: white, weight: "bold")[Skalowalność],
      text(fill: white, weight: "bold")[Złożoność],
      text(fill: white, weight: "bold")[Zastosowanie],
    ),
    [*Long polling*], [1–30 s], [Średnia], [Niska], [Fallback],
    [*WebSocket*], [< 100 ms], [Niska], [Wysoka], [Real-time (czat, kolaboracja)],
    [*SSE*], [< 100 ms], [Średnia], [Średnia], [Jednokierunkowy push],
    [*Hybrid*], [< 100 ms], [Wysoka], [Średnia], [Produkcja (WS #sym.arrow SSE #sym.arrow polling)],
  )]

  #defblock[Produkcyjny wzorzec: kaskada z fallbackiem][
    Klient próbuje WebSocket. Jeśli nie działa (proxy, firewall) #sym.arrow SSE. Jeśli nie działa #sym.arrow long polling. At-least-once delivery + exponential backoff.
  ]
]

#slide(title: [Rozwiązywanie konfliktów synchronizacji])[
  #defblock[Problem: dwóch użytkowników edytuje ten sam plik offline][
    Oba urządzenia mają wersję 5. Urządzenie A tworzy wersję 6a, B tworzy 6b. Kto wygrywa?
  ]

  Strategie:
  + *Last Writer Wins (LWW)* — proste, deterministyczne, ale utrata danych
  + *Operational Transformation (OT)* — transformacja operacji (Google Docs)
  + *Kopie konfliktowe* — brak utraty danych (Dropbox/Google Drive: „kopia konfliktu z...")
  + *Vector Clocks* — wykrywanie przyczynowości, identyfikacja współbieżnych zmian

  #sm[Google Drive: pierwsza przetworzona wersja wygrywa; reszta jako kopie konfliktu + historia wersji.]
]

// ── Dyskusja ─────────────────────────────────────────────────

#focus-slide[
  Wasz zespół ma serwis przetwarzający *10 req/s* na co dzień, ale raz w miesiącu — *10 000 req/s* przez 2h (flash sale).

  Czy wybieracie *serverless* (Lambda), *kontenery* (Fargate/Cloud Run), czy *dedykowane VM* z autoscaling?

  Jakie trade-offy bierzecie pod uwagę? (koszt, opóźnienie, złożoność operacyjna, czas wdrożenia)
]

// ── Podsumowanie ─────────────────────────────────────────────

#title-slide[Podsumowanie]

#slide(title: [Kluczowe wnioski])[

  + *Serverless* to model odpowiedzialności, nie technologia — od IaaS do pełnego serverless
  + *FaaS* wygrywa przy zmiennym, nieprzewidywalnym ruchu; przegrywa kosztowo przy stałym obciążeniu
  + *Cold starty*: Rust/Go (16–38 ms) vs Java (698 ms); SnapStart skraca 5,6#sym.times
  + *Event-driven*: fan-out (SNS/EventBridge) dla dekouplingu; Step Functions dla workflow z gwarancjami
  + *Edge computing*: V8 isolates (Cloudflare) lub Wasm (Fastly) — logika < 5 ms od użytkownika
  + *WebAssembly*: start w mikrosekundach, 85% mniejsze obrazy, ale ekosystem jeszcze młody
  + #emoji.cloud *Koszty*: Lambda break-even z Fargate przy 3–8M req/mies.; Cloud Run najlepszy stosunek ceny do elastyczności
]

#slide(title: [Źródła i lektury])[

  - A. Xu — _System Design Interview_, rozdz. 15 (Google Drive)
  - AWS Documentation — Lambda, Step Functions, EventBridge (docs.aws.amazon.com)
  - M. Roberts — „Serverless Architectures" (martinfowler.com, 2018)
  - Y. Cui — _Production-Ready Serverless_ (Manning)
  - J. Daly — „Serverless Microservice Patterns for AWS" (jeremydaly.com)
  - Cloudflare Blog — „How Workers Works" (blog.cloudflare.com)
  - Bytecode Alliance — WASI Specification (wasi.dev)
  - Fermyon — Spin Documentation (developer.fermyon.com/spin)
  - github.com/maxday/lambda-perf — codzienne benchmarki cold startów
  - AWS Well-Architected Serverless Lens (docs.aws.amazon.com/wellarchitected)
]

#slide(title: [Następny wykład])[

  #defblock[Wykład 10: Obserwowalność, bezpieczeństwo i przyszłość systemów rozproszonych][
    Distributed tracing #sym.dot.c OpenTelemetry #sym.dot.c Zero Trust #sym.dot.c mTLS #sym.dot.c Platform Engineering
  ]
]

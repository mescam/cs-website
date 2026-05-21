// Wykład 9: Serverless, FaaS i architektura na brzegu
// PSR · Semestr letni 2025/26 · Politechnika Poznańska

#import "@preview/typslides:1.3.2": *
#import "psr-theme.typ": *
#import emoji: checkmark, crossmark, cloud, warning, fire, zap, rocket, lock, chart

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
  subtitle: [Funkcje, zdarzenia i obliczenia na krawędzi sieci],
  authors: "mgr inż. Jakub Woźniak",
  info: [Politechnika Poznańska · Instytut Informatyki · Semestr letni 2025/26],
)

#title-slide[Plan wykładu]

#slide(title: [Agenda])[
  - Koncepcja serverless — „bez zarządzania serwerem"
  - FaaS — AWS Lambda, Azure Functions, Google Cloud Functions
  - Cold starts i strategie mitygacji
  - Event-driven serverless — wzorce integracji
  - Serverless poza FaaS — bazy danych, kontenery
  - Edge computing — Cloudflare Workers, Lambda@Edge
  - Ograniczenia i trade-offs
  - #emoji.cloud Porównanie kosztów i use cases
]

// ── Część 1: Koncepcja Serverless ────────────────────────────

#title-slide[Koncepcja Serverless]

#slide(title: [Serverless ≠ bez serwera])[
  #defblock[Definicja][
    Serverless to model obliczeniowy, w którym *dostawca chmury zarządza infrastrukturą*, a deweloper płaci tylko za *rzeczywisty czas wykonania* kodu.
  ]

  Kluczowe cechy:
  - #hl[Brak zarządzania serwerem] — nie provisjonujesz, nie skalujesz, nie patchujesz
  - #hl[Płatność za użycie] — per-request, per-millisecond, scale-to-zero
  - #hl[Automatyczne skalowanie] — od 0 do 1000s instancji w sekundy
  - #hl[Event-driven] — funkcje uruchamiane przez zdarzenia (HTTP, S3, DB, timer)

  #src[AWS Serverless Whitepaper 2024; Azure Functions Architecture Guide 2026]
]

#slide(title: [Ewolucja abstrakcji — od IaaS do Serverless])[
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (center, center, center, center, center),
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.odd(y) { ibm-blue-10 } else { white },
    text(fill: white, weight: "bold", size: 0.85em, "IaaS"),
    text(fill: white, weight: "bold", size: 0.85em, "CaaS"),
    text(fill: white, weight: "bold", size: 0.85em, "PaaS"),
    text(fill: white, weight: "bold", size: 0.85em, "FaaS"),
    text(fill: white, weight: "bold", size: 0.85em, "Serverless"),
    
    text(size: 0.8em, "EC2, GCE"),
    text(size: 0.8em, "ECS, K8s"),
    text(size: 0.8em, "App Service"),
    text(size: 0.8em, "Lambda"),
    text(size: 0.8em, "DynamoDB"),
    
    text(size: 0.75em, "Zarządzasz: OS, runtime, scaling"),
    text(size: 0.75em, "Zarządzasz: app, scaling"),
    text(size: 0.75em, "Zarządzasz: app"),
    text(size: 0.75em, "Zarządzasz: funkcja"),
    text(size: 0.75em, "Zarządzasz: nic"),
    
    text(size: 0.75em, "Koszt: zawsze"),
    text(size: 0.75em, "Koszt: zawsze"),
    text(size: 0.75em, "Koszt: zawsze"),
    text(size: 0.75em, "Koszt: per-ms"),
    text(size: 0.75em, "Koszt: per-op"),
    
    text(size: 0.75em, "Skalowanie: ręczne"),
    text(size: 0.75em, "Skalowanie: HPA"),
    text(size: 0.75em, "Skalowanie: auto"),
    text(size: 0.75em, "Skalowanie: auto"),
    text(size: 0.75em, "Skalowanie: auto"),
  )
]

// ── Część 2: FaaS — AWS Lambda, Azure Functions, GCP ────────

#title-slide[FaaS — Funkcje jako Usługa]

#slide(title: [AWS Lambda — architektura])[
  #cols[
    #defblock[Charakterystyka][
      - *Timeout*: 15 minut (900s)
      - *Memory*: 128 MB — 10 GB (skaluje CPU)
      - *Concurrency*: 1000 domyślnie (soft limit)
      - *Ephemeral storage*: 512 MB — 10 GB
      - *Runtimes*: Node.js, Python, Java, Go, Rust, .NET, Ruby
    ]
  ][
    #exblock[Pricing (10M req/msc, 200ms avg)][
      - Compute: $0.0000166/ms × 200ms × 10M = $33.20
      - Requests: $0.20/M × 10M = $2.00
      - *Total: ~$35/msc*
      
      vs EC2 t3.micro: $7.50/msc (zawsze)
    ]
  ]

  #src[AWS Lambda Pricing 2026; AWS Lambda Quotas]
]

#slide(title: [Azure Functions — plany])[
  #table(
    columns: (1fr, 1fr, 1fr, 1fr),
    align: (left, center, center, center),
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.odd(y) { ibm-blue-10 } else { white },
    text(fill: white, weight: "bold", "Plan"),
    text(fill: white, weight: "bold", "Consumption"),
    text(fill: white, weight: "bold", "Flex Consumption"),
    text(fill: white, weight: "bold", "Premium"),
    
    text(size: 0.85em, "Scale-to-zero"),
    text(size: 0.85em, "#emoji.checkmark.box"),
    text(size: 0.85em, "#emoji.checkmark.box"),
    text(size: 0.85em, "#emoji.crossmark"),
    
    text(size: 0.85em, "Always-ready"),
    text(size: 0.85em, "#emoji.crossmark"),
    text(size: 0.85em, "0-100 instances"),
    text(size: 0.85em, "#emoji.checkmark.box"),
    
    text(size: 0.85em, "Per-function scaling"),
    text(size: 0.85em, "#emoji.crossmark"),
    text(size: 0.85em, "#emoji.checkmark.box"),
    text(size: 0.85em, "#emoji.checkmark.box"),
    
    text(size: 0.85em, "Timeout"),
    text(size: 0.85em, "10 min"),
    text(size: 0.85em, "60 min"),
    text(size: 0.85em, "60 min"),
    
    text(size: 0.85em, "Pricing"),
    text(size: 0.85em, "per-ms"),
    text(size: 0.85em, "per-ms + instance"),
    text(size: 0.85em, "fixed + per-ms"),
  )

  #src[Azure Functions Pricing 2026; Flex Consumption Plan Announcement]
]

#slide(title: [Google Cloud Functions — 2nd gen])[
  #defblock[Cloud Functions 2nd gen (Cloud Run-based)][
    - *Timeout*: 60 minut (vs 9 min w 1st gen)
    - *Memory*: 256 MB — 16 GB
    - *Concurrency*: Multi-concurrency per instancja (vs 1 w 1st gen)
    - *Runtimes*: Node.js, Python, Go, Java, .NET, Ruby, PHP
    - *Pricing*: $0.0000041/vCPU-s (vs $0.0000025 w 1st gen)
  ]

  #exblock[Porównanie z Lambda][
    - GCP: 60 min timeout vs AWS: 15 min
    - GCP: Multi-concurrency vs AWS: 1000 concurrent executions
    - GCP: Wyższa cena per vCPU-s, ale mniej cold startów dzięki multi-concurrency
  ]

  #src[Google Cloud Functions 2nd Gen Documentation 2026]
]

// ── Część 3: Cold Starts ─────────────────────────────────────

#title-slide[Cold Starts — Problem i Rozwiązania]

#slide(title: [Co to jest cold start?])[
  #defblock[Definicja][
    Cold start to opóźnienie od momentu wyzwolenia funkcji do momentu, gdy kod zaczyna się wykonywać. Obejmuje:
    1. Alokacja kontenera
    2. Załadowanie runtime'u
    3. Inicjalizacja kodu (imports, connections)
  ]

  #alertblock[Wpływ na UX][
    - P50 cold start: 50-700ms (zależy od runtime)
    - P99 cold start: 200-1100ms
    - Dla synchronicznych API: zauważalne opóźnienie
    - Dla asynchronicznych: zwykle nieistotne
  ]

  #src[Lambda Performance Report 2026 (maxday/lambda-perf)]
]

#slide(title: [Cold start latency — porównanie runtime'ów])[
  #table(
    columns: (1.2fr, 0.8fr, 0.8fr, 0.8fr),
    align: (left, center, center, center),
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.odd(y) { ibm-blue-10 } else { white },
    text(fill: white, weight: "bold", "Runtime"),
    text(fill: white, weight: "bold", "P50 (ms)"),
    text(fill: white, weight: "bold", "P99 (ms)"),
    text(fill: white, weight: "bold", "Koszt/10M req"),
    
    text(size: 0.85em, "Rust"),
    text(size: 0.85em, "16"),
    text(size: 0.85em, "22"),
    text(size: 0.85em, "$0.53"),
    
    text(size: 0.85em, "Go"),
    text(size: 0.85em, "38"),
    text(size: 0.85em, "52"),
    text(size: 0.85em, "$1.27"),
    
    text(size: 0.85em, "Node.js"),
    text(size: 0.85em, "148"),
    text(size: 0.85em, "210"),
    text(size: 0.85em, "$4.93"),
    
    text(size: 0.85em, "Python"),
    text(size: 0.85em, "171"),
    text(size: 0.85em, "325"),
    text(size: 0.85em, "$5.70"),
    
    text(size: 0.85em, "Java (JVM)"),
    text(size: 0.85em, "698"),
    text(size: 0.85em, "1100"),
    text(size: 0.85em, "$23.27"),
    
    text(size: 0.85em, "Java + SnapStart"),
    text(size: 0.85em, "100-200"),
    text(size: 0.85em, "200-400"),
    text(size: 0.85em, "$3.33-6.67"),
  )

  #src[Lambda Performance Report 2026; AWS SnapStart Documentation]
]

#slide(title: [SnapStart — przyspieszenie Java])[
  #defblock[AWS Lambda SnapStart (Java, Python, .NET)][
    - Tworzy snapshot JVM po inicjalizacji
    - Przywraca snapshot zamiast restartować JVM
    - *Poprawa*: 5.6x dla Java (583ms → 104ms), 2-3x dla Python
    - *Koszt*: +15% do ceny compute
  ]

  #alertblock[Ograniczenia][
    - Wymaga CRaC hooks do obsługi state (connections, timers)
    - Brak wsparcia dla arm64
    - Brak wsparcia dla custom container images
    - Snapshot size limit: 50 MB
  ]

  #exblock[Kiedy warto?][
    - Synchroniczne API (REST, GraphQL)
    - Wysokie volume (>50M req/msc)
    - Akceptowalny ROI: +15% koszt vs -80% latency
  ]

  #src[AWS Lambda SnapStart Documentation 2026]
]

#slide(title: [Strategie mitygacji cold startów])[
  #cols[
    #defblock[Runtime selection][
      1. Rust/Go: 16-52ms (best)
      2. Node.js: 148ms
      3. Python: 171ms
      4. Java: 698ms (use SnapStart)
    ]
  ][
    #exblock[Provisioned Concurrency][
      - Utrzymuj N instancji zawsze gotowych
      - Koszt: $0.015/hour per concurrency
      - Breakeven: ~50M req/msc
      - Eliminuje cold starts
    ]
  ]

  #cols[
    #defblock[Package optimization][
      - Minimalizuj dependencies
      - Lazy-load heavy libraries
      - Use tree-shaking (webpack, esbuild)
      - Compress: 50MB → 5MB
    ]
  ][
    #exblock[Initialization patterns][
      - Move DB connections outside handler
      - Cache SDK clients
      - Lazy-initialize expensive resources
      - Use connection pooling
    ]
  ]

  #src[AWS Lambda Best Practices 2026]
]

// ── Część 4: Event-Driven Serverless ─────────────────────────

#title-slide[Event-Driven Serverless]

#slide(title: [Event sources — Lambda triggers])[
  #table(
    columns: (1.2fr, 1fr, 1fr),
    align: (left, center, center),
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.odd(y) { ibm-blue-10 } else { white },
    text(fill: white, weight: "bold", "Event Source"),
    text(fill: white, weight: "bold", "Latency"),
    text(fill: white, weight: "bold", "Guarantee"),
    
    text(size: 0.85em, "API Gateway (HTTP)"),
    text(size: 0.85em, "<100ms"),
    text(size: 0.85em, "At-most-once"),
    
    text(size: 0.85em, "S3 (object upload)"),
    text(size: 0.85em, "1-5s"),
    text(size: 0.85em, "At-least-once"),
    
    text(size: 0.85em, "DynamoDB Streams"),
    text(size: 0.85em, "<1s"),
    text(size: 0.85em, "At-least-once"),
    
    text(size: 0.85em, "SQS (queue)"),
    text(size: 0.85em, "<1s"),
    text(size: 0.85em, "At-least-once"),
    
    text(size: 0.85em, "SNS (topic)"),
    text(size: 0.85em, "<100ms"),
    text(size: 0.85em, "At-most-once"),
    
    text(size: 0.85em, "EventBridge (rules)"),
    text(size: 0.85em, "<1s"),
    text(size: 0.85em, "At-least-once"),
    
    text(size: 0.85em, "CloudWatch Events (timer)"),
    text(size: 0.85em, "~1min precision"),
    text(size: 0.85em, "At-least-once"),
  )

  #src[AWS Lambda Event Source Mapping 2026]
]

#slide(title: [EventBridge — wzorce filtrowania])[
  #defblock[EventBridge pattern matching][
    Filtruj zdarzenia na podstawie zawartości (256KB limit per event):
  ]

  ```json
  {
    "source": ["order.service"],
    "detail-type": ["Order Placed"],
    "detail": {
      "amount": [{ "numeric": [">", 100] }],
      "status": ["pending", "confirmed"]
    }
  }
  ```

  #exblock[Quotas (soft limits)][
    - 300 rules per event bus
    - 5 targets per rule
    - 10,000 TPS per bus
    - 256 KB event size
    - Scaling: multiple buses, SNS fan-out
  ]

  #src[AWS EventBridge Documentation 2026]
]

#slide(title: [Wzorzec: Fan-out / Fan-in])[
  #cols[
    #defblock[Fan-out (1 → N)][
      1. Zdarzenie trafia do SNS/SQS
      2. Rozpropagowane do N konsumentów
      3. Każdy konsument niezależnie
      
      *Use case*: Order placed → email, inventory, analytics
    ]
  ][
    #exblock[Fan-in (N → 1)][
      1. N producentów wysyła do SQS
      2. Lambda batch-processes
      3. Agreguje wyniki
      
      *Use case*: Collect metrics, batch processing
    ]
  ]

  #src[AWS Serverless Application Lens 2026]
]

#slide(title: [Orkiestracja vs Choreografia (serverless)])[
  #table(
    columns: (1fr, 1fr, 1fr),
    align: (left, center, center),
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.odd(y) { ibm-blue-10 } else { white },
    text(fill: white, weight: "bold", "Aspekt"),
    text(fill: white, weight: "bold", "Orkiestracja (Step Functions)"),
    text(fill: white, weight: "bold", "Choreografia (EventBridge)"),
    
    text(size: 0.85em, "Kontrola"),
    text(size: 0.85em, "Centralna (workflow)"),
    text(size: 0.85em, "Rozproszona (events)"),
    
    text(size: 0.85em, "Coupling"),
    text(size: 0.85em, "Tight (zna wszystkie kroki)"),
    text(size: 0.85em, "Loose (zna tylko eventy)"),
    
    text(size: 0.85em, "Debugowanie"),
    text(size: 0.85em, "Łatwe (widać flow)"),
    text(size: 0.85em, "Trudne (rozproszone)"),
    
    text(size: 0.85em, "Skalowanie"),
    text(size: 0.85em, "Ograniczone (1 workflow)"),
    text(size: 0.85em, "Nieograniczone (N konsumentów)"),
    
    text(size: 0.85em, "Koszt"),
    text(size: 0.85em, "$0.000025 per state transition"),
    text(size: 0.85em, "$0.35 per M events"),
    
    text(size: 0.85em, "Use case"),
    text(size: 0.85em, "Długie workflow, kompensacje"),
    text(size: 0.85em, "Asynchroniczne, event-driven"),
  )

  #src[AWS Step Functions vs EventBridge 2026]
]

#slide(title: [Durable Functions (Azure) — nowe w 2026])[
  #defblock[Azure Durable Functions][
    Orkiestracja long-running workflows z checkpoint-based resumption:
    - *Orchestrator*: definiuje flow (sekwencja, parallel, retry)
    - *Activity*: wykonuje pracę (HTTP, DB, compute)
    - *Checkpoint*: zapisuje state po każdym activity
    - *Resumption*: wznawia od ostatniego checkpointa
  ]

  #exblock[Porównanie z AWS Step Functions][
    - Durable Functions: wbudowane w Azure Functions (tańsze)
    - Step Functions: osobna usługa (bardziej elastyczna)
    - Oba: obsługują retry, timeout, compensation
  ]

  #src[Azure Durable Functions Documentation 2026]
]

// ── Część 5: Serverless poza FaaS ────────────────────────────

#title-slide[Serverless poza FaaS]

#slide(title: [Serverless databases — porównanie])[
  #table(
    columns: (1.2fr, 0.9fr, 0.9fr, 0.9fr),
    align: (left, center, center, center),
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.odd(y) { ibm-blue-10 } else { white },
    text(fill: white, weight: "bold", "Baza"),
    text(fill: white, weight: "bold", "Latency"),
    text(fill: white, weight: "bold", "Pricing (10M ops)"),
    text(fill: white, weight: "bold", "Scale-to-zero"),
    
    text(size: 0.85em, "DynamoDB on-demand"),
    text(size: 0.85em, "<10ms"),
    text(size: 0.85em, "$12.50"),
    text(size: 0.85em, "#emoji.checkmark.box"),
    
    text(size: 0.85em, "Aurora Serverless v2"),
    text(size: 0.85em, "<5ms"),
    text(size: 0.85em, "$43.20 (0.5 ACU min)"),
    text(size: 0.85em, "Partial"),
    
    text(size: 0.85em, "Neon (PostgreSQL)"),
    text(size: 0.85em, "50-200ms"),
    text(size: 0.85em, "$0 (free tier)"),
    text(size: 0.85em, "#emoji.checkmark.box"),
    
    text(size: 0.85em, "PlanetScale (MySQL)"),
    text(size: 0.85em, "50-200ms"),
    text(size: 0.85em, "$0 (free tier)"),
    text(size: 0.85em, "#emoji.checkmark.box"),
    
    text(size: 0.85em, "Firestore"),
    text(size: 0.85em, "<10ms"),
    text(size: 0.85em, "$6.00"),
    text(size: 0.85em, "#emoji.checkmark.box"),
  )

  #src[AWS DynamoDB Pricing 2026; Neon Pricing 2026; PlanetScale Pricing 2026]
]

#slide(title: [Serverless containers — Fargate vs Cloud Run])[
  #table(
    columns: (1.2fr, 0.9fr, 0.9fr, 0.9fr),
    align: (left, center, center, center),
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.odd(y) { ibm-blue-10 } else { white },
    text(fill: white, weight: "bold", "Aspekt"),
    text(fill: white, weight: "bold", "Fargate"),
    text(fill: white, weight: "bold", "Cloud Run"),
    text(fill: white, weight: "bold", "Container Apps"),
    
    text(size: 0.85em, "Scale-to-zero"),
    text(size: 0.85em, "#emoji.crossmark"),
    text(size: 0.85em, "#emoji.checkmark.box"),
    text(size: 0.85em, "#emoji.checkmark.box"),
    
    text(size: 0.85em, "Min cost"),
    text(size: 0.85em, "$0.04/hour"),
    text(size: 0.85em, "$0"),
    text(size: 0.85em, "$0"),
    
    text(size: 0.85em, "Pricing/vCPU-s"),
    text(size: 0.85em, "$0.0000441"),
    text(size: 0.85em, "$0.0000041"),
    text(size: 0.85em, "$0.0000411"),
    
    text(size: 0.85em, "Timeout"),
    text(size: 0.85em, "No limit"),
    text(size: 0.85em, "60 min"),
    text(size: 0.85em, "30 min"),
    
    text(size: 0.85em, "Use case"),
    text(size: 0.85em, "Long-running, stateful"),
    text(size: 0.85em, "Stateless, bursty"),
    text(size: 0.85em, "Hybrid (Azure)"),
  )

  #src[AWS Fargate Pricing 2026; Google Cloud Run Pricing 2026]
]

// ── Część 6: Edge Computing ──────────────────────────────────

#title-slide[Edge Computing — Obliczenia na Brzegu]

#slide(title: [Lambda@Edge vs Cloudflare Workers])[
  #table(
    columns: (1.2fr, 0.9fr, 0.9fr),
    align: (left, center, center),
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.odd(y) { ibm-blue-10 } else { white },
    text(fill: white, weight: "bold", "Aspekt"),
    text(fill: white, weight: "bold", "Lambda@Edge"),
    text(fill: white, weight: "bold", "Cloudflare Workers"),
    
    text(size: 0.85em, "Lokacje"),
    text(size: 0.85em, "500+ CloudFront"),
    text(size: 0.85em, "300+ data centers"),
    
    text(size: 0.85em, "Timeout"),
    text(size: 0.85em, "5-30s"),
    text(size: 0.85em, "30s (CPU), 600s (wall)"),
    
    text(size: 0.85em, "Cold start"),
    text(size: 0.85em, "50-100ms"),
    text(size: 0.85em, "<1ms (V8 Isolates)"),
    
    text(size: 0.85em, "Runtime"),
    text(size: 0.85em, "Node.js"),
    text(size: 0.85em, "JavaScript, WASM"),
    
    text(size: 0.85em, "Pricing"),
    text(size: 0.85em, "$0.60/M requests"),
    text(size: 0.85em, "$0.50/M requests"),
    
    text(size: 0.85em, "Egress"),
    text(size: 0.85em, "Included"),
    text(size: 0.85em, "Zero egress"),
    
    text(size: 0.85em, "Stateful"),
    text(size: 0.85em, "#emoji.crossmark"),
    text(size: 0.85em, "Durable Objects"),
    
    text(size: 0.85em, "Use case"),
    text(size: 0.85em, "CDN customization"),
    text(size: 0.85em, "Global API, auth, transform"),
  )

  #src[AWS Lambda@Edge Documentation 2026; Cloudflare Workers Pricing 2026]
]

#slide(title: [Edge use cases])[
  #cols[
    #defblock[Lambda@Edge][
      - Request/response rewriting
      - A/B testing
      - Bot detection
      - Image optimization
      - Authentication
      - Geo-routing
    ]
  ][
    #exblock[Cloudflare Workers][
      - Global API gateway
      - Request routing
      - Authentication/authorization
      - Rate limiting
      - Cache control
      - CORS handling
      - WebAssembly execution
    ]
  ]

  #src[AWS Lambda@Edge Use Cases 2026; Cloudflare Workers Examples 2026]
]

// ── Część 7: Ograniczenia i Trade-offs ────────────────────────

#title-slide[Ograniczenia i Trade-offs]

#slide(title: [Kiedy serverless NIE jest dobrym wyborem])[
  #alertblock[Problemy][
    - *Vendor lock-in*: Brak standardu, migracja trudna
    - *Debugowanie*: Rozproszone logi, trudne do śledzenia
    - *Koszty przy stałym ruchu*: Fargate/EC2 tańsze dla 24/7 workloads
    - *Timeout*: Lambda 15 min, GCF 60 min — za krótko dla batch jobs
    - *Startup time*: Synchroniczne API wrażliwe na cold starts
    - *Observability*: Wymaga X-Ray, CloudWatch, OpenTelemetry
  ]

  #exblock[Kiedy wybrać tradycyjne kontenery?][
    - Long-running processes (>15 min)
    - Stały, przewidywalny ruch (24/7)
    - Wymagania na niskie latency (<50ms)
    - Potrzeba pełnej kontroli nad runtime
  ]

  #src[AWS Serverless Lens 2026]
]

#slide(title: [Vendor lock-in — strategie mitygacji])[
  #cols[
    #defblock[Abstrakcja][
      - Używaj standardów (OpenTelemetry, CloudEvents)
      - Izoluj vendor-specific code
      - Wrapper functions dla SDK
    ]
  ][
    #exblock[Portability][
      - Serverless Framework (multi-cloud)
      - AWS SAM, Azure Functions Core Tools
      - Terraform dla IaC
      - Dokumentuj architekturę
    ]
  ]

  #cols[
    #defblock[Hybrid approach][
      - Serverless dla bursty workloads
      - Kontenery dla baseline
      - Mieszaj w zależności od use case
    ]
  ][
    #exblock[Monitoring][
      - Metryki: latency, cost, errors
      - Alerting na anomalie
      - Regular cost reviews
    ]
  ]

  #src[AWS Well-Architected Framework 2026]
]

// ── Część 8: Cloud Context ──────────────────────────────────

#title-slide[#emoji.cloud Porównanie kosztów — Serverless vs Tradycyjne]

#slide(title: [Scenariusz: 10M requests/msc, 200ms avg execution])[
  #table(
    columns: (1.2fr, 0.9fr, 0.9fr, 0.9fr),
    align: (left, center, center, center),
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.odd(y) { ibm-blue-10 } else { white },
    text(fill: white, weight: "bold", "Opcja"),
    text(fill: white, weight: "bold", "Koszt/msc"),
    text(fill: white, weight: "bold", "Skalowanie"),
    text(fill: white, weight: "bold", "Effort"),
    
    text(size: 0.85em, "Lambda (Go)"),
    text(size: 0.85em, "$35"),
    text(size: 0.85em, "Auto"),
    text(size: 0.85em, "Low"),
    
    text(size: 0.85em, "Lambda (Python)"),
    text(size: 0.85em, "$41"),
    text(size: 0.85em, "Auto"),
    text(size: 0.85em, "Low"),
    
    text(size: 0.85em, "Cloud Run"),
    text(size: 0.85em, "$41"),
    text(size: 0.85em, "Auto"),
    text(size: 0.85em, "Low"),
    
    text(size: 0.85em, "Fargate (1 vCPU)"),
    text(size: 0.85em, "$29"),
    text(size: 0.85em, "Manual HPA"),
    text(size: 0.85em, "Medium"),
    
    text(size: 0.85em, "ECS on EC2 (t3.micro)"),
    text(size: 0.85em, "$7.50"),
    text(size: 0.85em, "Manual"),
    text(size: 0.85em, "High"),
    
    text(size: 0.85em, "Kubernetes (self-managed)"),
    text(size: 0.85em, "$50+"),
    text(size: 0.85em, "HPA"),
    text(size: 0.85em, "Very High"),
  )

  #src[AWS Pricing Calculator 2026; Google Cloud Pricing 2026]
]

#slide(title: [#emoji.cloud Managed services — serverless ecosystem])[
  #defblock[Poza compute — serverless w całym stacku][
    - *Databases*: DynamoDB, Aurora Serverless, Firestore
    - *Message queues*: SQS, SNS, Pub/Sub
    - *Workflows*: Step Functions, Durable Functions, Workflows
    - *Storage*: S3, Cloud Storage, Blob Storage
    - *Analytics*: BigQuery, Redshift Spectrum, Athena
    - *ML*: SageMaker, Vertex AI, Azure ML
  ]

  #exblock[Korzyść][
    Całkowita eliminacja zarządzania infrastrukturą — od compute po storage.
  ]

  #src[AWS Serverless Whitepaper 2026]
]

// ── Część 9: Checklist i Best Practices ──────────────────────

#title-slide[Production Checklist]

#slide(title: [Przed wdrożeniem do produkcji])[
  #cols[
    #defblock[Observability][
      - #emoji.checkmark.box CloudWatch Logs + X-Ray
      - #emoji.checkmark.box Metryki: latency, errors, cost
      - #emoji.checkmark.box Alerting na anomalie
      - #emoji.checkmark.box Distributed tracing
    ]
  ][
    #exblock[Cost Management][
      - #emoji.checkmark.box Budgets i alerts
      - #emoji.checkmark.box Reserved Concurrency
      - #emoji.checkmark.box Cost allocation tags
      - #emoji.checkmark.box Regular reviews
    ]
  ]

  #cols[
    #defblock[Security][
      - #emoji.checkmark.box IAM roles (least privilege)
      - #emoji.checkmark.box VPC endpoints
      - #emoji.checkmark.box Secrets Manager
      - #emoji.checkmark.box Input validation
    ]
  ][
    #exblock[Reliability][
      - #emoji.checkmark.box Retry logic + DLQ
      - #emoji.checkmark.box Timeout handling
      - #emoji.checkmark.box Idempotency keys
      - #emoji.checkmark.box Chaos testing
    ]
  ]

  #src[AWS Serverless Lens 2026]
]

// ── Podsumowanie ────────────────────────────────────────────

#title-slide[Kluczowe wnioski]

#slide(title: [Serverless — kiedy i jak])[
  #defblock[Serverless jest idealne dla:][
    - Bursty, event-driven workloads
    - Szybkie prototypy i MVP
    - Asynchroniczne procesy
    - Globalne API (edge computing)
    - Zespoły bez DevOps
  ]

  #exblock[Serverless NIE jest idealne dla:][
    - Stały, 24/7 ruch (Fargate/EC2 tańsze)
    - Long-running batch jobs (>15 min)
    - Wymagania na ultra-niskie latency
    - Zespoły wymagające pełnej kontroli
  ]

  #alertblock[2026 trendy][
    - SnapStart ekspanduje (Python, .NET)
    - Managed Instances (Lambda) konkuruje z Fargate
    - Flex Consumption (Azure) zmienia game
    - Edge computing (Workers, Lambda@Edge) rośnie
  ]

  #src[AWS re:Invent 2025; Azure Ignite 2025; Google Next 2025]
]

#slide(title: [Źródła i lektury])[
  #defblock[Oficjalna dokumentacja][
    - AWS Lambda: https://docs.aws.amazon.com/lambda/
    - Azure Functions: https://learn.microsoft.com/en-us/azure/azure-functions/
    - Google Cloud Functions: https://cloud.google.com/functions/docs
  ]

  #exblock[Benchmarki i case studies][
    - Lambda Performance Report: https://github.com/maxday/lambda-perf
    - AWS Serverless Whitepaper: https://aws.amazon.com/serverless/
    - Cloudflare Workers: https://workers.cloudflare.com/
  ]

  #defblock[Artykuły i blogi][
    - "Serverless Cold Starts" — AWS Blog 2026
    - "SnapStart Performance" — AWS Lambda Blog 2026
    - "Durable Functions" — Azure Blog 2026
  ]
]


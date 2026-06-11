// Wykład 10: Obserwowalność, bezpieczeństwo i przyszłość systemów rozproszonych
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
  title: "Obserwowalność, bezpieczeństwo i przyszłość",
  subtitle: [Observability #sym.dot.c Zero Trust #sym.dot.c mTLS #sym.dot.c Platform Engineering #sym.dot.c FinOps #sym.dot.c Trendy],
  authors: "mgr inż. Jakub Woźniak",
  info: [Politechnika Poznańska · Instytut Informatyki · Semestr letni 2025/26],
)

#title-slide[Plan wykładu]

#slide(title: [Agenda])[

  - Obserwowalność — monitoring vs observability, trzy filary
  - Structured logging i correlation IDs
  - OpenTelemetry — standard instrumentacji
  - Distributed tracing i W3C Trace Context
  - Metryki: RED, USE, Four Golden Signals
  - Zero Trust Architecture — „never trust, always verify"
  - OAuth 2.0 / OIDC, JWT, mTLS, service mesh
  - Zarządzanie sekretami
  - #emoji.cloud AI/ML inference, Platform Engineering, FinOps, Well-Architected
  - Trendy i przyszłość systemów rozproszonych
  - Case study: Design YouTube (A. Xu, rozdz. 14)
  - Podsumowanie kursu
]

// ════════════════════════════════════════════════════════════
//  CZĘŚĆ I — OBSERWOWALNOŚĆ
// ════════════════════════════════════════════════════════════

#title-slide[Obserwowalność]

#slide(title: [Monitoring vs Observability])[
  #defblock[Dwa różne pytania][
    *Monitoring* odpowiada na pytanie „*czy* coś jest zepsute?" (known-unknowns). \
    *Observability* odpowiada na pytanie „*dlaczego* user 4821 zobaczył 500 ms o 16:35?" (unknown-unknowns).
  ]

  #cols[
    #defblock[Monitoring][
      - Predefiniowane dashboardy
      - Znane scenariusze awarii
      - Low-cardinality (region, status)
      - Skaluje się słabo z liczbą serwisów
    ]
  ][
    #alertblock[Observability][
      - Eksploracja ad-hoc
      - Emergentne, nieprzewidziane interakcje
      - High-cardinality (trace_id, user_id)
      - Skaluje się z złożonością
    ]
  ]

  #sm[W mikroserwisach 1 request = 10+ wywołań = kombinatoryczna eksplozja trybów awarii (nawiązanie do wykładu 6).]
]

#slide(title: [Trzy filary obserwowalności (+ czwarty)])[
  #align(center)[
    #sm[#table(
      columns: 3,
      align: (left, left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Filar],
        text(fill: white, weight: "bold")[Co to jest],
        text(fill: white, weight: "bold")[Model kosztu],
      ),
      [*Logs*], [Dyskretne zdarzenia z timestampem (najlepiej JSON)], [Per-event],
      [*Metrics*], [Agregaty numeryczne (counter, gauge, histogram)], [Per-unikalna-seria],
      [*Traces*], [Ścieżka requestu przez serwisy (spans)], [Per-trace],
      [*Profiles*], [Próbki CPU/pamięci skorelowane ze spanami (eBPF)], [Per-sample],
    )]
  ]

  #exblock[Czwarty filar — Continuous Profiling][
    OpenTelemetry Profiles: sygnał w fazie alpha (2026). Integracja eBPF, overhead 1–3% CPU. Korelacja profilu z `trace_id` / `span_id`.
  ]
]

#slide(title: [Structured logging — JSON, nie tekst])[
  #defblock[Dlaczego JSON > plain text][
    - Parsowanie 10–100#sym.times szybsze (brak regexów)
    - Każde pole niezależnie filtrowalne i agregowalne
    - High-cardinality wartości (`trace_id`) w polach, nie w etykietach
    - Lepsza kompresja (storage kolumnowy 3–5#sym.times wydajniejszy)
  ]

  #exblock[Minimalny zestaw pól w produkcji][
    `timestamp` (ISO 8601 UTC), `level`, `service`, `version`, `environment`, \
    `event`, `trace_id`, `span_id`, `message`, `error.{type,code}`, `context.{...}`
  ]

  #alertblock[Nie loguj danych wrażliwych][
    Nigdy: hasła, tokeny, PII (email zamiast `user_id`). Logi trafiają do wielu systemów.
  ]
]

#slide(title: [Correlation ID — szycie requestu przez serwisy])[
  #defblock[Jeden identyfikator na całe żądanie][
    Generowany na *granicy systemu* (API Gateway, wejście do kolejki). Wszystkie logi, spany i zdarzenia w obsłudze jednego requestu dzielą ten sam `trace_id`.
  ]

  Propagacja:
  - *HTTP*: nagłówek `traceparent` (W3C) lub `X-Request-ID`
  - *gRPC*: metadata w kontekście
  - *Kolejki*: nagłówki wiadomości (Kafka, SNS, RabbitMQ)
  - *SQL*: komentarz w zapytaniu `/* trace_id: xyz */`

  #sm[SDK OpenTelemetry *automatycznie* wstrzykuje `trace_id` i `span_id` do logów, gdy aktywny jest span.]
]

#title-slide[OpenTelemetry]

#slide(title: [OpenTelemetry — dominujący standard instrumentacji])[
  #defblock[Konsolidacja standardów][
    2017–2019: OpenTracing (CNCF) vs OpenCensus (Google) #sym.arrow 2019: fuzja w *OpenTelemetry* #sym.arrow 2023: traces + metrics stabilne #sym.arrow 2026: projekt *graduated* (poziom K8s, Prometheus).
  ]

  Dlaczego dominuje:
  - Vendor-neutral — niezależny od dostawcy
  - Wspierany przez wszystkich hyperscalerów (AWS, GCP, Azure) i niezależnych (Datadog, Grafana, Honeycomb)
  - OTLP jako de-facto format eksportu dla każdego backendu
  - Auto-instrumentacja popularnych frameworków bez zmian w kodzie

  #src[opentelemetry.io/status #sym.dot.c CNCF: 12 300+ kontrybutorów z 2 800+ firm]
]

#slide(title: [Architektura OTel: API #sym.arrow SDK #sym.arrow Collector #sym.arrow Backend])[
  #defblock[Cztery warstwy][
    + *API* — niezależne od języka interfejsy (tworzenie spanów, metryk, logów)
    + *SDK* — implementacja per język; samplowanie, batching, eksportery
    + *Collector* — vendor-neutral; receivers #sym.arrow processors #sym.arrow exporters
    + *OTLP* — protokół: gRPC (`:4317`) lub HTTP/Protobuf (`:4318`)
  ]

  #align(center)[
    #sm[#table(
      columns: 2,
      align: (left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Sygnał],
        text(fill: white, weight: "bold")[Status (2026)],
      ),
      [*Traces*], [Stabilny],
      [*Metrics*], [Stabilny],
      [*Logs*], [Stabilny],
      [*Profiles*], [Alpha (eBPF, marzec 2026)],
    )]
  ]
]

#title-slide[Distributed tracing]

#slide(title: [Span, trace, relacja parent-child])[
  #defblock[Anatomia][
    *Span* = pojedyncza operacja. Zawiera: `span_id` (64-bit), `trace_id` (128-bit), `parent_span_id`, `name`, `status`, `attributes`, `events`, czasy z dokładnością ns. \
    *Trace* = zbiór spanów połączonych tym samym `trace_id`. *Root span* — bez rodzica.
  ]

  #exblock[W3C Trace Context — nagłówek `traceparent`][
    `00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01` \
    `version` (2 hex) #sym.dot.c `trace-id` (32 hex) #sym.dot.c `parent-id` (16 hex) #sym.dot.c `flags` (sampled)
  ]

  #src[W3C Trace Context Level 2 — w3.org/TR/trace-context]
]

#slide(title: [Sampling — head-based vs tail-based])[
  #align(center)[
    #sm[#table(
      columns: 4,
      align: (left, left, left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Cecha],
        text(fill: white, weight: "bold")[Head-based],
        text(fill: white, weight: "bold")[Tail-based],
        text(fill: white, weight: "bold")[Uwagi],
      ),
      [*Decyzja*], [Przy tworzeniu spanu], [Po zakończeniu trace], [—],
      [*Stan*], [Bezstanowe], [Collector buforuje], [Pamięć],
      [*Błędy*], [Może zgubić], [Gwarancja 100%], [Kluczowe],
      [*Typowa stopa*], [1–5% przy >10k RPS], [100% błędy + 1% reszta], [Hybryda],
    )]
  ]

  #alertblock[Po co samplować?][
    Koszt i wolumen. 100% sampling = \~\$480/mies. (10M req/dzień). 1% = \~\$4,80. \
    Tail sampling: 100% błędów + latency >2s, 1% reszty = oszczędność 80–90% przy zachowaniu debugowalności.
  ]

  #sm[Narzędzia: Jaeger (Elasticsearch/Cassandra), Grafana Tempo (object storage, TraceQL), Zipkin, AWS X-Ray.]
]

#title-slide[Metryki]

#slide(title: [RED, USE, Four Golden Signals])[
  #align(center)[
    #sm[#table(
      columns: 4,
      align: (left, left, left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Metoda],
        text(fill: white, weight: "bold")[Sygnały],
        text(fill: white, weight: "bold")[Zakres],
        text(fill: white, weight: "bold")[Autor],
      ),
      [*RED*], [Rate, Errors, Duration], [Serwisy request-driven], [T. Wilkie (Grafana)],
      [*USE*], [Utilization, Saturation, Errors], [Zasoby (CPU, RAM, dysk)], [B. Gregg],
      [*Golden Signals*], [Latency, Traffic, Errors, Saturation], [Systemy user-facing], [Google SRE],
    )]
  ]

  #exblock[Wzorzec praktyczny][
    RED na warstwie serwisów + USE na warstwie infrastruktury = Golden Signals w obu. \
    Stos de-facto: *Prometheus* (zbieranie) + *Grafana* (wizualizacja).
  ]

  #src[Google SRE Book, rozdz. 6 #sym.dot.c brendangregg.com/usemethod.html]
]

#slide(title: [Cardinality explosion — problem skalowalności Prometheusa])[
  #alertblock[Jedna zła etykieta = miliony serii][
    `http_requests_total{method, status, user_id=<10M>}` = miliardy serii czasowych. Każda unikalna kombinacja nazwa + etykiety = jedna seria.
  ]

  Skutki:
  - Wzrost zużycia pamięci (każda seria indeksowana)
  - Spowolnienie zapytań, eksplozja storage
  - Prometheus *OOMKilled* przy >5–10M serii

  #defblock[Zakazane etykiety (nieograniczona kardynalność)][
    `user_id`, `request_id`, `trace_id`, `url` z parametrami, `error_message`. \
    Reguła: < 1000 unikalnych wartości per etykieta. High-cardinality #sym.arrow logi/trace, nie metryki.
  ]
]

#slide(title: [Obserwowalność a SLO (nawiązanie do wykładu 1)])[
  #defblock[Obserwowalność zasila pomiar SLO][
    + *Mierz SLI* — z metryk/trace liczysz realny p99, error rate
    + *Wykrywaj burn rate* — czy zużywasz error budget za szybko?
    + *Root cause* — gdy SLO złamane, trace + logi wskazują który serwis
    + *Feedback* — metryki incydentów #sym.arrow korekta SLO i alertów
  ]

  #exblock[eBPF — auto-instrumentacja bez kodu (2026)][
    OpenTelemetry eBPF Instrumentation (OBI): HTTP/gRPC tracing + RED metrics, overhead 1–3% CPU. 67% klastrów K8s używa narzędzia eBPF (CNCF Q1 2026).
  ]
]

// ════════════════════════════════════════════════════════════
//  CZĘŚĆ II — BEZPIECZEŃSTWO
// ════════════════════════════════════════════════════════════

#title-slide[Bezpieczeństwo]

#slide(title: [Zero Trust — „never trust, always verify"])[
  #defblock[NIST SP 800-207 (2020)][
    Brak domyślnego zaufania do zasobów na podstawie *lokalizacji sieciowej* lub właściciela. Każde żądanie — z biura czy z domu — wymaga uwierzytelnienia, autoryzacji i ciągłej walidacji.
  ]

  #alertblock[Model perymetrowy (castle-and-moat) jest niewystarczający][
    Chmura, praca zdalna, mikroserwisy, efemeryczne IP w K8s — sieci nie da się już „obwarować". Granicą jest *tożsamość*, nie adres IP.
  ]

  #cols[
    *Tenety NIST:*
    - Wszystko to zasób
    - Komunikacja zawsze szyfrowana
    - Dostęp per-sesja
  ][
    *Mechanizm:*
    - PDP (Policy Decision Point)
    - PEP (Policy Enforcement Point)
    - Dynamiczna polityka kontekstowa
  ]

  #src[Google BeyondCorp — zero udanych ataków phishing po wymuszeniu kluczy sprzętowych (2017)]
]

#slide(title: [OAuth 2.0 vs OpenID Connect])[
  #align(center)[
    #sm[#table(
      columns: 3,
      align: (left, left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Aspekt],
        text(fill: white, weight: "bold")[OAuth 2.0],
        text(fill: white, weight: "bold")[OpenID Connect],
      ),
      [*Cel*], [Autoryzacja (delegowany dostęp)], [Uwierzytelnianie (tożsamość)],
      [*Pytanie*], [„Co aplikacja może?"], [„Kto to jest?"],
      [*Token*], [Access + refresh token], [+ ID token (zawsze JWT)],
      [*Standard*], [RFC 6749], [Warstwa nad OAuth 2.0],
    )]
  ]

  #defblock[Cztery role OAuth][
    Resource Owner (user) #sym.dot.c Client (aplikacja) #sym.dot.c Authorization Server (wydaje tokeny) #sym.dot.c Resource Server (chroni zasób).
  ]
]

#slide(title: [OAuth 2.1 — konsolidacja best practices])[
  #align(center)[
    #sm[#table(
      columns: 3,
      align: (left, left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Cecha],
        text(fill: white, weight: "bold")[OAuth 2.0],
        text(fill: white, weight: "bold")[OAuth 2.1],
      ),
      [*PKCE*], [Opcjonalne (mobile)], [*Obowiązkowe* dla wszystkich],
      [*Implicit grant*], [Dozwolony], [*Usunięty*],
      [*Password grant (ROPC)*], [Dozwolony], [*Usunięty*],
      [*Redirect URI*], [Wildcardy], [Dokładne dopasowanie],
      [*Bearer w query string*], [Dozwolony], [Tylko nagłówek/body],
    )]
  ]

  #defblock[Authorization Code + PKCE — domyślny przepływ][
    `code_challenge = SHA256(code_verifier)`. Kod bezużyteczny bez `code_verifier` #sym.arrow ochrona przed przechwyceniem kodu. \
    Service-to-service: *Client Credentials* (JWT + mTLS zamiast gołego sekretu).
  ]
]

#slide(title: [JWT — struktura i pułapki])[
  #defblock[`header.payload.signature` (base64url) — RFC 7519][
    Claims: `iss`, `sub`, `aud`, `exp`, `iat`, `jti`. \
    Podpis: HS256 (symetryczny, współdzielony sekret) lub RS256/ES256 (asymetryczny — klucz prywatny tylko u wydawcy).
  ]

  #alertblock[Klasyczne podatności][
    + *`alg: none`* — biblioteka akceptuje token bez podpisu (CVE-2015-9235)
    + *Algorithm confusion* — RS256 #sym.arrow HS256, klucz publiczny jako sekret HMAC
    + *Brak walidacji `exp`/`aud`* — token z innego serwisu akceptowany
    + *localStorage* — kradzież tokenu przez XSS
  ]

  #exblock[Best practice][
    Krótki `exp` (15 min) + rotacja refresh tokenów. Waliduj *wszystko* (`algorithms: ['RS256']`, `aud`, `iss`, `exp`). Token w httpOnly cookie, nie localStorage.
  ]
]

#slide(title: [mTLS i tożsamość workloadów — SPIFFE/SPIRE])[
  #defblock[Mutual TLS — obie strony przedstawiają certyfikat][
    Zwykły TLS: serwer dowodzi tożsamości. mTLS: *klient też*. Spoofing IP/DNS nie wystarczy — potrzebny certyfikat workloadu.
  ]

  #defblock[SPIFFE/SPIRE — standaryzowana tożsamość][
    `spiffe://prod.example.com/ns/payments/sa/stripe-integration` \
    SVID (X.509 lub JWT) wydawany per workload. Klucz prywatny *nigdy* nie opuszcza poda. Automatyczna rotacja co \~5 min.
  ]

  #alertblock[Problem rotacji certyfikatów][
    X.509 mają sztywny termin ważności. Ręczna rotacja w skali = źródło awarii. SPIRE atestuje workload (K8s ServiceAccount) i rotuje automatycznie.
  ]
]

#slide(title: [Service mesh — mTLS „za darmo"])[
  #align(center)[
    #sm[#table(
      columns: 4,
      align: (left, left, left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Cecha],
        text(fill: white, weight: "bold")[Istio sidecar],
        text(fill: white, weight: "bold")[Istio ambient],
        text(fill: white, weight: "bold")[Linkerd],
      ),
      [*mTLS*], [Automatyczny], [Automatyczny], [Automatyczny],
      [*Proxy*], [Envoy per pod], [ztunnel per node], [micro-proxy (Rust)],
      [*Pamięć/pod*], [\~50 MB], [\~0,5 MB ztunnel], [\~1 MB],
      [*Narzut mTLS*], [99–166%], [8–33%], [\~33%],
    )]
  ]

  #exblock[Istio Ambient Mesh (GA v1.24, XI 2024)][
    Zmiana modelu: bez sidecarów. *ztunnel* (L4 mTLS, per node) + opcjonalny *waypoint* (L7) per namespace. Oszczędność pamięci >90% vs sidecar. Inkrementalna adopcja (nawiązanie do service mesh z ZSR).
  ]

  #sm[Linkerd 2.19 (2025): kryptografia post-kwantowa ML-KEM-768.]
]

#slide(title: [Zarządzanie sekretami])[
  #alertblock[Czego nie robić][
    Hardcode w kodzie #sym.dot.c commit do gita (nieodwracalny wyciek) #sym.dot.c K8s Secrets bez szyfrowania (base64 #sym.eq.not szyfrowanie; plaintext w etcd).
  ]

  #defblock[HashiCorp Vault — dynamiczne sekrety][
    Zamiast przechowywać statyczne hasło — *generuj* unikalne, krótkożyjące poświadczenia na żądanie (TTL 1h). Automatyczne odwołanie po wygaśnięciu. Per-serwis = audyt + mały blast radius.
  ]

  #cols[
    *Cloud:*
    - AWS Secrets Manager + KMS
    - GCP Secret Manager
    - Azure Key Vault
  ][
    *Kubernetes:*
    - Szyfrowanie at-rest (KMS provider)
    - External Secrets Operator
    - SOPS / sealed-secrets (GitOps)
  ]
]

#slide(title: [Defense in depth i confused deputy])[
  #defblock[Warstwy obrony][
    + *API Gateway* — authN na brzegu, rate limiting, walidacja schematu
    + *Service mesh* — mTLS, AuthorizationPolicy L4/L7
    + *Logika aplikacji* — fine-grained uprawnienia (czy user *posiada* zasób?)
    + *Warstwa danych* — szyfrowanie at-rest, row-level security
  ]

  #alertblock[Problem confused deputy][
    User A (niskie uprawnienia) nakłania serwis X (wysokie) do wywołania serwisu Y w jego imieniu. \
    *Ochrona*: token związany z zasobem (`aud`, `scope`), token exchange (zawężenie scope), least privilege.
  ]
]

// ════════════════════════════════════════════════════════════
//  CZĘŚĆ III — CHMURA, AI, PLATFORM ENGINEERING, FINOPS
// ════════════════════════════════════════════════════════════

#title-slide[#emoji.cloud Chmura, AI i nowe dyscypliny]

#slide(title: [AI/ML inference jako problem systemu rozproszonego])[
  #defblock[Wąskie gardło 2025/26 to nie trening, lecz serving][
    Miliardy tokenów dziennie, latencja w ms. Koszt napędzany przez *throughput tokenów*, *KV-cache*, *głębokość kolejki* — nie przez CPU/RAM.
  ]

  #align(center)[
    #sm[#table(
      columns: 3,
      align: (left, left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Narzędzie],
        text(fill: white, weight: "bold")[Rola],
        text(fill: white, weight: "bold")[Innowacja],
      ),
      [*vLLM*], [Silnik inferencji LLM], [PagedAttention, continuous batching],
      [*KServe*], [Orkiestracja na K8s (CRD)], [KV-cache aware routing, scale-to-zero],
      [*NVIDIA Triton*], [Heterogeniczna flota], [TensorRT-LLM backend],
      [*AI Gateway*], [Warstwa przed modelem], [Semantic caching, token rate limiting],
    )]
  ]

  #sm[Wzorce rozproszone: tensor/data/expert parallelism, disaggregated prefill-decode, RAG jako pipeline (embedding #sym.arrow vector store #sym.arrow retriever #sym.arrow LLM).]
]

#slide(title: [Platform Engineering — platforma jako produkt])[
  #defblock[Od „zespołu DevOps" do Internal Developer Platform (IDP)][
    Cognitive load — nie możliwości infrastruktury — jest realnym ograniczeniem. Platforma self-service z *golden paths* (paved roads) redukuje obciążenie zespołów stream-aligned.
  ]

  #cols[
    #defblock[Backstage (Spotify, CNCF)][
      - Software Catalog (kto czego właściciel)
      - Software Templates (scaffolding < 5 min)
      - TechDocs (docs-as-code)
      - 200+ pluginów
    ]
  ][
    #defblock[Team Topologies][
      - Stream-aligned (e2e domena)
      - Platform (X-as-a-Service)
      - Enabling (czasowe wsparcie)
      - Complicated-subsystem
    ]
  ]

  #src[M. Skelton, M. Pais — _Team Topologies_ (2019) #sym.dot.c backstage.io]
]

#slide(title: [FinOps — koszt jako obywatel pierwszej klasy])[
  #defblock[Framework FinOps: Inform #sym.arrow Optimize #sym.arrow Operate][
    Widoczność kosztu per workload #sym.arrow rightsizing i eliminacja marnotrawstwa #sym.arrow dyscyplina przez automatyzację i governance.
  ]

  #alertblock[Skala marnotrawstwa (2026)][
    \~29% wydatków IaaS/PaaS to marnotrawstwo. Idle compute (35%) + overprovisioning (25%). Średnia utylizacja GPU: 23%. K8s: requesty napędzają rachunek, nie realne użycie.
  ]

  #cols[
    *Narzędzia:*
    - OpenCost (CNCF)
    - Kubecost
    - CAST AI (auto-optimize)
  ][
    *W praktyce:*
    - FinOps ma *widoczność*, rzadko *władzę*
    - Działa: auto-shutdown z grace period
    - Unit economics: koszt/request
  ]
]

#slide(title: [Well-Architected Framework — sześć filarów])[
  #defblock[AWS Well-Architected — lekcje całego kursu w jednym frameworku][
    + *Operational Excellence* — bezpieczne i przewidywalne wdrożenia
    + *Security* — ochrona danych i systemów
    + *Reliability* — poprawne działanie mimo awarii (wykład 6)
    + *Performance Efficiency* — efektywne użycie zasobów
    + *Cost Optimization* — wartość przy rozsądnym koszcie (FinOps)
    + *Sustainability* — minimalizacja śladu środowiskowego (dodany 2021)
  ]

  #sm[Azure Well-Architected i Google Cloud Architecture Framework — analogiczne. Procesory ARM (Graviton) = 60% mniej energii vs x86.]
]

// ════════════════════════════════════════════════════════════
//  CZĘŚĆ IV — TRENDY I PRZYSZŁOŚĆ
// ════════════════════════════════════════════════════════════

#title-slide[Trendy i przyszłość]

#slide(title: [Emerging trends — co dojrzewa w 2025/26])[
  #align(center)[
    #sm[#table(
      columns: 2,
      align: (left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Trend],
        text(fill: white, weight: "bold")[Istota],
      ),
      [*eBPF / Cilium*], [Sieć + observability + security w jądrze; \~2#sym.times throughput vs iptables],
      [*WebAssembly server-side*], [WASI 0.2 stabilny; edge serverless, pluginy; cold start w #sym.mu\s],
      [*Durable execution*], [Temporal, AWS Step Functions, pg_durable — workflow przeżywa awarie],
      [*Modular monolith*], [Odwrót od „mikro-wszystkiego"; right-sizing zamiast 100 serwisów],
      [*Distributed SQL*], [CockroachDB, YugabyteDB, TiDB — skala zapisu + silna spójność],
      [*Data Mesh*], [Zdecentralizowana własność danych; data jako produkt],
    )]
  ]
]

#slide(title: [Prawo Conwaya — organizacja kształtuje architekturę])[
  #defblock[Conway (1968)][
    „Organizacja projektująca system wytworzy projekt, którego struktura kopiuje strukturę komunikacji tej organizacji."
  ]

  #exblock[Inverse Conway Maneuver][
    Świadomie projektuj *strukturę zespołów*, by uzyskać pożądaną architekturę. \
    Chcesz mikroserwisy? #sym.arrow zespoły stream-aligned per domena. \
    Chcesz modularny monolit? #sym.arrow zespoły we wspólnym repo.
  ]

  #alertblock[Wahadło: centralizacja #sym.arrow.l.r decentralizacja][
    Lata 2010: decentralizacja (mikroserwisy). Lata 2020: re-centralizacja governance (platform teams, policy-as-code). 2026: hybryda — centralne standardy, zdecentralizowana własność.
  ]
]

#slide(title: [Ponadczasowe zasady — przetrwają cykle trendów])[
  #defblock[Trwałe zasady projektowania][
    + *„Nie ma rozwiązań, są tylko trade-offy"* (T. Sowell) — artykułuj kompromis jawnie
    + *Choose Boring Technology* (D. McKinley) — innowuj w biznesie, nie w infrastrukturze
    + *Design for failure* — każdy komponent zawiedzie (wykład 6)
    + *Dane przeżywają kod* — przepiszesz kod 5–10#sym.times, format danych zostaje
    + *Fallacies of Distributed Computing* nadal prawdziwe (wykład 6)
  ]

  #sm[Systemy, które wygrywają: architektura techniczna odzwierciedla granice organizacyjne, infrastruktura jest na tyle prosta, by ją obsłużyć, koszt jest widoczny i ma właściciela.]
]

// ════════════════════════════════════════════════════════════
//  CASE STUDY — DESIGN YOUTUBE
// ════════════════════════════════════════════════════════════

#title-slide[Case study: Design YouTube]

#slide(title: [Wymagania i skala (A. Xu, rozdz. 14)])[
  #defblock[Wymagania funkcjonalne][
    Upload wideo. Streaming/oglądanie. Zmiana rozdzielczości. Niska latencja. Wsparcie mobile i web.
  ]

  Estymacja (back-of-the-envelope, nawiązanie do wykładu 1):
  - 5 mld użytkowników, 800 mln DAU
  - 5 wyświetleń/dzień/user #sym.arrow \~46 000 wyświetleń/s
  - Upload:wyświetlenia = 1:200
  - Storage: 500h wideo/min uploadowane

  #alertblock[Łączy wszystkie wykłady][
    To synteza: estymacja, architektura, komunikacja, dane, odporność, serverless, obserwowalność, bezpieczeństwo.
  ]
]

#slide(title: [Architektura end-to-end])[
  #defblock[Pipeline uploadu i transkodowania][
    Upload #sym.arrow object storage (S3) #sym.arrow kolejka #sym.arrow DAG transkodowania (równolegle: rozdzielczości, formaty, thumbnails) #sym.arrow CDN.
  ]

  #align(center)[
    #sm[#table(
      columns: 2,
      align: (left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Wyzwanie],
        text(fill: white, weight: "bold")[Rozwiązanie (wykład)],
      ),
      [Streaming z niską latencją], [CDN + adaptive bitrate (DASH/HLS) — w.9 edge],
      [Transkodowanie w skali], [DAG zadań, kolejka, fan-out — w.4, w.9],
      [Metadane vs pliki], [Strong vs eventual consistency — w.5],
      [Odporność pipeline], [DLQ, retry, idempotencja — w.6],
      [Koszt storage], [Tiering (hot/cold), deduplikacja — w.9, FinOps],
    )]
  ]
]

// ── Dyskusja ─────────────────────────────────────────────────

#focus-slide[
  Wasz system mikroserwisowy ma 40 serwisów. Production incident: latencja p99 wzrosła z 200 ms do 4 s, ale *żaden* dashboard nie pokazuje błędów.

  Jak użyjecie *obserwowalności* (traces, metrics, logs), by znaleźć przyczynę?

  Od czego zaczniecie — i dlaczego akurat od tego?
]

// ════════════════════════════════════════════════════════════
//  ŹRÓDŁA
// ════════════════════════════════════════════════════════════

#title-slide[Źródła]

#slide(title: [Źródła i lektury])[

  - M. Kleppmann — _Designing Data-Intensive Applications_ (O'Reilly, 2017)
  - S. Newman — _Building Microservices_, 2nd ed. (O'Reilly, 2021)
  - A. Xu — _System Design Interview_, rozdz. 14 (YouTube)
  - Google SRE Team — _SRE Book_ (Golden Signals, error budgets)
  - M. Skelton, M. Pais — _Team Topologies_ (2019)
  - B. Gregg — _Systems Performance_, 2nd ed. (USE Method)
  - OpenTelemetry — opentelemetry.io/docs
  - W3C Trace Context — w3.org/TR/trace-context
  - NIST SP 800-207 — Zero Trust Architecture
  - OAuth 2.1 — oauth.net/2.1 #sym.dot.c SPIFFE — spiffe.io
  - FinOps Foundation — finops.org #sym.dot.c AWS Well-Architected — aws.amazon.com/architecture
]

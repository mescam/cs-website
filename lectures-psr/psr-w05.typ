// Wykład 5: Dane w systemach rozproszonych — strategie, replikacja, partycjonowanie
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
  title: "Dane w systemach rozproszonych",
  subtitle: [Replikacja · Partycjonowanie · Spójność · CAP/PACELC],
  authors: "mgr inż. Jakub Woźniak",
  info: [Politechnika Poznańska · Instytut Informatyki · Semestr letni 2025/26],
)

#title-slide[Plan wykładu]

#slide(title: [Agenda])[

  - Database per Service — konsekwencje projektowe
  - Dobór bazy danych pod przypadek użycia
  - Replikacja — leader-follower, multi-leader, leaderless
  - Partycjonowanie — range, hash, consistent hashing
  - Spójność — ACID vs BASE, CAP, PACELC
  - Change Data Capture (CDC)
  - #emoji.cloud Managed databases w chmurze
]

// ── Database per Service ─────────────────────────────────────

#title-slide[Database per Service]

#slide(title: [Zasada: każdy serwis = własne dane])[

  #defblock[Database per Service][
    Każdy mikroserwis *jest właścicielem* swojego stanu. Żaden inny serwis nie sięga bezpośrednio do jego bazy — komunikacja wyłącznie przez API lub zdarzenia.
  ]

  Konsekwencje:
  - Brak JOIN-ów między serwisami — denormalizacja lub API composition
  - Brak transakcji ACID między bazami — potrzebne sagi (wykład 4)
  - Wolność wyboru technologii — serwis A na PostgreSQL, B na Redis
  - *Właściciel danych = właściciel schematu* — niezależne migracje

  #src[C. Richardson — microservices.io/patterns/data/database-per-service.html]
]

#slide(title: [Anti-pattern: Shared Database])[

  #alertblock[Shared Database][
    Wiele serwisów pisze/czyta z *jednej bazy*. Każda zmiana schematu wymaga koordynacji wszystkich zespołów. Tight coupling przez współdzielone tabele.
  ]

  Sygnały ostrzegawcze:
  - Serwis zamówień robi `SELECT * FROM users` bezpośrednio
  - Migracja kolumny wymaga deploymentu 5 serwisów jednocześnie
  - „Nie możemy zmienić tabeli, bo ktoś z innego zespołu z niej czyta"
]

// ── Dobór bazy danych ────────────────────────────────────────

#title-slide[Dobór bazy danych]

#slide(title: [Nie ma jednej bazy na wszystko])[

  #align(center)[
    #sm[#table(
      columns: 4,
      align: (left, left, left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Typ],
        text(fill: white, weight: "bold")[Przykłady],
        text(fill: white, weight: "bold")[Silne strony],
        text(fill: white, weight: "bold")[Przypadek użycia],
      ),
      [*Relacyjna*],     [PostgreSQL, MySQL],      [ACID, JOIN-y, dojrzałość],    [Zamówienia, finanse],
      [*Dokumentowa*],   [MongoDB, Firestore],     [Elastyczny schemat, JSON],    [Katalog produktów, CMS],
      [*Wide-column*],   [Cassandra, HBase],       [Write-heavy, skala],          [Logi, IoT, time-series],
      [*Klucz-wartość*], [Redis, DynamoDB],        [Sub-ms latencja, prostota],   [Cache, sesje, leaderboard],
      [*Grafowa*],       [Neo4j, Neptune],         [Relacje N:M, traversal],      [Social graph, fraud detect.],
    )]
  ]

  Kleppmann: _„Nie pytaj »jaka baza jest najlepsza?« — pytaj »jaki mam wzorzec dostępu?«"_
]

// ── Replikacja ───────────────────────────────────────────────

#title-slide[Replikacja]

#slide(title: [Po co replikować?])[

  #defblock[Trzy cele replikacji][
    + *Wysoka dostępność* — awaria jednego węzła nie zatrzymuje systemu
    + *Niskie opóźnienie odczytów* — replika blisko użytkownika (multi-region)
    + *Skalowalność odczytów* — rozkładanie read load na wiele replik
  ]

  Fundamentalny kompromis (Kleppmann, DDIA rozdz. 5): \
  _Im więcej replik, tym trudniej utrzymać ich spójność._
]

#slide(title: [Leader-Follower (single-leader)])[

  #defblock[Zasada działania][
    Jeden węzeł (*leader*) przyjmuje zapisy. Followerzy replikują log asynchronicznie lub synchronicznie.
  ]

  - *Synchroniczna replikacja*: follower potwierdza przed commit — gwarantuje spójność, ale zwiększa latency
  - *Asynchroniczna*: leader commituje natychmiast — ryzyko utraty danych przy awarii leadera
  - *Semi-synchroniczna* (PostgreSQL): 1 follower synchroniczny, reszta async — kompromis

  Problemy: *failover* — kto zostaje nowym leaderem? Split-brain jeśli stary leader wraca.
]

#slide(title: [Multi-Leader i Leaderless])[

  #cols[
    #defblock[Multi-Leader][
      Wielu leaderów w różnych DC. Zapis do najbliższego.
      - Niższe opóźnienie zapisu (lokalny DC)
      - *Konflikty zapisu* — ten sam rekord zmieniony w dwóch DC
      - Rozwiązywanie: last-write-wins, merge, CRDT
      - Np. CouchDB, Cassandra (multi-DC)
    ]
  ][
    #defblock[Leaderless (Dynamo-style)][
      Brak leadera. Zapis do *N replik* jednocześnie.
      - Klient pisze do W replik, czyta z R
      - Quorum: *W + R > N* gwarantuje overlap
      - Np. Cassandra, Riak, DynamoDB
    ]
  ]

  #src[G. DeCandia et al. — „Dynamo: Amazon's Highly Available Key-value Store" (SOSP 2007)]
]

#slide(title: [Quorum: W + R > N])[

  #defblock[Parametry quorum (N=3)][
    - *W=2, R=2*: zapis na 2 z 3 replik, odczyt z 2 → zawsze overlap z najnowszym zapisem
    - *W=1, R=3*: szybki zapis, wolny odczyt → read-repair naprawia niespójne repliki
    - *W=3, R=1*: wolny zapis, szybki odczyt → gwarancja read-after-write
  ]

  #alertblock[Quorum nie gwarantuje linearizability!][
    Sloppy quorum (hinted handoff), network partitions, concurrent writes — nawet z W+R>N możliwe odczytanie starych danych. Artykuł Dynamo opisuje to szczegółowo.
  ]

  #src[Kleppmann — DDIA, rozdz. 5: „Quorums for reading and writing"]
]

// ── Partycjonowanie ──────────────────────────────────────────

#title-slide[Partycjonowanie]

#slide(title: [Po co partycjonować (sharding)?])[

  #defblock[Cel][
    Dane nie mieszczą się na jednym węźle → *podziel je* na partycje (shardy) rozłożone na wiele maszyn.
  ]

  Dwa cele:
  - *Skalowalność zapisu* — rozpraszamy write load
  - *Skalowalność danych* — terabajty rozłożone na klaster

  Klucz partycjonowania (*partition key*) determinuje, na który węzeł trafi rekord.
]

#slide(title: [Range vs Hash partitioning])[

  #cols[
    #defblock[Range-based][
      Klucze posortowane, zakres per partycja.
      - + Efektywne range scany
      - − *Hot spots* — np. klucz = data, dziś = cały ruch na jednej partycji
      - Np. HBase, BigTable
    ]
  ][
    #defblock[Hash-based][
      Klucz → hash → partycja.
      - + Równomierny rozkład
      - − Brak range scanów (hash niszczy kolejność)
      - Np. Cassandra (z opcją compound key)
    ]
  ]
]

#slide(title: [Consistent Hashing])[

  #defblock[Consistent Hashing (Karger et al., 1997)][
    Węzły i klucze mapowane na *pierścień*. Klucz trafia do najbliższego węzła w kierunku zgodnym z wskazówkami zegara. Dodanie/usunięcie węzła przesuwa tylko ~1/N kluczy.
  ]

  Użyte w: DynamoDB, Cassandra, Riak, Memcached, load balancerach.

  Wariant: *virtual nodes* (vnodes) — każdy fizyczny węzeł ma wiele pozycji na pierścieniu → lepszy balans.

  #src[Karger et al. — „Consistent Hashing and Random Trees" (STOC 1997)]
]

// ── Spójność ─────────────────────────────────────────────────

#title-slide[Spójność danych]

#slide(title: [ACID vs BASE])[

  #cols[
    #defblock[ACID][
      *Atomicity* — all or nothing \
      *Consistency* — invarianty zachowane \
      *Isolation* — transakcje nie widzą siebie nawzajem \
      *Durability* — zapisane = trwałe
    ]
  ][
    #alertblock[BASE][
      *Basically Available* — system odpowiada (może stare dane) \
      *Soft state* — stan może być niespójny tymczasowo \
      *Eventual consistency* — po czasie repliki się zsynchronizują (spójność ostateczna)
    ]
  ]

  ACID = gwarancja dla jednej bazy. W systemie rozproszonym (wiele baz) → BASE + sagi.
]

#slide(title: [CAP Theorem (Brewer, 2000)])[

  #defblock[CAP][
    W obliczu *partycji sieciowej* (P) musisz wybrać: \
    *Consistency* (C) — każdy odczyt zwraca najnowszy zapis, albo błąd \
    *Availability* (A) — każdy odczyt zwraca odpowiedź (niekoniecznie najnowszą)
  ]

  #alertblock[Typowe nieporozumienia][
    - CAP nie mówi „wybierz 2 z 3" — *partycje się zdarzają*, więc wybór to C vs A _podczas partycji_
    - Kiedy sieć działa normalnie — możesz mieć i C, i A
    - CP: odrzuć zapisy/odczyty przy partycji (np. HBase, Spanner)
    - AP: odpowiadaj, ale dane mogą być stale (np. Cassandra, DynamoDB default)
  ]

  #src[E. Brewer — „CAP Twelve Years Later: How the 'Rules' Have Changed" (2012)]
]

#slide(title: [PACELC — bardziej użyteczny model])[

  #defblock[PACELC (Abadi, 2012)][
    Jeśli *Partition* (P): wybierz *A* vs *C* \
    *Else* (E) — gdy sieć OK: wybierz *Latency* (L) vs *Consistency* (C)
  ]

  #align(center)[
    #sm[#table(
      columns: 3,
      align: (left, center, center),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[System],
        text(fill: white, weight: "bold")[P: A vs C],
        text(fill: white, weight: "bold")[E: L vs C],
      ),
      [DynamoDB],       [A],  [L],
      [Cassandra],      [A],  [L],
      [Spanner],        [C],  [C],
      [PostgreSQL (1n)],[C],  [C],
      [MongoDB],        [A],  [C],
      [Cosmos DB],      [konfigurowalne], [konfigurowalne],
    )]
  ]

  #src[D. Abadi — „Consistency Tradeoffs in Modern Distributed Database System Design" (2012)]
]

// ── Transakcje rozproszone ───────────────────────────────────

#title-slide[Transakcje rozproszone]

#slide(title: [2PC — Two-Phase Commit])[

  #defblock[Fazy][
    *Faza 1 (Prepare)*: koordynator pyta uczestników „czy możesz commitować?" \
    *Faza 2 (Commit/Abort)*: jeśli wszyscy OK → commit, w przeciwnym razie → abort
  ]

  #alertblock[Problemy 2PC][
    - *Blokujący* — uczestnicy trzymają locki czekając na decyzję
    - *Single point of failure* — awaria koordynatora = zablokowane transakcje
    - *Nie skaluje się* — latency rośnie z liczbą uczestników
    - *Niewspierany* przez wiele NoSQL i brokerów (Kafka, DynamoDB)
  ]

  W mikroserwisach: preferuj *Sagi* (wykład 4) zamiast 2PC.
]

// ── Change Data Capture ──────────────────────────────────────

#title-slide[Change Data Capture]

#slide(title: [CDC — propagacja zmian między serwisami])[

  #defblock[Change Data Capture][
    Czytaj *log transakcji* bazy danych (WAL/binlog) i publikuj zmiany jako zdarzenia do Kafki. Inne serwisy konsumują te zdarzenia i aktualizują swoje projekcje.
  ]

  Dlaczego CDC zamiast dual writes?
  - Dual write (zapis do DB + zapis do Kafki) = *brak atomowości* — jedno może się udać, drugie nie
  - CDC = *atomowe* — jeśli jest w DB, będzie w Kafce

  Narzędzia: *Debezium* (open-source, wspiera PostgreSQL, MySQL, MongoDB), Kafka Connect, AWS DMS
]

#slide(title: [CDC w praktyce — Debezium + Kafka Connect])[

  #defblock[Architektura][
    PostgreSQL (WAL) → *Debezium Connector* → Kafka topic per tabela → konsumenci (projekcje, cache, search index)
  ]

  Typowe zastosowania:
  - *Materialized views* między serwisami — serwis zamówień emituje zdarzenia, serwis analityki buduje dashboardy
  - *Cache invalidation* — zmiana w DB → usunięcie z Redis
  - *Search index sync* — zmiana w DB → update Elasticsearch
  - *Migracja danych* — streaming z legacy DB do nowego systemu

  #src[debezium.io — Debezium Documentation]
]

// ── Case study: Key-Value Store ──────────────────────────────

#title-slide[Case study: Key-Value Store]

#slide(title: [Design a Key-Value Store (A. Xu, rozdz. 6)])[

  #defblock[Od hash mapy do rozproszonego systemu][
    - *Consistent hashing* — dystrybucja kluczy na klaster
    - *Quorum* (W, R, N) — kompromis spójność vs dostępność
    - *Vector clocks* — wykrywanie konfliktów w leaderless replication
    - *Gossip protocol* — propagacja membership i failure detection
    - *Merkle trees* — synchronizacja danych między replikami
  ]

  Artykuł Dynamo (2007) opisuje dokładnie te decyzje: \
  Amazon wybrał *spójność ostateczną jako domyślną* — „always-writable" ważniejsze niż silna spójność dla koszyka zakupowego.

  #src[DeCandia et al. — „Dynamo" (SOSP 2007) · allthingsdistributed.com/files/amazon-dynamo-sosp2007.pdf]
]

// ── Cloud — Managed databases ────────────────────────────────

#title-slide[Managed databases w chmurze]

#slide(title: [Managed relational — za i przeciw])[

  #align(center)[
    #sm[#table(
      columns: 3,
      align: (left, left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Usługa],
        text(fill: white, weight: "bold")[Architektura],
        text(fill: white, weight: "bold")[Kluczowa cecha],
      ),
      [*AWS RDS*],       [Single-AZ lub Multi-AZ failover],        [6 silników, failover < 60s],
      [*AWS Aurora*],    [6-krotna replikacja w 3 AZ, log-based], [Do 15 read replik, 5x throughput PostgreSQL],
      [*Cloud SQL*],     [Managed MySQL/PostgreSQL na GCP],        [Automatyczne backupy, repliki cross-region],
      [*AlloyDB*],       [PostgreSQL-compatible, columnar engine], [4x szybszy niż std. PostgreSQL (wg. Google)],
      [*Azure SQL DB*],  [Managed SQL Server],                    [Hyperscale tier, auto-tuning],
    )]
  ]
]

#slide(title: [Managed NoSQL i NewSQL])[

  #align(center)[
    #sm[#table(
      columns: 3,
      align: (left, left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Usługa],
        text(fill: white, weight: "bold")[Model],
        text(fill: white, weight: "bold")[Kluczowa cecha],
      ),
      [*DynamoDB*],     [Klucz-wartość / dokument],    [Single-digit ms, global tables, on-demand scaling],
      [*Cosmos DB*],    [Multi-model (dokument, graf)], [5 poziomów spójności (od silnej do ostatecznej)],
      [*Spanner*],      [Relacyjna, globalnie spójna],  [TrueTime: external consistency + global sharding],
      [*CockroachDB*],  [Distributed SQL (PostgreSQL)], [Survives AZ/region failure, serializable default],
      [*PlanetScale*],  [MySQL (Vitess)],               [Schema branching jak Git, zero-downtime migrations],
    )]
  ]

  #exblock[Spanner — jak to działa?][
    GPS + zegary atomowe (*TrueTime*) → znany bound na clock skew → *commit-wait* protocol → globalna linearizability bez locków międzykontynentalnych.
  ]

  #src[Corbett et al. — „Spanner: Google's Globally-Distributed Database" (OSDI 2012)]
]

// ── Dyskusja ─────────────────────────────────────────────────

#focus-slide[
  Twój system ma 3 repliki bazy danych. Ustawiasz W\=2, R\=2 (quorum).

  Użytkownik zapisał dane i *natychmiast* je czyta — czy zawsze zobaczy swój zapis?

  A jeśli W\=1, R\=3?

  Narysuj scenariusz, w którym quorum *nie* gwarantuje odczytu swoich zapisów.
]

// ── Podsumowanie ─────────────────────────────────────────────

#title-slide[Podsumowanie]

#slide(title: [Kluczowe wnioski])[

  + *Database per Service* — niezależność kosztem JOIN-ów i transakcji
  + *Replikacja*: leader-follower (proste) vs leaderless (quorum, Dynamo-style)
  + *Partycjonowanie*: consistent hashing = standard w rozproszonych systemach
  + *CAP to nie „wybierz 2 z 3"* — PACELC lepiej opisuje codzienny kompromis L vs C
  + *CDC > dual writes* — atomowa propagacja zmian między serwisami
  + *Managed DB* — Aurora, Spanner, Cosmos DB to nie „hostuję Postgresa na VM"
]

#slide(title: [Źródła i lektury])[

  - M. Kleppmann — _DDIA_, rozdz. 5, 6, 7, 9
  - G. DeCandia et al. — _Dynamo_ (SOSP 2007)
  - J. Corbett et al. — _Spanner_ (OSDI 2012)
  - E. Brewer — _CAP Twelve Years Later_ (2012)
  - D. Abadi — _Consistency Tradeoffs..._ (2012) — PACELC
  - W. Vogels — _Eventually Consistent_ (2008)
  - A. Xu — _System Design Interview_, rozdz. 6
  - Jepsen.io — Kyle Kingsbury — testy spójności baz danych
  - debezium.io — Debezium Documentation
]

#slide(title: [Następny wykład])[

  #defblock[Wykład 6: Odporność i niezawodność — projektowanie na awarie][
    Circuit Breaker · Retry · Rate Limiting · Chaos Engineering
  ]
]

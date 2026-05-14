// Wykład 8: Przetwarzanie danych w skali — batch, streaming, pipelines
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
  title: "Przetwarzanie danych w skali",
  subtitle: [Batch · Streaming · Kafka jako szkielet · CDC · Lambda/Kappa · Real-time OLAP],
  authors: "mgr inż. Jakub Woźniak",
  info: [Politechnika Poznańska · Instytut Informatyki · Semestr letni 2025/26],
)

#title-slide[Plan wykładu]

#slide(title: [Agenda])[

  - Wzorce przetwarzania wsadowego (batch)
  - Fundamentalne problemy przetwarzania strumieniowego (streaming)
  - Kafka jako centralny szkielet danych (rozwinięcie z wykładu 3)
  - Lambda vs Kappa Architecture
  - Change Data Capture w praktyce (rozwinięcie z wykładu 5)
  - Wzorce analityki czasu rzeczywistego (real-time OLAP)
  - ETL vs ELT
  - #emoji.cloud Managed streaming i OLAP w chmurze
]

// ── Batch Processing ─────────────────────────────────────────

#title-slide[Przetwarzanie wsadowe (batch)]

#slide(title: [Fundamentalny wzorzec: Map → Shuffle → Reduce])[
  #defblock[MapReduce jako wzorzec (nie narzędzie)][
    Schemat przetwarzania dużych zbiorów danych równolegle.
  ]

  + *Map* — niezależne przetwarzanie fragmentów danych → pary `(klucz, wartość)`
  + *Shuffle* — grupowanie par po kluczu, dystrybucja do procesorów odpowiedzialnych za redukcję
  + *Reduce* — agregacja wartości per klucz → wynik końcowy

  #exblock[Dlaczego ten wzorzec działa?][
    - *Partycjonowanie pracy*: Map jest trywialnie równoległy
    - *Determinizm*: te same dane → ten sam wynik
    - *Lokalizacja danych*: przetwarzaj tam, gdzie leżą
  ]
]

#slide(title: [Uniwersalne wzorce batch processing])[

  #defblock[1. Partycjonowanie pracy][
    Duży zbiór dzielimy na niezależne fragmenty. Każdy fragment przetwarzany osobno. Brak komunikacji między węzłami roboczymi podczas przetwarzania.
  ]

  #defblock[2. Odporność przez lineage (nie replikację)][
    Nie kopiujemy danych pośrednich na inne węzły. Zamiast tego pamiętamy *przepis* (lineage) — ciąg transformacji od inputu. Awaria? Powtórz obliczenie z przepisu.
  ]

  #cols[
    #defblock[3. Lazy evaluation + DAG][
      Transformacje nie wykonują się natychmiast — budują graf (DAG). Optymalizator analizuje cały graf _przed_ uruchomieniem. Eliminuje zbędne kroki, scala operacje.
    ]
  ][
    #defblock[4. Bariera shuffle][
      Jedyny punkt synchronizacji — wymiana danych między fazami. Zapis na dysk → odczyt przez następną fazę. *Wąskie gardło* każdego systemu batch.
    ]
  ]
]

#slide(title: [Ewolucja: od MapReduce do Spark])[
  #alertblock[Problem MapReduce (Hadoop, 2006)][
    Każdy krok Map→Reduce zapisuje wyniki na dysk (HDFS). Algorytmy iteracyjne (ML, PageRank) wymagają wielu przebiegów → wielokrotne I/O.
  ]

  #defblock[Rozwiązanie: przetwarzanie in-memory (Spark, 2014)][
    Wyniki pośrednie w pamięci (RDD → DataFrame). Zapis na dysk tylko przy shuffle. *10–100× szybszy* dla iteracyjnych obliczeń.
  ]

  Kluczowe innowacje: *Catalyst Optimizer* (predicate pushdown, join reordering), *AQE* (dynamiczna optymalizacja w runtime), *Tungsten* (codegen + off-heap).

  Wzorzec ogólny: *deklaratywne API + optymalizator* — użytkownik opisuje cel, system planuje wykonanie.
]

#slide(title: [dbt — transformacja jako kod w warehouse])[
  #defblock[Wzorzec: Transform-in-Place][
    Zamiast wyciągać dane, transformować na zewnętrznym silniku i ładować z powrotem — transformuj *wewnątrz* warehouse za pomocą SQL. Warehouse ma już compute i dane.
  ]

  Co to zmienia architektonicznie:
  - *Modularność* — modele SQL z zależnościami (DAG transformacji)
  - *Testowalność* — assertions na danych (not_null, unique, własne reguły)
  - *Wersjonowanie* — SQL w Git, CI/CD, code review
  - *Inkrementalność* — przetwarzaj tylko nowe/zmienione rekordy

  Pozycja w Modern Data Stack:
  #align(center)[
    #sm[Ingestion (EL) #sym.arrow.r *Warehouse* (surowe) #sym.arrow.r *dbt* (Transform) #sym.arrow.r BI / ML]
  ]

]

// ── Stream Processing ────────────────────────────────────────

#title-slide[Przetwarzanie strumieniowe (streaming)]

#slide(title: [Fundamentalny problem: czas])[
  #defblock[Event-time vs Processing-time][
    - *Event-time*: kiedy zdarzenie *naprawdę się wydarzyło* (timestamp z urządzenia/serwisu)
    - *Processing-time*: kiedy zdarzenie *dotarło do systemu* przetwarzającego
  ]

  #alertblock[Dlaczego to problem?][
    Zdarzenia docierają *nie w kolejności*. Opóźnienia sieci, retransmisje, buffering. \
    Zdarzenie z 10:00 może dotrzeć o 10:05. Jeśli okno `[10:00–10:05]` już zamknięte — dane utracone.
  ]

  Konsekwencje architektoniczne:
  - Nie możesz przetwarzać „po kolei" — musisz *tolerować nieporządek*
  - Musisz zdefiniować: jak długo czekam na spóźnione dane?
  - Musisz wybrać: *kompletność* (czekaj dłużej) vs *świeżość* (emituj szybciej)

]

#slide(title: [Watermarks — sygnał kompletności])[
  #defblock[Watermark = „wszystkie zdarzenia z event-time #sym.lt.eq T prawdopodobnie dotarły"][
    Watermarki zamykają okna.
  ]

  Strategie: *perfekcyjne* albo *heurystyczne*.

  #cols[
    *Watermark za wcześnie:*
    - Dane jeszcze docierają
    - Dozwolone spóźnienie (*allowed lateness*)
  ][
    *Watermark za późno:*
    - Wyniki później
  ]
]

#slide(title: [Okna czasowe (windowing)])[
  #defblock[Rodzaje okien — mechanizm grupowania zdarzeń w czasie][
    - *Tumbling (stałe)* — nieprzekrywające się okna o stałym rozmiarze (np. co 5 min)
    - *Sliding (przesuwne)* — nakładające się okna (np. 5 min co 1 min) — jedno zdarzenie w wielu oknach
    - *Session (sesyjne)* — dynamiczne, zamykane po okresie nieaktywności (gap)
  ]

  #align(center)[
    #sm[#table(
      columns: 4,
      align: (left, left, left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Typ okna],
        text(fill: white, weight: "bold")[Rozmiar],
        text(fill: white, weight: "bold")[Zdarzenie należy do],
        text(fill: white, weight: "bold")[Zastosowanie],
      ),
      [*Tumbling*],  [Stały],       [Dokładnie 1 okna],     [Raporty co N minut, billing],
      [*Sliding*],   [Stały],       [Wielu okien naraz],    [Średnia krocząca, alerting],
      [*Session*],   [Dynamiczny],  [1 sesji per klucz],    [Aktywność użytkownika, clickstream],
    )]
  ]

  #sm[Late events: *allowed lateness* (okno otwarte dłużej, retraction) lub *side output* (osobny strumień).]
]

#slide(title: [Gwarancje dostarczenia — semantyka przetwarzania])[
  #defblock[Trzy poziomy gwarancji][
    - *At-most-once*: zdarzenie przetwarzane 0 lub 1 raz. Utrata danych możliwa. Najszybsze.
    - *At-least-once*: zdarzenie przetwarzane 1+ razy. Duplikaty możliwe. Wymaga idempotencji konsumenta.
    - *Exactly-once*: zdarzenie przetwarzane dokładnie 1 raz. Najdroższe. Wymaga koordynacji.
  ]

  #alertblock[Exactly-once nie istnieje „za darmo"][
    Checkpointing, atomowy commit offsetu i 2-Phase Commit. Koszt: większe opóźnienie.
  ]

  #defblock[Pragmatyczna rekomendacja][
    *At-least-once + idempotentne odbiorniki* = najczęstszy wybór.
  ]
]

#slide(title: [Stan w przetwarzaniu strumieniowym])[
  #defblock[Problem: operacje stanowe (aggregation, join, deduplication)][
    Streaming to nie tylko `map/filter`. Agregacja wymaga *pamiętania* dotychczasowych wyników. JOIN dwóch strumieni wymaga *buforowania* jednego w oczekiwaniu na drugi.
  ]

  #cols[
    *Wzorzec: Local State + Checkpoint*
    - Stan lokalny
    - Zapis do storage
    - Awaria → odtworzenie + replay
  ][
    *Konsekwencje architektoniczne:*
    - Stan rośnie → potrzebne TTL / eviction
    - Rebalancing = migracja stanu
  ]

  #alertblock[Stan to ukryta baza danych][
    Stan streamingu traktuj jak bazę danych.
  ]
]

#slide(title: [Narzędzia streamingowe — przegląd])[
  #align(center)[
    #sm[#table(
      columns: 4,
      align: (left, left, left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Narzędzie],
        text(fill: white, weight: "bold")[Model deploymentu],
        text(fill: white, weight: "bold")[Silna strona],
        text(fill: white, weight: "bold")[Ograniczenie],
      ),
      [*Kafka Streams*],  [Biblioteka],  [Niskie opóźn.],  [Kafka],
      [*Apache Flink*],   [Klaster],     [Stan],           [Złożoność],
      [*Spark Streaming*],[Micro-batch],  [Batch + stream], [Sekundy],
    )]
  ]

]

// ── Kafka jako szkielet ──────────────────────────────────────

#title-slide[Kafka jako centralny szkielet danych]

#slide(title: [Wzorzec: Log jako źródło prawdy])[
  #exblock[Z wykładu 3: Kafka = rozproszony log zdarzeń][
    Teraz Kafka jako *centralny szkielet danych* — nie tylko transport, ale fundament architektury.
  ]

  #defblock[Immutable append-only log — fundamentalne właściwości][
    - *Niezmienność*: zdarzenie zapisane nigdy nie jest modyfikowane (append-only)
    - *Uporządkowanie*: zdarzenia w partycji mają gwarantowaną kolejność
    - *Replay*: konsument cofa offset do dowolnego punktu → przetworzenie historii od nowa
    - *Wielokrotna konsumpcja*: wiele konsumentów czyta te same dane niezależnie
  ]

  Architektonicznie Kafka jako szkielet oznacza:
  - Każdy serwis *produkuje* zdarzenia do centralnego logu
  - Nowy serwis? Podłącz się do istniejących topiców — dane już tam są
  - *Decoupling w czasie*: producent i konsument nie muszą działać jednocześnie
  - *Jedno źródło prawdy* dla przepływu danych między systemami
]

#slide(title: [Kafka Connect — wzorzec integracji])[
  #defblock[Wzorzec: Source/Sink Connector][
    Standaryzowany interfejs integracji z logiem centralnym.
  ]

  Dlaczego connector framework: konfiguracja zamiast kodu, restart i tracking offsetów, gotowe konektory.

  #exblock[Typowe pipeline'y][
    - CDC → Kafka → Elasticsearch
    - CDC → Kafka → S3
    - CDC → Kafka → ClickHouse/Pinot
  ]

]

// ── Lambda vs Kappa ──────────────────────────────────────────

#title-slide[Lambda vs Kappa Architecture]

#slide(title: [Lambda Architecture (Nathan Marz, ~2011)])[
  #defblock[Trzy warstwy Lambda][+ *Batch* — historia. + *Speed* — świeże dane. + *Serving* — scala wyniki.]

  #cols[*Dlaczego:* stream dawał świeżość, batch dokładność.][*Problem:* dwie bazy kodu muszą dawać identyczne wyniki.]
]

#slide(title: [Kappa Architecture (Jay Kreps, 2014)])[
  #defblock[Jeden pipeline zamiast dwóch][
    Jeden pipeline streamingowy przetwarza *wszystkie* dane — bieżące i historyczne. Reprzetworzenie = replay logu od początku.
  ]

  Wymagania:
  + *Długa retencja logu* — dni/miesiące, nie godziny (cały dataset w logu)
  + *Immutable events* — append-only, nigdy nie mutujemy przeszłości
  + *Determinizm* — ten sam input → ten sam output przy replay
  + *Logika wyrażalna inkrementalnie* — rolling aggregations, counters, session windows

  #alertblock[Kiedy Kappa nie wystarczy][
    - ML training z wieloma epokami
    - Globalne agregacje
    - Batch różny od streaming
  ]

]

#slide(title: [Lambda vs Kappa — decyzja architektoniczna])[
  #align(center)[
    #sm[#table(
      columns: 3,
      align: (left, center, center),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Aspekt],
        text(fill: white, weight: "bold")[Lambda],
        text(fill: white, weight: "bold")[Kappa],
      ),
      [Duplikacja], [Tak], [Nie],
      [Historia], [Batch], [Replay],
      [Złożoność], [Wysoka], [Średnia],
      [Logika], [Opcj.], [Wymagana],
    )]
  ]
]

// ── CDC w praktyce ───────────────────────────────────────────

#title-slide[Change Data Capture — w praktyce]

#slide(title: [CDC — przypomnienie i rozwinięcie pipeline'owe])[
  #exblock[Z wykładu 5 i 7][
    CDC jako element *pipeline'u danych*.
  ]

  #defblock[Wzorzec: Log-based Change Propagation][Czytaj *log transakcji* i publikuj zdarzenia. Konsumenci budują projekcje.]

  Zastosowania pipeline'owe:
  - *Materialized views* — CDC → streaming processor → OLAP (dashboard real-time)
  - *Search index sync* — CDC → search engine (pełnotekstowe wyszukiwanie)
  - *Cache invalidation* — CDC → usunięcie/aktualizacja w cache
  - *Data lake ingestion* — CDC → object storage (Parquet/Avro) → analytics
  - *Cross-region replication* — CDC → inna region (disaster recovery)
]

#slide(title: [CDC — architektura i tryby])[
  #defblock[Trzy modele wdrożenia CDC][
    + *Connector* (Kafka Connect)
    + *Standalone server*
    + *Embedded engine*
  ]

  #defblock[Outbox Pattern + CDC (dobra praktyka)][
    Outbox daje atomowość jednej transakcji DB. CDC czyta `outbox` z logu transakcji i publikuje natychmiast.
  ]

  #defblock[Porównanie][Dual writes: brak atomowości. Polling: sekundy i duże obciążenie. CDC: atomowość i szybkie.]
]

// ── Real-time Analytics ──────────────────────────────────────

#title-slide[Analityka czasu rzeczywistego]

#slide(title: [Wzorce OLAP real-time])[
  #defblock[Dlaczego zwykła baza relacyjna nie wystarczy?][
    Analityka = agregacje na milionach/miliardach wierszy. Tradycyjna baza (PostgreSQL) zoptymalizowana pod OLTP (pojedyncze wiersze). OLAP wymaga innej architektury.
  ]

  #defblock[1. Magazyn kolumnowy (columnar storage)][Dane kolumnami.]

  #defblock[2. Wstępna agregacja (pre-aggregation)][Skraca zapytania kosztem elastyczności.]

  #defblock[3. Partycjonowanie czasowe][Dane podzielone na segmenty po czasie.]
]

#slide(title: [Wzorce OLAP real-time (cd.)])[
  #defblock[4. Indeks odwrócony + indeks bitmapowy][
    - *Indeks odwrócony*: lista wierszy
    - *Indeks bitmapowy*: bit per wiersz
  ]

  #defblock[5. Rozdzielenie ścieżki zapisu i odczytu][*Zapis*: szybkie ładowanie. *Odczyt*: szybkie zapytania.]

]

#slide(title: [Kiedy który model analityczny?])[
  #align(center)[
    #sm[#table(
      columns: 3,
      align: (left, left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Konsument],
        text(fill: white, weight: "bold")[Potrzeba],
        text(fill: white, weight: "bold")[Model],
      ),
      [Analityk biznesowy], [Ad-hoc SQL, pełna historia], [Data warehouse (BigQuery, Redshift)],
      [Dashboard / BI],     [Predefiniowane metryki, niskie opóźnienie], [Real-time OLAP (ClickHouse, Druid)],
      [Użytkownik końcowy], [Wynik w #sym.lt 100 ms], [Pre-agregacja + cache],
      [Data scientist],     [Pełny skan, ML], [Data lake (Parquet, Iceberg)],
    )]
  ]

  #alertblock[Nie ma jednego silnika na wszystko][
    Real-time OLAP to *kompromis*: elastyczność, opóźnienie i koszt ładowania danych. Jeden system nie obsłuży wszystkiego.
  ]
]

// ── ETL vs ELT ───────────────────────────────────────────────

#title-slide[ETL vs ELT]

#slide(title: [Dwa paradygmaty przetwarzania danych])[
  #cols[
    #defblock[ETL (Extract, Transform, Load)][
      + Wyciągnij dane ze źródeł
      + *Przekształć* na oddzielnym silniku
      + Załaduj do warehouse

      Era on-premise: compute drogi, storage drogi, SQL wolny na dużą skalę.
    ]
  ][
    #defblock[ELT (Extract, Load, Transform)][
      + Wyciągnij dane ze źródeł
      + Załaduj *surowe* do warehouse
      + *Przekształć* wewnątrz warehouse (SQL)

      Era cloud: compute elastyczny, storage tani, SQL = najlepsza transformacja.
    ]
  ]

  #defblock[Dlaczego ELT wygrało w chmurze][*Compute* tani, *storage* tani, *SQL* jako transformacja.]
]

#slide(title: [Kiedy ETL nadal wygrywa])[
  #alertblock[ETL nie jest martwy][*PII / compliance*, *Złożone transformacje non-SQL*, *Ekstremalny wolumen*, *Integracje operacyjne*.]

  #defblock[Kluczowe pytanie architektoniczne][
    *Gdzie* następuje transformacja? Odpowiedź zależy od: kto jest konsumentem, jakie są wymagania compliance, jaki jest wolumen, ile kosztuje compute.
  ]
]

// ── Cloud ────────────────────────────────────────────────────

#title-slide[#emoji.cloud Managed Streaming i OLAP]

#slide(title: [#emoji.cloud Przegląd usług chmurowych])[
  #align(center)[
    #sm[#table(
      columns: 4,
      align: (left, left, left, left),
      stroke: 0.5pt + ibm-gray-30,
      fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
      table.header(
        text(fill: white, weight: "bold")[Kategoria],
        text(fill: white, weight: "bold")[AWS],
        text(fill: white, weight: "bold")[GCP],
        text(fill: white, weight: "bold")[Azure],
      ),
      [*Streaming*],    [Kinesis],    [Pub/Sub],   [Event Hubs],
      [*Kafka*],        [MSK],        [—],         [Event Hubs],
      [*Processing*],   [Kinesis A.], [Dataflow],  [Stream Analytics],
      [*Warehouse*],    [Redshift],   [BigQuery],  [Synapse],
      [*ETL*],          [Glue],       [Dataflow],  [Data Factory],
      [*OLAP*],         [Timestream], [BigQuery],  [ADX],
    )]
  ]

]

// ── Case study ───────────────────────────────────────────────

#title-slide[Case study: News Feed System]

#slide(title: [Design a News Feed (A. Xu, rozdz. 11)])[
  #defblock[Problem][10M DAU, 500M postów/dzień. Wymaganie: szybki feed i aktualizacje.]

  #cols[
    #alertblock[Fan-out on Write (Push)][Post → cache per user. Odczyt szybki, zapis drogi.]
  ][
    #alertblock[Fan-out on Read (Pull)][Request → merge przy odczycie. Zapis tani, odczyt drogi.]
  ]
]

#slide(title: [Wzorzec: Hybrid Fan-out])[
  #defblock[Routing na podstawie asymetrii grafu społecznego][
    Sieci społeczne są *asymetryczne* — 99% autorów ma #sym.lt 10K followersów, ale 1% generuje większość wzmocnienia zapisu.
  ]

  Rozwiązanie: *routing progowy* — poniżej progu Push, powyżej Pull.

  #defblock[Przykłady][Twitter/X i Facebook: hybrid. LinkedIn: fan-out on read.]

]

#slide(title: [News Feed — wzorce danych])[
  #defblock[ID-only cache — oszczędność pamięci][W cache: ID + score. Pełne obiekty pobierane dopiero przy renderowaniu.]

  #defblock[Pipeline za News Feed][
    - *Write path* (streaming): nowy post → fan-out → zapis ID do cache followersów
    - *Read path* (batch/on-demand): pobranie pełnych obiektów, ranking, hydration
    - *Sync* (CDC): zmiany w profilu/poście propagowane do cache i indeksów
  ]
]

// ── Dyskusja ─────────────────────────────────────────────────

#focus-slide[
  Wasz system e-commerce generuje 50M zdarzeń zamówień dziennie.

  Analitycy chcą: dashboardy real-time (ostatnie 5 min) + raporty dzienne (pełna historia).

  *Lambda czy Kappa?* Uzasadnijcie.

  Jakie *wzorce* (nie narzędzia!) wybierzecie dla każdej warstwy?

  Bonus: skąd dane trafią do analityki — polling, dual writes, czy CDC? Dlaczego?
]

// ── Podsumowanie ─────────────────────────────────────────────

#title-slide[Podsumowanie]

#slide(title: [Kluczowe wnioski])[

  + *Batch*: partycjonuj pracę, odporność przez lineage, optymalizuj DAG
  + *Streaming*: event-time #sym.eq.not processing-time → watermarki i okna
  + *Kafka*: immutable log umożliwia replay, decoupling i wielokrotną konsumpcję
  + *Kappa vs Lambda*: jeden pipeline upraszcza, ale nie zawsze wystarczy
  + *CDC*: log transakcji → zdarzenia, bez dual writes
  + *OLAP*: kolumny, pre-agregacja, rozdzielenie zapisu i odczytu
]

#slide(title: [Źródła i lektury])[

  - M. Kleppmann — _DDIA_, rozdz. 10 (batch), 11 (stream)
  - J. Dean, S. Ghemawat — „MapReduce: Simplified Data Processing on Large Clusters" (OSDI 2004)
  - M. Zaharia et al. — „Resilient Distributed Datasets" (NSDI 2012)
  - T. Akidau — „The world beyond batch: Streaming 101" (O'Reilly, 2015)
  - J. Kreps — „Questioning the Lambda Architecture" (O'Reilly Radar, 2014)
  - J. Kreps — „I Heart Logs" (O'Reilly, 2014)
  - N. Marz, J. Warren — _Big Data_ (Manning, 2015)
  - A. Xu — _System Design Interview_, rozdz. 11 (News Feed)
  - LinkedIn Engineering — „FollowFeed" (2024)
  - Debezium Documentation — debezium.io
]

#slide(title: [Następny wykład])[

  #defblock[Wykład 9: Serverless, FaaS i architektura na brzegu][
    Serverless jako model · FaaS vs kontenery · Edge Computing · Koszty · WebAssembly
  ]
]

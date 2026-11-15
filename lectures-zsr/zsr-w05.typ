#import "@preview/typslides:1.3.2": *
#import "zsr-theme.typ": *
#import emoji: cloud

#show: typslides.with(
  ratio: "16-9", theme: kolor-pp, font: "DejaVu Sans", font-size: 20pt,
  show-progress: true, show-page-numbers: true,
)
#set text(lang: "pl")

#front-slide(
  title: "Obserwowalność",
  subtitle: [Diagnoza na podstawie metryk, logów i śladów],
  authors: "mgr inż. Jakub Woźniak",
  info: [Zarządzanie Systemami Rozproszonymi · Semestr zimowy 2026/27],
)

#slide(title: [Objaw: wolne przyjmowanie zamówień])[
  #data-table(3,
    [Pomiar], [09:55], [10:05],
    [Żądania API / s], [100], [100],
    [Błędy API], [0,1%], [0,1%],
    [p95 czasu API], [180 ms], [2400 ms],
    [CPU API], [35%], [38%],
    [Repliki API], [10], [10],
  )

  #alertblock[Pytanie diagnostyczne][
    Ruch i liczba błędów się nie zmieniły, a czas odpowiedzi wzrósł ponad
    dziesięciokrotnie. Czy niski CPU i brak błędów 5xx oznaczają, że usługa
    działa poprawnie?
  ]

  - Jakiego pomiaru brakuje, aby odróżnić pracę procesora od oczekiwania?

  #src[Kontynuacja wykładu 4: znamy sondy, limity i skalowanie. Teraz pytamy,
  skąd wiemy, co dzieje się w usłudze.]
]

#slide(title: [Plan wykładu])[
  - Od monitoringu do obserwowalności: pytanie „czy działa?” i „dlaczego tak działa?”.
  - Trzy sygnały i reguła wyboru między nimi.
  - OpenTelemetry: po co powstał wspólny standard.
  - Prometheus: zbieranie, typy metryk i zapytania.
  - p95 z histogramu oraz koszt etykiety.
  - Ślad i log tej samej operacji.
  - #cloud Collector, backend zarządzany, retencja i próbkowanie.
  - Diagnoza przypadku: co zmieniło się o 10:00?
]

#slide(title: [Monitoring a obserwowalność])[
  #data-table(3,
    [Pytanie], [Monitoring], [Obserwowalność],
    [Treść], [Czy system działa?], [Dlaczego działa właśnie tak?],
    [Zakres], [Znane wcześniej warunki], [Także sytuacje nieprzewidziane],
    [Sposób], [Próg i alert], [Badanie przez zapytania do telemetrii],
  )

  #defblock[Definicja][
    Obserwowalność to zdolność do wnioskowania o stanie wewnętrznym systemu
    na podstawie jego zewnętrznej telemetrii.
  ]

  - Alert pozostaje potrzebny. Obserwowalność odpowiada na pytanie zadane
    *po* alercie, gdy przyczyna nie jest znana.

  #src[#link("https://opentelemetry.io/docs/concepts/observability-primer/")[OpenTelemetry — Observability primer]]
]

#slide(title: [Trzy sygnały i ich zadania])[
  #data-table(3,
    [Sygnał], [Jednostka], [Zadanie w diagnozie],
    [Metryka], [Szereg czasowy], [Zawęzić okres i usługę],
    [Ślad], [Spany jednej operacji], [Wskazać wolny etap na ścieżce],
    [Log], [Zdarzenie z kontekstem], [Wyjaśnić szczegół zdarzenia],
  )

  #flow[Metryka zawęża][Ślad lokalizuje][Log wyjaśnia]

  - Reguła wyboru: zaczynamy od metryki, bo jest agregowalna i tania.
  - Metryka mówi *gdzie* i *kiedy*, nie mówi *dlaczego*.
  - Bez wspólnego identyfikatora ślad i log opisują dwa różne zdarzenia.

  #src[#link("https://opentelemetry.io/docs/concepts/signals/")[OpenTelemetry — Signals]]
]

#slide(title: [OpenTelemetry: po co wspólny standard])[
  #data-table(2,
    [Przed], [Po],
    [Agent każdego producenta ma własny format i API], [Jeden standard instrumentacji],
    [Zmiana dostawcy wymaga ponownej instrumentacji], [Zmiana backendu nie rusza kodu],
    [Dwa konkurencyjne projekty: OpenTracing i OpenCensus], [Od 2019 jeden projekt w CNCF],
  )

  - OTel opisuje generowanie, eksport i zbieranie telemetrii: API, SDK,
    specyfikację i Collector. Nie jest backendem — przechowywanie danych
    i wizualizacja zostają poza nim.
  - Dwie zasady: dane pozostają Twoje, a uczysz się jednego zestawu API.
  - Neutralność obejmuje instrumentację i zbieranie, nie backend: zapytania,
    dashboardy i alerty nadal wiążą się z wybranym narzędziem.

  #src[#link("https://opentelemetry.io/docs/what-is-opentelemetry/")[OpenTelemetry — What is OpenTelemetry?] · #link("https://www.cncf.io/blog/2019/05/21/a-brief-history-of-opentelemetry-so-far/")[CNCF — A brief history]]
]

#slide(title: [Prometheus: zbieranie i odczyt])[
  #flow[Aplikacja /metrics][Prometheus: scrape + TSDB][PromQL][Grafana]
  #flow[Reguła alertu][Alertmanager][Dyżurny]

  - Model pull: Prometheus okresowo odpyta endpointy metryk.
  - Brak odpowiedzi na scrape nie znaczy, że metryka wynosi zero —
    to brak danych i inny alert.
  - Grafana prezentuje wynik zapytania; nie zastępuje instrumentacji.

  #src[#link("https://prometheus.io/docs/introduction/overview/")[Prometheus — Overview]]
]

#slide(title: [Counter, gauge, histogram])[
  #codebox[
```text
orders_completed_total{result="ok"} 12340
queue_oldest_age_seconds{queue="orders"} 42
http_request_duration_seconds_bucket{le="0.5"} 950
http_request_duration_seconds_bucket{le="1"} 990
http_request_duration_seconds_bucket{le="+Inf"} 1000
```
  ]

  - Counter: rośnie monotonicznie; po restarcie procesu zaczyna od zera.
  - Gauge: bieżący stan; może rosnąć i maleć.
  - Histogram klasyczny: kumulatywne liczniki przedziałów; przedział `+Inf`
    obejmuje całość.
  - Wynik `950` przy `le="0.5"` oznacza 950 żądań *nie dłuższych* niż 0,5 s.
  - Natywne histogramy są już stabilne, ale wymagają jawnego włączenia
    i ekspozycji w formacie protobuf; klasyczny bywa ścieżką domyślną.

  #src[#link("https://prometheus.io/docs/concepts/metric_types/")[Prometheus — Metric types] · #link("https://prometheus.io/docs/practices/histograms/")[Histograms and summaries]]
]

#slide(title: [PromQL: tempo i udział błędów])[
  #codebox[
```promql
sum(rate(http_requests_total{job="orders-api"}[5m]))

sum(rate(http_requests_total{job="orders-api", code=~"5.."}[5m]))
/
sum(rate(http_requests_total{job="orders-api"}[5m]))
```
  ]

  - `rate` liczy tempo na sekundę i sam obsługuje reset countera.
  - Kolejność ma znaczenie: najpierw `rate` na każdym szeregu, potem suma.
  - Odwrotna kolejność (`rate` po `sum`) gubi resety pojedynczych instancji.
  - Udział błędów przy braku ruchu jest nieokreślony, nie równy zeru.

  #src[#link("https://prometheus.io/docs/prometheus/latest/querying/functions/#rate")[Prometheus — rate()]]
]

#slide(title: [p95 z histogramu wielu instancji])[
  #codebox[
```promql
histogram_quantile(
  0.95,
  sum by (le) (
    rate(http_request_duration_seconds_bucket{job="orders-api"}[5m])
  )
)
```
  ]

  - Sumujemy liczniki przedziałów, zachowując granicę `le` jako wymiar.
  - Dopiero na sumie liczymy kwantyl — to daje rozkład całej usługi.
  - Wynik jest przybliżony: histogram z granicami 0,2 i 0,3 s przy rzeczywistym
    p95 = 220 ms zwraca około 295 ms. To interpolacja w przedziale, nie błąd zapytania.
  - Średnia z p95 dziesięciu instancji nie jest p95 usługi.

  #src[#link("https://prometheus.io/docs/practices/histograms/")[Prometheus — Histograms and summaries]]
]

#slide(title: [Koszt jednej etykiety])[
  #defblock[Przykład dydaktyczny][
    Trasa × kod odpowiedzi × instancja: 10 × 5 × 20 = do 1000 kombinacji
    etykiet dla jednej metryki. Histogram mnoży tę liczbę przez liczbę
    przedziałów.
  ]

  - Gdyby doszedł `user_id` o 100 000 wartości, granica rośnie do 100 mln
    kombinacji — niezależnie od tego, czy wszystkie wystąpią.
  - Każda nowa kombinacja to nowy szereg: pamięć, zapis i czas zapytania.
  - Reguła: identyfikator (zamówienie, użytkownik, `trace_id`) należy do
    logu lub śladu, nigdy do etykiety metryki.
  - Etykiety opisują wymiar, po którym chcemy agregować, nie konkretny obiekt.

  #src[#link("https://prometheus.io/docs/practices/naming/")[Prometheus — Naming and labels]]
]

#slide(title: [Ślad: praca i oczekiwanie])[
  #text(size: 17pt)[
    #grid(columns: (165pt, 1fr), row-gutter: 12pt,
      [API: 2400 ms], [#rect(width: 100%, height: 18pt, fill: kolor-pp)],
      [Pool DB: 2100 ms], [#grid(columns: (12.5%, 87.5%), [], rect(width: 100%, height: 18pt, fill: orange-pp))],
      [SQL: 90 ms], [#grid(columns: (87.5%, 3.75%, 8.75%), [], rect(width: 100%, height: 18pt, fill: dark-green), [])],
    )
  ]

  #sm[Oś: 0–2400 ms. Przykład jednego wolnego żądania; pozostały czas to inne etapy API.]

  - Span oczekiwania na połączenie z bazą dominuje nad wykonaniem SQL, więc
    wąskim gardłem nie jest samo zapytanie — i dlatego CPU pozostaje niski.
  - Exemplar przy przedziale histogramu niesie `trace_id` konkretnego żądania:
    tak przechodzimy od skoku metryki do właściwego śladu.
  - Przy kolejce kontekst trzeba przenieść w wiadomości; dla operacji
    asynchronicznej używamy relacji `links`, nie rodzica i dziecka.

  #src[#link("https://opentelemetry.io/docs/concepts/signals/traces/")[OpenTelemetry — Traces] · #link("https://opentelemetry.io/docs/concepts/context-propagation/")[Context propagation] · #link("https://prometheus.io/docs/specs/om/open_metrics_spec/")[OpenMetrics — Exemplars]]
]

#slide(title: [Log powiązany ze śladem])[
  #codebox[
```json
{
  "time": "10:05:12.210",
  "service": "orders-api", "version": "v2",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "event": "db_pool_wait", "wait_ms": 2100,
  "pool_max": 5, "pool_in_use": 5
}
```
  ]

  - Metryka podała skalę zjawiska, ślad wskazał miejsce, log ujawnił
    konfigurację puli.
  - `trace_id` jest tym samym identyfikatorem, który widzieliśmy w śladzie.
  - W logu nie umieszczamy tokenów, haseł ani pełnych danych zamówienia.

  #src[Log syntetyczny. Nazwy pól są aplikacyjne, nie pochodzą z biblioteki.]
]

#slide(title: [#cloud Collector i backend zarządzany])[
  #flow[SDK OTel][Collector][Backend telemetrii]

  - Collector odbiera dane, przetwarza je, dzieli na paczki i eksportuje;
    obsługuje też kolejki i limity przy przeciążeniu.
  - Backend zarządzany, np. Azure Monitor, przechowuje dane i udostępnia
    zapytania według własnego modelu.
  - Redakcja danych wrażliwych odbywa się przed eksportem, po stronie
    Collectora.
  - Awaria backendu telemetrii nie może blokować przyjmowania zamówień:
    eksport jest poza ścieżką krytyczną żądania.

  #src[#link("https://opentelemetry.io/docs/collector/")[OpenTelemetry — Collector]]
]

#slide(title: [#cloud Retencja i próbkowanie])[
  #data-table(3,
    [Decyzja], [Zysk], [Ograniczenie],
    [Krótsza retencja logów], [Mniej przechowywanych danych], [Krótsza historia dostępna w diagnozie],
    [Próbkowanie śladów], [Mniejszy eksport i koszt], [Rzadka awaria może nie wejść do próbki],
    [Agregacja metryk], [Mniej szeregów], [Utrata części wymiarów],
  )

  - Dobrze dobrana próbka bywa reprezentatywna: przy dużym ruchu nawet 1%
    potrafi opisać pozostałe 99%.
  - Reprezentatywność zależy od sposobu próbkowania. Rzadkie błędy mogą
    wypaść z próbki, dlatego próbkuje się je inną regułą niż ruch poprawny.
  - Retencja jest kompromisem, nie ustawieniem domyślnym.

  #src[#link("https://opentelemetry.io/docs/concepts/sampling/")[OpenTelemetry — Sampling]]
]

#slide(title: [Przypadek: co zmieniło się o 10:00?])[
  #codebox[
```diff
# Zmiana konfiguracji orders-api o 10:00
- DB_POOL_MAX: "20"
+ DB_POOL_MAX: "5"

# W tym samym okresie
DB active connections: 50 / limit 200
DB CPU: 25%
API replicas: 10; traffic: bez zmiany
```
  ]

  #alertblock[Zadanie][
    Połącz diff, ślad i log w jedną hipotezę. Podaj pomiar, który ją
    potwierdzi, oraz jedną konkurencyjną hipotezę i sposób jej odrzucenia.
  ]
]

#slide(title: [Kluczowe wnioski])[
  - Trzy sygnały odpowiadają na różne pytania: metryka zawęża, ślad
    lokalizuje, log wyjaśnia. Diagnoza łączy wszystkie trzy.
  - Percentyl usługi liczymy z połączonego rozkładu, a identyfikatory
    trafiają do logów i śladów, nie do etykiet metryk.
  - #cloud Backend zarządzany przechowuje i przeszukuje telemetrię, ale
    decyzja, co mierzyć i jak długo trzymać, pozostaje po naszej stronie.

  #alertblock[Pytanie sprawdzające][
    p95 wzrosło z 180 ms do 2400 ms, a ślad pokazuje 2100 ms oczekiwania
    na połączenie i 90 ms wykonania SQL. Której metryki szukasz najpierw
    i dlaczego nie jest nią czas wykonania zapytania?
  ]
]

#slide(title: [Źródła i lektury])[
  #text(size: 16pt)[
    - #link("https://opentelemetry.io/docs/what-is-opentelemetry/")[OpenTelemetry — What is OpenTelemetry?]
    - #link("https://opentelemetry.io/docs/concepts/observability-primer/")[OpenTelemetry — Observability primer]
    - #link("https://opentelemetry.io/docs/concepts/signals/")[OpenTelemetry — Signals]
    - #link("https://opentelemetry.io/docs/concepts/context-propagation/")[OpenTelemetry — Context propagation]
    - #link("https://opentelemetry.io/docs/concepts/signals/traces/")[OpenTelemetry — Traces]
    - #link("https://opentelemetry.io/docs/collector/")[OpenTelemetry — Collector]
    - #link("https://opentelemetry.io/docs/concepts/sampling/")[OpenTelemetry — Sampling]
    - #link("https://www.cncf.io/blog/2019/05/21/a-brief-history-of-opentelemetry-so-far/")[CNCF — A brief history of OpenTelemetry]
    - #link("https://prometheus.io/docs/introduction/overview/")[Prometheus — Overview]
    - #link("https://prometheus.io/docs/concepts/metric_types/")[Prometheus — Metric types]
    - #link("https://prometheus.io/docs/practices/histograms/")[Prometheus — Histograms and summaries]
    - #link("https://prometheus.io/docs/practices/naming/")[Prometheus — Naming and labels]
    - #link("https://prometheus.io/docs/specs/om/open_metrics_spec/")[OpenMetrics — Specification]
    - #link("https://learn.microsoft.com/en-us/azure/azure-monitor/overview")[Microsoft — Azure Monitor overview]
  ]
  #src[Dokumentacja sprawdzona: 15.11.2026. Dane przypadków: przykłady dydaktyczne.]
]

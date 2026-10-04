#import "@preview/typslides:1.3.2": *
#import "zsr-theme.typ": *
#import emoji: cloud
#show: typslides.with(ratio: "16-9", theme: kolor-pp, font: "DejaVu Sans", font-size: 20pt, show-progress: true, show-page-numbers: true)
#set text(lang: "pl")
#front-slide(title: "Obserwowalność", subtitle: [Metryki, logi i ślady w jednej diagnozie], authors: "mgr inż. Jakub Woźniak", info: [Zarządzanie Systemami Rozproszonymi · Semestr zimowy 2026/27])
#slide(title: [Objaw: wolne przyjmowanie zamówień])[
#data-table(3,
[Pomiar],
[09:55],
[10:05],
[Żądania API / s],
[100],
[100],
[Błędy API],
[0,1%],
[0,1%],
[p95 czasu API],
[180 ms],
[2400 ms],
[CPU API],
[35%],
[38%],
)
#alertblock[Pytanie diagnostyczne][Czy niski CPU i brak 5xx oznaczają poprawne działanie? Jak oddzielić czas pracy od czasu oczekiwania?]
]
#slide(title: [Trzy rodzaje danych])[
#data-table(3,
[Sygnał],
[Jednostka],
[Zastosowanie],
[Metryka],
[Szereg czasowy],
[Trend, agregacja, alert],
[Log],
[Zdarzenie z kontekstem],
[Szczegół błędu i identyfikator],
[Trace],
[Spany powiązanej operacji],
[Czas i zależności na ścieżce],
)
- Metryka zawęża okres i usługę; trace wskazuje wolny etap; log opisuje zdarzenie.
#src[#link("https://opentelemetry.io/docs/concepts/signals/")[OpenTelemetry — Signals]]
]
#slide(title: [Prometheus: zbieranie i odczyt])[
#flow[Aplikacja /metrics][Prometheus: scrape + TSDB][PromQL][Grafana]
#flow[Reguła alertu][Alertmanager][Dyżurny]
- Pull: Prometheus okresowo odpytuje endpointy metryk.
- Scrape niedostępny ≠ wartość metryki równa zero.
- Grafana prezentuje wyniki zapytań; nie zastępuje instrumentacji.
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
- Counter: rośnie; może się wyzerować po restarcie.
- Gauge: bieżący stan, może rosnąć i maleć.
- Histogram klasyczny: kumulatywne liczniki przedziałów.
#src[#link("https://prometheus.io/docs/concepts/metric_types/")[Prometheus — Metric types]]
]
#slide(title: [PromQL: tempo i udział błędów])[
#codebox[
```promql
sum(rate(http_requests_total{job="api"}[5m]))

sum(rate(http_requests_total{job="api",code=~"5.."}[5m]))
/
sum(rate(http_requests_total{job="api"}[5m]))
```
]
- `rate`: tempo na sekundę, z obsługą resetu countera.
- Najpierw rate na szeregu, potem suma po instancjach.
- Okno 5 min wygładza; udział błędów bez ruchu wymaga osobnej interpretacji.
#src[#link("https://prometheus.io/docs/prometheus/latest/querying/functions/#rate")[Prometheus — rate()]]
]
#slide(title: [p95 z histogramu wielu instancji])[
#codebox[
```promql
histogram_quantile(
  0.95,
  sum by (le) (
    rate(http_request_duration_seconds_bucket{job="api"}[5m])
  )
)
```
]
- Sumujemy bucket counters; zachowujemy granicę `le`.
- Wynik przybliżony: dokładność zależy od granic przedziałów.
- Średnia z p95 instancji nie daje p95 całej usługi.
#src[#link("https://prometheus.io/docs/practices/histograms/")[Prometheus — Histograms and summaries]]
]
#slide(title: [Kardynalność: koszt jednego labela])[
#defblock[Przykład dydaktyczny][10 tras × 5 kodów odpowiedzi × 20 instancji = do 1000 kombinacji etykiet jednej metryki.]
- Dodatkowo `user_id` o 100 000 wartościach: do 100 mln kombinacji.
- Rzeczywista liczba zależy od występujących kombinacji; histogram mnoży serie przez buckety.
- Identyfikator zamówienia: log lub trace zamiast labela metryki.
#src[#link("https://prometheus.io/docs/practices/naming/")[Prometheus — Naming and labels]]
]
#slide(title: [Trace: czas pracy i oczekiwania])[
#text(size: 17pt)[
#grid(columns: (180pt, 1fr), row-gutter: 12pt,
[API — 2400 ms], [#rect(width: 100%, height: 18pt, fill: kolor-pp)],
[Pool DB — 2100 ms], [#rect(width: 87.5%, height: 18pt, fill: orange-pp)],
[SQL — 90 ms], [#grid(columns: (87.5%, 3.75%, 8.75%), [], rect(width: 100%, height: 18pt, fill: dark-green), [])],
)
]
#sm[Oś: 0–2400 ms; przykład jednego wolnego żądania. Pozostały czas: inne etapy API.]
- Span oczekiwania na połączenie DB dominuje nad wykonaniem SQL.
- W kolejce kontekst wymaga przeniesienia w wiadomości; możliwe relacje links.
#src[#link("https://opentelemetry.io/docs/concepts/signals/traces/")[OpenTelemetry — Traces]]
]
#slide(title: [Log powiązany ze śladem])[
#codebox[
```json
{
  "time": "10:05:12.210",
  "service": "orders-api", "version": "v2",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "event": "db_pool_wait",
  "wait_ms": 2100, "pool_max": 5, "pool_in_use": 5
}
```
]
- Metryka: skala zjawiska. Trace: miejsce oczekiwania. Log: konfiguracja puli.
- Bez tokenów, haseł i pełnych danych zamówienia w logu.
#src[Log syntetyczny; nazwy pól aplikacyjne.]
]
#slide(title: [#cloud Collector i backend zarządzany])[
#flow[SDK OTel][Collector][Backend telemetrii]
- Collector: odbiór, przetwarzanie, batching i eksport; także kolejki i limity.
- Backend, np. Azure Monitor: przechowywanie i zapytania według jego modelu.
- Redakcja danych przed eksportem; awaria backendu nie powinna blokować zamówień.
#src[#link("https://opentelemetry.io/docs/collector/")[OpenTelemetry — Collector]]
]
#slide(title: [#cloud Retencja i próbkowanie])[
#data-table(3,
[Decyzja],
[Zysk],
[Ograniczenie],
[Krótsza retencja logów],
[Mniej przechowywanych danych],
[Mniej historii diagnozy],
[Sampling śladów],
[Mniej eksportu],
[Możliwe pominięcie rzadkiej awarii],
[Agregacja metryk],
[Mniej serii],
[Utrata części wymiarów],
)
- SLI i rachunek błędów opierać na odpowiednim pełnym pomiarze.
- Próbka trace pomaga diagnozować; nie daje automatycznie bezstronnej statystyki.
]
#slide(title: [Przypadek: co zmieniło się o 10:00?])[
#codebox[
```diff
# Zmiana konfiguracji orders-api
- DB_POOL_MAX: "20"
+ DB_POOL_MAX: "5"

# W tym samym okresie
DB active connections: 50 / limit 200
DB CPU: 25%
API replicas: 10; traffic: bez zmiany
```
]
#alertblock[Decyzja][Połącz diff, trace i log. Zaproponuj zmianę, pomiar potwierdzający i jedną alternatywną hipotezę.]
]
#slide(title: [Źródła i lektury])[
#text(size: 16pt)[
- #link("https://prometheus.io/docs/introduction/overview/")[Prometheus — Overview]
- #link("https://prometheus.io/docs/prometheus/latest/querying/functions/")[Prometheus — Query functions]
- #link("https://prometheus.io/docs/practices/histograms/")[Prometheus — Histograms]
- #link("https://prometheus.io/docs/practices/naming/")[Prometheus — Naming]
- #link("https://opentelemetry.io/docs/concepts/signals/traces/")[OpenTelemetry — Traces]
- #link("https://opentelemetry.io/docs/collector/")[OpenTelemetry — Collector]
]
#src[Dokumentacja sprawdzona: 26.09.2026. Dane przypadków: przykłady dydaktyczne.]
]

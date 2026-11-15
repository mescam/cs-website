# Plan redakcyjny — monitoring i diagnoza w laboratorium ZSR

Dokument decyzyjny dla części o monitoringu. Powstał jako plan samodzielnego laboratorium 5, a zrealizowano go jako **część III skryptu `1-docker.typ`** (rozdział [monitoring.typ](../chapters/monitoring.typ)). Zapisuje, **co** ma być w materiale, **dlaczego** i **czym to się różni od wersji LaTeX** w `4-monitoring.tex`. Nie jest skryptem dla studentów.

Stary `4-monitoring.tex` zostaje w repozytorium jako archiwum i nadal jest publikowany jako `4-monitoring.pdf`; plik `4-monitoring.typ` nie powstał. Część III opisuje też wersje sprawdzone 15.11.2026 i błędy wykonawcze starego skryptu, które były podstawą przepisania.

## 1. Umiejscowienie w kursie

Laboratorium 5 jest pierwszym, w którym student diagnozuje działającą usługę na podstawie danych, a nie tylko sprawdza jej stan. Odpowiada wykładowi 05 „Obserwowalność: diagnoza na podstawie metryk, logów i trace”.

**Wejście (co już umieją):**

| Źródło | Co wnosi do laboratorium |
|---|---|
| Lab 1 (Docker) | `docker logs`, `docker exec`, `docker inspect`, odróżnienie procesu od kontenera |
| Lab 2 (Docker i Kubernetes) | Minikube, Deployment, Service, sondy, readiness vs liveness, ConfigMap, Secret, StatefulSet PostgreSQL, `kubectl logs/describe/exec`, HPA |
| Wykład 03–04 | rekonsyliacja, stan oczekiwany, requests/limits, throttling i OOM, HPA liczone z metryk |
| Wykład 05 | monitoring vs obserwowalność, reguła „metryka zawęża → ślad lokalizuje → log wyjaśnia”, OpenTelemetry, histogram i p95, kardynalność, przypadek `DB_POOL_MAX` |

**Wyjście (świadomie odraczamy):**

| Temat | Gdzie należy |
|---|---|
| SLO, error budget, alert wymagający działania, triage i postmortem | Wykład 11 |
| Retencja i próbkowanie jako pozycja kosztowa, FinOps | Wykład 13 |
| GitOps, wersjonowanie manifestów, rollback | Lab 6 (ArgoCD) |
| Service mesh jako źródło telemetrii | Lab 8 (Istio) — tylko wzmianka |
| Pełny stos Tempo/Loki z korelacją w Grafanie | rozszerzenie poza częścią obowiązkową |

**Zasada nadrzędna:** laboratorium uczy *diagnozy*, nie katalogu narzędzi. Każde zadanie kończy się pomiarem potwierdzającym hipotezę, a nie zrzutem ekranu dashboardu.

## 2. Kontrakt dydaktyczny

- **Czas:** jedno spotkanie 135 min, rytm jak w pozostałych laboratoriach: 0–15 przygotowanie środowiska, 15–45 ćwiczenie wspólne, 45–120 zadania, 120–135 demonstracja i zapis pracy.
- **Część obowiązkowa:** zadania A–E oraz diagnoza przypadku (F). **Rozszerzenia** dla szybszych: G (kardynalność, próbkowanie, retencja, `absent()` na wyłączonym eksporcie).
- **Konwencja skryptu:** jak w `1-docker.typ` — zadania literowe, każde z akapitem *Weryfikacja:*, na końcu „Diagnostyka problemów”, „Pytania końcowe i źródła”. Bez surowych emoji Unicode.
- **Wersje:** wszystkie obrazy i charty pinowane; brak `latest` i brak `stable`.
- **Źródła:** dokumentacja pierwotna (Prometheus, OpenTelemetry, charty) przy istotnych twierdzeniach; linki sprawdzone pod HTTP 200 przed publikacją.
- **Ciągłość nazw:** aplikacja `zsr-flask` (nowa wersja obrazu `v3`), baza `postgres` z StatefulSet z lab 2, namespace `zsr`, stos monitoringowy w namespace `monitoring`, porty aplikacji 5000 i Redmine 3000 bez zmian.

## 3. Zmiany względem wersji LaTeX (`4-monitoring.tex`)

Obecny skrypt (705 linii) jest poprawny jako wprowadzenie do narzędzi, ale uczy „obserwowalności” jako progów i dashboardów oraz zawiera błędy wykonawcze, które uniemożliwiają część ćwiczeń.

| # | Problem w wersji obecnej | Korekta w nowej wersji |
|---|---|---|
| 1 | `service/alertmanager` (:446) i `statefulset alertmanager` (:546) — chart tworzy `prometheus-alertmanager`; w kodzie zostały Twoje TODO (:439, :543) | Kube-prometheus-stack z `alertmanager.config`; nazwy zasobów konsekwentnie `<release>-alertmanager` |
| 2 | Reguły w `serverFiles.alerts.alerting_rules.yml` (:568–577) — deprecjonowany klucz `alerts`; ConfigMap `alertmanager-config` (:511–547) nigdy nie jest czytany | Reguły jako `PrometheusRule` (CRD), konfiguracja Alertmanagera przez `alertmanager.config` — chart sam tworzy Secret |
| 3 | Brak `require_tls: false` w konfiguracji SMTP → Alertmanager nie wysyła maila | Jawnie `require_tls: false` i `smtp_smarthost` na usługę Mailpit w klastrze |
| 4 | MailHog — projekt nieutrzymywany od 2020 | Mailpit (`axllent/mailpit`, pin), SMTP 1025, UI 8025 |
| 5 | node-exporter instalowany osobno (:122), choć jest domyślnym subchartem → podwójne serie i zawyżone `avg`/`sum` | Jeden stos, bez podwójnej instalacji; brak samodzielnego `helm install node-exporter` |
| 6 | `node_cpu_seconds_total{mode="idle"} < 0.2` (:582) — counter porównany z ułamkiem; ta sama reguła zrobiona poprawnie w :612 | Jedna poprawna reguła `avg(rate(...{mode!="idle"}[5m])) > 0.8` |
| 7 | Alert na `nginx_http_response_time_seconds` (:626) — metryka nie istnieje w nginx-exporterze | Histogram latencji pochodzi z aplikacji Flaska (`prometheus_client`), nie z eksportera NGINX |
| 8 | `sum(nginx_http_requests_total)` bez `rate` (:356) | `rate` przed agregacją, zgodnie z wykładem |
| 9 | Zero `histogram_quantile` — w skrypcie nie ma ani jednego histogramu, więc nie ma p95 | Zadanie C w całości o histogramie i p95, z błędem estymacji |
| 10 | „Grafana … zapewniająca obserwowalność” (:430) — sprzeczne z wykładem | Dashboard jest narzędziem odczytu; obserwowalność daje instrumentacja, alert pozostaje potrzebny |
| 11 | Sekcja PostgreSQL + postgres-exporter (:642–704) opisuje kroki bez manifestów; „czas odpowiedzi zapytań SQL” wymaga `pg_stat_statements` | Usunięta; stan bazy sprawdzamy przez metryki własnej aplikacji i `kubectl exec` do bazy z lab 2 |
| 12 | Brak pinów wersji chartów i obrazów; `polinux/stress-ng` w prozie (:131) vs `polinux/stress` w manifestach (:162) | Jedna wersja obrazu obciążenia, jeden zestaw pinów w jednym miejscu |
| 13 | Obciążenie: 3 repliki × 4 CPU i 3 × 1 GB — throttling i OOM klastra na jednym węźle | Jedna replika obciążenia z limitami i jawnym parametrem CPU |
| 14 | Ćwiczenie kończy się „zobacz maila”, bez pomiaru potwierdzającego | Każde zadanie ma *Weryfikację*; przypadek wymaga hipotezy i pomiaru, który ją rozstrzyga |

**Czego nie przenosimy:** osobnej sekcji o PostgreSQL i eksporterze bazy, instalacji `metrics-server` jako osobnego tematu (HPA było w lab 2), porównań stosów logowania, listy komponentów Prometheusa jako katalogu, treści o SLO (wykład 11) i kosztach retencji (wykład 13).

## 4. Szkielet zadań

| # | Zadanie | Min | Rola | Treść i kryterium |
|---|---|---|---|---|
| A | Stos monitoringowy z pinami | 20 | mechanizm | Helm, `kube-prometheus-stack` w wersji pinowanej, wartości ograniczające zakres; `up == 1` dla wszystkich targetów, Grafana z datasource z provisioningu, brak OOM na stanowisku |
| B | Od objawu do wąskiego zapytania | 20 | umiejętność | `up`, `absent()`, „brak danych to nie zero”; `sum(rate(http_requests_total[5m]))` i udział błędów; max 3 zapytania w części obowiązkowej; kryterium: student wskazuje, które zapytanie zawęża obszar poszukiwań |
| C | Histogram i p95 | 25 | umiejętność | Aplikacja `zsr-flask:v3` eksponuje histogram `http_request_duration_seconds`; `histogram_quantile(0.95, sum by (le) (rate(..._bucket[5m])))`; porównanie ze średnią z p95 instancji i z błędem interpolacji; kryterium: wskazanie, dlaczego średnia p95 nie jest p95 usługi |
| D | Alert, Alertmanager, Mailpit | 20 | mechanizm | `PrometheusRule` z `for: 1m`, `require_tls: false`, mail w Mailpit (8025); kryterium: przejście `Pending` → `Firing` → mail → `Resolved` po usunięciu przyczyny |
| E | Od metryki do śladu i logu | 20 | synteza | Aplikacja wysyła OTLP do Collectora z eksporterem `debug`; log JSON zawiera `trace_id`; kryterium: ten sam `trace_id` w śladzie i w logu oraz wskazanie, gdzie czas jest tracony (praca czy oczekiwanie) |
| F | Diagnoza przypadku | 15 | decyzja | Wstrzyknięcie awarii (zmiana rozmiaru puli połączeń), hipoteza, pomiar potwierdzający, odrzucenie hipotezy konkurencyjnej, poprawka i ponowny pomiar |
| G | Rozszerzenia | poza budżetem | rozszerzenie | `user_id` w etykiecie i wzrost `prometheus_tsdb_head_series`, `absent()` po wyłączeniu eksportera, próbkowanie i retencja jako koszt (odsyłacz do wykładu 13) |

## 5. Rozkład budżetu

| Blok | Minuty | Zawartość |
|---|---|---|
| Przygotowanie | 15 | start Minikube, `helm repo`, pobranie obrazów; cel do zmierzenia, nie założenie |
| Ćwiczenie wspólne | 30 | A i B z omówieniem obserwacji po każdej komendzie |
| Zadania samodzielne | 75 | C, D, E (część obowiązkowa) oraz F jako zadanie kończące |
| Demonstracja i zapis | 15 | pokazanie wyniku F, zapis plików i notatki z dowodem |

Suma: 135 min. **Kontrola czasu:** przy opóźnieniu cięcie w kolejności (a) rozszerzenia G, (b) Tempo zamiast Collectora `debug`, (c) liczba zapytań w B. Zadania C i F nie są skracane — C daje sygnał, F uczy go użyć.

## 6. Rozwiązanie przypadku (do notatek, nie do skryptu)

Wstrzyknięcie: `DB_POOL_MAX` z 20 na 5 w manifeście aplikacji. Ruch, liczba błędów i CPU bez zmian, a p95 rośnie z ~180 ms do ~2,4 s.

- **Potwierdzenie:** p95 z histogramu aplikacji rośnie; `db_pool_in_use / db_pool_max` osiąga 5/5; histogram `db_pool_wait_seconds` przesuwa się w prawo; log zawiera `pool_wait_ms` i `pool_max=5`.
- **Hipoteza konkurencyjna:** wolne zapytanie SQL lub throttling CPU. Rozstrzygnięcie: `rate(container_cpu_throttled_seconds_total[5m])` blisko zera, a czas w bazie bez zmian — więc czas jest tracony na oczekiwanie, nie na pracę.
- **Pułapka rachunkowa (z wykładu):** 10 replik × 20 połączeń = 200 = limit połączeń bazy. Bezpieczna odpowiedź nie brzmi „przywróć 20”, lecz „ustal budżet puli z zapasem i sprawdź, czy 5 nie było celowe”.
- **Domknięcie pętli:** ta sama operacja widoczna w trzech sygnałach — metryka podaje skalę, ślad miejsce (span oczekiwania na połączenie), log konfigurację (`pool_max`).

## 7. Wersje i zależności (sprawdzone 15.11.2026)

| Element | Wersja | Uwaga |
|---|---|---|
| `kube-prometheus-stack` | 93.3.0 | jeden release: Prometheus, Alertmanager, Grafana, node-exporter, kube-state-metrics, CRD |
| Prometheus | 3.16.0 (LTS 3.13.5) | wariant LTS dopuszczalny, jeśli stanowisko ma mało pamięci |
| Grafana | 13.3.1 (chart 14.4.1) | chart przeniesiony do `grafana-community` |
| Alertmanager | 0.35.0 | `require_tls: false` dla Mailpita |
| Mailpit | pin obrazu | zastępuje MailHoga; SMTP 1025, UI 8025 |
| OpenTelemetry Collector | pin obrazu contrib | eksporter `debug` w wariancie podstawowym |
| Aplikacja | `zsr-flask:v3` | histogram + licznik + gauge puli, ekspozycja OpenMetrics |
| Stanowisko | Minikube 6–8 GB, 2 CPU | przy 2 GB stos OOM-uje; wariant lekki opisany w „Diagnostyce problemów” |

## 8. Kryteria odbioru

- [ ] `nix build` kończy się sukcesem; `result/4-monitoring.pdf` istnieje, a link na stronie laboratoriów działa.
- [ ] Wszystkie charty i obrazy pinowane; żaden `latest` ani `stable`.
- [ ] Wszystkie linki w skrypcie odpowiadają HTTP 200.
- [ ] Każde zadanie A–F ma *Weryfikację* z mierzalnym kryterium.
- [ ] Budżet pokrywa 135 min, część obowiązkowa jest oddzielona od rozszerzeń.
- [ ] Część obowiązkowa nie wymaga Tempo ani Loki; ślad jest dostępny przez Collector i logi.
- [ ] Przegląd wizualny wszystkich stron PDF: brak przepełnień, brak surowych emoji, brak bloków kodu uciętych na marginesie.
- [ ] Instalacja stosu na czystym stanowisku mieści się w 15 min (do zmierzenia; jeśli nie — wariant lekki).
- [ ] Nazwy spójne z lab 1–2: `zsr-flask`, `postgres`, `zsr`, porty 5000/3000, hasła i wolumeny bez zmian.
- [ ] `git diff --check`; brak zmian w pozostałych laboratoriach i w `lectures-psr/`.

## 9. Ryzyka

| Ryzyko | Reakcja |
|---|---|
| Stos monitoringowy OOM-uje na stanowisku | Minimum 6 GB; wyłączyć kube-state-metrics i zbędne dashboardy; wariant lekki w „Diagnostyce problemów” |
| Instalacja zjada czas zadaniowy | Obrazy pobrane przed zajęciami; jeśli nadal > 15 min, część A przechodzi w zadanie domowe, a zajęcia startują od B |
| Alert nie przychodzi w kilka minut | `scrapeInterval: 15s`, `for: 1m`; w skrypcie jawnie wyjaśnić czas `Pending` |
| Exemplars nie działają | Wymagają `exemplar-storage` i ekspozycji protobuf/OpenMetrics; w części obowiązkowej ślad idzie przez Collector, exemplars tylko jako rozszerzenie |
| Studenci gubią się w PromQL | Maks. 3 zapytania obowiązkowe, reszta jako materiał dodatkowy |
| Brak Tempo/Loki uznany za brak treści | Wprost napisać, że korelacja przez `trace_id` w logach jest metodą, a backend to osobna decyzja kosztowa (wykład 13) |
| Dashboardy zamiast diagnozy | Każde zadanie kończy się decyzją „co sprawdzić dalej”, nie zrzutem ekranu |

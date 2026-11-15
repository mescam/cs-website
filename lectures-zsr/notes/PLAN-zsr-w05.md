# Plan redakcyjny — ZSR 05 „Obserwowalność: diagnoza na podstawie metryk, logów i trace”

Dokument decyzyjny dla przepisania `zsr-w05.typ` i `notes/zsr-w05.md`. Zapisuje, **co** ma być na slajdach, **dlaczego** i **czym to się różni od wersji z 26.09.2026**. Nie jest slajdami dla studentów.

## 1. Umiejscowienie w kursie

W05 jest piątym spotkaniem i pierwszym, które odpowiada na pytanie „skąd wiemy, co się dzieje”. Jest pomostem między modelem działania (W03) i eksploatacją (W04) a wdrożeniami (W06) i incydentami (W11).

**Wejście (co już wiedzą):**

| Wykład | Co wnosi do W05 |
|---|---|
| W01 | system zamówień, pętla informacji zwrotnej, „sygnały muszą obejmować cały przepływ”, timeout ≠ brak operacji |
| W03 | rekonsyliacja, stan oczekiwany; `kubectl describe` jako narzędzie pierwszej linii |
| W04 | sondy, requests/limits, throttling CPU, OOM, HPA liczone z metryk |

**Wyjście (co odraczamy świadomie):**

| Temat | Gdzie należy |
|---|---|
| SLI/SLO, error budget, burn rate, alert wymagający działania | W11 |
| Rollout, GitOps, rollback, wersje aplikacji | W06 |
| Podpis, provenance, skanowanie artefaktów | W07 |
| Retencja jako pozycja kosztowa, FinOps | W13 |
| `kubectl describe`, restart count, sondy | W03/W04 — nie powtarzać jako nowego tematu |

**Zasada nadrzędna:** W05 uczy *diagnozy*, nie katalogu narzędzi. Każdy slajd musi prowadzić do decyzji „co sprawdzić dalej”.

## 2. Kontrakt dydaktyczny

- **Budżet bazowy:** 5 min problem + 22 min pojęcia + 10 min przykład + 5 min pytania + 3 min podsumowanie = 45 min.
- **Otwarcie:** problem z życia usługi na pierwszym slajdzie merytorycznym, potem agenda. Świadomie **bez** osobnego slajdu z efektami kształcenia — patrz korekta 22.
- **Ostatni slajd merytoryczny:** trzy wnioski i krótkie pytanie sprawdzające.
- **Przykład przewodni:** system zamówień — `orders-api`, `orders-worker`, kolejka `orders`, baza. Te same nazwy co w całym kursie.
- **Co najmniej jedna decyzja** do podjęcia na podstawie danych, nie lista narzędzi.
- **Kontekst chmurowy:** punkt agendy + 2 slajdy + wniosek + źródła (konwencja PSR/ZSR). Slajdy chmurowe wchodzą w budżet 45 min.
- **Emoji:** wyłącznie `#emoji.cloud` / `#emoji.warning` itd. Zero surowych znaków Unicode.
- **Źródła:** dokumentacja pierwotna obok istotnych twierdzeń. Żadnych nieudokumentowanych statystyk ani fikcyjnych historii firm.

## 3. Zmiany względem wersji z 26.09.2026

Obecny `zsr-w05.typ` (14 stron) jest poprawny merytorycznie, ale:

| # | Problem w wersji obecnej | Korekta w nowej wersji |
|---|---|---|
| 1 | ~~Brak slajdu z umiejętnościami po zajęciach~~ — **korekta wycofana, patrz 22** | Nie dodawaj takiego slajdu |
| 2 | Brak „Planu wykładu” (W01 i W03 go mają) | Dodaj agendę z punktem `#emoji.cloud` |
| 3 | Slajd „Trzy rodzaje danych” definiuje sygnały, ale nie ma kryterium wyboru | Dodaj regułę: metryka zawęża → trace lokalizuje → log wyjaśnia |
| 4 | Brakuje rozróżnienia **monitoring vs obserwowalność** — jest w `zsr-6.tex` i PSR, a jest to oś wykładu | Dodaj jeden slajd zamiast rozwlekłej definicji |
| 5 | Kardynalność jest, ale bez odniesienia do kosztu i bez reguły „co nie może być labelem” | Wzmocnij o jawną regułę decyzyjną |
| 6 | Brak `#src` przy slajdach o retencji i samplingu (twierdzenia bez źródła) | Dodaj źródła OTel |
| 7 | Slajd o trace jest wizualny, ale nie pokazuje **propagacji kontekstu** — klucza do kolejki | Dodaj wątek propagacji i `links` przy asynchroniczności |
| 8 | Brak wniosków w formacie „trzy wnioski + pytanie” — W03 ma „Kluczowe wnioski” | Dodaj slajd wniosków przed bibliografią |
| 8a | Brak wniosku chmurowego w „Kluczowych wnioskach”, wymaganego konwencją ZSR/PSR | Trzeci wniosek dotyczy podziału odpowiedzialności z backendem zarządzanym |
| 9 | Slajd przypadku kończy się na „zaproponuj zmianę”, bez kryterium weryfikacji | Doprecyzuj pomiar potwierdzający |
| 10 | Źródła: 6 pozycji bez OTel Metrics/Logs i bez Azure Monitor | Uzupełnij do spójnego zestawu |

### Korekty po weryfikacji dokumentacji — 15.11.2026

Sprawdzenie linków i treści dokumentacji źródłowej wykazało trzy błędy w pierwszej wersji tego planu i w przepisanym wykładzie:

| # | Problem | Korekta |
|---|---|---|
| 11 | Slajd o próbkowaniu twierdził, że próbka „nie daje bezstronnej statystyki o całości ruchu” | Dokumentacja OpenTelemetry opisuje próbkę jako *reprezentanta populacji* i podaje, że przy dużym ruchu 1% dobrze opisuje pozostałe 99%. Slajd mówi teraz o reprezentatywności i o tym, że **sposób** próbkowania decyduje, co wypada — rzadkie błędy próbkuje się inną regułą |
| 12 | Slajd o typach metryk nie odnotowywał, że dokumentacja Prometheusa zaleca dziś histogramy natywne | Dodano jedno zdanie o świadomym wyborze histogramu klasycznego; uzasadnienie dydaktyczne w notatkach |
| 13 | Slajd o propagacji kontekstu nie miał źródła dla samej propagacji | Dodano OTel *Context propagation*; brakowało też tego linku w bibliografii |

### Research z wyszukiwaniem internetowym — 15.11.2026

Po uruchomieniu `web_search` (provider Exa) research objął nie tylko sprawdzenie znanych adresów, lecz także wyszukiwanie nowych źródeł i faktów zależnych od wersji. Ustalenia i wynikające z nich zmiany:

| # | Ustalenie | Wpływ na wykład |
|---|---|---|
| 14 | Histogramy natywne są stabilne od Prometheus 3.8.0 (XII 2025), 3.13 (VII 2026) to pierwsze LTS; wymagają jawnego `scrape_native_histograms`, a **ekspozycja działa tylko w protobufie** — format tekstowy nie został rozszerzony i nie ma takich planów | Slajd 8 mówi teraz o protobufie zamiast ogólnikowego „zaleca natywne”. To realna pułapka: student wystawiający natywne histogramy w formacie tekstowym nie zobaczy danych |
| 15 | Dokumentacja Prometheusa podaje konkretny błąd estymacji: przy rzeczywistym p95 = 220 ms histogram klasyczny z granicami 0,2/0,3 s zwraca ok. 295 ms | Slajd 10 zamienia mgliste „wynik jest przybliżony” na liczby i wyjaśnia, że to interpolacja w przedziale, nie błąd zapytania |
| 16 | **Exemplars** to brakujące ogniwo metryka → ślad: etykieta przy przedziale histogramu niesie `trace_id` i `span_id` | Dodane na slajd 12. Wcześniej wykład uczył trzech sygnałów, ale nie mówił, **jak** przejść od skoku metryki do właściwego śladu — exemplars są tym mechanizmem |
| 17 | Kolejność `rate` przed agregacją potwierdzona dosłownie w dokumentacji: inaczej funkcja nie wykryje resetu countera | Teza slajdu 9 potwierdzona źródłem pierwotnym; brak zmian w treści |
| 18 | Reguła „średnia z p95 nie jest p95 usługi” potwierdzona oficjalnym przykładem `// BAD!` w dokumentacji | Teza slajdu 10 potwierdzona; brak zmian w treści |
| 19 | Prometheus **nie wyzwala alertu**, gdy zapytanie nie zwraca danych — cicha awaria; `up == 0` nie wykrywa pojedynczych instancji, które zniknęły z szeregu | Materiał do notatek i ewentualnego pytania; nie wchodzi na slajdy z powodu budżetu |
| 20 | Dokumentacja OTel rozróżnia wzorce wdrożenia Collectora: agent, gateway i agent–gateway; próbkowanie tail-based wymaga gatewaya | Wzmianka w notatkach; slajd pozostaje ogólny |
| 21 | Profile wchodzą jako czwarty sygnał — alfa publiczna od III 2026, profiler eBPF bez zmian w kodzie, dokumentacja odradza użycie produkcyjne | Materiał na przyszłość w notatkach; świadomie poza wykładem |
| 22 | Slajd „Po tym wykładzie” z efektami kształcenia — **usunięty na polecenie prowadzącego** | Żaden z wykładów W01–W15 takiego slajdu nie ma; moje wcześniejsze uzasadnienie „wzorzec z W01–W04” było nieprawdziwe i zostało wycofane. Odsyłacz do wykładu 4 przeniesiono na slajd z problemem, zgodnie z tym, jak robi to W02 |
| 23 | Wykład cytował OpenTelemetry w kilku miejscach, ale nigdy nie wyjaśniał, **czym OTel jest i jaki problem rozwiązuje** — dodane na polecenie prowadzącego | Nowy slajd 6: tabela „przed / po”, historia połączenia OpenTracing i OpenCensus (2019, CNCF), rozróżnienie „OTel nie jest backendem” oraz uczciwe zastrzeżenie, że neutralność nie obejmuje backendu. Zagadnienie zajmuje 3 min z bloku pojęć; pozostałe bloki przesunięto tak, by budżet nadal sumował się do 45 |

Wszystkie 13 adresów w W05 zweryfikowano jako odpowiadające HTTP 200. Szczegóły wersji i pułapek opisano w `notes/zsr-w05.md` w sekcji „Ustalenia z dokumentacji”, żeby nie obciążały slajdów ani budżetu 45 minut.

Nieaktualna data „Dokumentacja sprawdzona: 26.09.2026” została zastąpiona rzeczywistą datą sprawdzenia (15.11.2026). Wszystkie 12 linków w W05 zweryfikowano jako odpowiadające HTTP 200.

**Czego nie przenosimy z `zsr-6.tex`:** AIOps, Chaos Engineering, ELK vs EFK jako porównanie stosów, Jaeger vs Zipkin jako „pionier vs nowoczesny”, SLI/SLO (→ W11), incident response (→ W11), lista komponentów Prometheusa jako katalog.

## 4. Szkielet slajdów

Kolejność i przypisanie do minut. Tytuły robocze.

| # | Slajd | Min | Rola | Treść i źródło |
|---|---|---|---|---|
| 1 | *(tytuł)* | — | — | Bez bloku czasowego |
| 2 | Objaw: wolne przyjmowanie zamówień | 0–5 | Problem | Tabela 09:55 vs 10:05: ruch i błędy bez zmian, p95 180→2400 ms, CPU 35→38%. Pytanie: czy niski CPU i brak 5xx oznaczają poprawne działanie? `#src` z odsyłaczem do wykładu 4 |
| 3 | Plan wykładu | 5–7 | Agenda | 7 punktów, w tym `#emoji.cloud` |
| 4 | Monitoring a obserwowalność | 5–7 | Pojęcie | Pytanie „czy działa?” vs „dlaczego tak działa?”; znane vs nieznane niewiadome. Definicja: wnioskowanie o stanie wewnętrznym z telemetrii zewnętrznej. `#src` OTel |
| 5 | Trzy sygnały i ich zadania | 7–10 | Pojęcie | Tabela: metryka (szereg, trend, alert), log (zdarzenie, szczegół), trace (spany, ścieżka). Reguła: metryka zawęża → trace lokalizuje → log wyjaśnia. `#src` OTel Signals |
| 6 | OpenTelemetry: po co wspólny standard | 10–13 | Pojęcie | Tabela „przed / po”: agenci producentów i lock-in → jeden standard. OpenTracing i OpenCensus połączone w 2019, CNCF. OTel nie jest backendem. Neutralność nie obejmuje backendu. `#src` What is OTel + CNCF history |
| 7 | Prometheus: zbieranie i odczyt | 13–16 | Mechanizm | `#flow` aplikacja `/metrics` → scrape+TSDB → PromQL → Grafana; `#flow` reguła → Alertmanager → dyżurny. Pull ≠ push. Scrape niedostępny ≠ 0. `#src` |
| 8 | Counter, gauge, histogram | 13–16 | Pojęcie | Cztery linie przykładu; counter zeruje się po restarcie; histogram = kumulatywne buckety. Uwaga o natywnych: stabilne, ale opt-in i tylko protobuf. `#src` |
| 9 | PromQL: tempo i udział błędów | 16–20 | Umiejętność | `rate` na szeregu, potem suma po instancjach; reset countera; udział błędów bez ruchu wymaga interpretacji. `#src` |
| 10 | p95 z histogramu wielu instancji | 20–25 | Umiejętność | `histogram_quantile` + `sum by (le)`; konkretny błąd estymacji 220 ms → 295 ms; średnia z p95 ≠ p95 usługi. `#src` |
| 11 | Kardynalność: koszt jednego labela | 25–28 | Decyzja | 10 tras × 5 kodów × 20 instancji ≈ 1000 kombinacji; `user_id` ×100 000 → do 100 mln. Reguła: identyfikator idzie do logu/trace, nie do labela. `#src` |
| 12 | Trace: czas pracy i czas oczekiwania | 28–32 | Umiejętność | Pasek 2400 ms: API → pool DB 2100 ms → SQL 90 ms. Oczekiwanie dominuje nad wykonaniem SQL. Exemplar jako przejście od metryki do śladu. Propagacja kontekstu przez kolejkę; `links`. `#src` |
| 13 | Log powiązany ze śladem | 28–32 | Synteza | JSON z `trace_id`, `db_pool_wait`, `pool_max=5`, `pool_in_use=5`. Metryka = skala, trace = miejsce, log = konfiguracja. Zakaz tokenów i danych osobowych. |
| 14 | `#emoji.cloud` Collector i backend zarządzany | 32–35 | Chmura | `#flow` SDK OTel → Collector → backend. Collector: odbiór, przetwarzanie, batching, eksport, kolejki, limity. Backend np. Azure Monitor. Redakcja przed eksportem; awaria backendu nie blokuje zamówień. `#src` |
| 15 | `#emoji.cloud` Retencja i próbkowanie | 35–37 | Chmura | Tabela decyzja/zysk/ograniczenie. Próbka jest reprezentatywna, jeśli dobrze dobrana; rzadkie błędy próbkuje się inną regułą. `#src` OTel Sampling |
| 16 | Przypadek: co zmieniło się o 10:00? | 37–42 | Decyzja | `#codebox` diff: `DB_POOL_MAX` 20→5; DB active 50/200; DB CPU 25%; repliki i ruch bez zmian. `#alertblock` + zadanie: połącz diff, trace i log |
| 17 | Kluczowe wnioski | 42–45 | Domknięcie | Trzy wnioski, w tym wniosek `#emoji.cloud` wymagany konwencją, oraz pytanie sprawdzające |
| 18 | Źródła i lektury | — | — | Bez bloku czasowego |

Suma bloków merytorycznych wynosi dokładnie 45 minut i pokrywa ciągły przedział 0–45. Tabela jest mapą treści; wiążący przebieg znajduje się w `notes/zsr-w05.md` i jest z nią zgodny. Numeracja odpowiada stanowi po usunięciu slajdu z efektami kształcenia (korekta 22) i dodaniu slajdu o OpenTelemetry (korekta 23).

## 5. Rozkład budżetu

| Blok | Minuty | Zawartość |
|---|---|---|
| Problem | 5 | Slajd 2 i hipotezy studentów |
| Pojęcia | 22 | Slajdy 5–11 (obserwowalność, sygnały, Prometheus, typy metryk, PromQL, p95, kardynalność) |
| Przykład | 10 | Slajdy 12–16 (ślad, log, chmura, retencja, przypadek) |
| Pytania | 5 | Dyskusja w trakcie i odpowiedź na pytanie sprawdzające |
| Podsumowanie | 3 | Slajd 17 |

**Kontrola czasu:** przy rozciągniętej dyskusji cięcie następuje w kolejności: (a) dygresja o histogramach natywnych, (b) czytanie składni PromQL na slajdzie 9, (c) drugie pytanie o kardynalność. Slajdu z przypadkiem nie skracamy — jest jedynym miejscem, w którym studenci sami łączą trzy sygnały.

## 6. Rozwiązanie przypadku (do notatek, nie na slajd)

Diff `DB_POOL_MAX` 20→5 wyjaśnia wzrost p95 przy niezmienionym ruchu, błędach i CPU: żądania czekają na połączenie, nie na CPU. Potwierdzenie: czas oczekiwania w puli, wykorzystanie puli, p95 i obciążenie bazy po stronie serwera.

**Pułapka rachunkowa:** 10 replik × 20 połączeń = 200 = limit bazy. Powrót do 20 wyczerpuje limit, gdy dochodzi druga usługa. Bezpieczna odpowiedź nie brzmi „przywróć 20”, lecz „ustal budżet połączeń z zapasem i sprawdź, czy 5 nie było celowe”.

**Hipoteza alternatywna:** wyciek połączeń albo długie transakcje trzymające połączenia. Rozstrzygnięcie: rozkład czasu zajęcia połączenia i liczba otwartych/zamkniętych połączeń w czasie, nie pojedynczy ślad.

## 7. Kryteria odbioru

- [x] `nix build path:.` kończy się sukcesem; `result/zsr-w05.pdf` istnieje.
- [x] Budżet w notatkach pokrywa ciągły przedział 0–45 min i ma odpowiedź do zadania.
- [x] Przegląd wizualny **wszystkich** stron PDF, w tym powiększone strony z `#codebox` i diagramem trace.
- [x] Brak surowych emoji Unicode w `.typ`; brak przepełnień i przypadkowych dodatkowych stron.
- [x] Każde istotne twierdzenie ma `#src`; linki prowadzą do dokumentacji autorów narzędzi.
- [x] Spójność nazw: `orders-api`, `orders-worker`, kolejka `orders`; dane liczbowe spójne między slajdami.
- [x] Notatki odsyłają do W11 po SLO i nie rozwijają go tutaj.
- [x] `git diff --check`; brak zmian w `labs/`, `lectures-psr/`, `lectures-src/`.
- [x] README (`lectures-zsr/README.md`) zgodne z rzeczywistą liczbą stron i stanem.

Sprawdzenie wykonano 15.11.2026: kompilacja 15 PDF-ów, przegląd wszystkich 18 stron W05, kontrola braku surowych emoji i ciągłości budżetu 0–45. Podczas przeglądu wykryto i naprawiono przepełnienie slajdu z logiem JSON na dwie strony oraz brak wniosku chmurowego wymaganego konwencją.

## 8. Ryzyka

| Ryzyko | Reakcja |
|---|---|
| Przeciążenie PromQL — studenci gubią wątek | Maks. 3 zapytania; reszta jako materiał dodatkowy |
| Kardynalność zdominuje wykład | Twardy limit: jeden slajd, jedno pytanie |
| Trace „za ładny” — brak związku z decyzją | Zawsze kończyć slajd wnioskiem diagnostycznym |
| Powtórzenie W11 (SLO) | Odsyłacz, nie omówienie |
| Wysoka liczba stron | Cięcie najpierw z retencji/samplingu i agendy, nigdy z przypadku |

# Plan redakcyjny — ZSR 06 „CI/CD i GitOps: artefakt, stan oczekiwany i okno rollbacku"

Dokument decyzyjny dla przepisania `zsr-w06.typ` i `notes/zsr-w06.md`. Zapisuje, **co** ma być na slajdach, **dlaczego** i **czym różni się od wersji z 26.09.2026**. Nie jest slajdami dla studentów.

## 1. Umiejscowienie w kursie

W06 jest szóstym spotkaniem i pierwszym, które odpowiada na pytanie „jak zmienia się stan usługi w sposób, który umiemy udowodnić". Jest pomostem między diagnozą (W05) a bezpieczeństwem operacyjnym (W07): to, co tu wyprodukujemy jako artefakt i deklarację, tam będzie weryfikowane kryptograficznie.

**Wejście (co już wiedzą):**

| Wykład | Co wnosi do W06 |
|---|---|
| W01 | system zamówień (`orders-api`, `orders-worker`, kolejka `orders`, baza), pętla informacji zwrotnej |
| W03/W04 | model Kubernetes, Deployment, sondy, skalowanie — na tym operują strategie wdrożenia |
| W05 | metryki, PromQL, `rate`, p95 — na tym opiera się bramka kanarka; pytanie sprawdzające W05 jako otwarcie |

**Wyjście (co odraczamy świadomie):**

| Temat | Gdzie należy |
|---|---|
| Skan, podpis, provenance, SBOM | W07 |
| Sekrety w deklaracjach (GitOps a sekrety) | W07 |
| Polityka admission i dopuszczenie obrazu | W07 |
| SLO jako bramka wdrożenia, error budget | W11 |
| Retencja artefaktów a odtwarzanie po awarii | W12 |
| Koszt środowisk podwójnych (blue–green) | W13 |

## 2. Kontrakt dydaktyczny

- **Budżet bazowy:** 5 min problem + 20 min pojęcia i mechanizmy + 12 min warianty i implikacje (w tym chmura) + 5 min przypadek + 3 min podsumowanie = 45 min, przedział ciągły.
- **Otwarcie:** problem z życia usługi — „zielony pipeline i ręczne polecenie, a zachowanie bez zmian".
- **Ostatni slajd merytoryczny:** wnioski + pytanie sprawdzające.
- **Przykład przewodni:** system zamówień. Bez drugiego przykładu.
- **Co najmniej jedna decyzja** do podjęcia na podstawie danych (przypadek DROP COLUMN).
- **Kontekst chmurowy:** decyzja prowadzącego z 22.11.2026 — **jeden** slajd chmurowy (OIDC + zarządzana bramka środowiska); awaria rejestru pozostaje slajdem regularnym; cykl życia rozszerzeń GitOps zarządzanych przeniesiony do notatek.
- **Emoji:** wyłącznie `#emoji.cloud` (`#cloud`). Zero surowych znaków Unicode.
- **Źródła:** dokumentacja pierwotna przy każdym twierdzeniu zależnym od narzędzia.

## 3. Zmiany względem wersji z 26.09.2026

Obecny `zsr-w06.typ` (14 stron) jest poprawny merytorycznie, ale:

| # | Problem w wersji obecnej | Korekta w nowej wersji |
|---|---|---|
| 1 | Pierwszy slajd merytoryczny to definicje CI/delivery/deployment — brak problemu | Slajd problemu: poprawka scalona i wdrożona, a zachowanie bez zmian; tag `v2.0.1` użyty dwa razy |
| 2 | Brak „Planu wykładu" | Agenda, 7 punktów, w tym `#cloud` |
| 3 | Tytuły rzeczownikowe („CI, delivery i deployment", „Strategie zmiany wersji") | Tytuły-twierdzenia: „Deployment i release to dwie różne decyzje", „Liczba replik to nie procent ruchu" |
| 4 | Definicje, strategie, canary i promocja bez `#src` | `#src` przy każdym slajdzie z twierdzeniem cudzym lub zależnym od narzędzia |
| 5 | „GitOps: stan oczekiwany i drift" zakłada, że GitOps już znamy | Nowy slajd: definicja GitOps + cztery zasady OpenGitOps; drift jako osobny slajd z konsekwencją (rollback) |
| 6 | Brak slajdu „Kluczowe wnioski" i pytania sprawdzającego | Dodany, z wnioskiem chmurowym |
| 7 | Brak lektury obowiązkowej na W07 i pytania otwierającego | SLSA 1.2 Provenance + pytanie o dowód tożsamości obrazu |
| 8 | Brak odsłony „kontekst/ewolucja" | Slajd „sygnał → rozwiązanie" (skrypty → pipeline → GitOps) + jedna liczba DORA 2025 |
| 9 | „Fragment potoku GitHub Actions" to mock skryptów o niskiej wartości dydaktycznej | Zamieniony na tabelę kontraktów etapów; YAML mock do notatek |
| 10 | Slajd canary łączy strategie i bramkę bez rachunku progu | Rozdzielone: mechanizm (repliki vs ruch) i bramka na metrykach z rachunkiem |
| 11 | Slajd OIDC i awaria rejestru oznaczone jako chmurowe bez spójnego wątku | Jeden slajd chmurowy (decyzja prowadzącego); reszta jako treść regularna |

### Research z wyszukiwaniem internetowym — 22.11.2026

Po uruchomieniu `web_search`/`web_fetch` (provider Exa) zweryfikowano wszystkie twierdzenia zależne od wersji. Ustalenia i wpływ:

| # | Ustalenie | Wpływ na wykład |
|---|---|---|
| 1 | Dokumentacja Argo CD wprost: *rollback nie jest możliwy przy włączonej synchronizacji automatycznej*; uzgadnianie domyślnie co 120 s ± 60 s, self-heal po 5 s | Slajd 9 dostaje twardą tezę „ręczna zmiana żyje krótko i rollback poza Gitem nie istnieje"; dokładne liczby do notatek |
| 2 | Prune przy automated sync jest domyślnie **wyłączony** (mechanizm bezpieczeństwa); nowe pole `manualDefaults` zmienia domyślne zachowań manual sync, gdy jest ustawione | Komentarze w YAML na slajdzie 9 precyzyjne; pułapka `manualDefaults` do notatek |
| 3 | Argo Rollouts: bez `trafficRouting` `setWeight` jest „best effort" — przykład z dokumentacji: 10 replik i 41% → 4 Pody nowej wersji i 6 starych | Nowy slajd 11 z tym przykładem zamiast ogólnego „liczba replik nie gwarantuje procentu" |
| 4 | Argo Rollouts Analysis: `successCondition`, `failureLimit`, provider Prometheus; wynik AnalysisRun to Successful / Failed / Inconclusive → kontynuacja / przerwanie / pauza; nowe dostawcy metryk tylko jako pluginy | Fragment AnalysisTemplate na slajdzie 12 zgodny ze składnią dokumentacji; szczegóły do notatek |
| 5 | Kubernetes Images: digest jest niezmenny, „Tags can be moved to point to different images" — dosłowne wsparcie tezy o tożsamości artefaktu | Slajd 6 ma źródło pierwotne zamiast wiedzy potocznej |
| 6 | GitHub OIDC: warunki zaufania (`sub`) obejmują repozytorium, gałąź, environment; repozytoria utworzone po 15.07.2026 dostają niezmienne identyfikatory w `sub` | Slajd 14 i notatki; data zmiany jako materiał „co się zmienia" |
| 7 | GitHub environments: required reviewers (do 6, jedno zatwierdzenie wystarcza), wait timer do 30 dni, polityka gałęzi, etykieta „Waiting", automatyczne niepowodzenie po 30 dniach | Slajd 14 oparty na dokumentacji, nie na pamięci |
| 8 | DORA 2025: 16,2% respondentów wdraża na żądanie (kilka razy dziennie), największa grupa 31,5% wdraża raz w tygodniu–miesiącu; ok. 5 000 ankietowanych (VI–VII 2025) | Jedna liczba na slajdzie 7 jako uzasadnienie „po co to ćwiczymy"; zastrzeżenie do notatek |
| 9 | Rozszerzenie AKS/Arc `microsoft.flux` (Flux v2) **jest aktualne** (XI 2026, v1.26.5 na Flux v2.9.6); wycofano natomiast rozszerzenie **Flux v1** (ogłoszone I 2023, wykonane 24.05.2025); Flux upstream: 2.10 GA (X 2026), 2.7 EOL | Świadoma korekta: pierwotny pomysł „GitOps zarządzany jako lekcja o wycofaniu usługi" był oparty na mylnym skojarzeniu; materiał przeniesiony do notatek |
| 10 | Argo CD 3.2 osiągnęło EOL 4.08.2026; wspierane 3.3–3.5 | Tylko notatki (kontekst wsparcia) |
| 11 | OpenGitOps 1.0: cztery zasady (deklaratywny, wersjonowany i niezmienialny, pobierany automatycznie, ciągle uzgadniany) — tekst zweryfikowany w repozytorium `open-gitops/documents` | Slajd 8 |

Wszystkie 16 adresów źródłowych zweryfikowano HTTP 200 (22.11.2026).

### Korekty po konsultacji z prowadzącym — 22.11.2026

| # | Decyzja | Wpływ na wykład |
|---|---|---|
| 12 | Usunięcie wstawki „Kontynuacja wykładu 5…" ze slajdu problemu — nawiązanie do W05 zostaje wyłącznie w notatkach (minuty 0–2), nie na slajdzie | Slajd 2 kończy się kolumnami „Co wiemy" / „Czego jeszcze nie wiemy", bez `#src` |
| 13 | Zamiana „potok" → „pipeline" we wszystkich formach gramatycznych (tytuły, agenda, tabele, przypadek, źródła; odmiana jak w PSR: pipeline'u, pipeline'y) — prowadzący: „nikt nie mówi potok" | Spójna terminologia; slajd 5 nosi tytuł „Pipeline: każdy etap ma wejście i wynik". Pozostałe wykłady (W07, W08, W14) i ogólny boilerplate README pozostają poza tą zmianą — do osobnej redakcji |
| 14 | Usunięcie meta-komentarzy typu „liczba dydaktyczna" ze slajdów — fakt trafia do infoboxa (`#exblock`), a zastrzeżenia o danych przykładowych zostają w notatkach i w standardowej nocie na slajdzie bibliograficznym | Slajd 7: infobox „DORA 2025" z samym faktem; `#src` na slajdach 12 i 15 bez dopisków o przykładach |

## 4. Szkielet slajdów

| # | Slajd | Min | Rola | Treść i źródło |
|---|---|---|---|---|
| 1 | *(tytuł)* | — | — | Podtytuł: „Tożsamość artefaktu, stan oczekiwany i okno rollbacku" |
| 2 | Zielony pipeline nie mówi, co działa w produkcji | 0–5 | Problem | Tabela 09:55/10:05 (błędy bez zmian, wersja w metrykach zmieniona); `#cols` „Co wiemy" / „Czego jeszcze nie wiemy" |
| 3 | Plan wykładu | 5–7 | Agenda | 7 punktów, w tym `#cloud` |
| 4 | Deployment i release to dwie różne decyzje | 7–10 | Pojęcie | Tabela CI/delivery/deployment + `#defblock` definicja deployment/release; flaga funkcji; `#src` Humble/Farley |
| 5 | Pipeline: każdy etap ma wejście i wynik | 10–13 | Mechanizm | `#flow` commit→…→promocja; tabela kontraktów etapów; odsyłacz do W07 |
| 6 | Tag jest etykietą, digest jest tożsamością | 13–16 | Mechanizm | `#codebox` tag dziś/wczoraj vs digest; `#defblock` zasada promocji; pułapka ponownego buildu; `#src` Kubernetes Images |
| 7 | Każde rozwiązanie zostawia nowy koszt | 16–18 | Kontekst | Tabela „sygnał → rozwiązanie → pozostały koszt"; infobox DORA 2025; `#src` DORA |
| 8 | GitOps: klaster dąży do stanu zadeklarowanego w Git | 18–21 | Pojęcie | `#defblock` definicja; cztery zasady OpenGitOps; `#flow` pętla uzgadniania; `#src` |
| 9 | Ręczna zmiana w klastrze żyje krótko | 21–24 | Mechanizm | YAML `syncPolicy`; `prune`/`selfHeal` z komentarzami; rollback niemożliwy przy automated sync; wstrzymanie syncu jako decyzja; `#src` Argo CD |
| 10 | Każda strategia płaci inną cenę | 24–27 | Warianty | Tabela rolling/blue–green/canary; rollback nie odtwarza danych; `#src` Kubernetes + Rollouts |
| 11 | Liczba replik to nie procent ruchu | 27–29 | Warianty | Przykład 10 replik / 41% → 4 Pody; dokładne procenty wymagają routera ruchu; `#src` Rollouts Canary |
| 12 | Bramka kanarka liczy się na metrykach | 29–31 | Umiejętność | Tabela 90k/10k (0,1% vs 2,0%); fragment AnalysisTemplate; rachunek progu 0,5 pp; `#src` Rollouts Analysis |
| 13 | Okno rollbacku wyznaczają dane, nie obrazy | 31–33 | Implikacja | Tabela expand–contract; „contract kończy okno rollbacku"; `#src` Fowler |
| 14 | `#cloud` Token czasowy i zarządzana bramka | 33–35 | Chmura | `#flow` workflow→OIDC→rola; warunki zaufania; środowisko z wymaganiem zatwierdzenia; `#src` GitHub OIDC + environments |
| 15 | Rollback wymaga dostępu do poprzedniego artefaktu | 35–37 | Implikacja | Tabela stanów podczas niedostępności rejestru; retencja w procedurze odtworzenia; przykład dydaktyczny |
| 16 | Przypadek: v2 działa, v1 już nie | 37–42 | Decyzja | `#codebox` os czasu z `contract: DROP COLUMN`; pytanie o to, co zamknęło okno rollbacku, wzmocnione o selfHeal i Git |
| 17 | Kluczowe wnioski | 42–45 | Domknięcie | 4 wnioski (w tym chmurowy) + pytanie sprawdzające |
| 18 | Źródła i lektury | — | — | 11 pozycji (13 linków); `#defblock` lektura obowiązkowa (SLSA provenance) + pytanie otwierające na W07 |

Budżet pokrywa ciągły przedział 0–45 minut; tytuł i bibliografia bez bloków czasowych.

## 5. Rozkład budżetu

| Blok | Minuty | Zawartość |
|---|---|---|
| Problem | 5 | Slajd 2 i hipotezy studentów |
| Pojęcia i mechanizmy | 20 | Slajdy 4–9 (CI/delivery/deployment, pipeline, artefakt, kontekst, GitOps, drift) |
| Warianty i implikacje | 12 | Slajdy 10–15 (strategie, kanarek, dane, chmura, retencja) |
| Przypadek | 5 | Slajd 16 |
| Podsumowanie | 3 | Slajd 17 |

**Kontrola czasu:** cięcie w kolejności: (a) czytanie składni AnalysisTemplate na slajdzie 12, (b) dygresja o `manualDefaults` i wersjach Argo CD, (c) drugie pytanie o OIDC. Slajdu z przypadkiem nie skracamy — to jedyne miejsce, gdzie studenci sami wyznaczają okno rollbacku.

## 6. Rozwiązanie przypadku (do notatek, nie na slajd)

Okno rollbacku zamknął krok `contract` (10:20), nie wdrożenie ani backfill. Cofnięcie tagu w Git przywróci obraz v1, ale v1 czyta `amount`, którego nie ma — błąd SQL po każdej próbie odczytu zamówienia. Opcje: zgodna poprawka v2 (preferowana), odtworzenie kompatybilnego schematu z wiarygodnym przeliczeniem danych, czasowe ograniczenie funkcji. Nie proponować globalnego restore produkcji bez oceny zapisów po 10:20.

Wzmocnienie GitOps: przy `automated.selfHeal` każda ręczna próba „naprawy" schematu zostanie cofnięta przez kontroler; jawnym wyjątkiem jest wstrzymanie synchronizacji z zapisem decyzji. To, co w push-modelu było „dręczonym wyjątkiem", tu staje się procedurą.

**Jak pipeline ma wymusić okres obserwacji:** osobne zmiany (PR z nową kolumną i PR z `DROP COLUMN` po okresie), kontrola linterem/migracją, sprawdzenie wszystkich czytających kolumnę przed contract — i brak automatycznego scalania PR-a `contract` bez zgody właściciela danych.

## 7. Kryteria odbioru

- [x] `nix build path:.` kończy się sukcesem; `result/zsr-w06.pdf` istnieje.
- [x] Liczba stron PDF zgodna z deklaracją w README (18 stron).
- [x] Budżet w notatkach pokrywa ciągły przedział 0–45 min i ma odpowiedzi do decyzji.
- [x] Przegląd wizualny wszystkich 18 stron (render strony po stronie), w tym slajdów z `#codebox`, `#cols` i `#flow`.
- [x] Brak surowych emoji Unicode w `.typ`; brak przepełnień — po sześciu iteracjach cięcia (tabela problemu, komórki tabel CI, lista zasad, dwa fragmenty YAML).
- [x] Każde istotne twierdzenie ma `#src` lub kryterium; 13 linków w W06 HTTP 200 (sprawdzone 22.11.2026).
- [x] Spójność nazw: `orders-api`, `orders-worker`, kolejka `orders`; liczby spójne między slajdami.
- [x] Notatki: 3 pytania kontrolne z odpowiedziami; omówienie pytania sprawdzającego W05 na otwarcie (W05 nie zostawiło pytania otwierającego — konwencja nowsza niż tamta rewizja).
- [x] `git diff --check`; brak zmian w `labs/`, `lectures-psr/`, `lectures-src/`.
- [x] README zaktualizowany (wiersz W06: 18 stron + sekcja o planie).

Sprawdzenie wykonano 22.11.2026: kompilacja 15 PDF-ów przez `nix build path:.`, przegląd wszystkich 18 stron W06 w renderze 90 dpi, kontrola braku surowych emoji i ciągłości budżetu 0–45. Podczas przeglądu wykryto i naprawiono przepełnienia na sześciu slajdach oraz skrócono tytuł slajdu kontekstowego, który nie mieścił się w nagłówku. Składnia fragmentów YAML (2) i SQL (1) sprawdzona przez inspekcję, bez wykonywania.

## 8. Ryzyka

| Ryzyko | Reakcja |
|---|---|
| Za dużo narzędzi (Argo CD, Rollouts, GitHub) — student gubi oś | Oś jest jedna: tożsamość artefaktu i stan oczekiwany. Narzędzia ilustrują mechanizm, nigdy odwrotnie |
| Kanarek zdominuje wykład | Dwa slajdy twarde: repliki-vs-ruch i bramka; reszta do notatek |
| Studenci mylą GitOps z „IaC w Git" | Zasada „ciągle uzgadniany" jako różnica; porównanie na slajdzie 8 |
| Powtórzenie W07 (podpis, provenance) | Odsyłacz „szczegóły na wykładzie 7", nie omówienie |
| Powtórzenie W12 (retencja) | Slajd 15 kończy się odsyłaczem do procedury odtworzenia |
| Wysoka liczba stron | Cięcie najpierw z tabeli kontraktów (slajd 5), nigdy z przypadku |

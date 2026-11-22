# ZSR 06 — CI/CD i GitOps

Budżet: 45 minut, w tym dyskusja. Plan prowadzenia, nie wynik próby czasowej. Tytuł i bibliografia bez osobnych bloków czasowych. Wszystkie dane liczbowe przypadków są dydaktyczne. Fragmenty kodu na slajdach służą analizie; pominięcia opisano przy przykładach.

## Przebieg

| Minuty | Slajdy / temat i sposób prowadzenia |
|---|---|
| 0–2 | Nawiązanie do wykładu 5. W05 nie zadał pytania otwierającego (konwencja lektur obowiązkowych jest nowsza niż tamta rewizja), więc otwieramy krótkim powrotem do pytania sprawdzającego W05: p95 wzrosło dziesięciokrotnie, ślad pokazał 2100 ms oczekiwania na połączenie — szukamy `pool_max`/`pool_in_use`, a nie czasu wykonania SQL. Jedna minuta na odpowiedzi, bez dyskusji. |
| 2–5 | Objaw z tabeli: poprawka scalona, pipeline zielony, rollout ukończony, a zachowanie bez zmian. Trzy hipotezy studentów zapisujemy na tablicy i nie rozstrzygamy — wróci do nich slajd o digestach. |
| 5–7 | Agenda. |
| 7–10 | CI/delivery/deployment i rozdzielenie deploymentu od wydania; przykład flagi funkcji. |
| 10–13 | Pipeline jako kontrakt etapów; tabela wejść i wyników; odsyłacz do W07. |
| 13–16 | Tożsamość artefaktu: tag zmienny, digest stały; tu rozstrzygamy hipotezy z otwarcia (etykieta v2.0.1 w metrykach, ale build spod wczorajszego taga). |
| 16–18 | Kontekst: od skryptów do GitOps, tabela „sygnał → rozwiązanie → pozostały koszt"; infobox DORA 2025 jako tło, bez moralizowania. |
| 18–21 | Definicja GitOps i cztery zasady; pętla uzgadniania; różnica między „IaC w Git" a „ciągle uzgadniany". |
| 21–24 | selfHeal i prune; ręczna zmiana żyje krótko; rollback poza Gitem nie istnieje; wstrzymanie synchronizacji jako jawna decyzja. |
| 24–27 | Strategie: rolling, blue–green, canary; rollback nie odtwarza danych. |
| 27–29 | Repliki a ruch: przykład 41% → 4 Pody. |
| 29–31 | Bramka kanarka: rachunek progu na tablicy (1,9 pp > 0,5 pp). |
| 31–33 | Expand–contract; kontrakt jako koniec okna rollbacku. |
| 33–35 | Chmura: token OIDC i środowisko z wymaganym zatwierdzeniem. |
| 35–37 | Retencja artefaktów a rollback; odsyłacz do W12. |
| 37–42 | Przypadek: v2 działa, v1 już nie. Decyzja po dyskusji, potem rozwiązanie z notatek. |
| 42–45 | Wnioski i pytanie sprawdzające; jedna odpowiedź studenta na głos. |

Bloki pokrywają ciągły przedział 0–45. Budżet bazowy przedmiotu (5 min problemu, 20 min pojęć, 12 min wariantów, 5 min przypadku, 3 min podsumowania) traktujemy jako proporcję: dyskusja przeplata się przez cały wykład.

## Objaśnienia i założenia

- Skrypty CI w kursie są kontraktami etapów i nie istnieją w tym repozytorium; nie uruchamiać jako demonstracji. W kompletnym pipeline'ie potrzebne są checkout, przygotowanie narzędzi, uwierzytelnienie i przechowanie artefaktów.
- Tabela otwarcia: „wersja w metrykach" pochodzi z etykiety środowiska ustawianej przy starcie Poda. Jeśli Pody zostały wymienione o 10:03, etykieta zmieniła się na v2.0.1 — a zachowanie zostało, bo tag wskazywał na stary digest. To jest most do slajdu o digestach; warto poczekać, aż któryś student to zauważy, zamiast podawać od razu.
- Rachunek kanarka: 90/90 000 = 0,1% dla v1; 200/10 000 = 2,0% dla v2. Różnica 1,9 punktu procentowego przekracza próg 0,5 pp. Niskie p95 nie kompensuje udziału błędów — to dwie różne sygnatury awarii. Przy braku ruchu udział błędów jest nieokreślony (nawiązanie do W05), dlatego próg wymaga minimalnej liczby żądań; liczby 90 000/10 000 są dydaktyczne i celowo duże.
- Fragment AnalysisTemplate jest skrócony: w pełnym szablonie zapytanie PromQL liczy udział błędów tak, jak na wykładzie 5 (najpierw `rate`, potem podział). Warto pokazać to powiązanie jednym zdaniem — bramka kanarka to ten sam PromQL.
- Blue–green: nie obiecujemy „zero downtime za darmo". Koszt to podwójna pojemność i zgodność schematu; przełączenie jest szybkie, ale dane nie cofają się razem z ruchem.
- Chmura: przykład GitHub Actions i środowisk jest ilustracją modelu; te same mechanizmy (tożsamość federacyjna, zatwierdzenia) istnieją w Azure DevOps i GitLab. Nie robimy porównania produktów na slajdach.

## Rozwiązanie przypadku i dyskusja

Okno rollbacku zamknął krok `contract` o 10:20, nie wdrożenie o 10:10 i nie backfill. Cofnięcie deklaracji w Git przywróci v1, ale v1 czyta `amount`, którego nie ma — błąd SQL przy pierwszym odczycie zamówienia. Opcje, w kolejności preferencji: (1) zgodna poprawka v2 naprawiająca błąd biznesowy, (2) odtworzenie kompatybilnego schematu z wiarygodnym przeliczeniem danych, (3) czasowe ograniczenie funkcji. Nie proponować globalnego restore produkcji bez oceny zapisów wykonanych po 10:20 — utrata poprawnych zamówień to drugi incydent.

Wzmocnienie GitOps (nowość tej wersji wykładu): przy `automated.selfHeal` każda ręczna „naprawa" schematu zostanie cofnięta przez kontroler w trakcie incydentu — to samo zjawisko, które na slajdzie 9 uczy dyscypliny, w przypadku staje się pułapką. Jawnym wyjątkiem jest wstrzymanie synchronizacji z zapisem decyzji i późniejszym uzgodnieniem. To rozróżnienie warto wypowiedzieć wprost: GitOps nie zakazuje operacji awaryjnych, żąda tylko, żeby były decyzją z dokumentem, a nie odruchem.

Jak pipeline ma wymusić okres między przełączeniem a `contract`: osobne zmiany (PR z nową kolumną, osobny PR z usunięciem po okresie), kontrola w migracji, weryfikacja wszystkich czytających kolumnę przed usunięciem, brak automatycznego scalania PR-a `contract` bez zgody właściciela danych. Pytanie otwierające na W07 naturalnie wynika z tego przypadku: kto może w ogóle wykonać taką zmianę i jak to udowodnić po fakcie.

## Ustalenia z dokumentacji — sprawdzone 22.11.2026

Te fakty są zależne od wersji i dlatego nie wchodzą na slajdy w całości. Przed kolejnym semestrem trzeba je sprawdzić ponownie.

**Argo CD.** Wspierane serie to 3.3–3.5; seria 3.2 osiągnęła koniec życia 4.08.2026. Dokumentacja Automated Sync Policy podaje wprost: *„Rollback cannot be performed against an application with automated sync enabled"* — to źródło tezy „rollback poza Gitem nie istnieje". Uzgadnianie automatyczne wykonuje się tylko, gdy aplikacja jest OutOfSync; domyślny interwał to `timeout.reconciliation` 120 s plus jitter do 60 s, więc maksymalnie ok. 3 minut; po wykryciu rozbieżności z `selfHeal` ponowna próba następuje po 5 s (`--self-heal-timeout-seconds`). Dla tej samej pary commit-SHA i parametrów automatyczny sync nie powtarza się — chyba że `selfHeal` jest włączone. Prune jest domyślnie wyłączony jako mechanizm bezpieczeństwa i wymaga `automated.prune: true`. Pułapka nowości: pole `syncPolicy.manualDefaults` — gdy jest ustawione, manualny sync dziedziczy z niego wartości pominięte w żądaniu, w tym `prune` domyślnie `true`. Studenci mogą na to trafić w nowszych wersjach; na slajdach zostawiamy `automated` tylko.

**Argo Rollouts.** Rozwój aktywny: v1.9.0 z marca 2026, v1.11.0-rc1 z listopada 2026 (nie ma deprecacji projektu — takie skojarzenie byłoby nieprawdziwe). Kluczowe dla slajdu 11: bez `trafficRouting` `setWeight` jest najlepszym przybliżeniem na Podach — przykład z dokumentacji: 41% przy 10 replikach daje 4 Pody nowej wersji (nie 4,1), bo liczbę całkowitą wybiera się po najmniejszej różnicy. Z routingiem ruchu (`dynamicStableScale`, `setCanaryScale`) procenty są dokładne, a stabilna pula może pozostać pełna przez cały rollout — koszt podobny do blue-green. AnalysisRun kończy się jako Successful, Failed lub Inconclusive i odpowiednio kontynuuje, przerywa albo pauzuje rollout. Nowe dostawcy metryk przyjmowane są już tylko jako pluginy — rdzeń jest zamrożony; dostawca Prometheus zostaje w rdzeniu.

**GitHub Actions.** Dokumentacja OIDC przeniesiona pod `/en/actions/concepts/security/openid-connect`; link w wersji z 26.09.2026 nadal jest poprawny. Warunek zaufania (`sub`) obejmuje repozytorium, referencję (gałąź/ref), a dla jobów ze środowiskiem — nazwę środowiska. Zmiana warta omówienia: repozytoria utworzone po 15.07.2026 (i te, które włączyły opcję) dostają niezmienne identyfikatory właściciela i repozytorium w `sub`. Środowiska: required reviewers do 6 osób/zespołów, jedno zatwierdzenie wystarcza; wait timer do 30 dni; polityka gałęzi i tagów; zadanie czekające na zatwierdzenie ma etykietę „Waiting" i po 30 dniach niepowodzenie automatycznie; sekrety środowiska są dostępne dopiero po przejściu reguł ochrony. Plan darmowy: część funkcji środowisk działa tylko w repozytoriach publicznych — warto wspomnieć, jeśli studenci ćwiczą na kontach prywatnych.

**DORA 2025.** Liczba 16,2% (wdrażanie na żądanie, kilka razy dziennie) pochodzi z Fig. 12 raportu *State of AI-assisted Software Development 2025* (ok. 5 000 ankietowanych, czerwiec–lipiec 2025). Zweryfikowano przez omówienie danych raportu; przed użyciem w kolejnym semestrze sprawdzić w samym raporcie (dora.dev), bo liczby mogą być skorygowane w wydaniu drukowanym. Kontekst z tego samego źródła, który zostaje w notatkach: największa grupa (31,5%) wdraża raz w tygodniu–miesiącu, 55,4% rzadziej niż raz w tygodniu.

**GitOps zarządzany — materiał pominięty na slajdach.** Decyzja prowadzącego (22.11.2026): wątek chmurowy W06 to OIDC i środowisko; cykl życia rozszerzeń GitOps zostaje tutaj. Rozszerzenie AKS/Arc `microsoft.flux` jest aktualne (listopad 2026: v1.26.5 na Flux v2.9.6, wsparcie dla najnowszej wersji i dwóch poprzednich), natomiast rozszerzenie oparte o Flux v1 zostało ogłoszone do wycofania w styczniu 2023 i wycofane 24.05.2025. Upstream Flux żyje i rozwija się: 2.10 GA z października 2026 (SPIFFE, alerting API w v1), wersja 2.7 osiągnęła koniec wsparcia. Wniosek dla studentów: cykl życia rozszerzenia zarządzanego jest niezależny od cyklu życia projektu upstream; deklaracje w Git pozostają stabilnym interfejsem nawet wtedy, gdy zmienia się opakowanie dostawcy.

**Materiał na przyszłość.** ApplicationSet i wzorzec app-of-apps (skalowanie GitOps na wiele klastrów) — realny temat, świadomie poza wykładem; odpowiedź jednym zdaniem, gdy student zapyta. Sekrety w GitOps (External Secrets Operator, SOPS) — wchodzą na W07 w kontekście sekretów.

## Pytania kontrolne

1. **Dlaczego ponowny build tego samego commita nie daje tego samego obrazu i dlaczego tag nie jest tożsamością artefaktu?** — Build nie jest deterministyczny: wersje zależności, obrazy bazowe, czasy i ścieżki budowania mogą się różnić, więc zawartość, a z nią digest, wychodzi inna. Tag jest wskaźnikiem, który rejest może przestawić na inny obraz (dokumentacja Kubernetes: „Tags can be moved to point to different images"); digest wynika z zawartości i jest stały. Dlatego promocja przenosi digest, a konfigurację trzyma osobno.
2. **Zespół awaryjnie zmienia limit CPU przez `kubectl` przy włączonym `selfHeal`. Co się stanie i co jest trwałą poprawką?** — Kontroler wykryje rozbieżność i cofnie zmianę (uzgadnianie co ok. 2–3 min, ponowna próba po 5 s). Trwała poprawka to zmiana deklaracji w Git; jeśli ktoś musi działać ręcznie, wstrzymuje synchronizację jako jawną decyzję z zapisem i potem uzgadnia repo z rzeczywistością.
3. **Kiedy `kubectl rollout undo` jest bezużyteczne, mimo że obraz v1 wciąż jest w rejestrze?** — Gdy zamknięto okno rollbacku po stronie danych: krok `contract` usunął kolumnę (albo API/kolejka przestały rozumieć stare pole). v1 uruchomi się i nie umie czytać obecnych danych. Obraz jest dostępny, ale wersja nie jest zgodna z obecnym schematem — dlatego kolejność expand → przełączenie → contract decyduje o możliwości powrotu.

## Kontrola czasu

Przy opóźnieniu cięcie w kolejności: (1) czytanie składni AnalysisTemplate — zostaw sam rachunek progu, (2) dygresje o wersjach Argo CD i `manualDefaults`, (3) drugie pytanie o OIDC. Zachować rachunek kanarka, slajd o oknie rollbacku i przypadek — to oś wykładu. Otwarcie (0–2) można ścisnąć do 1 minuty, ale nie usuwać: spina W05 z W06.

# ZSR 05 — Obserwowalność

Budżet: 45 minut, w tym dyskusja. Plan prowadzenia, nie wynik próby czasowej. Tytuł i bibliografia bez osobnych bloków czasowych. Wszystkie dane liczbowe przypadków są dydaktyczne. Fragmenty kodu na slajdach służą analizie; pominięcia opisano przy przykładach.

## Przebieg

| Minuty | Slajdy / temat i sposób prowadzenia |
|---|---|
| 0–5 | Objaw z tabeli i trzy hipotezy studentów. Zapisujemy je na tablicy i nie rozstrzygamy. |
| 5–7 | Agenda i monitoring a obserwowalność. |
| 7–10 | Trzy sygnały i reguła wyboru między nimi. |
| 10–13 | OpenTelemetry: po co powstał wspólny standard. |
| 13–16 | Prometheus: model pull, TSDB, rola Alertmanagera; typy metryk na czterech liniach przykładu. |
| 16–20 | PromQL: `rate`, kolejność `rate`/`sum` i udział błędów. |
| 20–25 | p95 z histogramu; rachunek na tablicy. |
| 25–28 | Kardynalność i reguła „co nie jest etykietą”. |
| 28–32 | Ślad i log tej samej operacji; exemplars i propagacja kontekstu przez kolejkę. |
| 32–35 | Collector i backend zarządzany. |
| 35–37 | Retencja i próbkowanie. |
| 37–42 | Przypadek: diff, decyzja i pomiar potwierdzający; dyskusja ograniczona do jednej hipotezy. |
| 42–45 | Wnioski, pytanie sprawdzające i odpowiedź studenta. |

Bloki pokrywają ciągły przedział 0–45. Budżet bazowy przedmiotu (5 min problemu, 22 min pojęć, 10 min przykładu, 5 min pytań, 3 min podsumowania) traktujemy jako proporcję, nie sztywne cięcie: dyskusja studentów przeplata się przez cały wykład, więc pytania nie tworzą jednego bloku. Tytuł i bibliografia nie mają osobnych bloków czasowych.

Slajd o OpenTelemetry jest nowy i zajmuje 3 minuty z bloku pojęć. Warto go poprowadzić jako odpowiedź na pytanie „skoro są trzy sygnały, to czym je wytwarzamy?”. Sens jest taki: przed OTel każdy producent miał własnego agenta i własny format, więc zmiana dostawcy oznaczała ponowną instrumentację, a dwa konkurencyjne projekty — OpenTracing i OpenCensus — zamiast rozwiązać problem, same go komplikowały. OTel powstał w 2019 z ich połączenia i jest projektem CNCF.

Trzy rzeczy warte powiedzenia wprost. Po pierwsze, OTel **nie jest backendem** — opisuje generowanie, eksport i zbieranie telemetrii, a przechowywanie i wizualizację zostawia innym narzędziom; dlatego Prometheus i Grafana z dalszych slajdów nie konkurują z OTel, tylko go uzupełniają. Po drugie, dwie zasady projektu to własność danych i jeden zestaw API. Po trzecie — i to jest najczęstsze nieporozumienie — **neutralność nie obejmuje backendu**: zapytania, dashboardy i alerty nadal wiążą się z wybranym narzędziem. Warto to powiedzieć, bo studenci wychodzą z „wdrożyliśmy OTel, więc nie mamy lock-inu”, co nie jest prawdą w warstwie analizy.

Jeżeli dyskusja się rozciąga, cięcie robimy w kolejności: (1) dygresja o histogramach natywnych, (2) czytanie składni PromQL na slajdzie 9, (3) drugie pytanie o kardynalność. Slajdu z przypadkiem nie skracamy — jest jedynym miejscem, w którym studenci sami łączą trzy sygnały.

## Objaśnienia i założenia

Nie powtarzamy definicji SLO z wykładu 11; tutaj instrumentacja i diagnoza. Histogram pokazujemy celowo jako klasyczny, z jawnymi przedziałami, bo ma jawniejszy rachunek. Dokumentacja Prometheusa zaleca natywne, jeśli instrumentacja je wspiera, ale to nie jest darmowa zamiana — szczegóły w sekcji o ustaleniach z dokumentacji. `rate` liczymy na każdym szeregu przed agregacją, bo tylko wtedy obsługiwany jest reset pojedynczej instancji. Dane śladu opisują jedno żądanie, więc nie reprezentują p95; percentyl został policzony osobno w metrykach i to rozróżnienie warto powiedzieć wprost. Diagram puli zakłada instrumentację czasu oczekiwania, która nie pojawia się automatycznie — trzeba ją dodać świadomie.

Przy próbkowaniu nie mówimy, że próbka jest z założenia niereprezentatywna. Dokumentacja OpenTelemetry opisuje próbkę jako reprezentanta populacji i podaje, że przy dużym ruchu nawet 1% dobrze opisuje pozostałe 99%, a reprezentatywność da się zweryfikować matematycznie. Realne ograniczenie jest inne: sposób próbkowania decyduje o tym, co wypada — przy równomiernym próbkowaniu rzadkie błędy mogą nie trafić do próbki, dlatego błędy często próbkuje się inną regułą niż ruch poprawny. To rozróżnienie jest sednem slajdu o retencji.

Kolejność „najpierw `rate`, potem `sum`” jest najczęstszym błędem w zapytaniach, dlatego pokazujemy obie wersje i pytamy o różnicę, zamiast podawać gotową regułę.

## Rozwiązanie przypadku i dyskusja

Zmniejszenie puli z 20 do 5 wyjaśnia wzrost p95 przy niezmienionym ruchu, błędach i CPU: żądania czekają na wolne połączenie, nie na procesor. Potwierdzenie: czas oczekiwania w puli, wykorzystanie puli, p95 oraz obciążenie po stronie bazy.

Pułapka rachunkowa, którą warto pokazać: 10 replik × 20 połączeń = 200, czyli dokładnie limit bazy. Powrót do wartości 20 wyczerpuje limit, gdy dołączy druga usługa. Bezpieczna odpowiedź nie brzmi „przywróć 20”, lecz „ustal budżet połączeń z zapasem dla pozostałych klientów i sprawdź, czy wartość 5 nie była celowa”.

Hipoteza konkurencyjna: wyciek połączeń albo długo otwarte transakcje. Odrzucamy ją, patrząc na rozkład czasu zajęcia połączenia i liczbę połączeń otwartych i zamykanych w czasie — jeden ślad tego nie rozstrzyga. `pool_in_use = pool_max = 5` przy 50 aktywnych połączeniach z limitem 200 wskazuje na ograniczenie po stronie aplikacji, nie bazy.

Przykład dotyczy usługi `orders-api` z systemu zamówień, tego samego, który przewija się przez cały kurs: API, worker, kolejka `orders` i baza. Przy slajdzie o propagacji kontekstu warto przypomnieć, że worker pobiera wiadomość z kolejki, więc jego ślad nie jest dzieckiem śladu API — stąd relacja `links`.

## Ustalenia z dokumentacji — sprawdzone 15.11.2026

Te fakty są zależne od wersji i dlatego nie wchodzą na slajdy w całości. Przed kolejnym semestrem trzeba je sprawdzić ponownie.

**Histogramy natywne.** Stabilne od Prometheus 3.8.0 (grudzień 2025); 3.13 (lipiec 2026) to pierwsze LTS z tym wsparciem jako stabilnym. Wciąż wymagają jawnego `scrape_native_histograms` — od 3.9 flaga `--enable-feature=native-histograms` jest no-opem, a w wersji 4 oba ustawienia mają domyślnie być włączone. Kluczowe ograniczenie praktyczne: **ekspozycja działa wyłącznie w formacie protobuf**. Format tekstowy Prometheusa nie został rozszerzony i nie ma takich planów, a wsparcie w OpenMetrics text pozostaje niezaimplementowane. Oficjalne biblioteki instrumentacji wspierają natywne tylko w Go, Javie i Rust (stan na 15.06.2026); Python nie ma implementacji, a w Kubernetes to funkcja alfa (v1.36, domyślnie wyłączona). Dlatego zdanie na slajdzie mówi o protobufie — student, który spróbuje wystawić natywne histogramy w formacie tekstowym, po prostu nie zobaczy danych.

**Błąd estymacji kwantyla.** Liczby na slajdzie pochodzą z dokumentacji Prometheusa. Dla rozkładu o rzeczywistym p95 = 220 ms: histogram klasyczny z granicami 0,1/0,2/0,3/0,45 s daje ok. 295 ms (prawda mieści się między 200 a 300 ms), a histogram natywny o współczynniku 1,1 daje ok. 228 ms (prawda między 210 a 229 ms). Warto podkreślić wniosek z tego przykładu: klasyczny histogram w tym przypadku nadal poprawnie rozstrzyga, czy mieścimy się w SLO 300 ms, ale mylnie sugeruje, że jesteśmy blisko jego przekroczenia. To dobra ilustracja różnicy między „czy przekraczamy próg” a „jak daleko od progu jesteśmy”.

**Kolejność `rate` przed `sum`.** Dokumentacja Prometheusa mówi wprost: przy łączeniu `rate()` z agregacją zawsze najpierw `rate()`, potem agregacja, bo inaczej funkcja nie wykryje resetu countera po restarcie celu. To dokładnie teza ze slajdu 9. Warto dodać, że `rate()` ekstrapoluje nachylenie do granic okna, więc wynik nie jest średnią z próbek; przy szeregach zaczynających się lub kończących w oknie ekstrapolacja jest ograniczana. Inkrementy, które wydarzyły się po ostatnim scrape przed resetem, przepadają bezpowrotnie.

**Exemplars.** To ogniwo między metryką a śladem, którego wcześniej w wykładzie brakowało. Exemplar to etykieta przy przedziale histogramu niosąca `trace_id` i `span_id`, dzięki czemu ze skoku na wykresie przechodzimy do konkretnego żądania bez porównywania znaczników czasu. Ograniczenie: exemplars nie są wspierane w tekstowym formacie ekspozycji Prometheusa — działają w OpenMetrics i protobuf. Podobnie jak przy histogramach natywnych: mechanizm jest, ale wymaga właściwego formatu ekspozycji. Warto o tym powiedzieć, bo student zobaczy exemplars w dokumentacji i zdziwi się, że nie działają na jego endpoincie.

**Scrape nieudany a brak danych.** Slajd mówi, że brak odpowiedzi na scrape to nie zero. Warto rozwinąć: Prometheus w ogóle nie wyzwala alertu, gdy zapytanie nie zwraca danych — to cicha awaria. Standardowe `up == 0` wykrywa spadek celu, ale nie wykrywa pojedynczych instancji, które zniknęły z szeregu, ani metryki, która przestała istnieć. Do tego służą `absent_over_time()` i `present_over_time`, a przy alertowaniu w Grafanie jawne ustawienie zachowania przy braku danych. Jeśli zostanie czas, to jest dobry materiał na pytanie do studentów: „który alert nie zadziała, gdy target zniknie?”.

**Wzorce wdrożenia Collectora.** Slajd pokazuje Collector jako jeden blok. Dokumentacja OpenTelemetry rozróżnia agenta (przy aplikacji) i gateway (centralny), a także wzorzec agent–gateway. Różnica jest operacyjna, nie kosmetyczna: próbkowanie tail-based wymaga gatewaya, bo tylko on widzi kompletny ślad. Warto wspomnieć jednym zdaniem, że wybór wzorca wynika z tego, gdzie trzeba podjąć decyzję o danych.

**Materiał na przyszłość.** Profile wchodzą jako czwarty sygnał — alfa publiczna od marca 2026, z profilerem eBPF działającym bez zmian w kodzie. Dokumentacja wprost odradza użycie produkcyjne na tym etapie. Nie rozwijamy tego tematu w wykładzie; nadaje się na krótkie „co się zmienia” w podsumowaniu albo na pytanie studenta.

## Kontrola czasu

Nie rozbudowuj porównania backendów ani listy eksporterów. Ogranicz dygresję o histogramach natywnych i nie czytaj całej składni PromQL — zachowaj wspólną diagnozę metryka–ślad–log, bo to jest cel wykładu.

Dwie rzeczy doszły po researchu i mieszczą się w bloku 27–32 praktycznie bez kosztu: exemplars jako jedno zdanie łączące metrykę ze śladem oraz liczby o błędzie estymacji kwantyla. Jeżeli czas jest bardzo napięty, exemplars skracamy do zdania „exemplar niesie `trace_id` przy przedziale histogramu”, a szczegóły zostawiamy w notatkach — ale nie usuwamy tego punktu, bo bez niego wykład nie odpowiada na pytanie, jak przejść od metryki do śladu.

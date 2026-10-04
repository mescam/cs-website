#import "@preview/typslides:1.3.2": *
#import "zsr-theme.typ": *
#import emoji: cloud
#show: typslides.with(ratio: "16-9", theme: kolor-pp, font: "DejaVu Sans", font-size: 20pt, show-progress: true, show-page-numbers: true)
#set text(lang: "pl")
#front-slide(title: "HA, backup i disaster recovery", subtitle: [Domeny awarii i mierzalne odtworzenie usługi], authors: "mgr inż. Jakub Woźniak", info: [Zarządzanie Systemami Rozproszonymi · Semestr zimowy 2026/27])
#slide(title: [Ciągłość i odtwarzanie])[
#data-table(3,
[Mechanizm],
[Chroni przed],
[Nie wystarcza przy],
[HA],
[Awarią części komponentów],
[Wspólnym błędzie aplikacji],
[Replikacja],
[Utratą jednej kopii],
[Powielonym DELETE],
[Backup / historia],
[Utratą poprawnego stanu],
[Braku procedury restore],
)
- Zakres ochrony musi wskazywać konkretny scenariusz awarii.
#src[#link("https://docs.cloud.google.com/architecture/dr-scenarios-planning-guide")[Google Cloud — DR planning]]
]
#slide(title: [HA: repliki w różnych domenach awarii])[
#flow[Load balancer][API w strefie A / B][DB primary / standby]
- Health check odsuwa niedostępny endpoint.
- Pozostałe repliki muszą mieć pojemność na ruch po awarii.
- Failover bazy: wybór nowego lidera i odcięcie starego od zapisów.
- Dwa niezależnie zapisujące primary mogą spowodować rozbieżność danych.
#src[#link("https://www.postgresql.org/docs/current/warm-standby.html")[PostgreSQL — Standby servers]]
]
#slide(title: [Dostępność zależności: model uproszczony])[
#defblock[Trzy elementy wymagane jednocześnie][A = A1 × A2 × A3; przy niezależnych awariach i 99,9% każdego: A = 0,999³ ≈ *99,7003%*.]
- Wspólne przyczyny awarii naruszają założenie niezależności.
- Redundancja, cache i kolejka zmieniają model zachowania.
- SLA składników nie można po prostu przepisać jako SLO aplikacji.
#src[Obliczenie dydaktyczne modelu szeregowego, nie prognoza dostępności tego systemu.]
]
#slide(title: [RTO i RPO])[
#data-table(3,
[Cel],
[Pytanie],
[Przykład],
[RTO],
[Jak szybko przywrócić wymagany poziom usługi?],
[Do 45 min od zakłócenia],
[RPO],
[Jak stary może być ostatni odzyskany stan?],
[Do 5 min utraty zapisów],
)
- Cele odróżnić od zmierzonych wyników ćwiczenia.
- „Usługa przywrócona”: także poprawne dane, dostęp i zdolność realizacji.
#src[#link("https://csrc.nist.gov/pubs/sp/800/34/r1/final")[NIST SP 800-34 Rev. 1]]
]
#slide(title: [Oś czasu: zmierzona utrata danych])[
#flow[09:57: ostatni odzyskiwalny zapis][10:00: awaria][10:40: usługa]
- Luka danych: 3 min; cel RPO = 5 min → spełniony w tym teście.
- Przerwa usługi: 40 min; cel RTO = 45 min → spełniony.
- Mierzyć ostatni faktycznie odzyskany zapis, nie sam czas uruchomienia backupu.
#src[Przykład zakłada, że zapisy z 09:57–10:00 nie są odzyskiwalne inną drogą.]
]
#slide(title: [Składowe czasu odtworzenia])[
#data-table(2,
[Etap sekwencyjny],
[Czas],
[Wykrycie + decyzja],
[5 + 5 min],
[Przygotowanie infrastruktury],
[8 min],
[Odtworzenie danych],
[12 min],
[Walidacja i uruchomienie aplikacji],
[8 min],
[Przełączenie ruchu],
[2 min],
[Razem],
[40 min],
)
- Zapas do RTO 45 min: tylko 5 min.
- Część prac można zrównoleglić dopiero po sprawdzeniu zależności.
]
#slide(title: [PostgreSQL: PITR])[
#flow[Base backup][Archiwum WAL][Replay do punktu][Baza po restore]
- Potrzebny spójny backup bazowy i wymagane segmenty WAL.
- Zwykły dump nie daje samodzielnie odtworzenia do dowolnej sekundy.
- Przerwa w archiwizacji może ograniczyć odzyskiwalny punkt.
#src[#link("https://www.postgresql.org/docs/current/continuous-archiving.html")[PostgreSQL — Continuous archiving and PITR]]
]
#slide(title: [Replikacja synchroniczna i asynchroniczna])[
#data-table(3,
[Tryb],
[Potwierdzenie zapisu],
[Kompromis],
[Synchroniczny],
[Czeka na wybrany poziom potwierdzenia repliki],
[Opóźnienie i zależność dostępności],
[Asynchroniczny],
[Nie czeka na replikę],
[Możliwa utrata ostatnich zapisów],
)
- Gwarancja zależy od konfiguracji potwierdzeń i scenariusza awarii.
- Oba tryby mogą odtworzyć na replice błędne usunięcie danych.
#src[#link("https://www.postgresql.org/docs/current/warm-standby.html")[PostgreSQL — Streaming replication]]
]
#slide(title: [Test restore: warunki zaliczenia])[
#data-table(2,
[Obszar],
[Dowód],
[Dane],
[Spójność, liczby rekordów i przykładowe zamówienia],
[Aplikacja],
[Zapis i realizacja testowego zamówienia],
[Dostęp],
[Klucze, role, DNS i sekrety dostępne],
[Czas],
[Pomiar całej ścieżki do przywrócenia usługi],
)
- Środowisko odizolowane od produkcyjnych płatności i wysyłek.
- Wynik, brakujące kroki, właściciel poprawki i termin kolejnego testu.
]
#slide(title: [#cloud Strategie odtworzenia regionu])[
#data-table(3,
[Strategia],
[Gotowość zapasowa],
[Koszt / czas],
[Backup–restore],
[Kopie i deklaracje],
[Mniejszy stały koszt, dłuższy start],
[Warm standby],
[Działający mniejszy system],
[Koszt gotowości i skalowania],
[Aktywne regiony],
[Ruch w więcej niż jednym],
[Złożoność spójności i routingu],
)
#src[#link("https://docs.cloud.google.com/architecture/dr-scenarios-planning-guide")[Google Cloud — Disaster recovery planning]]
]
#slide(title: [#cloud Zależności poza bazą])[
#flow[Repozytorium + obrazy][Tożsamości + klucze][DNS + sieć][Restore]
- Kopia zaszyfrowana kluczem dostępnym tylko w utraconym regionie może być nieużyteczna.
- Control plane potrzebny do utworzenia zasobów może być niedostępny.
- Próbę prowadzić z uwzględnieniem niedostępności regionu podstawowego.
]
#slide(title: [Przypadek: DELETE o 09:40])[
#defblock[Dane][Błędnie usunięto 200 zamówień. Wykrycie o 09:50. Replika zawiera to samo usunięcie. Od 09:40 przyjęto 340 nowych zamówień. Dostępne base backup i pełne WAL.]
- Do jakiego punktu odtworzyć dane?
- Czy można podmienić produkcję bazą sprzed DELETE?
- Jak odzyskać brakujące rekordy bez utraty nowych i podwójnej realizacji?
]
#slide(title: [Źródła i lektury])[
#text(size: 16pt)[
- #link("https://csrc.nist.gov/pubs/sp/800/34/r1/final")[NIST SP 800-34 Rev. 1 — Contingency Planning]
- #link("https://www.postgresql.org/docs/current/continuous-archiving.html")[PostgreSQL — Continuous archiving and PITR]
- #link("https://www.postgresql.org/docs/current/warm-standby.html")[PostgreSQL — Standby servers]
- #link("https://docs.cloud.google.com/architecture/dr-scenarios-planning-guide")[Google Cloud — DR planning guide]
]
#src[Dokumentacja sprawdzona: 26.09.2026. Dane przypadków: przykłady dydaktyczne.]
]

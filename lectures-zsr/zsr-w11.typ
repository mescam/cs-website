#import "@preview/typslides:1.3.2": *
#import "zsr-theme.typ": *
#import emoji: cloud
#show: typslides.with(ratio: "16-9", theme: kolor-pp, font: "DejaVu Sans", font-size: 20pt, show-progress: true, show-page-numbers: true)
#set text(lang: "pl")
#front-slide(title: "SRE i incydenty", subtitle: [Pomiar niezawodności, budżet błędów i decyzje], authors: "mgr inż. Jakub Woźniak", info: [Zarządzanie Systemami Rozproszonymi · Semestr zimowy 2026/27])
#slide(title: [SLI: przyjęcie a realizacja zamówienia])[
#data-table(3,
[Etap],
[Możliwy SLI],
[Pominięte ryzyko],
[API],
[Udział poprawnie przyjętych żądań],
[Zamówienie utknęło później],
[Realizacja],
[Udział przyjętych zamówień ukończonych do 60 s],
[Problemy przed przyjęciem],
[Poprawność],
[Udział realizacji bez błędnego skutku],
[Wymaga weryfikacji biznesowej],
)
- Jeden wskaźnik nie opisuje całej jakości usługi.
#src[#link("https://sre.google/workbook/implementing-slos/")[Google SRE — Implementing SLOs]]
]
#slide(title: [Definicja pomiaru])[
#defblock[SLI realizacji][Liczba przyjętych zamówień ukończonych poprawnie do 60 s / liczba przyjętych zamówień podlegających ocenie.]
- Kohorta według czasu przyjęcia; ocena po upływie 60 s.
- Nieukończone zamówienie pozostaje w mianowniku.
- Powtórzenie z tym samym kluczem operacji nie tworzy kolejnego zamówienia.
- Okno i wyłączenia ustalone przed pomiarem, nie po incydencie.
]
#slide(title: [SLO i budżet błędów])[
#defblock[Przykład miesięczny][SLO = 99,9%. Oceniono 1 000 000 zamówień. Dopuszczalne złe zdarzenia: 1 000 000 × 0,001 = *1000*.]
- 600 przekroczyło 60 s lub zakończyło się niepoprawnie.
- SLI = 999 400 / 1 000 000 = *99,94%*.
- Zużyto 60% budżetu; pozostało *400 zdarzeń*.
#src[#link("https://sre.google/workbook/implementing-slos/")[Google SRE — Implementing SLOs]]
]
#slide(title: [Budżet zdarzeń i budżet czasu])[
#data-table(3,
[Definicja SLO],
[99,9% w 30 dniach],
[Pułapka],
[Czasowa dostępność],
[43,2 min niedostępności],
[Każda minuta ma równą wagę],
[Dobre zdarzenia],
[0,1% ocenianych zdarzeń],
[Waga okresu zależy od ruchu],
)
- 30 × 24 × 60 × 0,001 = 43,2 min.
- Awaria w szczycie może zużyć dużo budżetu zdarzeń w krótkim czasie.
- Nie zamieniać automatycznie liczby błędów na minuty.
]
#slide(title: [Burn rate: tempo zużycia budżetu])[
#defblock[Definicja][Burn rate = udział złych zdarzeń w oknie / dopuszczalny udział złych zdarzeń.]
- SLO 99,9%; aktualnie 2% złych zdarzeń.
- Burn rate = 0,02 / 0,001 = *20*.
- Przy stałym ruchu i takim błędzie pełny budżet 30 dni wystarczy na 36 h.
#sm[30 dni / 20 = 1,5 dnia. Prognoza wymaga założeń o przyszłym ruchu i błędach.]
#src[#link("https://sre.google/workbook/alerting-on-slos/")[Google SRE — Alerting on SLOs]]
]
#slide(title: [Dwa okna alertowania])[
#data-table(3,
[Pomiar burn rate],
[Ostatnia godzina],
[Ostatnie 5 min],
[Incydent aktywny],
[20],
[22],
[Incydent już ustąpił],
[20],
[0,5],
)
- Dłuższe okno: istotny wpływ; krótsze: problem trwa.
- Przykładowa reguła: oba okna powyżej 14,4 → wezwanie dyżurnego.
- Osobna wolniejsza reguła wykrywa długotrwałe, mniejsze pogorszenie.
#src[#link("https://sre.google/workbook/alerting-on-slos/")[Google SRE — Multiwindow, multi-burn-rate alerts]]
]
#slide(title: [Polityka wykorzystania budżetu])[
#data-table(2,
[Stan],
[Przykładowa decyzja zespołu],
[Budżet dostępny, stabilne pomiary],
[Standardowy rytm zmian],
[Szybkie zużywanie budżetu],
[Wstrzymanie ryzykownej promocji],
[Budżet wyczerpany],
[Priorytet napraw i ograniczenia wpływu],
)
- Polityka uzgodniona z właścicielem usługi.
- Poprawka incydentu i pilna poprawka bezpieczeństwa nie są zwykłym wydaniem funkcji.
#src[#link("https://sre.google/workbook/error-budget-policy/")[Google SRE — Error budget policy]]
]
#slide(title: [Role podczas incydentu])[
#data-table(3,
[Rola],
[Zadanie],
[Ryzyko bez podziału],
[Koordynator],
[Priorytety i decyzje],
[Kilka sprzecznych zmian naraz],
[Operator],
[Wykonanie i weryfikacja zmian],
[Brak kontroli skutków],
[Komunikacja / zapis],
[Wpływ, oś czasu, aktualizacje],
[Utrata ustaleń],
)
#sm[W małym zespole role można łączyć, ale odpowiedzialności nadal powinny być jawne.]
#src[#link("https://sre.google/sre-book/managing-incidents/")[Google SRE — Managing incidents]]
]
#slide(title: [Incydent: utrata dostępu do bazy])[
#data-table(2,
[Czas],
[Fakt / działanie],
[10:00],
[Zmiana reguły sieciowej],
[10:02],
[API: błędy połączeń; 30% żądań nieudanych],
[10:04],
[Koordynator; wstrzymanie kolejnych zmian],
[10:06],
[Przywrócenie poprzedniej reguły],
[10:08],
[Spadek błędów; sprawdzanie zaległych operacji],
)
- Ograniczenie wpływu może wyprzedzać pełną analizę przyczyny.
- Nie zamykać incydentu wyłącznie dlatego, że komenda zakończyła się sukcesem.
]
#slide(title: [#cloud SLA dostawcy i SLO aplikacji])[
#flow[API][Sieć][Baza zarządzana]
- SLA: zobowiązanie usługowe o określonym zakresie i warunkach.
- SLO aplikacji: cel mierzony na operacjach użytkownika.
- Błędna reguła klienta może naruszać SLO mimo działającej bazy dostawcy.
#src[#link("https://sre.google/sre-book/service-level-objectives/")[Google SRE — Service Level Objectives]]
]
#slide(title: [#cloud Komunikacja przy niepewnej przyczynie])[
#exblock[Przykład komunikatu][Od 10:02 część żądań zamówień kończy się błędem. Przywracamy poprzednią konfigurację połączeń. Trwa weryfikacja wpływu na zapisane zamówienia. Następna aktualizacja o 10:15.]
- Status dostawcy: jedno źródło informacji, nie dowód przyczyny własnego incydentu.
- Oddzielać fakty, hipotezy i przewidywany czas kolejnej informacji.
]
#slide(title: [Postmortem: działanie sprawdzalne])[
#data-table(3,
[Obserwacja],
[Działanie],
[Dowód wykonania],
[Reguła odcięła API od DB],
[Test łączności przed promocją],
[Test wykrywa celowo złą regułę],
[Alarm zauważono po 2 min],
[Przegląd opóźnienia alertu],
[Pomiar na ćwiczeniu],
[Nieznany zakres utraty],
[Korelacja przyjęcia i zapisu],
[Raport zgodności zamówień],
)
- Każde działanie: właściciel i termin.
#src[#link("https://sre.google/workbook/postmortem-culture/")[Google SRE — Postmortem culture]]
]
#slide(title: [Zadanie: budżet po kolejnym incydencie])[
#defblock[Dane][Przed incydentem: 600 złych zdarzeń. Incydent: 15 min, 100 zamówień/min, 20% złych. Prognoza całego miesiąca: 1 000 000 zamówień, SLO 99,9%.]
- Ile zdarzeń dodał incydent? Ile budżetu pozostało w prognozie?
- Czy sam pozostały budżet uzasadnia natychmiastowe wznowienie zmian?
]
#slide(title: [Źródła i lektury])[
#text(size: 16pt)[
- #link("https://sre.google/workbook/implementing-slos/")[Google SRE — Implementing SLOs]
- #link("https://sre.google/workbook/alerting-on-slos/")[Google SRE — Alerting on SLOs]
- #link("https://sre.google/workbook/error-budget-policy/")[Google SRE — Error budget policy]
- #link("https://sre.google/sre-book/managing-incidents/")[Google SRE — Managing incidents]
- #link("https://sre.google/workbook/postmortem-culture/")[Google SRE — Postmortem culture]
]
#src[Dokumentacja sprawdzona: 26.09.2026. Dane przypadków: przykłady dydaktyczne.]
]

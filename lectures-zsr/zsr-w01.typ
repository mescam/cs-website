// Wykład 1: DevOps i automatyzacja
#import "@preview/typslides:1.3.2": *
#import "zsr-theme.typ": *
#import emoji: cloud

#set text(lang: "pl")
#show: typslides.with(
  ratio: "16-9", theme: kolor-pp, font: "DejaVu Sans", font-size: 20pt,
  show-progress: true, show-page-numbers: true,
)

#front-slide(
  title: "DevOps i automatyzacja",
  subtitle: [Odpowiedzialność za usługę, feedback i małe zmiany],
  authors: "mgr inż. Jakub Woźniak",
  info: [Zarządzanie Systemami Rozproszonymi · Semestr zimowy 2026/27],
)

#slide(title: [Zarządzanie Systemami Rozproszonymi])[
  #cols[
    #defblock[Forma][
      - semestr zimowy 2026/27
      - 15 spotkań × maks. 45 minut
      - wykład i laboratorium
    ]
  ][
    #exblock[Oś kursu][
      - zmiana
      - wdrożenie
      - obserwacja
      - reakcja na awarię
    ]
  ]

  #align(center)[
    Od kontenera i klastra, przez automatyzację oraz obserwowalność,
    do odporności i odtworzenia usługi.
  ]
]

#slide(title: [Prowadzący])[
  #defblock[mgr inż. Jakub Woźniak][
    - Informatyka · specjalność: systemy rozproszone
    - Politechnika Poznańska · Wydział Informatyki · 2017
    - #link("mailto:jakub.wozniak@cs.put.poznan.pl")[#text("jakub.wozniak@cs.put.poznan.pl")]
  ]

  #exblock[Praca zawodowa][
    CTO for Software Services · IBM Consulting
  ]

  #sm[IBM Consulting nie jest organizatorem ani partnerem przedmiotu.]
]

#slide(title: [System zamówień jako wspólny przykład kursu])[
  #flow[Klient][API][Baza: order + outbox]
  #v(10pt)
  #flow[Outbox][Publisher][Kolejka][Worker → baza]
  - Zamówienie i outbox: jedna transakcja; 202 po trwałym zapisie.
  - Publisher publikuje zapisane zdarzenia; możliwe powtórzenia.
  - Worker pobiera wiadomość, zapisuje skutek, potem potwierdza odbiór.
  #src[#link("https://microservices.io/patterns/data/transactional-outbox")[C. Richardson — Transactional outbox.]]
]

#slide(title: [Plan wykładu])[
  - Awaria po zmianie konfiguracji
  - DevOps jako sposób organizacji odpowiedzialności
  - CALMS, małe zmiany i pętla feedbacku
  - #cloud Usługa zarządzana a odpowiedzialność zespołu
  - Retry zamówienia i idempotencja
  - Decyzja operacyjna
]

#slide(title: [Awaria o 10:05])[
  #alertblock[Sygnał][
    Po wdrożeniu nowej konfiguracji worker nie łączy się z kolejką. API nadal
    zapisuje zamówienia w bazie, lecz zlecenia nie są realizowane.
  ]

  #cols[
    #defblock[Co wiemy][
      - rośnie liczba wiadomości oczekujących;
      - klient może nadal dostać potwierdzenie zamówienia;
      - zmiana objęła konfigurację workera.
    ]
  ][
    #alertblock[Czego jeszcze nie wiemy][
      - czy problem dotyczy wersji workera, uprawnień czy kolejki;
      - czy poprzednia wersja jest zgodna z zaległymi wiadomościami;
      - czy można bezpiecznie kontynuować wdrożenie.
    ]
  ]
]

#slide(title: [DevOps: współodpowiedzialność za usługę])[
  #cols[
    #alertblock[Przekazanie][
      Zespół przekazuje artefakt do wdrożenia. Informacja o skutkach zmiany
      wraca późno i do innego zespołu.
    ]
  ][
    #exblock[Współodpowiedzialność][
      Osoby przygotowujące zmianę współpracują przy jej wdrożeniu,
      obserwacji i odzyskaniu działania usługi.
    ]
  ]

  #src[J. Humble, D. Farley, _Continuous Delivery_, 2010, rozdz. 1.]
]

#slide(title: [CALMS jako pytania zadawane przy każdej zmianie])[
  #table(
    columns: (1fr, 3fr), stroke: 0.5pt + ibm-gray-30,
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
    table.header([#text(fill: white, weight: "bold")[Obszar]], [#text(fill: white, weight: "bold")[Pytanie dla systemu zamówień]]),
    [Culture], [Kto razem podejmuje decyzję o zatrzymaniu wdrożenia?],
    [Automation], [Które kroki odtworzymy bez ręcznej konfiguracji?],
    [Lean], [Jak zmniejszyć zakres następnej zmiany?],
    [Measurement], [Po jakich sygnałach poznamy, że zamówienia są realizowane?],
    [Sharing], [Gdzie zapisujemy wnioski i procedurę po incydencie?],
  )
  #src[G. Kim i in., _The DevOps Handbook_, 2. wyd., 2021; CALMS.]
]

#slide(title: [Zakres zmiany a diagnoza])[
  #defblock[Zmiana ryzykowna][
    Nowy worker, nowa konfiguracja kolejki i migracja schematu bazy trafiają
    do produkcji w jednym wdrożeniu.
  ]
  #exblock[Zmiana kontrolowana][
    Najpierw wdrażamy workera zgodnego z poprzednim formatem wiadomości,
    obserwujemy przepływ, a kolejne zmiany wprowadzamy osobno.
  ]

  Efekt: prostsza diagnoza, mniejszy zakres rollbacku i krótszy czas między
  hipotezą a wynikiem.
]

#slide(title: [Pętla informacji zwrotnej])[
  #align(center)[
    #box(stroke: 1pt + kolor-pp, inset: 12pt)[Zmiana] #h(12pt) #sym.arrow.r #h(12pt)
    #box(stroke: 1pt + kolor-pp, inset: 12pt)[Wdrożenie] #h(12pt) #sym.arrow.r #h(12pt)
    #box(stroke: 1pt + kolor-pp, inset: 12pt)[Sygnały] #h(12pt) #sym.arrow.r #h(12pt)
    #box(stroke: 1pt + dark-green, inset: 12pt)[Decyzja]
  ]

  #align(center)[#sym.arrow.l Wynik decyzji określa kolejną zmianę i pomiar #sym.arrow.l]

  #cols[
    #defblock[Hipoteza][
      „Nowy worker odbiera i przetwarza zamówienia tak jak poprzedni.”
    ]
  ][
    #exblock[Decyzja][
      Kontynuować rollout, zatrzymać go albo wykonać kontrolowany rollback.
    ]
  ]
]

#slide(title: [Sygnały muszą obejmować cały przepływ])[
  #table(
    columns: (1.35fr, 1.65fr, 1.35fr), stroke: 0.5pt + ibm-gray-30,
    fill: (x, y) => if y == 0 { ibm-blue-80 } else if calc.rem(y, 2) == 0 { ibm-blue-10 } else { white },
    table.header(
      [#text(fill: white, weight: "bold")[Perspektywa]],
      [#text(fill: white, weight: "bold")[Sygnał]],
      [#text(fill: white, weight: "bold")[Interpretacja]],
    ),
    [Klient], [odsetek udanych zamówień, czas odpowiedzi], [czy usługa realizuje cel użytkownika],
    [Przepływ], [liczba i wiek wiadomości w kolejce], [czy worker nadąża z przetwarzaniem],
    [Komponent], [błędy połączenia workera z kolejką], [gdzie rozpocząć diagnozę],
  )
  #alertblock[Pułapka][
    Działający proces workera nie jest dowodem, że zamówienia są realizowane.
  ]
  #src[B. Beyer i in., _Site Reliability Engineering_, 2016, rozdz. 6.]
]

#slide(title: [#cloud Kolejka zarządzana: podział obowiązków])[
  #cols[
    #defblock[Dostawca usługi][
      - infrastruktura usługi kolejki;
      - dostępność komponentu zgodnie z umową;
      - mechanizmy szyfrowania i aktualizacje platformy.
    ]
  ][
    #alertblock[Zespół aplikacji][
      - tożsamości i uprawnienia workera;
      - konfiguracja, alerty i procedura reakcji;
      - zgodność formatu wiadomości oraz poprawność przetwarzania.
    ]
  ]
  #src[Microsoft Learn, _Shared responsibility in the cloud_, 2026.]
]

#slide(title: [Timeout nie oznacza, że operacja się nie wydarzyła])[
  #align(center)[
    #box(stroke: 1pt + kolor-pp, inset: 10pt)[Klient] #h(8pt) #sym.arrow.r #h(8pt)
    #box(stroke: 1pt + kolor-pp, inset: 10pt)[API: utwórz zamówienie] #h(8pt) #sym.arrow.r #h(8pt)
    #box(stroke: 1pt + orange-pp, inset: 10pt)[Odpowiedź utracona]
  ]
  Po timeoutcie klient może ponowić żądanie. Bez dodatkowego mechanizmu API może
  utworzyć drugie zamówienie i opublikować drugą wiadomość.

  #defblock[Klucz idempotencji][
    Klient przekazuje identyfikator operacji. API atomowo zapisuje klucz,
    treść operacji i wynik wraz z zamówieniem. Ponowienie tej samej operacji
    zwraca zapisany rezultat; ten sam klucz z inną treścią jest odrzucany.
  ]
  #src[RFC 9110, sekcja 9.2.2; właściwości metod HTTP nie rozwiązują automatycznie semantyki zamówienia.]
]

#slide(title: [Decyzja operacyjna])[
  Po zmianie workera obserwujesz przez pięć minut (dane dydaktyczne):
  - napływ do kolejki: bez zmiany;
  - błędy API: 0,2% → 0,3%;
  - liczba wiadomości w kolejce: 200 → 4 800;
  - wiek najstarszej wiadomości: 10 s → 4 min.

  #alertblock[Pytanie][
    Czy kontynuujesz rollout, zatrzymujesz go czy robisz rollback? Jakie dwa
    sprawdzenia wykonasz przed następną decyzją?
  ]
]

#slide(title: [Omówienie: najpierw zatrzymaj rollout])[
  #exblock[Uzasadnienie][
    Rosnąca kolejka i wiek najstarszej wiadomości wskazują, że przepływ zamówień
    nie nadąża. To przesłanka wstrzymania promocji, ale jeszcze nie dowód
    błędu nowej wersji; sprawdzenia wymagają również zależności.
  ]
  Przed rollbackiem sprawdź:
  - błędy uwierzytelnienia i połączeń oraz różnicę konfiguracji między wersjami;
  - zgodność poprzedniego workera z zaległymi wiadomościami i tempo ich opróżniania.

  Rollback wymaga zgodności poprzedniej wersji z danymi i potwierdzenia, że może
  ograniczyć wpływ. Samo wstrzymanie promocji nie przywraca przetwarzania.
]

#slide(title: [Wnioski])[
  - DevOps łączy przygotowanie zmiany z odpowiedzialnością za jej skutki.
  - Mała zmiana staje się bezpieczna dopiero wraz z sygnałami, które pozwalają ją ocenić.
  - Usługa zarządzana zmienia podział obowiązków, lecz nie zastępuje odpowiedzialności za aplikację.

  #defblock[Pytanie na koniec][
    Jaką metrykę dodałbyś, aby odróżnić wolne przetwarzanie od całkowitego zatrzymania workera?
  ]
]

#slide(title: [Źródła i lektury])[
  #set text(size: 16pt)
  - C. Richardson, _Transactional outbox_: #link("https://microservices.io/patterns/data/transactional-outbox")[microservices.io].
  - J. Humble, D. Farley, _Continuous Delivery_, Addison-Wesley, 2010, rozdz. 1.
  - G. Kim i in., _The DevOps Handbook_, 2. wyd., IT Revolution, 2021, rozdz. 1.
  - B. Beyer i in., _Site Reliability Engineering_, O'Reilly, 2016, rozdz. 6: #link("https://sre.google/sre-book/monitoring-distributed-systems/")[sre.google].
  - Microsoft Learn, _Shared responsibility in the cloud_: #link("https://learn.microsoft.com/azure/security/fundamentals/shared-responsibility")[learn.microsoft.com].
  - R. Fielding i in., RFC 9110, sekcja 9.2.2: #link("https://www.rfc-editor.org/rfc/rfc9110#section-9.2.2")[rfc-editor.org].
]

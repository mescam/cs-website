#import "@preview/typslides:1.3.2": *
#import "zsr-theme.typ": *
#import emoji: cloud

#show: typslides.with(
  ratio: "16-9", theme: kolor-pp, font: "DejaVu Sans", font-size: 20pt,
  show-progress: true, show-page-numbers: true,
)
#set text(lang: "pl")

#front-slide(
  title: "Kontenery w systemie rozproszonym",
  subtitle: [Od niezgodnych środowisk do wymienialnej usługi],
  authors: "mgr inż. Jakub Woźniak",
  info: [Zarządzanie Systemami Rozproszonymi · Semestr zimowy 2026/27],
)

#slide(title: [Ten sam kod, dwa różne wyniki])[
  #alertblock[Przypadek][
    Worker systemu zamówień działa na pierwszym serwerze. Na drugim uruchamia
    się z tego samego commita, ale korzysta z innej wersji biblioteki i kończy
    pracę błędem.
  ]

  #align(center)[
    Ten sam kod źródłowy ≠ to samo działające środowisko
  ]

  - Wdrożenie zależy nie tylko od programu, lecz także od jego otoczenia.
  - Celem jest ograniczenie liczby różnic między miejscami uruchomienia.

  #src[Worker nawiązuje do systemu zamówień z wykładu 1.]
]

#slide(title: [Kod nie określa środowiska uruchomienia])[
  #flow[Program][Biblioteki i runtime][System gospodarza]

  - Proces potrzebuje określonych bibliotek, narzędzi i ustawień.
  - Gdy są przygotowywane osobno na każdym serwerze, łatwo o różnice
    niewidoczne w repozytorium źródeł.
  - Potrzebna jest jednostka dostarczenia obejmująca program i jego
    zależności, którą można przenieść między węzłami.

  #src[#link("https://github.com/opencontainers/image-spec")[OCI — Image Format Specification]]
]

#slide(title: [Kontener współdzieli jądro hosta])[
  #data-table(3,
    [Podejście], [Co przenosimy], [Konsekwencja],
    [Sam program], [Kod lub plik wykonywalny], [Środowisko trzeba przygotować na hoście],
    [Maszyna wirtualna], [System gościa i aplikacja], [Osobne jądro wzmacnia izolację],
    [Kontener], [Aplikacja i środowisko użytkowe], [Wspólne jądro hosta],
  )

  - Kontener pozwala powielać środowisko aplikacji bez dołączania osobnego
    systemu gościa do każdej instancji.
  - Ta oszczędność wynika z decyzji o współdzieleniu jądra; wpływa też na
    granicę izolacji.
]

#slide(title: [Kontener jest izolowanym procesem])[
  #cols[
    #defblock[Wewnątrz][
      Proces widzi własne drzewo plików, przestrzeń procesów i sieć.
    ]
  ][
    #exblock[Na hoście][
      Proces nadal wykonuje wywołania do jądra gospodarza i zużywa jego zasoby.
    ]
  ]

  #align(center)[
    Kontener = proces + izolowany widok otoczenia + kontrola zasobów
  ]

  - Nie jest to osobny komputer ani osobne jądro systemu operacyjnego.
  - Na Docker Desktop hostem kontenerów Linux może być maszyna wirtualna.

  #src[#link("https://docs.docker.com/engine/security/")[Docker — Engine security]]
]

#slide(title: [Izolacja kontenera ma granice])[
  #data-table(3,
    [Mechanizm], [Po co jest], [Czego nie rozwiązuje],
    [Namespaces], [Osobny widok procesów i sieci], [Błędu współdzielonego jądra],
    [cgroups], [Kontrola zużycia zasobów], [Poprawności programu],
    [Uprawnienia], [Proces bez roota ogranicza skutki błędu], [Błędnej konfiguracji usługi],
  )

  #alertblock[Wniosek][
    Izolacja pomaga uruchamiać wiele usług na jednym węźle, ale nie zastępuje
    kontroli uprawnień, aktualizacji hosta ani projektowania odporności.
  ]
]

#slide(title: [Obraz i kontener pełnią różne role])[
  #flow[Jeden obraz][Wiele niezależnych instancji]

  - Obraz opisuje program i jego zależności jako artefakt.
  - Kontener jest konkretnym uruchomieniem obrazu: ma proces, konfigurację
    uruchomienia i własną warstwę zapisywalną.
  - Jeden obraz może służyć do tworzenia wielu instancji. Nowa wersja obrazu
    nie zmienia procesów już działających.

  #exblock[Po co ten podział?][
    Umożliwia zastępowanie instancji bez ręcznej zmiany ich zawartości.
  ]
]

#slide(title: [Warstwy ułatwiają budowanie i dystrybucję])[
  #data-table(2,
    [Idea], [Uzasadnienie],
    [Dockerfile], [Jawny przepis utworzenia artefaktu],
    [Warstwy], [Współdzielenie niezmienionych składników obrazów],
    [Pamięć podręczna], [Szybsze ponowne budowanie po częściowej zmianie],
  )

  - Te mechanizmy ułatwiają dystrybucję i rozwój aplikacji.
  - Sam przepis nie gwarantuje identycznego wyniku, jeżeli obraz bazowy
    lub pobierane zależności mogą się zmieniać.

  #src[#link("https://docs.docker.com/build/cache/invalidation/")[Docker — Cache invalidation]]
]

#slide(title: [Zachowanie usługi zależy także od otoczenia])[
  #flow[Obraz][Konfiguracja + dane + sieć][Zachowanie usługi]

  - Obraz ogranicza różnice w programie i jego zależnościach.
  - Zgodność hosta, adres kolejki, dostępność bazy i dane pozostają
    właściwościami środowiska uruchomienia.
  - Dwie instancje tego samego obrazu mogą więc zachowywać się inaczej.

  #alertblock[Granica obietnicy][
    Przenośność artefaktu ułatwia wdrożenie; nie oznacza przenośności całego
    działającego systemu.
  ]
]

#slide(title: [Stan usługi ma osobny cykl życia])[
  #cols[
    #defblock[Proces i pliki tymczasowe][
      Można je zastąpić razem z kontenerem.
    ]
  ][
    #exblock[Zamówienia i załączniki][
      Muszą przetrwać wymianę instancji i awarię węzła.
    ]
  ]

  - Warstwa zapisywalna kontenera znika po jego usunięciu.
  - Wolumen może przetrwać usunięcie kontenera, lecz lokalny wolumen nadal
    wiąże dane z węzłem. Trwałość wymaga osobnej architektury i kopii zapasowej.

  #src[#link("https://docs.docker.com/engine/storage/volumes/")[Docker — Volumes]]
]

#slide(title: [Wymiana instancji może przerwać pracę])[
  #flow[Stary proces pracuje][Wymiana][Nowy proces pracuje]

  - Kontener może zniknąć podczas obsługi żądania lub wiadomości.
  - Możliwość ponownego dostarczenia pracy chroni przed jej utratą, lecz
    może prowadzić do powtórnego wykonania.
  - Dlatego bezpieczna wymiana zależy od zachowania aplikacji: obsługi
    zakończenia, trwałego zapisu i idempotencji.

  #src[Przypadek workera rozwija problem ponawiania z wykładu 1.]
]

#slide(title: [Kontener nie gwarantuje własności całej usługi])[
  #data-table(2,
    [Daje], [Nie daje automatycznie],
    [Przenośny artefakt], [Identycznego zachowania w każdym środowisku],
    [Izolację procesów], [Pełnej granicy bezpieczeństwa],
    [Wymienialną instancję], [Nieprzerwanej obsługi żądań],
    [Możliwość montowania danych], [Kopii zapasowej i odtworzenia],
  )

  #alertblock[Sens tej granicy][
    Kontenery rozwiązują problem pakowania i uruchamiania procesu. Własności
    całej usługi wynikają z projektu aplikacji i infrastruktury.
  ]
]

#slide(title: [#cloud Orkiestracja zarządza instancjami])[
  - Obraz i kontener dotyczą pojedynczego artefaktu oraz instancji.
  - Przy wielu węzłach pojawiają się nowe pytania: gdzie uruchomić instancję,
    jak skierować do niej ruch i co zrobić po awarii węzła?
  - Platforma kontenerowa może zarządzać rozmieszczeniem, wykrywaniem usług
    i zastępowaniem instancji. Nie zna jednak znaczenia danych biznesowych.

  #align(center)[
    Kontener → instancja aplikacji → usługa działająca na wielu węzłach
  ]

  #src[Następny wykład: Kubernetes i rekonsyliacja stanu usługi.]
]

#slide(title: [Przenośny obraz ogranicza różnice między serwerami])[
  #cols[
    #alertblock[Na początku][
      Ten sam kod zależał od bibliotek przygotowanych osobno na serwerach.
    ]
  ][
    #exblock[Po konteneryzacji][
      Program i zależności są przenoszone jako obraz. Instancje można zastępować.
    ]
  ]

  - Różnice między węzłami zostały ograniczone, ale nie zniknęły: pozostają
    jądro hosta, konfiguracja, sieć i dostęp do danych.
  - O niezawodności przetwarzania zamówień nadal decydują trwałość danych
    i zachowanie workera podczas przerwania pracy.

  #align(center)[
    Kontener upraszcza dostarczenie programu; nie zastępuje projektu usługi.
  ]
]

#slide(title: [Źródła i lektury])[
  #text(size: 16pt)[
    - #link("https://github.com/opencontainers/image-spec")[OCI — Image Format Specification]
    - #link("https://docs.docker.com/engine/security/")[Docker — Engine security]
    - #link("https://docs.docker.com/build/cache/invalidation/")[Docker — Cache invalidation]
    - #link("https://docs.docker.com/engine/storage/volumes/")[Docker — Volumes]
  ]

  #src[Przykład workera służy wyjaśnieniu granic i zastosowań kontenerów.]
]

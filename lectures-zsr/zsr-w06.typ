#import "@preview/typslides:1.3.2": *
#import "zsr-theme.typ": *
#import emoji: cloud

#show: typslides.with(
  ratio: "16-9", theme: kolor-pp, font: "DejaVu Sans", font-size: 20pt,
  show-progress: true, show-page-numbers: true,
)
#set text(lang: "pl")

#front-slide(
  title: "CI/CD i GitOps",
  subtitle: [Tożsamość artefaktu, stan oczekiwany i okno rollbacku],
  authors: "mgr inż. Jakub Woźniak",
  info: [Zarządzanie Systemami Rozproszonymi · Semestr zimowy 2026/27],
)

#slide(title: [Zielony pipeline nie mówi, co działa w produkcji])[
  #data-table(3,
    [Pomiar], [09:55], [10:05],
    [Udział odrzuconych zamówień], [2,0%], [2,0%],
    [Wersja w metrykach], [v2.0.0], [v2.0.1],
    [Rollout ukończony], [--], [10:03],
  )

  #cols[
    #exblock[Co wiemy][
      - Poprawka scalona o 10:00 (commit `9c81f2`), pipeline zielony.
      - Operator wykonał `kubectl set image` na produkcji o 10:02.
      - Tag `v2.0.1` wskazywał wczoraj na inny build — przestawiono go dziś rano.
    ]
  ][
    #alertblock[Czego jeszcze nie wiemy][
      - Który digest faktycznie uruchamia produkcja.
      - Czy to w ogóle obraz z commita `9c81f2`.
      - Do której wersji można wrócić i gdzie to zapisano.
    ]
  ]
]

#slide(title: [Plan wykładu])[
  - Trzy praktyki i trzy decyzje: CI, delivery, deployment.
  - Pipeline jako kontrakt etapów i tożsamość artefaktu.
  - GitOps: stan oczekiwany, uzgadnianie i koszt ręcznej zmiany.
  - Strategie zmiany wersji i bramka kanarka oparta na metrykach.
  - Zgodność danych wyznacza okno rollbacku.
  - #cloud Token czasowy i zarządzana bramka wdrożenia.
  - Przypadek: v2 działa, v1 już nie.
]

#slide(title: [Deployment i release to dwie różne decyzje])[
  #data-table(3,
    [Praktyka], [Warunek], [Przykład],
    [Continuous integration], [Szybka weryfikacja zmian], [Testy po każdej zmianie],
    [Continuous delivery], [Wersja gotowa do wydania], [Wydanie: decyzja ręczna],
    [Continuous deployment], [Wydanie automatyczne], [Produkcja bez bramki ręcznej],
  )

  #defblock[Definicja][
    Deployment to umieszczenie nowej wersji w środowisku. Release to
    udostępnienie jej zachowania użytkownikom — niezależnie od czasu
    wdrożenia.
  ]

  - Flaga funkcji rozdziela te decyzje: wdrożenie o 10:00, wydanie dla 1% klientów o 14:00.
  - Zielony pipeline dowodzi jakości commitu, nie tego, co działa w produkcji.

  #src[#link("https://continuousdelivery.com/")[Humble, Farley — Continuous Delivery, 2010]]
]

#slide(title: [Pipeline: każdy etap ma wejście i wynik])[
  #flow[Commit][Test i build][Obraz z digestem][Weryfikacja][Promocja]
  #data-table(3,
    [Etap], [Wejście], [Wynik],
    [Test], [Commit i zależności], [Wynik testów],
    [Build], [Ten sam commit], [Obraz identyfikowany digestem],
    [Weryfikacja], [Obraz], [Skan, podpis, provenance],
    [Promocja], [Digest i konfiguracja], [Zmiana deklaracji środowiska],
  )

  - Etap jest kontraktem: błąd zatrzymuje kolejny, wynik zostaje artefaktem;
    weryfikujemy artefakt, nie kod — to ostatnie miejsce przed publikacją.
  - #sm[Skan, podpis i provenance: szczegóły na wykładzie 7.]

  #src[#link("https://continuousdelivery.com/")[Humble, Farley — Continuous Delivery, 2010]]
]

#slide(title: [Tag jest etykietą, digest jest tożsamością])[
  #codebox[
```text
orders-api:v2.0.1        # dziś: sha256:9f3a…  ·  wczoraj: sha256:c417…
orders-api@sha256:9f3a…  # zawsze ta sama zawartość
```
  ]

  #defblock[Zasada promocji][
    Między środowiskami przenosimy jeden digest. Zmienia się konfiguracja —
    endpointy, tożsamości, limity — nie zawartość obrazu.
  ]

  - Tag można przestawić na inny obraz; digest wynika z zawartości i jest stały.
  - Ponowny build z tego samego commita nie daje tego samego obrazu:
    zależności i warunki budowania się różnią.
  - Nazwa gałęzi ani tag nie identyfikują artefaktu — identyfikuje go digest.

  #src[#link("https://kubernetes.io/docs/concepts/containers/images/")[Kubernetes — Images]]
]

#slide(title: [Każde rozwiązanie zostawia nowy koszt])[
  #data-table(3,
    [Sygnał], [Rozwiązanie], [Pozostały koszt],
    [Wdrożenia „z pamięci", inne na każdym środowisku], [Skrypty, pipeline CI/CD], [Pipeline ma uprawnienia produkcyjne],
    [Nikt nie wie, która wersja działa], [Digest, deklaracje w Git], [Git i klaster mogą się rozjechać],
    [Ręczne „szybkie poprawki" w klastrze], [Pętla uzgadniania], [Zmiana wymaga commita],
  )

  #exblock[DORA 2025][
    16,2% badanych wdraża na żądanie — kilka razy dziennie.
    Ok. 5 000 ankietowanych.
  ]

  - Każde rozwiązanie zmniejszało jeden problem i otwierało następny.

  #src[#link("https://dora.dev/research/2025/dora-report/")[DORA — State of AI-assisted Software Development, 2025]]
]

#slide(title: [GitOps: klaster dąży do stanu zadeklarowanego w Git])[
  #defblock[Definicja][
    GitOps zarządza systemem przez stan oczekiwany zapisany w Git: agent
    pobiera deklaracje, porównuje ze stanem rzeczywistym i dąży do zgodności.
  ]

  Stan oczekiwany musi być:
  - deklaratywny — opis deklaracjami, nie poleceniami,
  - wersjonowany i niezmienialny — pełna historia zmian,
  - pobierany automatycznie — agent ciągnie stan,
  - ciągle uzgadniany — naprawa rozbieżności.

  #flow[Git: digest + konfiguracja][Kontroler: porównanie][Klaster: stan rzeczywisty]
  #align(center)[#sym.arrow.l Odczyt stanu i ponowne porównanie #sym.arrow.l]

  - Model pull: uprawnienia do klastra ma kontroler, nie CI.

  #src[#link("https://opengitops.dev/")[OpenGitOps — Principles]]
]

#slide(title: [Ręczna zmiana w klastrze żyje krótko])[
  #codebox[
```yaml
# Fragment spec Application Argo CD
syncPolicy:
  automated:
    prune: false    # zasób usunięty z Gitu nie jest kasowany
    selfHeal: true  # ręczna zmiana zostanie cofnięta
```
  ]

  - Uzgadnianie działa w pętli: domyślnie co ok. 2–3 minuty, self-heal
    przyspiesza reakcję po wykryciu rozbieżności.
  - Awaryjna zmiana ręczna jest możliwa tylko jako jawna decyzja:
    wstrzymać synchronizację, naprawić, potem uzgodnić z Gitem.
  - Trwała poprawka to commit, nie polecenie.
  - Rollback poza Gitem nie istnieje: przy włączonej synchronizacji
    automatycznej Argo CD nie wykonuje rollbacku.

  #src[#link("https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/")[Argo CD — Automated Sync Policy]]
]

#slide(title: [Każda strategia płaci inną cenę])[
  #data-table(3,
    [Strategia], [Mechanizm], [Koszt / ryzyko],
    [Rolling], [Stopniowa wymiana Podów], [Okres koegzystencji wersji],
    [Blue–green], [Dwie pule i przełączenie ruchu], [Podwójna pojemność w chwili zmiany],
    [Canary], [Część ruchu do nowej wersji], [Reprezentatywność próbki],
  )

  - Wszystkie strategie zakładają zgodność współdzielonych danych.
  - Rollback Deploymentu cofa definicję, ale nie odtwarza danych zapisanych
    przez nową wersję.

  #src[#link("https://kubernetes.io/docs/concepts/workloads/controllers/deployment/")[Kubernetes — Deployments] · #link("https://argo-rollouts.readthedocs.io/en/stable/features/bluegreen/")[Argo Rollouts — BlueGreen]]
]

#slide(title: [Liczba replik to nie procent ruchu])[
  #defblock[Przykład z dokumentacji][
    10 replik i `setWeight: 41%` bez routera ruchu: kontroler dąży do najlepszego
    przybliżenia — 4 Pody nowej wersji i 6 starych, bo 41% z 10 jest bliżej 4 niż 5.
  ]

  - Bez zarządzania ruchem proporcja Podów jest przybliżeniem, nie pomiarem.
  - Przy małej liczbie replik 10% oznacza jednego Poda albo żadnego.
  - Dokładne procenty wymagają routera ruchu: wagi w Ingressie lub meshu.
  - Repliki v2 nie dowodzą, że 41% ruchu tam trafiło.

  #src[#link("https://argo-rollouts.readthedocs.io/en/stable/features/canary/")[Argo Rollouts — Canary]]
]

#slide(title: [Bramka kanarka liczy się na metrykach])[
  #data-table(3,
    [10 min obserwacji], [v1], [v2],
    [Żądania], [90 000], [10 000],
    [Błędy], [90], [200],
    [Udział błędów], [0,1%], [2,0%],
  )
  #codebox[
```yaml
metrics:
  - name: error-rate
    successCondition: result[0] <= 0.005
    failureLimit: 3
    provider: { prometheus: … } # zapytanie pominięte
```
  ]

  - Różnica 1,9 pp przekracza próg 0,5 pp — wstrzymać promocję.
  - #sm[Niskie p95 tego nie kompensuje — to dwie różne sygnatury. Wiarygodność
    metryki: segmenty ruchu i wielkość próby.]

  #src[#link("https://argo-rollouts.readthedocs.io/en/stable/features/analysis/")[Argo Rollouts — Analysis]]
]

#slide(title: [Okno rollbacku wyznaczają dane, nie obrazy])[
  #data-table(3,
    [Etap], [Schemat / kod], [Zgodność],
    [Expand], [Dodaj total_cents, zachowaj amount], [Stary kod nadal działa],
    [Migracja], [Dual-write lub synchronizacja, backfill], [Obie reprezentacje zgodne],
    [Przełączenie], [Nowy kod czyta total_cents], [Okres obserwacji i rollbacku],
    [Contract], [Usuń amount po wycofaniu zależności], [Stary kod już nie działa],
  )

  - Dopóki nie wykonano `contract`, wracamy do dowolnej wersji — to jest
    okno rollbacku.
  - To samo rozumowanie obejmuje API i kolejki: nie usuwaj pola, zanim
    nikt z niego nie czyta.

  #src[#link("https://martinfowler.com/bliki/ParallelChange.html")[Fowler — Parallel Change]]
]

#slide(title: [#cloud Token czasowy i zarządzana bramka])[
  #flow[Workflow][Token OIDC][Dostawca: polityka zaufania][Rola w chmurze]

  - Klucz statyczny w sekrecie żyje latami i przenosi uprawnienia; token OIDC
    żyje minuty i opisuje, kto, gdzie i z jakiej gałęzi go użył.
  - Warunek zaufania ogranicza repozytorium, gałąź i `audience`; przy
    środowisku warunek zawiera jego nazwę.
  - Środowisko z wymaganym zatwierdzeniem: zadanie czeka z etykietą „Waiting",
    a sekrety środowiska są dostępne dopiero po zatwierdzeniu.
  - Zaufany workflow nie może dostawać uprawnień wydania w pracy nad PR-em
    niezaufanego autora.

  #src[#link("https://docs.github.com/en/actions/concepts/security/openid-connect")[GitHub — OpenID Connect] · #link("https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments")[GitHub — Deployments and environments]]
]

#slide(title: [Rollback wymaga dostępu do poprzedniego artefaktu])[
  #data-table(2,
    [Stan], [Możliwy skutek],
    [Działający Pod ze starym obrazem], [Może nadal obsługiwać ruch],
    [Nowy węzeł bez obrazu], [Nie pobierze usuniętego digestu],
    [Rollback do usuniętego digestu], [Nie odtworzy poprzedniej wersji],
  )

  - Retencja i dostępność artefaktów są częścią procedury odtworzenia,
    nie dodatkiem do niej.
  - Ćwiczenie rollbacku musi objąć nowe instancje — cache węzłów nie dowodzi
    odtwarzalności.
  #sm[Artefakty w rejestrze zarządzanym podlegają polityce dostawcy; szczegóły odtwarzania: wykład 12.]

  #src[Wniosek z mechanizmu digestu (Kubernetes — Images); retencja: decyzja zespołu.]
]

#slide(title: [Przypadek: v2 działa, v1 już nie])[
  #codebox[
```text
10:00  expand: dodano total_cents; amount nadal istnieje
10:10  wdrożono v2; zakończono backfill
10:20  contract: DROP COLUMN amount
10:25  wykryto błąd biznesowy v2

# Zapytanie v1
SELECT amount FROM orders WHERE id = $1;
```
  ]

  #alertblock[Decyzja][
    Cofnięcie deklaracji w Git przywróci v1 — a v1 czyta `amount`, którego
    już nie ma. Który etap zamknął okno rollbacku? Czy wystarczy wrócić do
    obrazu v1, czy potrzebna jest zgodna poprawka v2? Jak pipeline wymusi
    okres między przełączeniem a `contract` następnym razem?
  ]
]

#slide(title: [Kluczowe wnioski])[
  - Digest jest tożsamością artefaktu, a Git jest źródłem stanu: bez tego
    „co działa w produkcji" jest odpowiedzią z pamięci, nie z systemu.
  - Uzgadnianie cofa ręczne zmiany; trwałą poprawką jest commit, a
    wstrzymanie synchronizacji to jawna decyzja z zapisem.
  - Okno rollbacku wyznacza zgodność danych, nie dostępność obrazu —
    kolejność to expand, przełączenie, contract.
  - #cloud Bramka zarządzana przez dostawcę (token czasowy, wymagane
    zatwierdzenie) przenosi decyzję o produkcji do systemu z dowodem działania.

  #alertblock[Pytanie sprawdzające][
    Pipeline zielony, obraz pobrany po digest, kontroler zgłasza „Synced", a
    klient nadal widzi stary błąd. Co sprawdzasz pierwsze i dlaczego
    „Synced" nie dowodzi, że działa nowa wersja?
  ]
]

#slide(title: [Źródła i lektury])[
  #text(size: 16pt)[
    - #link("https://continuousdelivery.com/")[Humble, Farley — Continuous Delivery, 2010]
    - #link("https://opengitops.dev/")[OpenGitOps — Principles]
    - #link("https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/")[Argo CD — Automated Sync Policy]
    - #link("https://kubernetes.io/docs/concepts/containers/images/")[Kubernetes — Images]
    - #link("https://kubernetes.io/docs/concepts/workloads/controllers/deployment/")[Kubernetes — Deployments]
    - #link("https://argo-rollouts.readthedocs.io/en/stable/features/canary/")[Argo Rollouts — Canary]
    - #link("https://argo-rollouts.readthedocs.io/en/stable/features/analysis/")[Argo Rollouts — Analysis]
    - #link("https://argo-rollouts.readthedocs.io/en/stable/features/bluegreen/")[Argo Rollouts — BlueGreen]
    - #link("https://martinfowler.com/bliki/ParallelChange.html")[Fowler — Parallel Change]
    - #link("https://docs.github.com/en/actions/concepts/security/openid-connect")[GitHub — OpenID Connect] · #link("https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments")[środowiska wdrożeń]
    - #link("https://dora.dev/research/2025/dora-report/")[DORA — State of AI-assisted Software Development, 2025]
  ]

  #defblock[Lektura obowiązkowa na wykład 7][
    SLSA 1.2, sekcja Provenance: #link("https://slsa.dev/spec/v1.2/provenance").
    Pytanie otwierające: co dowodzi, że obraz pobrany z rejestru to dokładnie
    ten, który zbudował Twój pipeline?
  ]

  #src[Dokumentacja sprawdzona: 22.11.2026. Dane przypadków: przykłady dydaktyczne.]
]

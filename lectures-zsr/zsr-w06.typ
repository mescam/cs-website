#import "@preview/typslides:1.3.2": *
#import "zsr-theme.typ": *
#import emoji: cloud
#show: typslides.with(ratio: "16-9", theme: kolor-pp, font: "DejaVu Sans", font-size: 20pt, show-progress: true, show-page-numbers: true)
#set text(lang: "pl")
#front-slide(title: "CI/CD i GitOps", subtitle: [Artefakt, strategia wdrożenia i zgodność danych], authors: "mgr inż. Jakub Woźniak", info: [Zarządzanie Systemami Rozproszonymi · Semestr zimowy 2026/27])
#slide(title: [CI, delivery i deployment])[
#data-table(3,
[Praktyka],
[Warunek],
[Przykład],
[Continuous integration],
[Częsta integracja i szybka weryfikacja],
[Testy po zmianie kodu],
[Continuous delivery],
[Wersja gotowa do wydania],
[Decyzja o produkcji ręczna],
[Continuous deployment],
[Automatyczne wydanie po kontroli],
[Produkcja bez ręcznej bramki],
)
#sm[Deployment: umieszczenie wersji. Release: udostępnienie zachowania, np. flagą funkcji.]
]
#slide(title: [Potok: wejścia i wyniki])[
#data-table(3,
[Etap],
[Wejście],
[Wynik],
[Test],
[Commit i zależności],
[Wynik testów],
[Build],
[Ten sam commit],
[Obraz identyfikowany digestem],
[Weryfikacja],
[Obraz],
[Skan, podpis, provenance],
[Promocja],
[Digest i konfiguracja],
[Zmiana deklaracji środowiska],
[Obserwacja],
[Ruch do wersji],
[Decyzja o kontynuowaniu],
)
- Test kodu nie dowodzi, że wdrożono właśnie ten kod.
]
#slide(title: [Fragment potoku GitHub Actions])[
#codebox[
```yaml
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      # Checkout i przygotowanie narzędzi pominięte
      - run: ./ci/test.sh
      - run: ./ci/build-and-push.sh > image-digest.txt
      - run: ./ci/verify-image.sh image-digest.txt
      - run: ./ci/propose-release.sh image-digest.txt
```
]
- Skrypty: kontrakty etapów, nie gotowy workflow do uruchomienia.
- Błąd etapu zatrzymuje publikację propozycji wydania.
- Digest i raporty zachowane jako artefakty; akcje i narzędzia przypięte w pełnym potoku.
]
#slide(title: [Promocja jednego artefaktu])[
#flow[Build: sha256…][Test][Staging][Produkcja]
- Każde środowisko otrzymuje tę samą zawartość obrazu.
- Różne endpointy, tożsamości i limity w konfiguracji.
- Osobno zapisać wersję obrazu i wersję konfiguracji.
#alertblock[Pułapka][Ponowny build z tego samego commitu może pobrać inne zależności. Nazwa gałęzi nie identyfikuje artefaktu.]
]
#slide(title: [Strategie zmiany wersji])[
#data-table(3,
[Strategia],
[Przełączenie],
[Koszt / ryzyko],
[Rolling],
[Stopniowa wymiana Podów],
[Koegzystencja v1 i v2],
[Blue–green],
[Przełączenie ruchu między pulami],
[Dodatkowa pojemność],
[Canary],
[Część ruchu do nowej wersji],
[Reprezentatywność próbki],
)
- Liczba replik v2 nie gwarantuje dokładnego procentu ruchu.
- Wszystkie strategie wymagają zgodności współdzielonych danych.
]
#slide(title: [Canary: bramka oparta na danych])[
#data-table(3,
[10 min obserwacji],
[v1],
[v2],
[Żądania],
[90 000],
[10 000],
[Błędy],
[90],
[200],
[Udział błędów],
[0,1%],
[2%],
[p95],
[180 ms],
[210 ms],
)
#alertblock[Warunek w przykładzie][Wstrzymać promocję przy wzroście błędów o ponad 0,5 punktu procentowego. Czy p95 wystarczy do oceny?]
#src[Próg dydaktyczny; w praktyce uwzględnić wielkość próby, segmenty ruchu i SLO.]
]
#slide(title: [GitOps: stan oczekiwany i drift])[
#flow[Git: digest A][Argo CD][Klaster: digest B]
#align(center)[#sym.arrow.l Odczyt stanu i ponowne porównanie #sym.arrow.l]
- Ręczna zmiana obrazu powoduje rozbieżność.
- Auto-sync: wdrażanie zmian deklaracji.
- `selfHeal`: automatyczna korekta zmian w klastrze; `prune`: usuwanie zbędnych zasobów.
#src[#link("https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/")[Argo CD — Automated Sync Policy]]
]
#slide(title: [Zmiana awaryjna przy GitOps])[
#codebox[
```yaml
# Fragment spec Application Argo CD
syncPolicy:
  automated:
    prune: false
    selfHeal: true
```
]
- Ręczny rollback w klastrze może zostać cofnięty przez kontroler.
- Preferowana trwała korekta: zmiana deklaracji w Git.
- Awaryjne wstrzymanie synchronizacji: jawna decyzja, zapis i późniejsze uzgodnienie.
#src[#link("https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/#automatic-self-healing")[Argo CD — Automatic Self-Healing]]
]
#slide(title: [Expand–contract: zmiana kolumny])[
#data-table(3,
[Etap],
[Schemat / kod],
[Zgodność],
[Expand],
[Dodaj total_cents; zachowaj amount],
[Stary kod nadal działa],
[Migracja],
[Dual-write lub synchronizacja; backfill],
[Sprawdzanie obu reprezentacji],
[Przełączenie],
[Nowy kod czyta total_cents],
[Okres obserwacji i rollbacku],
[Contract],
[Usuń amount po wycofaniu zależności],
[Stary kod już nie działa],
)
#src[#link("https://martinfowler.com/bliki/ParallelChange.html")[Fowler — Parallel Change]]
]
#slide(title: [#cloud OIDC zamiast stałego klucza CI])[
#flow[Workflow: token OIDC][Dostawca: polityka zaufania][Token czasowy]
- Ograniczyć repozytorium, branch lub środowisko i audience.
- Uprawnienia tokenu docelowego oddzielne od uwierzytelnienia.
- Zaufany workflow nie może bez kontroli wykonywać kodu niezaufanego PR z uprawnieniami wydania.
#src[#link("https://docs.github.com/en/actions/concepts/security/openid-connect")[GitHub — OpenID Connect]]
]
#slide(title: [#cloud Awaria rejestru podczas wdrożenia])[
#data-table(2,
[Stan],
[Możliwy skutek],
[Działający Pod z obrazem],
[Może nadal obsługiwać ruch],
[Nowy węzeł bez obrazu],
[Nie pobierze obrazu],
[Rollback do usuniętego digestu],
[Nie odtworzy poprzedniej wersji],
)
- Retencja i dostępność artefaktów są częścią procedury odtworzenia.
- Ćwiczenie rollbacku musi objąć nowe instancje, nie tylko cache węzłów.
]
#slide(title: [Przypadek: v2 działa, v1 już nie])[
#codebox[
```sql
10:00  dodano total_cents; amount nadal istnieje
10:10  wdrożono v2; zakończono backfill
10:20  migracja: DROP COLUMN amount
10:25  wykryto błąd biznesowy v2

# Zapytanie v1
SELECT amount FROM orders WHERE id = $1;
```
]
#alertblock[Decyzja][Czy wystarczy wrócić do obrazu v1? Który etap zamknął możliwość prostego rollbacku? Jak ograniczyć ryzyko następnym razem?]
]
#slide(title: [Źródła i lektury])[
#text(size: 16pt)[
- #link("https://continuousdelivery.com/")[Humble, Farley — Continuous Delivery, 2010]
- #link("https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/")[Argo CD — Automated Sync Policy]
- #link("https://opengitops.dev/")[OpenGitOps — Principles]
- #link("https://martinfowler.com/bliki/ParallelChange.html")[Fowler — Parallel Change]
- #link("https://docs.github.com/en/actions/concepts/security/openid-connect")[GitHub — OpenID Connect]
]
#src[Dokumentacja sprawdzona: 26.09.2026. Dane przypadków: przykłady dydaktyczne.]
]

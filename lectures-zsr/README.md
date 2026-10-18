# Wykłady ZSR 2026/27

Cykl 15 spotkań po maksymalnie 45 minut. Źródła Typst korzystają z lokalnego motywu Politechniki Poznańskiej i `typslides` 1.3.2. Wykłady obejmują mechanizmy, analizę fragmentów konfiguracji, obliczenia i przypadki do dyskusji.

## Materiały

| Nr | Wykład | Strony PDF | Notatki prowadzącego |
|---|---|---|---|
| 01 | [DevOps i automatyzacja](result/zsr-w01.pdf) · [Typst](zsr-w01.typ) | 17 | [45 minut i rozwiązania](notes/zsr-w01.md) |
| 02 | [Kontenery w eksploatacji](result/zsr-w02.pdf) · [Typst](zsr-w02.typ) | 14 | [45 minut i rozwiązania](notes/zsr-w02.md) |
| 03 | [Kubernetes: model działania](result/zsr-w03.pdf) · [Typst](zsr-w03.typ) | 19 | [45 minut i rozwiązania](notes/zsr-w03.md) |
| 04 | [Kubernetes w eksploatacji](result/zsr-w04.pdf) · [Typst](zsr-w04.typ) | 13 | [45 minut i rozwiązania](notes/zsr-w04.md) |
| 05 | [Obserwowalność](result/zsr-w05.pdf) · [Typst](zsr-w05.typ) | 14 | [45 minut i rozwiązania](notes/zsr-w05.md) |
| 06 | [CI/CD i GitOps](result/zsr-w06.pdf) · [Typst](zsr-w06.typ) | 14 | [45 minut i rozwiązania](notes/zsr-w06.md) |
| 07 | [Bezpieczeństwo operacyjne](result/zsr-w07.pdf) · [Typst](zsr-w07.typ) | 14 | [45 minut i rozwiązania](notes/zsr-w07.md) |
| 08 | [Chmura dla operatora](result/zsr-w08.pdf) · [Typst](zsr-w08.typ) | 13 | [45 minut i rozwiązania](notes/zsr-w08.md) |
| 09 | [Infrastructure as Code](result/zsr-w09.pdf) · [Typst](zsr-w09.typ) | 14 | [45 minut i rozwiązania](notes/zsr-w09.md) |
| 10 | [IaC w zespole](result/zsr-w10.pdf) · [Typst](zsr-w10.typ) | 13 | [45 minut i rozwiązania](notes/zsr-w10.md) |
| 11 | [SRE i incydenty](result/zsr-w11.pdf) · [Typst](zsr-w11.typ) | 15 | [45 minut i rozwiązania](notes/zsr-w11.md) |
| 12 | [HA, backup i disaster recovery](result/zsr-w12.pdf) · [Typst](zsr-w12.typ) | 14 | [45 minut i rozwiązania](notes/zsr-w12.md) |
| 13 | [Koszt i złożoność operacyjna](result/zsr-w13.pdf) · [Typst](zsr-w13.typ) | 13 | [45 minut i rozwiązania](notes/zsr-w13.md) |
| 14 | [Compliance i ISO/IEC 27001](result/zsr-w14.pdf) · [Typst](zsr-w14.typ) | 13 | [45 minut i rozwiązania](notes/zsr-w14.md) |
| 15 | [Przypadek przekrojowy](result/zsr-w15.pdf) · [Typst](zsr-w15.typ) | 15 | [45 minut i rozwiązania](notes/zsr-w15.md) |

Liczba stron obejmuje tytuł i bibliografię. W1 zawiera wprowadzenie do przedmiotu oraz przedstawienie prowadzącego. Nix znajduje się w W2, przy odtwarzalności budowania. W15 jest przypadkiem z kolejnymi porcjami dowodów; wskazówki dotyczące kolejności ich ujawniania są w notatkach.

## Prowadzenie

Każdy plik w `notes/` zawiera przebieg od 0 do 45 min, założenia przykładów, odpowiedzi i wskazówki skrócenia dyskusji. Budżety są planem prowadzenia, nie wynikiem próby czasowej.

Dane incydentów, obciążenia i kwoty są dydaktyczne, a nie opisem konkretnego klienta ani ofertą dostawcy. Fragmenty YAML, HCL i potoków mają oznaczone pominięcia. Nie są kompletnymi instrukcjami wdrożenia. Rachunki należy omawiać wraz z założeniami i ograniczeniami.

## Budowanie

Z katalogu `lectures-zsr/`:

```sh
nix build path:.
```

PDF-y `zsr-w01.pdf`–`zsr-w15.pdf` znajdują się w `result/`. Użycie `path:.` uwzględnia także nowe pliki przed dodaniem ich do Git. Nix dostarcza Typst, pakiet slajdów i fonty DejaVu; `flake.lock` przypina wejścia.

Po każdej zmianie źródeł należy przebudować PDF-y. CI kompiluje `zsr-w*.typ`; same notatki prowadzącego nie są slajdami.

## Redakcja i sprawdzenie — 26.09.2026

- W1: jawny przepływ z outbox, idempotencja i ostrożniejsza interpretacja incydentu.
- W2–W4: Dockerfile, cache, wolumen, Nix, model Kubernetes, selektory, sondy, HPA i OOM.
- W5–W7: PromQL, histogram, trace i log; promocja obrazu, GitOps, zgodność danych, podpis i provenance.
- W8–W10: modele usług i kosztów, HCL, plan, moved, moduły, backend, blokada i drift.
- W11–W14: rachunki SLO i RTO/RPO, PITR, koszty i analiza dowodów kontroli.
- W15: niezgodność formatów, brak obrazu, DLQ, dodatkowe usunięcie danych i plan odzyskania.

Sprawdzenie obejmuje kompilację 15 PDF-ów, liczbę stron względem deklaracji slajdów, granice tekstu, przegląd wizualny wszystkich stron w zestawieniach oraz powiększone strony z kodem i diagramami. Budżety wszystkich notatek obejmują ciągły przedział 0–45 min. Sprawdzono również składnię 8 fragmentów YAML, 1 JSON i 4 fragmentów powłoki (bez wykonywania poleceń). Referencje prowadzą do dokumentacji autorów narzędzi, standardów i literatury; przy SoA odróżniono normę od noty edukacyjnej APG.

Nie przeprowadzono próby wygłoszenia wykładów ani uruchomienia fragmentów na rzeczywistej infrastrukturze. To pozostaje osobnym etapem przed demonstracją na żywo.

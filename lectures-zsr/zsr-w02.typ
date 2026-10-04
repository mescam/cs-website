#import "@preview/typslides:1.3.2": *
#import "zsr-theme.typ": *
#import emoji: cloud
#show: typslides.with(ratio: "16-9", theme: kolor-pp, font: "DejaVu Sans", font-size: 20pt, show-progress: true, show-page-numbers: true)
#set text(lang: "pl")
#front-slide(title: "Kontenery w eksploatacji", subtitle: [Izolacja, budowanie obrazu i trwałość danych], authors: "mgr inż. Jakub Woźniak", info: [Zarządzanie Systemami Rozproszonymi · Semestr zimowy 2026/27])
#slide(title: [Od źródeł do procesu])[
#flow[Źródła][Build][Obraz OCI][Rejestr][Kontener]
- Obraz: warstwy systemu plików, konfiguracja, identyfikator treści.
- Kontener: instancja uruchomienia obrazu; procesy i warstwa zapisywalna.
- Ten sam obraz, różne adresy usług i tożsamości przy uruchomieniu.
#src[#link("https://github.com/opencontainers/image-spec")[OCI — Image Format Specification]]
]
#slide(title: [Maszyna wirtualna i kontener])[
#data-table(3,
[Warstwa],
[Maszyny wirtualne],
[Kontenery Linux],
[Aplikacje],
[Procesy w każdej VM],
[Procesy w kontenerach],
[Izolacja OS],
[Osobne jądra gości],
[Wspólne jądro hosta],
[Podstawa],
[Hypervisor i sprzęt],
[Namespaces i cgroups],
[Konsekwencja],
[Własny system gościa],
[Zależność od jądra hosta],
)
#src[Docker Desktop może uruchamiać kontenery Linux wewnątrz VM.]
]
#slide(title: [Namespaces, cgroups i uprawnienia])[
#data-table(3,
[Mechanizm],
[Przykład],
[Czego nie zapewnia],
[Namespaces],
[Osobny widok PID, sieci, mountów],
[Odporności na błąd jądra],
[cgroups],
[Limit pamięci; udział CPU],
[Poprawności aplikacji],
[UID / capabilities],
[Proces bez uprawnień administratora],
[Pełnej izolacji samodzielnie],
)
- Root w kontenerze: zależny od mapowania użytkowników i uprawnień runtime.
- Unikać trybu privileged i udostępniania socketu Dockera.
#src[#link("https://docs.docker.com/engine/security/")[Docker — Security]]
]
#slide(title: [Dockerfile: narzędzia builda w obrazie])[
#codebox[
```dockerfile
FROM golang:1.26
WORKDIR /src
COPY . .
RUN go build -o /worker ./cmd/worker
CMD ["/worker"]
```
]
- Obraz końcowy zawiera kompilator i źródła.
- Zmiana dowolnego kopiowanego pliku unieważnia cache kolejnych kroków.
#src[Przykład: projekt Go z go.mod i go.sum; tag wersji nie jest niezmiennym digestem.]
]
#slide(title: [Multistage: osobny build i runtime])[
#codebox[
```dockerfile
FROM golang:1.26 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /worker ./cmd/worker
FROM scratch
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /worker /worker
USER 65532:65532
ENTRYPOINT ["/worker"]
```
]
#sm[Założenie: statyczny worker bez potrzeby powłoki i dodatkowych plików runtime.]
#src[#link("https://docs.docker.com/build/building/multi-stage/")[Docker — Multi-stage builds]]
]
#slide(title: [Cache, tag i digest])[
#data-table(2,
[Zmiana],
[Skutek w przykładzie],
[Tylko plik .go],
[Ponowienie COPY źródeł i kompilacji],
[go.mod / go.sum],
[Ponowne pobranie modułów i kompilacja],
[Zawartość tagu bazowego],
[Możliwy inny obraz przy kolejnym buildzie],
)
- Digest identyfikuje zawartość obrazu; tag może wskazywać inną zawartość.
- Przypięcie bazy nie przypina pakietów pobranych później z ruchomego repozytorium.
#src[#link("https://docs.docker.com/build/cache/invalidation/")[Docker — Cache invalidation]]
]
#slide(title: [Usunięcie kontenera a usunięcie danych])[
#codebox[
```bash
docker volume create orders-demo
docker run --rm -v orders-demo:/data alpine:3.23 \
  sh -c 'echo 42 > /data/order-id'
docker run --rm -v orders-demo:/data alpine:3.23 \
  cat /data/order-id
```
]
- Drugi kontener odczytuje `42` z tego samego wolumenu.
- Bez montowania: plik z warstwy kontenera znika wraz z jego usunięciem.
- Wolumen na jednym hoście nie jest backupem ani replikacją.
#src[#link("https://docs.docker.com/engine/storage/volumes/")[Docker — Volumes]]
]
#slide(title: [Konfiguracja i zakończenie procesu])[
#codebox[
```bash
docker run --read-only --memory=256m \
  --env QUEUE_URL=https://queue.example.test \
  --mount type=bind,src=/run/worker-token,dst=/run/token,readonly \
  registry.example.test/worker:v2
```
]
- Przykład wymaga obrazu i istniejącego pliku tokenu.
- SIGTERM: zatrzymanie pobierania, dokończenie lub oddanie wiadomości.
- ACK dopiero po trwałym skutku; ponowne dostarczenie musi być bezpieczne.
#src[Adresy przykładowe. Preferować tożsamość workloadu, gdy platforma ją udostępnia.]
]
#slide(title: [Nix i reprodukowalność budowania])[
#flow[flake.lock][Nix: narzędzia i fonty][Typst][PDF]
- Ten kurs: przypięte wejścia Nix, kompilator Typst, pakiet slajdów i fonty.
- Nix może także budować obrazy OCI; kontener może służyć jako środowisko builda.
- Identyczne wejścia i izolacja ograniczają zmienność środowiska.
#alertblock[Granica gwarancji][Identyczne bity wymagają również deterministycznego builda: bez zmiennych dat, losowości i niekontrolowanych wejść.]
#src[#link("https://reproducible.nixos.org/")[NixOS — Reproducible Builds]]
]
#slide(title: [#cloud Rejestr Azure Container Registry])[
#flow[CI: push digest][ACR][AKS: pull digest]
- Osobne uprawnienia publikowania i pobierania.
- Retencja obrazów: zachować wersje potrzebne do rollbacku.
- Przypięty digest daje identyfikację; aktualizacje bezpieczeństwa wymagają nowego builda.
#src[#link("https://learn.microsoft.com/azure/container-registry/container-registry-intro")[Microsoft — Introduction to container registries]]
]
#slide(title: [#cloud Trwałość danych w usłudze kontenerowej])[
#data-table(3,
[Dane],
[Przykładowe miejsce],
[Pytanie operacyjne],
[Pliki tymczasowe],
[Lokalny filesystem kontenera],
[Czy mogą zniknąć przy wymianie?],
[Zamówienia],
[Zarządzana baza danych],
[Jak wykonać i sprawdzić restore?],
[Załączniki],
[Object storage],
[Jaka retencja i wersjonowanie?],
)
#sm[Konkretny typ magazynu zależy od platformy; samo użycie kontenera niczego tu nie gwarantuje.]
]
#slide(title: [Przypadek: dwa buildy, jeden commit])[
#data-table(3,
[Właściwość],
[Build A],
[Build B],
[Commit / Dockerfile],
[Identyczne],
[Identyczne],
[Baza po digescie],
[Identyczna],
[Identyczna],
[RUN apt-get install libfoo],
[Repozytorium w poniedziałek],
[Repozytorium w piątek],
[Cache],
[Dostępny],
[Pusty],
)
#alertblock[Do rozstrzygnięcia][Czy obrazy muszą być identyczne? Jakie wejścia należy ustalić? Jak niezależnie sprawdzić reprodukowalność?]
]
#slide(title: [Źródła i lektury])[
#text(size: 16pt)[
- #link("https://docs.docker.com/build/building/multi-stage/")[Docker — Multi-stage builds]
- #link("https://docs.docker.com/build/cache/invalidation/")[Docker — Cache invalidation]
- #link("https://docs.docker.com/engine/storage/volumes/")[Docker — Volumes]
- #link("https://github.com/opencontainers/image-spec")[OCI — Image Format Specification]
- #link("https://reproducible.nixos.org/")[NixOS — Reproducible Builds]
- #link("https://learn.microsoft.com/azure/container-registry/container-registry-intro")[Microsoft — Azure Container Registry]
]
#src[Dokumentacja sprawdzona: 26.09.2026. Dane przypadków: przykłady dydaktyczne.]
]

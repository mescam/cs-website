#import "@preview/typslides:1.3.2": *
#import "zsr-theme.typ": *
#import emoji: cloud
#show: typslides.with(ratio: "16-9", theme: kolor-pp, font: "DejaVu Sans", font-size: 20pt, show-progress: true, show-page-numbers: true)
#set text(lang: "pl")
#front-slide(title: "Bezpieczeństwo operacyjne", subtitle: [Tożsamości, sekrety i pochodzenie artefaktu], authors: "mgr inż. Jakub Woźniak", info: [Zarządzanie Systemami Rozproszonymi · Semestr zimowy 2026/27])
#slide(title: [Model zagrożeń dla workera])[
#flow[Repozytorium][CI][Rejestr][Worker][Kolejka / baza]
#data-table(3,
[Punkt],
[Zagrożenie],
[Możliwy skutek],
[CI],
[Wykonanie kodu niezaufanego PR],
[Kradzież uprawnień wydania],
[Rejestr],
[Podmiana wskazania tagu],
[Uruchomienie innego obrazu],
[Worker],
[Przejęcie procesu],
[Dostęp do danych z jego rolą],
)
#sm[Granice zaufania wyznaczają osobne tożsamości i zasady dostępu.]
]
#slide(title: [Uwierzytelnienie i autoryzacja])[
#data-table(3,
[Pytanie],
[Mechanizm],
[Przykład],
[Kto wykonuje operację?],
[Token / certyfikat / tożsamość],
[worker-prod],
[Co może zrobić?],
[Rola i zakres],
[Odbiór z kolejki orders],
[Czy było dozwolone?],
[Log audytowy i decyzja polityki],
[Receive: allow; Delete: deny],
)
- Dostęp sieciowy do endpointu nie nadaje uprawnień do danych.
- Wspólna tożsamość wszystkich usług zwiększa zasięg przejęcia.
]
#slide(title: [Minimalny zakres roli])[
#data-table(3,
[Podmiot],
[Uprawnienie],
[Zakres],
[API / publisher],
[Wysyłanie wiadomości],
[Kolejka orders],
[Worker],
[Odbiór i potwierdzenie],
[Kolejka orders],
[Potok IaC],
[Zarządzanie zasobem],
[Wybrane środowisko],
)
- Worker nie potrzebuje usuwania kolejki ani zarządzania rolami.
- Rozdzielenie control plane i data plane.
#src[#link("https://learn.microsoft.com/azure/service-bus-messaging/service-bus-managed-service-identity")[Microsoft — Service Bus managed identities]]
]
#slide(title: [Sekret jako konfiguracja wrażliwa])[
#flow[Magazyn sekretów][Tożsamość workloadu][Proces]
- Token w obrazie lub repozytorium pozostaje w historii artefaktów.
- Base64 w Kubernetes Secret jest kodowaniem, nie szyfrowaniem.
- Potrzebne kontrola odczytu, szyfrowanie magazynu i ograniczenie montowania.
- Odczyt Secret i możliwość uruchomienia Poda wymagają wspólnej analizy uprawnień.
#src[#link("https://kubernetes.io/docs/concepts/security/secrets-good-practices/")[Kubernetes — Secrets good practices]]
]
#slide(title: [Rotacja bez przerwy w działaniu])[
#flow[Nowy sekret][Podwójna akceptacja][Zmiana klientów][Wycofanie starego]
- Sprawdzić, czy proces odczytuje sekret ponownie, czy tylko przy starcie.
- Okno zgodności ograniczone; pomiar użycia starego poświadczenia.
- Przy kompromitacji: pilne unieważnienie i analiza użycia; płynna rotacja może nie wystarczyć.
#sm[Tokeny krótkotrwałe ograniczają czas użycia, ale nie usuwają potrzeby kontroli ról.]
]
#slide(title: [SBOM, skan, podpis, provenance])[
#data-table(3,
[Artefakt],
[Odpowiada na pytanie],
[Nie dowodzi],
[SBOM],
[Jakie składniki zadeklarowano?],
[Braku podatności],
[Skan],
[Jakie znane problemy wykryto?],
[Braku błędów nieznanych],
[Podpis],
[Czy treść pasuje do podpisu i zaufania?],
[Bezpieczeństwa kodu],
[Provenance],
[Z czego i gdzie wykonano build?],
[Poprawności funkcjonalnej],
)
#src[#link("https://slsa.dev/spec/v1.2/")[SLSA 1.2 — Specification]]
]
#slide(title: [Przykład: SBOM i wynik skanu])[
#codebox[
```text
# Wyciąg dydaktyczny, format tabelaryczny
COMPONENT       VERSION   SOURCE
libexample      2.4.0     image layer sha256:aaa...

FINDING         FIXED IN  REACHABILITY
DEMO-2026-001   2.4.1     wymaga sprawdzenia
```
]
- Identyfikator podatności fikcyjny. Dopasowanie pakietu nie dowodzi wykorzystania błędu.
- Priorytet: ekspozycja, osiągalność kodu, skutek i dostępność poprawki.
- Wyjątek od polityki: właściciel, powód, termin i działanie ograniczające ryzyko.
]
#slide(title: [Provenance: powiązanie wejścia z wynikiem])[
#codebox[
```yaml
subject:
  name: worker
  digest: sha256:abc...
buildDefinition:
  resolvedDependencies:
    - uri: git+https://example.test/orders
      digest: {gitCommit: "9c81..."}
runDetails:
  builder: https://ci.example.test/trusted-builder
```
]
#sm[Schemat poglądowy, nie pełna atestacja SLSA. Wielokropki zastępują pełne identyfikatory.]
- Sprawdzić digest wyniku, oczekiwany builder, repozytorium i rewizję.
#src[#link("https://slsa.dev/spec/v1.2/provenance")[SLSA 1.2 — Provenance]]
]
#slide(title: [Weryfikacja podpisu wymaga polityki zaufania])[
#codebox[
```bash
cosign verify \
  --certificate-identity "$EXPECTED_IDENTITY" \
  --certificate-oidc-issuer "$EXPECTED_ISSUER" \
  "$IMAGE_BY_DIGEST"
```
]
- Zmienne ustala polityka wydania; nie dane dostarczone przez autora obrazu.
- Podpis zgodny kryptograficznie, lecz nieoczekiwany signer → odrzucenie.
- Zaufany signer z przejętym buildem nadal może podpisać szkodliwy obraz.
#src[#link("https://docs.sigstore.dev/cosign/verifying/verify/")[Sigstore — Verifying signatures]]
]
#slide(title: [#cloud Managed identity workera])[
#flow[Worker][Token Microsoft Entra][Service Bus: Data Receiver]
- Rola na konkretnej kolejce zamiast całej subskrypcji.
- Brak współdzielonego hasła w konfiguracji aplikacji.
- Przejęty proces nadal działa z uprawnieniami swojej tożsamości.
#src[#link("https://learn.microsoft.com/azure/service-bus-messaging/service-bus-managed-service-identity")[Microsoft — Service Bus managed identities]]
]
#slide(title: [#cloud Kontrola dopuszczenia do klastra])[
#flow[Żądanie wdrożenia][Polityka admission][Dopuszczenie / odmowa]
- Sprawdzenie dozwolonego rejestru, digestu i wymaganych poświadczeń.
- Polityka wymaga wdrożonego kontrolera weryfikacji; Kubernetes nie robi tego automatycznie.
- Awaria weryfikatora: jawna decyzja o dostępności i zachowaniu fail-closed.
#src[#link("https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/")[Kubernetes — Admission controllers]]
]
#slide(title: [Przypadek: obraz podpisany, ale obcy])[
#data-table(2,
[Warunek polityki],
[Odczyt z atestacji],
[Repozytorium: org/orders],
[org/orders],
[Builder: trusted-prod],
[personal-runner],
[Commit: zatwierdzony 9c81…],
[9c81…],
[Podpis],
[Poprawny, tożsamość innego workflow],
)
#alertblock[Decyzja][Dopuścić obraz? Które kontrole przechodzą, które zawodzą? Czy czysty skan zmienia decyzję?]
]
#slide(title: [Źródła i lektury])[
#text(size: 16pt)[
- #link("https://csrc.nist.gov/pubs/sp/800/190/final")[NIST SP 800-190 — Application Container Security Guide]
- #link("https://kubernetes.io/docs/concepts/security/secrets-good-practices/")[Kubernetes — Secrets good practices]
- #link("https://slsa.dev/spec/v1.2/")[SLSA 1.2 — Specification]
- #link("https://docs.sigstore.dev/cosign/verifying/verify/")[Sigstore — Verifying signatures]
- #link("https://learn.microsoft.com/azure/service-bus-messaging/service-bus-managed-service-identity")[Microsoft — Service Bus managed identities]
]
#src[Dokumentacja sprawdzona: 26.09.2026. Dane przypadków: przykłady dydaktyczne.]
]

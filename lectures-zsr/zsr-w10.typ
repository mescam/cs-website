#import "@preview/typslides:1.3.2": *
#import "zsr-theme.typ": *
#import emoji: cloud
#show: typslides.with(ratio: "16-9", theme: kolor-pp, font: "DejaVu Sans", font-size: 20pt, show-progress: true, show-page-numbers: true)
#set text(lang: "pl")
#front-slide(title: "IaC w zespole", subtitle: [Moduły, współdzielony stan i kontrola współbieżności], authors: "mgr inż. Jakub Woźniak", info: [Zarządzanie Systemami Rozproszonymi · Semestr zimowy 2026/27])
#slide(title: [Dwie zmiany tego samego środowiska])[
#flow[Anna: plan A][Wspólny state][Bartek: plan B]
- Przegląd Git kontroluje kod, ale nie blokuje równoległych operacji na zasobach.
- Potrzebne wspólne mapowanie zasobów i zasada wykonywania zmian.
- Oddzielne pliki state nie mogą niezależnie zarządzać tym samym obiektem.
]
#slide(title: [Moduł: interfejs dla użytkownika])[
#codebox[
```hcl
module "orders_queue" {
  source             = "./modules/queue"
  namespace_id       = var.namespace_id
  name               = "orders"
  max_delivery_count = 10
}

output "orders_queue_id" {
  value = module.orders_queue.id
}
```
]
- Moduł ukrywa strukturę, ale ujawnia istotne decyzje.
- Wersja modułu zdalnego musi być kontrolowana osobno od locka providerów.
]
#slide(title: [Walidacja wejścia modułu])[
#codebox[
```hcl
variable "max_delivery_count" {
  type    = number
  default = 10
  validation {
    condition = (
      var.max_delivery_count >= 1 &&
      floor(var.max_delivery_count) == var.max_delivery_count
    )
    error_message = "Wymagana dodatnia liczba całkowita."
  }
}
```
]
- Typ i walidacja ograniczają błędy wejścia; test zachowania wymaga planu i sprawdzenia usługi.
#src[#link("https://developer.hashicorp.com/terraform/language/values/variables")[Terraform — Input variables]]
]
#slide(title: [Podział state i uprawnień])[
#data-table(3,
[State],
[Właściciel],
[Powód rozdzielenia],
[network-prod],
[Zespół platformy],
[Inne uprawnienia i rytm zmian],
[orders-prod],
[Zespół usługi],
[Cykl życia aplikacji],
[orders-test],
[Zespół usługi],
[Izolacja środowiska testowego],
)
- Granica state wyznacza zasięg planu, blokady i dostępu.
- Więcej stanów → więcej jawnych zależności i kolejności zmian.
]
#slide(title: [#cloud Backend Azure Blob])[
#codebox[
```hcl
terraform {
  backend "azurerm" {
    storage_account_name = "zsrstateexample"
    container_name       = "tfstate"
    key                  = "orders/prod.tfstate"
    use_azuread_auth      = true
  }
}
```
]
- Magazyn utworzony wcześniej; nazwa przykładowa. Uwierzytelnienie przez środowisko.
- Backend azurerm obsługuje blokowanie z użyciem mechanizmów Blob Storage.
#src[#link("https://developer.hashicorp.com/terraform/language/backend/azurerm")[Terraform — azurerm backend]]
]
#slide(title: [Zakres blokady state])[
#data-table(3,
[Czas],
[Anna],
[Bartek],
[10:00],
[Zajmuje blokadę state],
[—],
[10:01],
[Wykonuje apply],
[Czeka na tę samą blokadę],
[10:03],
[Zapisuje state, zwalnia lock],
[Może ponowić operację],
)
- Obsługa blokady zależy od backendu.
- Lock nie blokuje portalu chmury ani operacji na innym state.
- Force-unlock dopiero po potwierdzeniu, że właściciel blokady nie działa.
#src[#link("https://developer.hashicorp.com/terraform/language/state/locking")[Terraform — State locking]]
]
#slide(title: [Zapisany plan może się zdezaktualizować])[
#codebox[
```text
10:00  plan A zapisany dla state o serial 41
10:02  apply B zmienia state: serial 42
10:05  próba apply A
       Error: Saved plan is stale
```
]
- Wygenerować nowy plan z aktualnym stanem i ponownie ocenić różnice.
- Lock nie jest utrzymywany przez cały czas ręcznego przeglądu planu.
- Zmiana poza Terraformem wymaga świeżego odczytu; serial nie wykrywa wszystkiego.
#src[#link("https://developer.hashicorp.com/terraform/cli/commands/plan")[Terraform — plan]]
]
#slide(title: [Drift: trzy możliwe decyzje])[
#data-table(3,
[Sytuacja],
[Działanie],
[Wynik],
[Ręczna zmiana była błędem],
[Plan przywracający konfigurację],
[Zmiana zasobu],
[Ręczna zmiana była potrzebna],
[Aktualizacja kodu i przegląd planu],
[Nowa intencja w repozytorium],
[Potrzebna aktualizacja zapisu stanu],
[Przegląd refresh-only],
[Uzgodniony state, nie naprawa zasobu],
)
#src[#link("https://developer.hashicorp.com/terraform/cli/commands/plan#planning-modes")[Terraform — Planning modes]]
]
#slide(title: [Sekrety w state i planie])[
#defblock[sensitive][Ogranicza pokazywanie wartości w wyjściu narzędzia; nie jest ogólną gwarancją usunięcia jej ze state.]
- Pliki planów i state traktować jako dane chronione.
- Tożsamości federacyjne zamiast stałego klucza w backend config.
- Oddzielić użytkownika przeglądającego kod od pełnego odczytu danych stanu.
#src[#link("https://developer.hashicorp.com/terraform/language/manage-sensitive-data")[Terraform — Sensitive data]]
]
#slide(title: [#cloud Dostępność i odtwarzanie backendu])[
#flow[Tożsamość CI][Sieć / DNS][Blob + lock][Historia state]
- Backend niedostępny: infrastruktura może działać, ale apply jest zablokowany.
- Historia wersji pomaga odtworzyć plik, nie cofa zasobów w chmurze.
- Przywrócony state porównać z rzeczywistymi ID i konfiguracją przed zmianą.
]
#slide(title: [Przypadek: blokada i ręczna zmiana])[
#codebox[
```text
10:00  pipeline A: apply w toku
10:01  operator: portal, max_delivery_count 10 -> 3
10:02  pipeline B: Error acquiring the state lock
10:03  propozycja: force-unlock i apply B
```
]
#alertblock[Decyzja][Co wolno zrobić teraz? Czy lock ochronił przed zmianą w portalu? Jak uzgodnić kod, state i zasób po zakończeniu A?]
]
#slide(title: [Źródła i lektury])[
#text(size: 16pt)[
- #link("https://developer.hashicorp.com/terraform/language/values/variables")[Terraform — Input variables]
- #link("https://developer.hashicorp.com/terraform/language/backend/azurerm")[Terraform — azurerm backend]
- #link("https://developer.hashicorp.com/terraform/language/state/locking")[Terraform — State locking]
- #link("https://developer.hashicorp.com/terraform/cli/commands/plan#planning-modes")[Terraform — Planning modes]
- #link("https://developer.hashicorp.com/terraform/language/manage-sensitive-data")[Terraform — Sensitive data]
]
#src[Dokumentacja sprawdzona: 26.09.2026. Dane przypadków: przykłady dydaktyczne.]
]

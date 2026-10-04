#import "@preview/typslides:1.3.2": *
#import "zsr-theme.typ": *
#import emoji: cloud
#show: typslides.with(ratio: "16-9", theme: kolor-pp, font: "DejaVu Sans", font-size: 20pt, show-progress: true, show-page-numbers: true)
#set text(lang: "pl")
#front-slide(title: "Infrastructure as Code", subtitle: [Konfiguracja, graf zależności, plan i state], authors: "mgr inż. Jakub Woźniak", info: [Zarządzanie Systemami Rozproszonymi · Semestr zimowy 2026/27])
#slide(title: [Trzy źródła informacji])[
#data-table(3,
[Element],
[Przykład],
[Rola],
[Konfiguracja],
[name = "orders"],
[Intencja zespołu],
[State],
[Adres → zdalne ID],
[Powiązanie obiektu z deklaracją],
[API dostawcy],
[Bieżąca kolejka i właściwości],
[Odczyt rzeczywistości przez provider],
)
#flow[Konfiguracja + state + odczyt API][Plan][Apply]
#src[#link("https://developer.hashicorp.com/terraform/language/state")[Terraform — State]]
]
#slide(title: [Provider i wersje zależności])[
#codebox[
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
provider "azurerm" {
  features {}
}
```
]
- Ograniczenie dopuszcza serię 4.x; plik lock wybiera konkretną wersję providera.
- Uwierzytelnienie i subskrypcja dostarczone przez środowisko.
#src[#link("https://developer.hashicorp.com/terraform/language/files/dependency-lock")[Terraform — Dependency lock file]]
]
#slide(title: [Deklaracja kolejki])[
#codebox[
```hcl
resource "azurerm_servicebus_queue" "orders" {
  name               = "orders"
  namespace_id       = azurerm_servicebus_namespace.main.id
  max_delivery_count = 10
}

output "queue_id" {
  value = azurerm_servicebus_queue.orders.id
}
```
]
- Fragment wymaga istniejącej deklaracji namespace `main`.
- Adres w konfiguracji: `azurerm_servicebus_queue.orders`.
- Zdalne ID: identyfikator kolejki zwrócony przez Azure.
#src[#link("https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_queue")[AzureRM — Service Bus Queue]]
]
#slide(title: [Graf zależności])[
#flow[Resource group][Namespace][Queue][Role assignment]
- Odwołanie do `.id` tworzy zależność; kolejność tekstu w pliku jej nie zastępuje.
- Niezależne zasoby mogą być obsługiwane równolegle.
- Kolejka utworzona przed nadaniem roli nie oznacza natychmiastowej gotowości całej aplikacji.
#src[#link("https://developer.hashicorp.com/terraform/language/expressions/references#named-values-and-dependencies")[Terraform — Resource dependencies]]
]
#slide(title: [Cykl zmiany infrastruktury])[
#codebox[
```bash
terraform init
terraform fmt -check
terraform validate
terraform plan -out=reviewed.tfplan
terraform show reviewed.tfplan
terraform apply reviewed.tfplan
```
]
- `validate`: poprawność konfiguracji, nie gwarancja dostępności zasobów w chmurze.
- Zapisany plan: konkretny przedmiot przeglądu; może zawierać dane wrażliwe.
#src[#link("https://developer.hashicorp.com/terraform/cli/commands/plan")[Terraform — plan]]
]
#slide(title: [Plan: zmiana właściwości])[
#codebox[
```text
# Skrócony, przykładowy wynik planu
~ resource "azurerm_servicebus_queue" "orders" {
    name               = "orders"
  ~ max_delivery_count = 10 -> 5
}

Plan: 0 to add, 1 to change, 0 to destroy.
```
]
- `~`: proponowana aktualizacja bez zastąpienia w tym planie.
- Mniej prób dostarczenia → wcześniejsze przeniesienie problematycznej wiadomości do DLQ.
- Brak destroy nie oznacza braku wpływu na zachowanie usługi.
]
#slide(title: [State: mapowanie i skutki utraty])[
#codebox[
```text
azurerm_servicebus_queue.orders
  -> /subscriptions/.../namespaces/shop/queues/orders
```
]
- Usunięcie lokalnego state nie usuwa automatycznie kolejki w chmurze.
- Utrata mapowania utrudnia zarządzanie istniejącym zasobem; możliwy konflikt tworzenia.
- Odtworzenie state lub import wymaga sprawdzenia zgodności z konfiguracją.
#src[#link("https://developer.hashicorp.com/terraform/language/state/purpose")[Terraform — State purpose]]
]
#slide(title: [Refaktoryzacja adresu: moved])[
#codebox[
```hcl
# Zmiana etykiety bloku: orders -> incoming
resource "azurerm_servicebus_queue" "incoming" {
  name         = "orders"
  namespace_id = azurerm_servicebus_namespace.main.id
}
moved {
  from = azurerm_servicebus_queue.orders
  to   = azurerm_servicebus_queue.incoming
}
```
]
- Nazwa zdalnej kolejki pozostaje `orders`.
- `moved` zachowuje powiązanie; pozostałe właściwości także muszą być zgodne.
#src[#link("https://developer.hashicorp.com/terraform/language/modules/develop/refactoring")[Terraform — Refactor modules]]
]
#slide(title: [Zmiana nazwy zdalnego zasobu])[
#codebox[
```text
# Skrót planu dla zmiany właściwości name
-/+ resource "azurerm_servicebus_queue" "orders" {
  ~ name = "orders" -> "orders-v2" # forces replacement
}

Plan: 1 to add, 0 to change, 1 to destroy.
```
]
- W tym zasobie provider wymaga zastąpienia przy zmianie `name`.
- `moved` nie migruje wiadomości między dwiema kolejkami.
#src[#link("https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_queue")[AzureRM — Service Bus Queue: name]]
]
#slide(title: [#cloud Kolejka i rola odbiorcy])[
#codebox[
```hcl
resource "azurerm_role_assignment" "receiver" {
  scope                = azurerm_servicebus_queue.orders.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = var.worker_principal_id
}
```
]
- Fragment: tożsamość workera utworzona osobno; input to jej principal ID.
- Zakres na konkretnej kolejce; brak hasła w deklaracji.
- Nadanie roli wymaga uprawnienia operatora IaC do zarządzania dostępem.
#src[#link("https://learn.microsoft.com/azure/service-bus-messaging/service-bus-managed-service-identity")[Microsoft — Service Bus managed identities]]
]
#slide(title: [#cloud Plan nie jest transakcją całej chmury])[
#flow[Queue: utworzona][Rola: błąd uprawnień][Apply przerwany]
- Część działań może zostać wykonana przed błędem.
- Sprawdzić stan zdalny i state; poprawić przyczynę, wygenerować nowy plan.
- Nie zakładać automatycznego cofnięcia wszystkich zasobów.
#src[#link("https://developer.hashicorp.com/terraform/cli/commands/apply")[Terraform — apply]]
]
#slide(title: [Przypadek: „tylko porządki w nazwach”])[
#data-table(2,
[Zmiana A],
[Zmiana B],
[Etykieta bloku orders → incoming],
[Właściwość name: orders → orders-v2],
[Zdalna nazwa bez zmian],
[Zdalna nazwa inna],
[Cel: czytelniejszy kod],
[Cel: nowa kolejka produkcyjna],
)
#alertblock[Przegląd][Gdzie użyć moved? Kiedy potrzebna migracja wiadomości i odbiorców? Jakie linie planu wymagają zatrzymania zmiany?]
]
#slide(title: [Źródła i lektury])[
#text(size: 16pt)[
- #link("https://developer.hashicorp.com/terraform/language/state")[Terraform — State]
- #link("https://developer.hashicorp.com/terraform/cli/commands/plan")[Terraform — plan]
- #link("https://developer.hashicorp.com/terraform/language/files/dependency-lock")[Terraform — Dependency lock file]
- #link("https://developer.hashicorp.com/terraform/language/modules/develop/refactoring")[Terraform — Refactor modules]
- #link("https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_queue")[AzureRM — Service Bus Queue]
- #link("https://developer.hashicorp.com/terraform/cli/commands/apply")[Terraform — apply]
]
#src[Dokumentacja sprawdzona: 26.09.2026. Dane przypadków: przykłady dydaktyczne.]
]

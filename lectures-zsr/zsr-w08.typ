#import "@preview/typslides:1.3.2": *
#import "zsr-theme.typ": *
#import emoji: cloud
#show: typslides.with(ratio: "16-9", theme: kolor-pp, font: "DejaVu Sans", font-size: 20pt, show-progress: true, show-page-numbers: true)
#set text(lang: "pl")
#front-slide(title: "Chmura dla operatora", subtitle: [Podział odpowiedzialności, lokalizacja i model kosztów], authors: "mgr inż. Jakub Woźniak", info: [Zarządzanie Systemami Rozproszonymi · Semestr zimowy 2026/27])
#slide(title: [IaaS, PaaS i SaaS])[
#data-table(3,
[Model],
[Przykład],
[Obszar zespołu],
[IaaS],
[Azure Virtual Machines],
[OS, runtime, aplikacja i dane],
[PaaS],
[Zarządzana baza PostgreSQL],
[Schemat, zapytania, dostęp, konfiguracja],
[SaaS],
[Gotowa usługa pocztowa],
[Konta, ustawienia, sposób użycia danych],
)
- Granice zależą od konkretnej usługi i umowy.
#src[#link("https://csrc.nist.gov/pubs/sp/800/145/final")[NIST SP 800-145 — Definition of Cloud Computing]]
]
#slide(title: [Ta sama baza na VM i jako usługa])[
#data-table(3,
[Zadanie],
[PostgreSQL na VM],
[Zarządzany PostgreSQL],
[Aktualizacja OS],
[Zespół],
[Dostawca platformy],
[Indeksy i zapytania],
[Zespół],
[Zespół],
[Backup],
[Projekt i utrzymanie],
[Konfiguracja usługi i sprawdzenie restore],
[Uprawnienia danych],
[Zespół],
[Zespół],
)
#src[#link("https://learn.microsoft.com/azure/security/fundamentals/shared-responsibility")[Microsoft — Shared responsibility]]
]
#slide(title: [Region i strefy dostępności])[
#defblock[Region R][#grid(columns: (1fr, 1fr, 1fr), gutter: 12pt, [Strefa A\ API + worker], [Strefa B\ API + worker], [Strefa C\ replika danych])]
- Strefa: wydzielona domena awarii infrastruktury wewnątrz regionu.
- Wiele instancji w jednej strefie nie chroni przed utratą tej strefy.
- Awaria regionu może dotknąć wszystkie jego strefy.
#src[#link("https://learn.microsoft.com/azure/reliability/availability-zones-overview")[Microsoft — Availability zones]]
]
#slide(title: [Rozmieszczenie zależności])[
#data-table(3,
[Komponent],
[Przykładowa konfiguracja],
[Pozostałe ryzyko],
[API],
[Repliki w A i B],
[Wspólny błąd wersji],
[Kolejka],
[Usługa z redundancją strefową],
[Błędne uprawnienia / usunięcie],
[Baza],
[Replikacja między strefami],
[Powielenie błędnego zapisu],
)
- Odporność usługi ogranicza jej zależność krytyczna.
- Dostępność konkretnej opcji zależy od usługi, regionu i SKU.
#src[#link("https://learn.microsoft.com/azure/reliability/availability-zones-overview")[Microsoft — Availability zones]]
]
#slide(title: [Control plane i data plane])[
#data-table(3,
[Operacja],
[Płaszczyzna],
[Przykład skutku awarii],
[Utworzenie kolejki],
[Control plane],
[Nie wdrożysz nowej infrastruktury],
[Odbiór wiadomości],
[Data plane],
[Worker nie przetworzy zadania],
[Zmiana roli],
[Control plane],
[Nie naprawisz uprawnień nową rolą],
)
- Działające żądania nie dowodzą, że można wykonać failover.
- Procedura awaryjna może zależeć od obu płaszczyzn.
]
#slide(title: [Tożsamość i sieć])[
#flow[Worker: tożsamość][Polityka dostępu][Kolejka]
- Sieć: którędy można się połączyć?
- Tożsamość: kto wykonuje operację?
- Uprawnienie: jakie działania i na jakim zasobie?
- Prywatny endpoint nie naprawia nadmiernej roli ani wycieku tokenu.
#src[#link("https://csrc.nist.gov/pubs/sp/800/207/final")[NIST SP 800-207 — Zero Trust Architecture]]
]
#slide(title: [Model kosztów: jednostka × ilość])[
#data-table(3,
[Składnik],
[Jednostka ilości],
[Model dydaktyczny],
[Obliczenia],
[Godziny instancji],
[Liczba × czas × stawka],
[Magazyn],
[GB-miesiąc],
[Średni zajęty rozmiar × stawka],
[Transfer],
[GB rozliczanego ruchu],
[Wolumen × stawka danej trasy],
[Żądania],
[Liczba operacji],
[Operacje × stawka],
)
- „Stały” oznacza stały przy danych założeniach obciążenia i rezerwacji.
- Transfer i magazyn nie są z definicji kosztami stałymi.
]
#slide(title: [Przykład: koszt miesięczny])[
#data-table(3,
[Składnik],
[Założenie],
[Koszt],
[2 instancje],
[2 × 720 h × 0,10 EUR/h],
[144 EUR],
[Magazyn],
[200 GB × 0,08 EUR/GB-mies.],
[16 EUR],
[Rozliczany transfer],
[500 GB × 0,06 EUR/GB],
[30 EUR],
[Razem],
[Tylko wskazane składniki],
[190 EUR],
)
#src[Stawki umowne do obliczenia; nie cennik Azure. Pominięte podatki, rabaty, backup i telemetria.]
]
#slide(title: [#cloud Wybór miejsca uruchomienia workera])[
#data-table(3,
[Wariant],
[Zespół zarządza],
[Istotne ograniczenie],
[VM],
[OS i procesem],
[Restart, patchowanie, skalowanie],
[AKS],
[Workloadem i politykami klastra],
[Pojemność oraz kompetencje operacyjne],
[Container Apps],
[Aplikacją i konfiguracją platformy],
[Model wykonania, limity i integracje],
)
- Wybór według czasu pracy, protokołów, skalowania i wymaganej kontroli.
#src[#link("https://learn.microsoft.com/azure/container-apps/overview")[Microsoft — Azure Container Apps overview]]
]
#slide(title: [#cloud Wybór regionu i usługi])[
#data-table(2,
[Warunek],
[Co sprawdzić przed wdrożeniem],
[Użytkownicy w Polsce],
[Pomiary opóźnień z ich sieci],
[Odporność na utratę strefy],
[Właściwe SKU i konfiguracja wszystkich zależności],
[Wymagania dotyczące danych],
[Lokalizacja danych, kopii i telemetrii],
[Odtworzenie],
[Czas, dostępność kopii i procedura],
)
#sm[RTO: docelowy czas przywrócenia. RPO: dopuszczalna utrata danych wyrażona czasem. Obliczenia: W12.]
]
#slide(title: [Przypadek: tańsza instancja czy mniej transferu?])[
#defblock[Założenie][Koszt bazowy: 190 EUR. Wariant A: obliczenia tańsze o 20%. Wariant B: transfer mniejszy o 50%. Koszty wdrożenia pominięte.]
- Który wariant daje większą oszczędność?
- Jakie pogorszenie działania może towarzyszyć mniejszej instancji?
- Co zmieni wynik po wzroście transferu dziesięciokrotnie?
]
#slide(title: [Źródła i lektury])[
#text(size: 16pt)[
- #link("https://csrc.nist.gov/pubs/sp/800/145/final")[NIST SP 800-145 — Cloud Computing]
- #link("https://learn.microsoft.com/azure/security/fundamentals/shared-responsibility")[Microsoft — Shared responsibility]
- #link("https://learn.microsoft.com/azure/reliability/availability-zones-overview")[Microsoft — Availability zones]
- #link("https://csrc.nist.gov/pubs/sp/800/207/final")[NIST SP 800-207 — Zero Trust]
- #link("https://learn.microsoft.com/azure/container-apps/overview")[Microsoft — Container Apps overview]
]
#src[Dokumentacja sprawdzona: 26.09.2026. Dane przypadków: przykłady dydaktyczne.]
]

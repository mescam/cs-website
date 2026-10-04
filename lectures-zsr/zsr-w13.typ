#import "@preview/typslides:1.3.2": *
#import "zsr-theme.typ": *
#import emoji: cloud
#show: typslides.with(ratio: "16-9", theme: kolor-pp, font: "DejaVu Sans", font-size: 20pt, show-progress: true, show-page-numbers: true)
#set text(lang: "pl")
#front-slide(title: "Koszt i złożoność operacyjna", subtitle: [Koszt jednostkowy, pojemność i zasoby przerywalne], authors: "mgr inż. Jakub Woźniak", info: [Zarządzanie Systemami Rozproszonymi · Semestr zimowy 2026/27])
#slide(title: [Koszt systemu zamówień])[
#data-table(3,
[Składnik / miesiąc],
[Koszt],
[Udział],
[Baza danych],
[1200 EUR],
[40%],
[Workery],
[900 EUR],
[30%],
[Telemetria],
[600 EUR],
[20%],
[Sieć i pozostałe],
[300 EUR],
[10%],
[Razem],
[3000 EUR],
[100%],
)
#src[Wszystkie kwoty i obciążenia w tym wykładzie: model dydaktyczny, nie cennik dostawcy.]
]
#slide(title: [Koszt jednostkowy])[
#defblock[100 000 poprawnie zrealizowanych zamówień][3000 EUR / 100 000 = *0,03 EUR za zamówienie*.]
- W kolejnym miesiącu: 3600 EUR / 150 000 = *0,024 EUR*.
- Koszt całkowity wzrósł o 20%, jednostkowy spadł o 20%.
- Ten sam zakres kosztów i definicja poprawnej realizacji w obu okresach.
#src[#link("https://www.finops.org/framework/capabilities/unit-economics/")[FinOps Foundation — Unit Economics]]
]
#slide(title: [Alokacja kosztów wspólnych])[
#data-table(3,
[Koszt platformy: 400 EUR],
[Zespół A],
[Zespół B],
[Równy podział],
[200 EUR],
[200 EUR],
[Udział w zużyciu: 75% / 25%],
[300 EUR],
[100 EUR],
)
- Wybrana metoda wpływa na decyzje zespołów.
- Tagi wskazują właściciela; nie rozwiązują automatycznie podziału kosztu wspólnego.
- Oddzielić koszty przypisane bezpośrednio od rozliczonych umownie.
#src[#link("https://www.finops.org/framework/capabilities/allocation/")[FinOps Foundation — Allocation]]
]
#slide(title: [Rightsizing: zapas po utracie repliki])[
#defblock[Pomiary pod obciążeniem][Szczyt: 100 zadań/s. Jeden worker: 40 zadań/s przy akceptowanym opóźnieniu. Założenie: brak wąskiego gardła w bazie.]
#data-table(3,
[Liczba workerów],
[Normalnie],
[Po utracie jednego],
[4],
[160 zadań/s],
[120 zadań/s],
[3],
[120 zadań/s],
[80 zadań/s],
)
- Trzy repliki wystarczają normalnie; nie wystarczają przy założonej awarii.
]
#slide(title: [Ile trwa opróżnienie kolejki?])[
#defblock[Model stałych przepływów][Zaległość B = 6000 zadań; napływ λ = 100/s; obsługa μ = 120/s. Czas ≈ B / (μ − λ) = *300 s*.]
- Warunek: μ > λ; przy μ ≤ λ kolejka nie zostanie opróżniona.
- Chwilowy koszt dodatkowych workerów może ograniczyć czas pogorszenia.
- Model pomija zmienność zadań i ograniczenia zależności.
#src[Obliczenie dydaktyczne bilansu kolejki.]
]
#slide(title: [Spot: cena za możliwość przerwania])[
#flow[Zadanie][Checkpoint / trwały skutek][ACK]
- Odebranie instancji przed ACK → możliwe ponowne dostarczenie.
- Potrzebne idempotencja i odzyskiwalny postęp długiej pracy.
- Dostępność zastępczej instancji Spot nie jest gwarantowana.
#src[#link("https://learn.microsoft.com/azure/architecture/guide/spot/spot-eviction")[Microsoft — Build workloads with Spot VMs]]
]
#slide(title: [#cloud Mieszana pula workerów])[
#data-table(3,
[Wariant],
[Pełna pojemność],
[Po utracie wszystkich Spot],
[2 regular + 2 Spot],
[160/s],
[80/s],
[3 regular + 1 Spot],
[160/s],
[120/s],
)
- Przy napływie 100/s drugi wariant zachowuje nadwyżkę przepustowości.
- Rabat Spot dotyczy jego części kosztu, nie całego systemu.
- Kryterium: przetestowany czas reakcji i skutek dla użytkownika.
]
#slide(title: [#cloud Koszt telemetrii])[
#defblock[Model][20 GB logów/dzień × 30 dni × 1 EUR/GB ingest = *600 EUR/miesiąc*.]
- Ograniczenie ingest do 10 GB/dzień → oszczędność 300 EUR.
- Krótsza retencja nie zmniejsza automatycznie opłaty za ingest.
- Redukować zbędne dane; zachować materiał wymagany do diagnozy i kontroli.
#src[Model obejmuje wyłącznie ingest, bez kosztu przechowywania i zapytań.]
]
#slide(title: [Usługa zarządzana a własny komponent])[
#data-table(3,
[Miesiąc — przykład],
[Własny komponent],
[Usługa zarządzana],
[Infrastruktura],
[300 EUR],
[700 EUR],
[Praca operacyjna],
[12 h × 50 EUR = 600 EUR],
[3 h × 50 EUR = 150 EUR],
[Razem w modelu],
[900 EUR],
[850 EUR],
)
- Założenia o nakładzie sprawdzić na rzeczywistych zadaniach.
- Migracja, dyżury, ryzyko i ograniczenia funkcji mogą zmienić wynik.
]
#slide(title: [Platforma wewnętrzna: próg opłacalności])[
#defblock[Założenia][Utrzymanie platformy: 80 h/miesiąc. Oszczędność: 10 h/miesiąc na zespół. Próg równowagi: *8 zespołów*.]
- Przy 5 zespołach: 50 h oszczędności wobec 80 h utrzymania.
- Model nie obejmuje kosztu początkowego i korzyści z ograniczenia błędów.
- Pomiar: czas dostarczenia zmiany, zgłoszenia, niezawodność i użycie platformy.
]
#slide(title: [Przypadek: obniżenie rachunku o 30%])[
#defblock[Dostępne działania][Workery tańsze o 30%; telemetria tańsza o 50%. Pozostałe koszty bez zmian. Bazowy rachunek: 3000 EUR.]
- Ile oszczędzimy łącznie? Czy osiągniemy cel 30%?
- Jakich testów wymagają obie zmiany?
- Czy redukcja liczby poprawnych realizacji może „poprawić” rachunek?
]
#slide(title: [Źródła i lektury])[
#text(size: 16pt)[
- #link("https://www.finops.org/framework/capabilities/unit-economics/")[FinOps Foundation — Unit Economics]
- #link("https://www.finops.org/framework/capabilities/allocation/")[FinOps Foundation — Allocation]
- #link("https://learn.microsoft.com/azure/architecture/guide/spot/spot-eviction")[Microsoft — Build workloads with Spot VMs]
- #link("https://sre.google/workbook/managing-load/")[Google SRE — Managing load]
]
#src[Dokumentacja sprawdzona: 26.09.2026. Dane przypadków: przykłady dydaktyczne.]
]

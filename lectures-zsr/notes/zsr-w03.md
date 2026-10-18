# ZSR 03 — Kubernetes: model działania

Budżet: 45 minut, w tym dyskusja. Plan prowadzenia, nie wynik próby czasowej. Tytuł i bibliografia bez osobnych bloków czasowych. Wszystkie dane liczbowe przypadków są dydaktyczne. Fragmenty konfiguracji służą analizie; pominięcia opisano przy przykładach.

## Przebieg

| Minuty | Slajdy / temat i sposób prowadzenia |
|---|---|
| 0–3 | Obraz jest gotowy i plan: nawiąż do workera z wykładu 2. Postaw pytania o rozmieszczenie, odtworzenie instancji i dostęp do API. |
| 3–7 | Klaster, węzeł i Pod. Jeden kontener workera w Podzie; trzy repliki oznaczają trzy Pody. |
| 7–15 | Stan oczekiwany i obserwowany, Deployment → ReplicaSet → Pody, manifest. Rozdziel liczbę istniejących i gotowych Podów. |
| 15–21 | Control plane, węzeł i rekonsyliacja. Prześledź powstanie jednego brakującego Poda. |
| 21–25 | Scheduler: wyjaśnij requests, allocatable i millicpu; wykonaj rachunek dla A i B. |
| 25–31 | Service: problem zmiennych adresów, selektor i porty; droga ruchu oraz rola EndpointSlice. |
| 31–33 | Trzy obserwacje awarii: dobierz pierwszy odczyt do problemu. |
| 33–37 | AKS: odpowiedzialność i dwa poziomy skalowania. |
| 37–44 | Diagnoza selektora; studenci proponują zmianę oraz odczyt i próbę potwierdzające naprawę. |
| 44–45 | Kluczowe wnioski i przejście do sond, zasobów i HPA na wykładzie 4. |

## Objaśnienia i założenia

### Pod i stan obserwowany

Pod to jednostka uruchomienia kontenerów na jednym węźle, a nie cały węzeł. Kontenery Poda współdzielą przestrzeń sieciową; wspólne wolumeny wymagają odpowiednich deklaracji i montowania. Zastępczy Pod ma nową tożsamość i może otrzymać inny adres IP. Trzy repliki nie gwarantują rozmieszczenia na trzech różnych węzłach; potrzebne są osobne reguły, jeśli chcemy wymusić taki rozkład.

W przykładzie spec/status istnieją trzy Pody, ale tylko dwa są gotowe. ReplicaSet nie dodaje automatycznie czwartego Poda tylko z powodu niegotowości trzeciego. W osobnym przykładzie rekonsyliacji istnieją tylko dwa Pody, więc kontroler tworzy brakujący obiekt. Nie utożsamiaj liczby istniejących Podów, działających procesów i gotowych replik. Sondy oraz dokładniejsze znaczenie readiness omówi wykład 4.

### Od deklaracji do uruchomienia

Model nie zakłada natychmiastowych działań. Deployment zarządza ReplicaSetami, ReplicaSet tworzy obiekty Podów, scheduler wybiera węzeł, a kubelet zleca uruchomienie kontenerów runtime'owi. Komponenty współpracują przez API. Diagram kubectl → API server → etcd dotyczy zapisu obiektów; nie przedstawia drogi żądań biznesowych do aplikacji.

Manifest prześledź od replicas, przez template, do zgodności selector.matchLabels z template.metadata.labels. Etykieta app=worker jest metadanymi używanymi do wyboru obiektów. Zmiana obrazu w szablonie uruchamia aktualizację zarządzaną przez Deployment. Nie rozwijaj tu strategii rollout ani wszystkich typów zasobów.

### Scheduler i requests

Request to deklarowane zapotrzebowanie używane przy planowaniu, a nie pomiar bieżącego użycia ani limit. 1000m oznacza 1 CPU; 600m to 0,6 CPU. Allocatable to pojemność węzła dostępna dla Podów po uwzględnieniu rezerwacji systemowych.

Na A pozostaje 400m, więc nowy Pod z request 600m nie mieści się. Na B pozostaje 1000m, więc warunek CPU jest spełniony. Pamięć i pozostałe warunki przypisania uznajemy za zgodne wyłącznie na potrzeby rachunku. Niskie faktyczne użycie CPU nie zwalnia requests. Pending nie oznacza wyłącznie braku CPU: obejmuje również przygotowanie kontenerów, np. pobieranie obrazu; odczyt zdarzeń pozwala ustalić etap.

### Service i EndpointSlice

Jawnie przejdź od workera pobierającego wiadomości do API przyjmującego żądania. Worker łączy się z kolejką połączeniem wychodzącym; Service może służyć np. do udostępnienia metryk, ale nie jest warunkiem konsumpcji kolejki.

Service w przykładzie ma domyślny typ ClusterIP. Zapewnia nazwę DNS i wirtualny IP wewnątrz klastra; nie oznacza to publicznego udostępnienia API. Selektor odnosi się do etykiet Podów w tym samym namespace. Nazwa Deploymentu nie decyduje o dopasowaniu. Port 80 jest portem Service, a 8080 portem aplikacji.

EndpointSlice jest obiektem API z adresami, portami i warunkami endpointów. Nie jest pośrednikiem przekazującym ruch. kube-proxy lub zastępujący go komponent korzysta z tych informacji, aby skonfigurować obsługę Service. Przypadek zakłada domyślne kierowanie ruchu do gotowych endpointów; pomijamy np. publishNotReadyAddresses i szczegóły kończenia Podów.

### AKS i skalowanie

Ogranicz tę część do czterech minut. Wyjaśnij HPA jako zmianę liczby replik na podstawie metryk, bez formuły i konfiguracji z wykładu 4. Autoscaler węzłów musi być włączony i skonfigurowany; nie każdy Pending powoduje dodanie węzła. Wzrost pojemności musi umożliwiać przypisanie oczekujących Podów i mieścić się w limitach konfiguracji oraz dostawcy. Odpowiedzialność za węzły zależy od wybranego trybu AKS.

## Rozwiązanie przypadku i dyskusja

Dane są skrócone, wszystkie obiekty są w tym samym namespace, a procesy API nasłuchują na porcie docelowym 8080. Pokazany EndpointSlice ma pustą listę endpointów. Samo istnienie obiektu EndpointSlice nie dowodzi dostępności backendów.

Selektor Service zmienić z app=orders na app=orders-api w źródle konfiguracji i zastosować zmianę. Następnie:

1. Sprawdzić EndpointSlice przypisane do orders-api: oczekujemy adresów obu Podów i gotowości endpointów. Można użyć `kubectl get endpointslice -l kubernetes.io/service-name=orders-api -o yaml`.
2. Potwierdzić zgodność portu docelowego z portem nasłuchu aplikacji.
3. Wykonać żądanie z klienta w klastrze przez nazwę i port Service, np. `http://orders-api:80/` dla klienta w tym samym namespace i znanej trasy aplikacji.

Restart bez zmiany selektora lub etykiet nic nie naprawi. Alternatywą jest zmiana etykiet Podów, ale może naruszyć selektor Deploymentu i inne zależności. Zapytaj o zakres skutków obu zmian. Rozróżnij potwierdzenie zgodności konfiguracji, obecności gotowych endpointów oraz rzeczywistej obsługi żądania.

## Kontrola czasu

Zachowaj siedem minut na przypadek oraz minutę na wnioski. Jeśli dyskusja się wydłuża, skróć przegląd awarii do jednego pytania i część AKS do granicy odpowiedzialności oraz rozróżnienia replik i węzłów. Nie dodawaj kolejnych typów zasobów ani szczegółów sond, magazynu i obliczeń HPA.

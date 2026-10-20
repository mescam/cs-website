#pagebreak()

= Część II. Kubernetes — od obrazu do działającej usługi

W części Dockerowej sposób uruchomienia aplikacji był zapisany w poleceniach `docker run` i skrypcie `start.sh`. Teraz należy opisać *stan oczekiwany*: jaki obraz uruchomić, ile kopii aplikacji utrzymywać, jak udostępnić usługę i gdzie zapisywać dane. Kubernetes porównuje ten opis ze stanem klastra i podejmuje działania, aby je uzgodnić.

Najpierw należy uruchomić własny obraz Flaska, sprawdzić odtwarzanie i skalowanie Podów oraz przeprowadzić aktualizację. Następnie należy zbadać sondy zdrowia i wdrożyć Redmine z PostgreSQL. Są to te same aplikacje co wcześniej, ale nowe instancje: wolumeny Dockerowe i zapisane w nich dane nie zostaną automatycznie przeniesione do klastra.

Po wykonaniu ćwiczeń należy umieć odróżnić restart kontenera od odtworzenia Poda, wyjaśnić związek Deploymentu z Service, znaleźć przyczynę nieudanego wdrożenia i wykazać trwałość danych po wymianie Podów.

== Plan pracy na kilka spotkań

#table(
  columns: (auto, 1fr, 1fr), inset: 6pt, stroke: 0.4pt,
  table.header([*Spotkanie*], [*Zakres*], [*Efekt pracy*]),
  [1], [Pod, Deployment, Service, obrazy i aktualizacje], [Flask w dwóch wersjach, skalowanie i rollback],
  [2], [Sondy, ConfigMap, Secret, PVC i baza], [Test sond i działający StatefulSet PostgreSQL],
  [3], [Job, CronJob, init container, sidecar i zasoby], [Zadania jednorazowe i wielokontenerowy Pod],
  [4], [Bezpieczeństwo Podów i NetworkPolicy], [Uruchomienie jako non-root i ograniczony ruch],
  [5], [Gateway API, Kustomize i scenariusz odbioru], [Redmine pod własną domeną i wdrożenie odtworzone z overlay],
)

Plan jest modułowy. Spotkania 1 i 2 rozwijają zadania A–G. Spotkania 3–5 są dodatkowymi rozdziałami. Prowadzący może rozłożyć każdy zakres na więcej laboratoriów. Ćwiczenia wykorzystują Minikube, więc mają jeden węzeł; służą nauce zasobów aplikacji, a nie prezentacji odporności na awarię maszyny.

== Od Dockera do Kubernetes

#table(
  columns: (1fr, 1fr), inset: 6pt, stroke: 0.4pt,
  table.header([*W części Dockerowej*], [*W Kubernetesie*]),
  [Obraz `zsr-flask:v2`], [Ten sam obraz uruchamiany w Podzie],
  [`docker run` i ręczne odtwarzanie], [Deployment i jego szablon Poda],
  [Nazwa kontenera we wspólnej sieci], [Service i nazwa w DNS klastra],
  [`-e NAZWA=wartość`], [`env`, ConfigMap i Secret],
  [Nazwany wolumen], [PVC powiązany z PersistentVolume],
  [`docker logs` i `docker exec`], [`kubectl logs` i `kubectl exec`],
)

Pod zawiera jeden lub więcej kontenerów współdzielących sieć i zadeklarowane wolumeny. W ćwiczeniach każdy Pod zawiera jeden kontener aplikacji. Węzeł to maszyna, na której działają Pody. Trzy Pody na jednym węźle nie oznaczają odporności na awarię tego węzła.

= A. Klaster i własny obraz

Wymagane są działający lokalny Docker, Minikube, `kubectl`, `curl` i `openssl`. Narzędzia należy przygotować zgodnie z #link("https://minikube.sigs.k8s.io/docs/start/")[instrukcją Minikube] i #link("https://kubernetes.io/docs/tasks/tools/")[instrukcją kubectl] dla systemu stanowiska. Klaster laboratoryjny otrzyma 2 CPU i 4 GiB pamięci; host musi mieć również zasoby dla własnego systemu. Potrzebny jest dostęp do Internetu do pobrania obrazów. Polecenia wykonuje się na stanowisku, w powłoce Bash, o ile nie wskazano inaczej.

Jeśli nie zainstalowano osobnego `kubectl`, Minikube udostępnia go przez `minikube kubectl --`. W Bash można przed kolejnymi poleceniami ustawić alias `alias kubectl='minikube kubectl --'`; działa on tylko w bieżącej powłoce, więc w nowym terminalu trzeba go ustawić ponownie. Przy zainstalowanym `kubectl` alias nie jest potrzebny.

```bash
docker info
minikube version
minikube profile list
minikube start --driver=docker --cni=calico --cpus=2 --memory=4096
kubectl version --client
kubectl config use-context minikube
kubectl config current-context
kubectl get nodes -o wide
kubectl get namespace zsr || kubectl create namespace zsr
kubectl config set-context minikube --namespace=zsr
```

Używamy domyślnego profilu Minikube (kontekst `minikube`), bez tworzenia profilu dla ćwiczenia. Jeśli domyślny klaster już istnieje z innym sterownikiem, np. VirtualBox, nie należy próbować zmieniać jego sterownika powyższym poleceniem ani usuwać klastra z danymi bez ich zabezpieczenia; przed ćwiczeniem należy uzgodnić przygotowanie klastra z prowadzącym. Węzeł ma mieć stan `Ready`. Namespace `zsr` grupuje zasoby ćwiczenia wewnątrz klastra i nie jest profilem Minikube. W każdym kolejnym terminalu należy sprawdzić bieżący kontekst i namespace (`kubectl config view --minify`); jeśli używany jest alias, ustawić go ponownie. Jeżeli namespace już istnieje po wcześniejszym uruchomieniu, należy go wykorzystać.

Należy utworzyć katalog `kubernetes` obok katalogu `starter` i zapisywać w nim manifesty YAML. YAML używa wcięć ze spacji; położenie pola określa, do którego obiektu ono należy. Polecenie `kubectl apply -f PLIK` wysyła opis do API klastra. Jego powodzenie oznacza przyjęcie konfiguracji, a nie gotowość aplikacji.

*Przed pierwszym `kubectl apply`* należy wczytać obie wersje Flaska przygotowane w części I do uruchomionego klastra Minikube:

```bash
docker image ls zsr-flask
minikube image load zsr-flask:v1
minikube image load zsr-flask:v2
minikube image ls
```

`docker build` lub `docker load` umieszcza obraz na hoście, ale węzeł Minikube korzysta z własnego magazynu obrazów, nawet gdy uruchomiono go ze sterownikiem Docker. `minikube image load` kopiuje obraz z hosta do węzła, aby Pod mógł go uruchomić przy `imagePullPolicy: Never` (bez pobierania z rejestru). Po ponownym zbudowaniu obrazu należy załadować go ponownie, zanim powstaną nowe Pody. Jeżeli brakuje wersji 2 na hoście, można ją odtworzyć poleceniem `docker load -i zsr-flask-v2.tar.gz`. Wersję 1 należy zachować z części I lub odbudować z jej kodu. Wersja 2 musi zwracać `ok` pod `/health`, a wersja 1 nie powinna zawierać tej trasy. Nie należy nadpisywać znaczników inną zawartością podczas kolejnych ćwiczeń.

*Weryfikacja:* węzeł jest gotowy, a lista obrazów w Minikube zawiera obie wersje Flaska. Należy wyjaśnić, dlaczego samo `docker build` na stanowisku nie wystarcza do ich uruchomienia w klastrze.

= B. Pod i Deployment

== Pojedynczy Pod

W pliku `pod.yaml` należy zapisać:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: flask-pod
spec:
  containers:
    - name: flask
      image: zsr-flask:v1
      imagePullPolicy: Never
      ports:
        - containerPort: 5000
```

`apiVersion` i `kind` wybierają rodzaj zasobu, `metadata` nadaje nazwę, a `spec` opisuje stan oczekiwany. `imagePullPolicy: Never` oznacza użycie obrazu obecnego na węźle bez próby pobierania go z rejestru. Brak obrazu ujawni się jako `ErrImageNeverPull`. `containerPort` opisuje port aplikacji; sam nie publikuje go na stanowisku.

```bash
kubectl apply -f pod.yaml
kubectl wait --for=condition=Ready pod/flask-pod --timeout=120s
kubectl get pod flask-pod -o wide
kubectl logs flask-pod
kubectl port-forward pod/flask-pod 8080:5000
```

Ostatnie polecenie pozostaje uruchomione. W drugim terminalu należy wykonać `curl --fail http://localhost:8080/`. Następnie należy zakończyć przekierowanie przez `Ctrl+C` i usunąć Poda:

```bash
kubectl delete pod flask-pod
kubectl get pods
```

*Weryfikacja:* aplikacja odpowiadała wersją 1, ale usunięty Pod nie został odtworzony. Kubernetes może restartować kontener wewnątrz istniejącego Poda; do zastępowania usuniętych Podów potrzebny jest kontroler.

== Deployment utrzymuje liczbę replik

W pliku `flask.yaml` należy zapisać:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask
  labels:
    app: flask
spec:
  replicas: 2
  selector:
    matchLabels:
      app: flask
  template:
    metadata:
      labels:
        app: flask
    spec:
      containers:
        - name: flask
          image: zsr-flask:v1
          imagePullPolicy: Never
          ports:
            - containerPort: 5000
          resources:
            requests:
              cpu: 100m
              memory: 64Mi
            limits:
              cpu: 500m
              memory: 128Mi
```

`template` jest szablonem nowych Podów. `selector.matchLabels` musi odpowiadać etykietom w `template.metadata.labels`. Deployment zarządza ReplicaSetem, a ten utrzymuje wymaganą liczbę Podów. Żądania `requests` służą do planowania przydziału zasobów; `100m` to jedna dziesiąta CPU. Limity ograniczają użycie: CPU może być ograniczane czasowo, a przekroczenie limitu pamięci może zakończyć proces (`OOMKilled`).

```bash
kubectl apply -f flask.yaml
kubectl rollout status deployment/flask --timeout=120s
kubectl get deployment,replicaset,pods -l app=flask
kubectl get pods -l app=flask -o wide
```

Należy zanotować nazwę jednego Poda i usunąć go przez `kubectl delete pod NAZWA`, zastępując `NAZWA` rzeczywistą wartością. W drugim terminalu należy obserwować `kubectl get pods -l app=flask -w`; obserwację kończy `Ctrl+C`.

*Weryfikacja:* liczba gotowych replik wraca do dwóch, ale odtworzony Pod ma nową nazwę i UID. Jest to nowy Pod, a nie restart poprzedniego kontenera. Pomocne polecenie: `kubectl get pods -l app=flask -o custom-columns=NAZWA:.metadata.name,UID:.metadata.uid`.

= C. Service, DNS i skalowanie

Adres Poda może zmienić się po jego odtworzeniu. Service wybiera Pody za pomocą etykiet i udostępnia stały punkt dostępu. Do `flask.yaml` należy dopisać drugi dokument YAML, zaczynając od separatora `---`:

```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: flask
spec:
  selector:
    app: flask
  ports:
    - port: 80
      targetPort: 5000
  type: ClusterIP
```

`port: 80` należy do Service, a `targetPort: 5000` wskazuje port aplikacji w Podach. Nazwa `flask` jest rozwiązywana przez DNS dla klientów w tym samym namespace. `ClusterIP` służy do komunikacji wewnątrz klastra.

```bash
kubectl apply -f flask.yaml
kubectl get service flask
kubectl get endpointslices -l kubernetes.io/service-name=flask
kubectl port-forward service/flask 8080:80
```

W drugim terminalu należy sprawdzić `curl --fail http://localhost:8080/`. Przekierowanie wybiera jednego Poda i utrzymuje połączenie z nim. Nie jest testem równoważenia ruchu przez Service; po usunięciu tego Poda może wymagać ponownego uruchomienia. Jeśli `kubectl` działa na zdalnym stanowisku, `localhost` oznacza to stanowisko; dostęp z własnego komputera wymaga np. tunelu SSH.

Do sprawdzenia rzeczywistego połączenia przez Service należy uruchomić jednorazowego klienta *wewnątrz klastra*, wykorzystując obecny już obraz:

```bash
kubectl run klient --rm -i --restart=Never \
  --image=zsr-flask:v1 --image-pull-policy=Never -- \
  python -c 'import urllib.request as u
print(u.urlopen("http://flask", timeout=5).read().decode())'
```

Należy zmienić `replicas` w `flask.yaml` z 2 na 3, wykonać `kubectl apply -f flask.yaml` i poczekać na `kubectl rollout status deployment/flask --timeout=120s`. Następnie należy porównać liczbę Podów oraz adresy w `kubectl get endpointslices -l kubernetes.io/service-name=flask -o yaml`. Pojawią się trzy gotowe adresy backendów. Polecenie `kubectl scale deployment/flask --replicas=2` również zmienia liczbę replik, lecz nie zapisuje tej zmiany w pliku; kolejne `apply` przywróci liczbę zadeklarowaną w manifeście.

*Zadanie diagnostyczne:* w selektorze *Service* należy na chwilę zmienić `app: flask` na `app: brak`, zastosować plik i ponowić próbę klienta. Należy porównać stan Podów z adresami EndpointSlice, po czym przywrócić właściwy selektor.

*Weryfikacja:* sprawny klient łączy się z nazwą `flask`. Przy błędnym selektorze Pody nadal działają, ale Service nie ma pasujących backendów. Po korekcie połączenie ponownie działa. Należy wyjaśnić różnicę między dostępnością procesu, Poda i usługi.

= D. Nowa wersja i wycofanie zmiany

W `flask.yaml` należy zmienić obraz na `zsr-flask:v2`, zastosować manifest i obserwować wdrożenie:

```bash
kubectl apply -f flask.yaml
kubectl rollout status deployment/flask --timeout=120s
kubectl rollout history deployment/flask
kubectl get replicasets
```

Zmiana szablonu Poda powoduje utworzenie nowego ReplicaSetu. Przy domyślnej strategii `RollingUpdate` nowe Pody stopniowo zastępują stare. W czasie zmiany mogą być obecne obie wersje aplikacji. Po jej zakończeniu należy ponownie uruchomić przekierowanie Service i sprawdzić tekst wersji 2 oraz odpowiedź `ok` pod `http://localhost:8080/health`.

Następnie należy celowo wpisać w manifeście nieistniejący obraz `zsr-flask:brak`, wykonać `apply` i powtórzyć `rollout status` z limitem 60 sekund. Należy odczytać `kubectl get pods`, wybrać niedziałający Pod i sprawdzić `kubectl describe pod NAZWA`. Dla polityki `Never` zdarzenia wskażą brak lokalnego obrazu. Poprzednie, gotowe repliki mogą nadal obsługiwać ruch, mimo że aktualizacja nie może się zakończyć.

```bash
kubectl rollout undo deployment/flask
kubectl rollout status deployment/flask --timeout=120s
```

Polecenie `undo` przywraca poprzedni szablon Poda w klastrze, ale nie poprawia pliku. Należy również przywrócić `zsr-flask:v2` w `flask.yaml` i ponownie wykonać `apply`. Kubernetes nie wycofuje automatycznie każdej nieudanej aktualizacji. Limit czasu klienta `kubectl` również nie cofa zmiany.

*Weryfikacja:* działająca usługa ponownie zwraca wersję 2, wdrożenie jest zakończone, a zapisany manifest zawiera właściwy obraz. Należy wskazać zdarzenie, które wyjaśniało niepowodzenie aktualizacji.

#pagebreak()

= E. Gotowość i żywotność aplikacji

Stan `Running` mówi, że Pod został uruchomiony, lecz nie potwierdza poprawnej obsługi żądań. `readinessProbe` określa gotowość do przyjmowania ruchu przez Service. Nieudana sonda readiness nie restartuje kontenera. `livenessProbe` pozwala wykryć stan wymagający restartu kontenera, a `startupProbe` daje aplikacji czas na start, zanim zaczną działać pozostałe sondy.

W kontenerze `flask` w `flask.yaml`, na tym samym poziomie co `image` i `resources`, należy dodać:

```yaml
          startupProbe:
            httpGet:
              path: /health
              port: 5000
            periodSeconds: 2
            failureThreshold: 30
          readinessProbe:
            httpGet:
              path: /health
              port: 5000
            periodSeconds: 3
            failureThreshold: 2
          livenessProbe:
            httpGet:
              path: /health
              port: 5000
            periodSeconds: 5
            failureThreshold: 3
```

W przykładzie wspólna trasa `/health` sprawdza, czy serwer Flaska odpowiada. W rozbudowanej aplikacji testy mogą być osobne: przejściowa niedostępność bazy może wpływać na gotowość, ale restartowanie wszystkich kontenerów aplikacji nie naprawi bazy.

Należy zastosować manifest, poczekać na zakończenie wdrożenia i wykonać dwa oddzielne doświadczenia:

1. *Readiness:* tylko w `readinessProbe` należy zmienić ścieżkę na `/brak`, zastosować plik i obserwować Pody oraz EndpointSlice. Nowe Pody odpowiadają sondzie kodem 404, mają `READY 0/1` i nie stają się gotowymi backendami Service. Licznik restartów nie rośnie z powodu readiness. Ponieważ to zmiana szablonu, stare, zdrowe Pody mogą nadal działać i utrzymywać dostępność usługi. Należy przywrócić `/health`, zastosować plik i poczekać na zakończenie wdrożenia.
2. *Liveness:* tylko w `livenessProbe` należy zmienić ścieżkę na `/brak`. Po zastosowaniu pliku należy wybrać nowego Poda i obserwować go przez co najmniej 30 sekund. Należy porównać jego UID oraz kolumnę `RESTARTS`, a także zdarzenia z `kubectl describe pod NAZWA`. Można odczytać logi poprzedniego kontenera przez `kubectl logs NAZWA --previous`. Po doświadczeniu należy przywrócić `/health` i zaczekać na poprawne wdrożenie.

Nie należy zmieniać trasy startup podczas tych prób: dopóki startup nie zakończy się powodzeniem, readiness i liveness nie są wykonywane. Sondy wykrywają błąd po określonej liczbie prób, więc efekt nie musi być natychmiastowy.

*Weryfikacja:* w pierwszym doświadczeniu nowe Pody tracą gotowość bez restartów, a w drugim rośnie licznik restartów kontenera w Podzie o tym samym UID. Należy porównać ten wynik z usuwaniem Poda w zadaniu B.

= F. Konfiguracja i PostgreSQL ze stanem trwałym

W części I nazwany wolumen przechowywał dane poza kontenerem. W Kubernetesie aplikacja zgłasza zapotrzebowanie na miejsce przez *PersistentVolumeClaim (PVC)*. Odpowiadający mu *PersistentVolume (PV)* opisuje przydzielony zasób. StorageClass określa sposób jego dostarczania; w Minikube lokalny provisioner może utworzyć PV na żądanie.

```bash
minikube addons list
kubectl get storageclass
```

Powinna istnieć klasa `standard` oznaczona jako domyślna. W świeżym Minikube odpowiadają za nią dodatki `storage-provisioner` i `default-storageclass`. Jeżeli są wyłączone, należy włączyć je przez `minikube addons enable storage-provisioner` oraz `minikube addons enable default-storageclass`. Dalsze manifesty korzystają z domyślnej klasy i są przeznaczone dla tego lokalnego klastra.

== ConfigMap i Secret

Należy utworzyć `redmine-config.yaml`. ConfigMap będzie wspólnym źródłem nazwy bazy i użytkownika. Secret przechowa hasło wykorzystywane przez oba kontenery:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: redmine-config
data:
  database: redmine
  username: redmine
---
apiVersion: v1
kind: Secret
metadata:
  name: redmine-secret
type: Opaque
stringData:
  password: lab1234
  secret-key-base: uzupelnij-przed-wdrozeniem
```

Hasło `lab1234` służy wyłącznie do lokalnego ćwiczenia. Wartość `secret-key-base` należy zastąpić wynikiem `openssl rand -hex 64` i zachować przy późniejszym odtwarzaniu Redmine. `stringData` przyjmuje zwykły tekst, który API zapisuje w polu `data` jako base64. *Base64 nie jest szyfrowaniem.* Dostęp do Secret zależy od uprawnień, a szyfrowanie danych klastra wymaga osobnej konfiguracji. Manifestu z rzeczywistymi hasłami nie należy publikować w repozytorium.

```bash
kubectl apply -f redmine-config.yaml
kubectl get configmap redmine-config
kubectl get secret redmine-secret
```

== StatefulSet dla jednej instancji PostgreSQL

StatefulSet zapewnia stabilne nazwy Podów i powiązanie instancji z jej PVC. W tym ćwiczeniu baza ma dokładnie jedną replikę. Zwiększenie liczby Podów PostgreSQL nie skonfiguruje replikacji bazy i nie utworzy wspólnej, spójnej bazy danych.

W pliku `postgres.yaml` należy zapisać Service bez adresu ClusterIP (*headless*) oraz StatefulSet. Service określa domenę sieciową Podów StatefulSetu; przy jednej replice nazwa `postgres` pozwoli Redmine dotrzeć do jedynej instancji bazy.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  clusterIP: None
  selector:
    app: postgres
  ports:
    - port: 5432
      targetPort: 5432
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:17.11
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_DB
              valueFrom:
                configMapKeyRef:
                  name: redmine-config
                  key: database
            - name: POSTGRES_USER
              valueFrom:
                configMapKeyRef:
                  name: redmine-config
                  key: username
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: redmine-secret
                  key: password
          readinessProbe:
            exec:
              command:
                - sh
                - -c
                - pg_isready -h 127.0.0.1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"
            periodSeconds: 5
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: [ReadWriteOnce]
        resources:
          requests:
            storage: 1Gi
```

`volumeClaimTemplates` tworzy osobny PVC dla każdej instancji. Dla Poda `postgres-0` będzie to `data-postgres-0`. `ReadWriteOnce` oznacza montowanie do zapisu na jednym węźle, a nie blokadę dopuszczającą dokładnie jednego Poda. Wersja 17 obrazu korzysta ze ścieżki danych poznanej w części Dockerowej.

```bash
kubectl apply -f postgres.yaml
kubectl rollout status statefulset/postgres --timeout=300s
kubectl get pods,pvc
kubectl get pv
kubectl logs postgres-0
kubectl exec -it postgres-0 -- psql -U redmine -d redmine
```

W kliencie `psql` należy zapisać i odczytać dane próbne, a potem zakończyć sesję:

```sql
CREATE TABLE zsr_proba (id integer PRIMARY KEY, opis text);
INSERT INTO zsr_proba VALUES (1, 'dane w Kubernetesie');
SELECT * FROM zsr_proba;
\q
```

Należy zanotować UID Poda oraz nazwę PV powiązanego z PVC, następnie usunąć `postgres-0`. Po jego odtworzeniu należy poczekać na gotowość i ponownie wykonać `SELECT`. StatefulSet nada Podowi tę samą nazwę, lecz jego UID będzie inny; nazwa PVC i przypisany PV powinny pozostać takie same.

*Weryfikacja:* wiersz przetrwał wymianę Poda. Trwałość wynika z ponownego użycia PVC, a nie z samej nazwy Poda. Lokalny dysk Minikube nie zapewnia kopii zapasowej ani odporności na utratę węzła. Nie należy usuwać PVC podczas tej próby.

= G. Zadanie samodzielne: Redmine w Kubernetesie

Należy przenieść konfigurację Redmine z `start.sh` do manifestów Kubernetes. Baza z zadania F jest już gotowa. Zadanie dotyczy ponownego wdrożenia aplikacji z pustą bazą Redmine, bez importowania danych z wolumenów Dockerowych.

W pliku `redmine.yaml` należy przygotować PVC, Deployment i Service, rozdzielone `---`. Wymagania:

1. PVC `redmine-files` żąda `1Gi` z trybem `ReadWriteOnce`.
2. Deployment `redmine` uruchamia jedną replikę obrazu `redmine:6.1.5`. Szablon Poda ma etykietę `app: redmine`, a kontener nasłuchuje na porcie `3000`.
3. Strategia Deploymentu to `Recreate`, aby podczas aktualizacji obrazu najpierw zakończyć stare Pody. Przy tej strategii trzeba zaakceptować przerwę w dostępności. Aplikacja ma jeden wolumen załączników i w tym zadaniu nie jest skalowana.
4. Wolumen wskazujący `persistentVolumeClaim.claimName: redmine-files` jest zamontowany pod `/usr/src/redmine/files`.
5. `REDMINE_DB_POSTGRES` ma wartość `postgres`. Zmienne `REDMINE_DB_DATABASE` i `REDMINE_DB_USERNAME` pobierają odpowiednie klucze z ConfigMap. `REDMINE_DB_PASSWORD` oraz `SECRET_KEY_BASE` korzystają z Secret.
6. Service `redmine` typu `ClusterIP` wybiera `app: redmine` i kieruje port `3000` na port `3000` Poda. Baza pozostaje dostępna wyłącznie wewnątrz klastra.
7. Startup probe i readiness probe sprawdzają przez HTTP ścieżkę `/login` na porcie `3000`. Startup powinien dopuszczać około 5 minut uruchamiania i migracji, np. `periodSeconds: 5` oraz `failureThreshold: 60`. W tym zadaniu nie jest wymagana sonda liveness Redmine.

Powiązanie gotowego PVC z Podem różni się od `volumeClaimTemplates`. Fragmenty szablonu Poda powinny mieć następującą strukturę; należy włączyć je do właściwego manifestu:

```yaml
    spec:
      containers:
        - name: redmine
          # Tutaj obraz, env, porty i sondy.
          volumeMounts:
            - name: files
              mountPath: /usr/src/redmine/files
      volumes:
        - name: files
          persistentVolumeClaim:
            claimName: redmine-files
```

Kubernetes nie interpretuje kolejności dokumentów YAML jako zależności startowych aplikacji. Przed pierwszym wdrożeniem Redmine należy poczekać na gotowość PostgreSQL, tak jak w części Dockerowej skrypt czekał na bazę. Sonda readiness sama nie opóźnia uruchomienia procesu aplikacji.

```bash
kubectl rollout status statefulset/postgres --timeout=300s
kubectl apply -f redmine.yaml
kubectl rollout status deployment/redmine --timeout=360s
kubectl get pods,pvc,services
kubectl logs deployment/redmine
kubectl port-forward service/redmine 8081:3000
```

W przeglądarce należy otworzyć `http://localhost:8081`, zalogować się na `admin` / `admin` i zmienić hasło. Następnie należy utworzyć nowy projekt, zgłoszenie i mały załącznik tekstowy. W razie błędów należy sprawdzić logi obu aplikacji, odwołania do ConfigMap i Secret oraz stan PVC.

== Próba trwałości i zmiany konfiguracji

1. Należy zapisać nazwy i UID obu Podów oraz nazwy PVC i powiązanych PV.
2. Należy usunąć Pod Redmine, poczekać na jego odtworzenie i gotowość, ponownie uruchomić przekierowanie i sprawdzić projekt, zgłoszenie oraz treść pobranego załącznika.
3. Należy usunąć Pod `postgres-0`, poczekać na gotowość odtworzonej bazy i powtórzyć sprawdzenie aplikacji. W czasie przerwy w działaniu bazy aplikacja może zwracać błędy; nie oznacza to utraty danych.
4. Należy potwierdzić zmianę UID Podów przy zachowaniu PVC i danych. Nie należy kasować namespace ani PVC w ramach doświadczenia.

Wartości ConfigMap i Secret przekazane przez zmienne środowiskowe są odczytywane przy uruchomieniu kontenera. Sama zmiana tych obiektów nie aktualizuje środowiska działającego procesu; potrzebne jest odtworzenie Podów, np. przez `kubectl rollout restart deployment/redmine`. Zmiana hasła w Secret nie zmieni hasła już zainicjalizowanego użytkownika PostgreSQL — tak samo jak ponowne ustawienie `POSTGRES_PASSWORD` w części Dockerowej.

*Weryfikacja:* Redmine korzysta z PostgreSQL po nazwie Service, a projekt i załącznik przetrwały wymianę Podów. Należy wskazać, który PVC przechowuje dane zgłoszenia, a który jego załącznik, oraz wyjaśnić, dlaczego w tym wdrożeniu nie wystarczy zwiększyć liczby replik bazy lub Redmine.

= H. Job, CronJob i wiele kontenerów w Podzie

Deployment utrzymuje działającą aplikację. Zadanie, które ma wykonać się raz i zakończyć, opisuje *Job*. *CronJob* tworzy kolejne Joby zgodnie z harmonogramem. `busybox:1.36` posłuży tu do krótkich poleceń powłoki; Minikube pobierze go przy pierwszym użyciu.

Należy utworzyć plik `job.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: raport
spec:
  backoffLimit: 2
  activeDeadlineSeconds: 60
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: raport
          image: busybox:1.36
          command: ["sh", "-c", "echo 'raport zaimportowanych rekordow: 42'"]
```

```bash
kubectl apply -f job.yaml
kubectl wait --for=condition=Complete job/raport --timeout=90s
kubectl get jobs,pods
kubectl logs job/raport
kubectl describe job raport
```

Job uruchamia Pod z `restartPolicy: Never`, ponawia próbę najwyżej dwa razy i przerywa pracę po minucie. Należy zmienić polecenie tak, aby zakończyło się kodem błędu, odczytać liczbę prób i zdarzenia, a potem przywrócić poprawne polecenie. Po usunięciu Jobu należy utworzyć go ponownie, by wykonać próbę na świeżym obiekcie.

W pliku `cronjob.yaml` należy zapisać:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: raport-cykliczny
spec:
  schedule: "*/5 * * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 2
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      backoffLimit: 1
      template:
        spec:
          restartPolicy: Never
          containers:
            - name: raport
              image: busybox:1.36
              command: ["sh", "-c", "date -u; echo raport cykliczny"]
```

```bash
kubectl apply -f cronjob.yaml
kubectl get cronjob
kubectl create job raport-reczny --from=cronjob/raport-cykliczny
kubectl wait --for=condition=Complete job/raport-reczny --timeout=90s
kubectl logs job/raport-reczny
```

Ręcznie utworzony Job pozwala sprawdzić szablon bez oczekiwania na zegar. CronJob planuje utworzenie Joba; nie gwarantuje, że uruchomienie nastąpi dokładnie w sekundzie harmonogramu. Domyślnie historia obiektów pozostaje do limitu ustawionego w CronJob.

`initContainers` to kontenery startowe uruchamiane przed kontenerami aplikacji. Każdy musi zakończyć się powodzeniem, zanim ruszy następny i główne kontenery. Sidecar działa równolegle z aplikacją w tym samym Podzie. Oba typy mogą montować ten sam wolumen `emptyDir`, który istnieje tak długo, jak sam Pod.

Należy zapisać w `logger.yaml` pełny manifest Poda z poniższego przykładu. `initContainers`, główny kontener i sidecar znajdują się w odpowiednich listach pod `spec` Poda. Oba kontenery aplikacyjne i init container montują ten sam wolumen:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: logger
spec:
  initContainers:
    - name: przygotowanie
      image: busybox:1.36
      command: ["sh", "-c", "echo przygotowano > /var/log/demo/status"]
      volumeMounts:
        - name: logi
          mountPath: /var/log/demo
  containers:
    - name: aplikacja
      image: busybox:1.36
      command: ["sh", "-c", "i=0; while true; do echo \"wiadomosc $i\" >> /var/log/demo/app.log; i=$((i+1)); sleep 5; done"]
      volumeMounts:
        - name: logi
          mountPath: /var/log/demo
    - name: tail
      image: busybox:1.36
      command: ["sh", "-c", "touch /var/log/demo/app.log; tail -F /var/log/demo/app.log"]
      volumeMounts:
        - name: logi
          mountPath: /var/log/demo
  volumes:
    - name: logi
      emptyDir: {}
```

Należy zastosować manifest, poczekać na `kubectl wait --for=condition=Ready pod/logger --timeout=120s`, sprawdzić `kubectl logs logger -c tail` oraz wykonać `kubectl exec logger -c aplikacja -- cat /var/log/demo/status`. Następnie należy usunąć init container z manifestu i utworzyć Poda ponownie. Należy porównać zachowanie kontenerów, poprzedni wolumen i logi po odtworzeniu Poda.

*Weryfikacja:* status utworzył się przed uruchomieniem aplikacji; sidecar odczytuje te same pliki, które zapisuje główny kontener. Odtworzenie Poda tworzy nowy `emptyDir`; nie zastępuje wolumenu trwałego dla bazy danych.

== Zasoby i HPA

Kontener w zadaniu B ma już żądania i limity CPU oraz pamięci. Należy zmienić limit pamięci na `16Mi`, zastosować manifest, odczytać nazwę Poda i wykonać `kubectl describe pod NAZWA` oraz `kubectl logs NAZWA --previous`. Po obserwacji należy przywrócić `128Mi`. Zbyt niski limit pamięci może wywołać `OOMKilled`; żądanie zbyt duże w stosunku do wolnych zasobów może pozostawić Pod w stanie `Pending`.

HPA (Horizontal Pod Autoscaler) zmienia liczbę replik na podstawie metryk. W lokalnym Minikube należy najpierw włączyć Metrics Server:

```bash
minikube addons enable metrics-server
kubectl top nodes
kubectl top pods
kubectl autoscale deployment flask --cpu=50% --min=2 --max=5
kubectl get hpa flask --watch
```

Procent CPU oblicza się względem `requests.cpu`; dlatego obraz Flaska deklaruje `100m`. Bez metryk HPA nie może wyliczyć docelowej liczby replik. Jeżeli dane metryczne są jeszcze niedostępne, należy odczekać chwilę i sprawdzić `kubectl describe hpa flask`. Zadanie kończy się w chwili, gdy studenci wyjaśnią stan HPA i jego aktualne metryki. Nie trzeba powodować ruchu na procesorze w ograniczonym klastrze szkoleniowym.

Po ćwiczeniu należy usunąć HPA przez `kubectl delete hpa flask`, a następnie przywrócić plik `flask.yaml` do liczby replik 2 i go zastosować. HPA i `kubectl scale` mogą zmienić aktualną liczbę w klastrze, ale źródłem deklarowanej konfiguracji pozostaje manifest.

= I. Konfiguracja i bezpieczeństwo Podów

ConfigMap może dostarczyć ustawienia jako zmienne środowiskowe lub pliki. Zmiana pliku wolumenu ConfigMap w końcu staje się widoczna w Podzie, lecz aplikacja musi ponownie go odczytać. Wartości zmiennych środowiskowych działającego kontenera nie zmieniają się po aktualizacji ConfigMap; wymagają restartu Poda.

```bash
kubectl create configmap flask-settings \
  --from-literal=komunikat='uruchomiono przez ConfigMap'
kubectl get configmap flask-settings -o yaml
```

Należy dodać do Deploymentu Flaska pod `containers[0].env`:

```yaml
            - name: KOMUNIKAT
              valueFrom:
                configMapKeyRef:
                  name: flask-settings
                  key: komunikat
```

Aby aplikacja wyświetliła tę wartość, trzeba rozszerzyć kod i zbudować nowy obraz. Zadanie polega na poprawnym dodaniu zmiennej, sprawdzeniu `kubectl exec POD -- env` i odtworzeniu Deploymentu po zmianie ConfigMap. Nie należy twierdzić, że dotychczasowy Flask używa ustawienia tylko dlatego, że zmienna jest obecna w kontenerze.

Sekrety służą do przekazywania wrażliwych danych. Należy sprawdzić nazwy kluczy w `kubectl describe secret redmine-secret`, bez wyświetlania wartości hasła w udostępnianym terminalu. W produkcji dostęp do Secret powinien mieć tylko potrzebny podmiot, a konfiguracja klastra powinna szyfrować sekrety w spoczynku. Manifest przykładowy z hasłem laboratoryjnym nie jest wzorem na zarządzanie sekretami repozytorium.

Następnie należy przetestować ograniczenie kontenerów nieuprzywilejowanych. W manifeście `logger.yaml` należy dodać `securityContext` na poziomie `spec` Poda oraz `securityContext` dla obu głównych kontenerów. `fsGroup` ustawia się na poziomie `spec`; pozostałe ograniczenia na poziomie pojedynczego kontenera:

```yaml
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 2000
    fsGroup: 2000
  containers:
    - name: tail
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop: ["ALL"]
```

Te same ograniczenia należy ustawić dla kontenera `aplikacja`. Inicjalizacyjny zapis i plik logu przechowywane są w `emptyDir`; `fsGroup: 2000` przyznaje grupie dostęp do zamontowanego wolumenu. `readOnlyRootFilesystem` blokuje zapis do głównego systemu plików, ale nie do jawnie podmontowanego `emptyDir`.

Po zastosowaniu należy wykonać `kubectl exec logger -c tail -- id` i `kubectl logs logger -c tail`. Jeżeli kontener nie startuje, należy odczytać zdarzenia i sprawdzić prawa dostępu do plików. Nie należy usuwać ograniczeń bezpieczeństwa bez ustalenia, które pole jest przyczyną problemu.

= J. Polityka ruchu i wejście HTTP

== NetworkPolicy

NetworkPolicy wybiera Pody etykietami i dopuszcza wskazany ruch wejściowy lub wyjściowy. API klastra może przyjąć obiekt, nawet jeżeli używany plugin CNI nie egzekwuje reguł. Dlatego klaster uruchomiono z Calico. Należy sprawdzić `kubectl get pods -n kube-system` i upewnić się, że komponenty sieciowe Calico działają.

W pliku `redmine-network-policy.yaml` należy na początku zapisać poniższą politykę bez reguł `ingress`, a następnie sprawdzić klientem z Poda `app: diagnostyka`, czy połączenie z `service/redmine` zostało zablokowane. `kubectl port-forward` nie jest odpowiednim testem tej reguły, bo ustanawia tunel przez API serwera:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: redmine-ingress
spec:
  podSelector:
    matchLabels:
      app: redmine
  policyTypes: [Ingress]
  ingress: []
```

Następnie `ingress: []` należy zastąpić regułą dla klienta w tym namespace:

```yaml
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: diagnostyka
      ports:
        - protocol: TCP
          port: 3000
```

Należy zmodyfikować politykę tak, by `ingress.from` zezwalał tylko na źródło w tym samym namespace z `podSelector.matchLabels.app: diagnostyka`, a `ingress.ports` zezwalał na TCP `3000`. Klient w osobnym namespace powinien wciąż nie mieć dostępu. Jeżeli klient diagnostyczny musi docierać również do DNS, egress klienta wymaga reguły dla UDP/TCP `53` skierowanej do Podów DNS w `kube-system`.

Sieć aplikacji i bazy można ograniczyć dodatkowo. Do powyższego manifestu należy dodać `Egress` do `policyTypes` i poniższe reguły. Wskazana etykieta DNS jest używana przez domyślny CoreDNS w Kubernetes; przed ćwiczeniem należy potwierdzić etykiety przez `kubectl get pods -n kube-system --show-labels`:

```yaml
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: postgres
      ports:
        - protocol: TCP
          port: 5432
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

Reguła egress izoluje cały ruch wychodzący Podów `app: redmine`; po jej wdrożeniu należy zachować wymagane połączenia z DNS i bazą. Do ćwiczenia wejściowego wystarczy pierwsza polityka ruchu przychodzącego. Reguły egress są rozszerzeniem.

*Weryfikacja:* przed dodaniem zezwolenia połączenie diagnostyczne nie działa, po dodaniu reguły działa dla właściwego źródła i portu. Należy sprawdzić dopasowane etykiety Podów i użyć klienta z klastra. Wdrożenie nie wpływa na dostęp do klastra ani na logi i odczyt przez API.

== Gateway API z kontrolerem Traefik

Gateway API rozdziela konfigurację ruchu między trzy zasoby. `GatewayClass` wskazuje kontroler, `Gateway` definiuje punkt wejścia i słuchacze, a `HTTPRoute` opisuje trasę konkretnej aplikacji. Kontroler Traefik obserwuje te zasoby i realizuje ruch. Service typu `ClusterIP` pozostaje adresem aplikacji wewnątrz klastra.

Najpierw należy zainstalować standardowe CRD Gateway API. CRD rozszerzają API Kubernetes klasami `GatewayClass`, `Gateway` i `HTTPRoute`; ich instalacja sama w sobie nie uruchamia kontrolera.

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/standard-install.yaml
kubectl get crd gateways.gateway.networking.k8s.io httproutes.gateway.networking.k8s.io
```

Następnie należy zainstalować Traefik przez Helm z włączonym providerem Gateway API:

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm upgrade --install traefik traefik/traefik \
  --version 42.0.0 \
  --namespace traefik --create-namespace \
  --set providers.kubernetesGateway.enabled=true \
  --set providers.kubernetesCRD.enabled=false \
  --set providers.kubernetesIngress.enabled=false \
  --set gateway.enabled=false \
  --set gatewayClass.enabled=false \
  --set service.spec.type=ClusterIP
kubectl rollout status deployment/traefik -n traefik --timeout=180s
```

W namespace `traefik` należy utworzyć GatewayClass i Gateway. Listener przyjmuje ruch HTTP na porcie 8000 kontrolera. Do Gateway mogą dołączyć trasy z namespace oznaczonego etykietą `zsr-gateway-access: "true"`.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: traefik
spec:
  controllerName: traefik.io/gateway-controller
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: aplikacje
  namespace: traefik
spec:
  gatewayClassName: traefik
  listeners:
    - name: http
      protocol: HTTP
      port: 8000
      allowedRoutes:
        namespaces:
          from: Selector
          selector:
            matchLabels:
              zsr-gateway-access: "true"
```

Namespace aplikacji należy oznaczyć, a następnie utworzyć plik `httproutes.yaml` z trasami. `parentRefs` łączy każdą trasę z Gateway w namespace `traefik`; `backendRefs` wskazuje Service w tym samym namespace co HTTPRoute.

```bash
kubectl label namespace zsr zsr-gateway-access=true --overwrite
kubectl apply -f gateway.yaml
kubectl apply -f httproutes.yaml
kubectl get gatewayclass,gateway -A
kubectl get httproutes -n zsr
kubectl describe httproute flask -n zsr
kubectl port-forward service/traefik -n traefik 8080:80
```

Przykładowy dokument HTTPRoute dla Flaska:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: flask
  namespace: zsr
spec:
  parentRefs:
    - name: aplikacje
      namespace: traefik
      sectionName: http
  hostnames:
    - flask.zsr.test
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: flask
          port: 80
```

Dla Redmine należy dodać drugi dokument `HTTPRoute` z nazwą `redmine`, hostem `redmine.zsr.test` i backendem `redmine` na porcie Service `3000`.

W drugim terminalu należy sprawdzić oba hosty, ustawiając nagłówek `Host`:

```bash
curl -H 'Host: flask.zsr.test' http://localhost:8080/
curl -I -H 'Host: redmine.zsr.test' http://localhost:8080/login
```

Nagłówek HTTP wybiera regułę hosta; modyfikowanie `/etc/hosts` nie jest potrzebne dla tych prób. Należy celowo zmienić nazwę usługi backendu w jednym wpisie, sprawdzić status i warunki HTTPRoute oraz logi Traefika, po czym przywrócić właściwą nazwę. Pozostawienie TLS, certyfikatu i publicznej nazwy domenowej do osobnych ćwiczeń pozwala skupić się na przepływie żądania: host → Gateway → HTTPRoute → Service → Pod.

= K. Kustomize i sprawdzian praktyczny

Kustomize pozwala utrzymać wspólną bazę manifestów oraz niewielkie różnice dla danego środowiska. `kubectl` ma wbudowaną obsługę przez `kubectl kustomize` i `kubectl apply -k`.

Należy utworzyć katalogi `deploy/base` i `deploy/overlays/lab`. W `deploy/base/kustomization.yaml` trzeba wskazać manifesty `flask.yaml`, `postgres.yaml`, `redmine.yaml` i `httproutes.yaml`. W overlay należy dodać własny `kustomization.yaml`, który odwołuje się do `../../base`, definiuje prefix `zsr-` i ustawia odpowiedni namespace. Przed zastosowaniem trzeba obejrzeć `kubectl kustomize deploy/overlays/lab`, sprawdzić nazwy Service i referencje w selektorach, PVC oraz `parentRefs` tras.

Jeżeli transformacja nazwy obejmuje obiekt, do którego odwołują się inne manifesty, należy sprawdzić wynikowy YAML: zmiana nazwy PVC lub Service wymaga zgodności referencji. Secret użyty do ćwiczenia należy zachować w osobnym pliku wyłączonym z repozytorium lub utworzyć bezpośrednio przez `kubectl`; nie należy generować publicznego overlay z hasłami.

== Zadanie zaliczeniowe

Na czystym namespace `zsr-egzamin` należy wdrożyć Flaska i Redmine według kryteriów:

1. Deployment Flaska ma dwie gotowe repliki z obrazem `zsr-flask:v2`, limitami CPU i pamięci, żądaniami CPU oraz sondami.
2. Service nie ma adresu zewnętrznego. Odpowiedź Flaska i trasa `/health` są dostępne po przekierowaniu portu.
3. Nieudany rollout nie pozbawia usługi ostatniej gotowej wersji; student potrafi odczytać powód i przywrócić właściwy obraz.
4. PostgreSQL działa jako pojedynczy StatefulSet z PVC, hasłem z Secret, gotowością sprawdzaną sondą i stabilną nazwą Service.
5. Redmine korzysta z ConfigMap, Secret i osobnego PVC na załączniki; login, baza i plik pozostają dostępne po odtworzeniu obu Podów.
6. Job zapisuje jednorazowy raport; CronJob tworzy raport cyklicznie; student potrafi odczytać logi i historię.
7. NetworkPolicy pozwala na ruch z klienta diagnostycznego tylko na port aplikacji i na ruch Redmine → PostgreSQL.
8. Gateway przyjmuje HTTP i pozwala na dołączenie HTTPRoute z przestrzeni nazw aplikacji; Kustomize renderuje spójny zestaw manifestów.

Odbiór powinien sprawdzić *działanie*, *stan obiektów* i *trwałość po odtworzeniu*. Sam wynik `kubectl apply` nie spełnia tych kryteriów. Student powinien umieć w czasie demonstracji użyć `kubectl get`, `describe`, `logs`, `exec`, `rollout status` i `rollout undo` oraz wyjaśnić, co konkretnie naprawił.

= Odbiór części Kubernetes

Do odbioru należy przedstawić manifesty oraz krótkie obserwacje z doświadczeń:

- Odtworzenie Poda Flaska, trzy gotowe repliki i działające połączenie przez Service z klienta wewnątrz klastra.
- Aktualizację do wersji 2, rozpoznaną przyczynę nieudanego wdrożenia i zgodność poprawionego pliku ze stanem klastra.
- Różnicę między skutkami błędów readiness i liveness: gotowość, restarty i UID.
- Redmine z PostgreSQL oraz projekt i załącznik dostępne po wymianie Podów.

Manifesty i obserwacje należy zachować. Dla konfiguracji z hasłami w repozytorium należy przechowywać jedynie szablon bez rzeczywistych sekretów. W ramach omówienia należy odpowiedzieć: co odtworzy Deployment, czego sam nie odtworzy PVC i co stanie się z usługą po awarii jedynego węzła?

== Zatrzymanie środowiska

Po demonstracji należy zakończyć procesy `port-forward` i zatrzymać klaster poleceniem `minikube stop`. Pracę można wznowić przez `minikube start`. Usunięcie namespace (`kubectl delete namespace zsr`) usuwa również należące do niego PVC i może spowodować usunięcie danych przez provisioner. Polecenie `minikube delete` usuwa cały domyślny klaster i jego dane, także spoza ćwiczenia. Tych operacji nie należy wykonywać bez upewnienia się, że dane nie są już potrzebne.

= Diagnostyka Kubernetes

Najpierw należy sprawdzić kontekst i namespace, potem obiekt, jego zdarzenia oraz logi:

```bash
kubectl config current-context
kubectl get pods,pvc,services
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl describe pod NAZWA
kubectl logs NAZWA
kubectl logs NAZWA --previous
```

`NAZWA` wymaga zastąpienia rzeczywistą nazwą Poda. `--previous` działa, gdy istnieją logi poprzedniej instancji kontenera w tym Podzie.

- `ErrImageNeverPull`: należy sprawdzić nazwę i znacznik oraz wczytać obraz przez `minikube image load` do domyślnego klastra. `ImagePullBackOff` przy obrazach z rejestru wymaga sprawdzenia zdarzeń, dostępu do rejestru i istnienia znacznika.
- `Pending`: `describe` może wskazać brak CPU lub pamięci albo nieprzydzielony PVC. Przy PVC należy sprawdzić `kubectl describe pvc NAZWA` i domyślną StorageClass.
- `CrashLoopBackOff`: należy odczytać logi bieżącego i poprzedniego kontenera, kod zakończenia oraz zdarzenia. Powodem może być błąd konfiguracji, brak bazy albo sonda liveness.
- `CreateContainerConfigError`: należy sprawdzić istnienie ConfigMap, Secret i wskazanych kluczy w namespace `zsr`.
- Service nie odpowiada: należy porównać selektor z etykietami Podów, porty i EndpointSlice. Brak gotowych adresów może wynikać z błędu selektora albo readiness.
- `port-forward` zakończył pracę: należy sprawdzić gotowość nowych Podów i uruchomić przekierowanie ponownie. Sam tunel nie zapewnia ciągłej dostępności podczas wymiany Poda.

= Dalsze kroki i źródła

HPA używający procentu CPU wymaga źródła metryk oraz zadeklarowanych `requests.cpu`. NetworkPolicy działa tylko wtedy, gdy CNI je egzekwuje. Gateway API wymaga zainstalowanych CRD i kontrolera, który obsługuje jego zasoby; same manifesty nie uruchamiają procesu obsługującego ruch. Zadania tych spotkań warto robić po samodzielnym sprawdzeniu Service, sond i ręcznego skalowania.

#link("https://github.com/cncf/curriculum/tree/master/ckad")[CKAD curriculum CNCF] · #link("https://minikube.sigs.k8s.io/docs/drivers/docker/")[Minikube z Dockerem] · #link("https://minikube.sigs.k8s.io/docs/handbook/pushing/")[Obrazy w Minikube] · #link("https://kubernetes.io/docs/concepts/workloads/controllers/deployment/")[Deployment] · #link("https://kubernetes.io/docs/concepts/services-networking/service/")[Service] · #link("https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/")[Sondy] · #link("https://kubernetes.io/docs/concepts/configuration/configmap/")[ConfigMap] · #link("https://kubernetes.io/docs/concepts/configuration/secret/")[Secret] · #link("https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/")[StatefulSet] · #link("https://kubernetes.io/docs/concepts/workloads/controllers/job/")[Job] · #link("https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/")[CronJob] · #link("https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/")[Sidecar] · #link("https://kubernetes.io/docs/tasks/configure-pod-container/security-context/")[SecurityContext] · #link("https://kubernetes.io/docs/concepts/services-networking/network-policies/")[NetworkPolicy] · #link("https://minikube.sigs.k8s.io/docs/handbook/network_policy/")[Calico i polityki w Minikube] · #link("https://kubernetes.io/docs/concepts/services-networking/gateway/")[Gateway API] · #link("https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/kubernetes/gateway-api/")[Traefik Gateway API] · #link("https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/")[Kustomize] · #link("https://minikube.sigs.k8s.io/docs/handbook/persistent_volumes/")[Dane trwałe w Minikube] · #link("https://helm.sh/docs/")[Helm] · #link("https://hub.docker.com/_/postgres")[Obraz PostgreSQL] · #link("https://hub.docker.com/_/redmine")[Obraz Redmine]

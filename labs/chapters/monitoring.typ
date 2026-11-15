#pagebreak()

= Część III. Monitoring i diagnoza

Traefik z części II staje się teraz źródłem telemetrii. Do klastra dołączają Prometheus, Grafana i Alertmanager, a żądania przechodzące przez Traefika dostarczają trzech rodzajów danych: metryk, śladów i logów. Celem nie jest zbieranie wykresów, lecz odpowiedź na pytanie, gdzie usługa traci czas i jak to potwierdzić pomiarem. Wszystkie obrazy i wykresy Helm są publiczne i przypięte do wersji.

== Plan pracy na kilka spotkań

#table(
  columns: (auto, 1fr, 1fr), inset: 6pt, stroke: 0.4pt,
  table.header([*Spotkanie*], [*Zakres*], [*Efekt pracy*]),
  [1], [Stos monitoringowy i telemetria z Traefika (A, B)], [Prometheus, Grafana i Alertmanager działają, cel Traefika jest zbierany],
  [2], [Ruch, błędy, p95 i alert (C, D)], [p95 z histogramu i alert, który dociera mailem],
  [3], [Ślad, log i diagnoza przypadku (E, F)], [Ten sam identyfikator śladu w logu i w Collectorze, przyczyna potwierdzona pomiarem],
  [4], [Brak danych, retencja i kardynalność (G)], [Student odróżnia brak serii od zera i zna koszt etykiety],
)

Plan jest modułowy. Zadania A–D są obowiązkowe, E i F domykają diagnozę, G jest rozszerzeniem dla szybszych grup.

= A. Stos monitoringowy

Prometheus zbiera metryki w modelu pobierania: to on odczytuje punkty końcowe `metrics`, a nie odwrotnie. Alertmanager odbiera alerty wyliczone przez Prometheusa, a Grafana jedynie odczytuje dane z Prometheusa. W tym zadaniu instalujemy cały stos jednym wydaniem Helm: `kube-prometheus-stack` zawiera Prometheusa, Alertmanagera, Grafanę, operatora, `node-exporter` i `kube-state-metrics`.

Należy utworzyć w katalogu `kubernetes` plik `monitoring-values.yaml`:

```yaml
grafana:
  adminPassword: lab1234
prometheus:
  prometheusSpec:
    retention: 6h
    serviceMonitorSelectorNilUsesHelmValues: false
    ruleSelectorNilUsesHelmValues: false
    resources:
      requests:
        cpu: 200m
        memory: 512Mi
      limits:
        memory: 1200Mi
kubeEtcd:
  enabled: false
kubeControllerManager:
  enabled: false
kubeScheduler:
  enabled: false
kubeProxy:
  enabled: false
```

Dwie opcje `serviceMonitorSelectorNilUsesHelmValues` i `ruleSelectorNilUsesHelmValues` ustawione na `false` sprawiają, że Prometheus zbiera *wszystkie* obiekty `ServiceMonitor` i `PrometheusRule` w klastrze, a nie tylko te opatrzone etykietą wydania. Bez tego nowy cel nie zostałby zauważony, a przyczyny szukano by w aplikacji.

Cztery sekcje `kubeEtcd`, `kubeControllerManager`, `kubeScheduler` i `kubeProxy` są wyłączone, ponieważ Minikube nie udostępnia tych punktów końcowych. Gdyby zostały włączone, ich cele byłyby trwale niedostępne, a lista celów przestałaby służyć do wykrywania rzeczywistych problemów.

Należy dodać repozytorium i zainstalować stos w wersji przypiętej:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --version 93.3.0 \
  --namespace monitoring \
  -f monitoring-values.yaml \
  --wait --timeout 15m
kubectl get pods -n monitoring
```

Instalacja pobiera kilkanaście obrazów i trwa kilka minut. Po zakończeniu należy sprawdzić stan stosu oraz uruchomić Prometheusa:

```bash
kubectl get alertmanager,prometheus -n monitoring
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9091:9090
```

W drugim terminalu należy otworzyć `http://localhost:9091` i w zakładce *Status → Targets* potwierdzić, że wszystkie cele mają stan `UP`. Następnie należy uruchomić Grafanę i zalogować się jako `admin` z hasłem `lab1234`:

```bash
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
```

*Weryfikacja:* obiekt `Alertmanager` ma stan `RECONCILED: True`, liczba celów wynosi kilkanaście i żaden nie jest czerwony, a Grafana ma gotowe źródło danych `Prometheus`. Jeżeli obiekt Alertmanagera pozostaje niespójny, należy odczytać komunikat w `kubectl get alertmanager -n monitoring -o yaml`; błąd dotyczy wtedy konfiguracji, a nie klastra.

= B. Traefik jako źródło telemetrii

Traefik z części II nie eksportował metryk do Prometheusa ani nie zapisywał logów w formacie czytelnym dla maszyny. Te ustawienia włącza się przez rozszerzenie tego samego wydania Helm — nie trzeba instalować Traefika ponownie.

Należy utworzyć plik `traefik-values.yaml`:

```yaml
metrics:
  prometheus:
    serviceMonitor:
      enabled: true
tracing:
  otlp:
    enabled: true
    http:
      enabled: true
      endpoint: http://otel-collector.monitoring.svc.cluster.local:4318/v1/traces
accessLog:
  enabled: true
  format: json
providers:
  kubernetesGateway:
    enabled: true
  kubernetesCRD:
    enabled: false
  kubernetesIngress:
    enabled: false
gateway:
  enabled: false
gatewayClass:
  enabled: false
service:
  spec:
    type: ClusterIP
```

Sekcje `providers` i `gateway` powtarzają ustawienia z części II, ponieważ `helm upgrade` z plikiem wartości zastępuje całą konfigurację wydania. Pominięcie tych linii wyłączyłoby Traefika i trasy przestałyby działać.

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm upgrade traefik traefik/traefik \
  --version 42.0.0 \
  --namespace traefik \
  -f traefik-values.yaml \
  --wait --timeout 5m
kubectl get servicemonitor -n traefik
kubectl rollout status deployment/traefik -n traefik --timeout=180s
```

Traefik eksponuje metryki na porcie `9100`, a wykres tworzy obiekt `ServiceMonitor`, który opisuje, jak Prometheus ma je zbierać. Cel pojawia się na liście po kilkudziesięciu sekundach.

Należy wykonać jedno żądanie przez Traefika i odczytać log dostępu:

```bash
kubectl run test-traefik --rm -i --restart=Never \
  --image=curlimages/curl:8.23.0 -n zsr -- \
  curl -s -o /dev/null -w 'kod=%{http_code}\n' \
  http://traefik.traefik.svc.cluster.local/
kubectl logs -n traefik deployment/traefik --tail=1
```

Log w formacie JSON zawiera między innymi `Duration`, `OriginDuration`, `ServiceName` i `TraceId`. `Duration` obejmuje całe żądanie widziane przez Traefika, a `OriginDuration` tylko czas oczekiwania na odpowiedź usługi. Różnica między nimi to czas pracy samego Traefika. Wartości podane są w nanosekundach.

Dwie pułapki etykiet, które należy znać przy pisaniu zapytań:

- Traefik nadaje metrykom usług własną etykietę `service`, ale Prometheus dodaje do każdej próbki etykietę `service` pochodzącą z celu. Nazwa jest zajęta, więc etykieta Traefika trafia do `exported_service`. Zapytanie o usługę musi używać `exported_service`, na przykład `exported_service=~".*-svc-zsr-.*"`.
- Metryki punktów wejścia mają etykietę `entrypoint` (na przykład `web`), a nie `entrypointName`. Zapytanie z błędną nazwą etykiety zwraca pusty wynik, nie błąd.

*Weryfikacja:* obiekt `ServiceMonitor` istnieje w namespace `traefik`, cel `serviceMonitor/traefik/traefik` ma stan `UP`, a `kubectl logs` pokazuje jedną linię JSON z polami `Duration` i `TraceId`. Należy wyjaśnić, dlaczego wyłączenie `providers.kubernetesGateway` zepsułoby trasy z części II.

#pagebreak()

= C. Ruch, błędy i p95 z histogramu

Do ćwiczenia potrzebna jest usługa odpowiadająca szybko i przewidywalnie. Należy użyć publicznego obrazu `traefik/whoami` oraz drugiej usługi `mccutchen/go-httpbin`, która potrafi odpowiadać z opóźnieniem. Obie będą potrzebne w zadaniu F.

Należy utworzyć plik `whoami.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whoami
  namespace: zsr
spec:
  replicas: 1
  selector:
    matchLabels:
      app: whoami
  template:
    metadata:
      labels:
        app: whoami
    spec:
      containers:
        - name: whoami
          image: traefik/whoami:v1.12.0
          ports:
            - name: http
              containerPort: 80
          resources:
            requests:
              cpu: 50m
              memory: 32Mi
            limits:
              memory: 64Mi
---
apiVersion: v1
kind: Service
metadata:
  name: whoami
  namespace: zsr
spec:
  selector:
    app: whoami
  ports:
    - name: http
      port: 80
      targetPort: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: whoami
  namespace: zsr
spec:
  parentRefs:
    - name: aplikacje
      namespace: traefik
      sectionName: http
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: whoami
          port: 80
```

Ta trasa nie podaje `hostnames`, więc pasuje do każdej nazwy hosta. Dzięki temu obciążenie można kierować pod adres usługi Traefika, bez nagłówka `Host`.

Obciążenie generuje `fortio` — publiczny obraz, który mierzy czas odpowiedzi po stronie klienta i podaje percentyle. Należy utworzyć plik `obciazenie.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: obciazenie
  namespace: zsr
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: fortio
          image: fortio/fortio:1.76.0
          args:
            - load
            - -qps
            - "100"
            - -c
            - "100"
            - -t
            - 300s
            - http://traefik.traefik.svc.cluster.local/
```

```bash
kubectl apply -f whoami.yaml
kubectl rollout status deployment/whoami -n zsr --timeout=120s
kubectl apply -f obciazenie.yaml
```

W Prometheusie należy wykonać trzy zapytania. Pierwsze pokazuje natężenie ruchu, drugie udział błędów, trzecie wartość p95:

```promql
sum(rate(traefik_service_requests_total{exported_service=~".*-svc-zsr-.*"}[1m]))
```

```promql
sum(rate(traefik_service_requests_total{exported_service=~".*-svc-zsr-.*",code=~"5.."}[1m]))
  / sum(rate(traefik_service_requests_total{exported_service=~".*-svc-zsr-.*"}[1m]))
```

```promql
histogram_quantile(
  0.95,
  sum by (le) (rate(traefik_service_request_duration_seconds_bucket{exported_service=~".*-svc-zsr-.*"}[1m]))
)
```

Funkcja `rate` musi objąć licznik przed agregacją; inaczej po restarcie procesu suma spadłaby do zera i wynik byłby zafałszowany. Zapytanie o błędy dzieli dwie sumy — przy braku ruchu mianownik jest zerem, więc wynik należy interpretować ostrożnie.

Wynik p95 wymaga komentarza, bo bywa mylący. Histogram Traefika ma przedziały `0,1`, `0,3`, `1,2`, `5,0` i `+Inf` sekundy, a `histogram_quantile` zakłada, że wartości wewnątrz przedziału rozkładają się równomiernie. Przy ruchu 100 żądań na sekundę i odpowiedziach rzędu kilku milisekund *wszystkie* próbki trafiają do pierwszego przedziału, więc funkcja zwraca około `0,095` s. To nie jest zmierzony czas odpowiedzi, lecz wynik interpolacji w pierwszym przedziale.

Rzeczywisty czas należy zmierzyć niezależnie. Po zakończeniu zadania `obciazenie` należy odczytać wynik:

```bash
kubectl logs -n zsr job/obciazenie --tail=5
```

*Weryfikacja:* zapytanie o ruch zwraca około `100` żądań na sekundę, udział błędów jest pusty lub równy zero, a `histogram_quantile` zwraca około `0,095` s, podczas gdy `fortio` raportuje kod 200 dla wszystkich 30 000 wywołań i średni czas około `3,9` ms. Należy wyjaśnić, dlaczego wartość z histogramu jest ponad dwadzieścia razy większa od pomiaru klienta i dlaczego nie znaczy to, że histogram jest bezużyteczny. Przedziały histogramu należy dobierać do rzędu wielkości mierzonego zjawiska; przy milisekundach przedział `0,1` s jest zbyt szeroki.

= D. Alert, Alertmanager i Mailpit

Alert ma docierać do odbiorcy. Zamiast poczty zewnętrznej uruchamiamy `Mailpit` — publiczny obraz, który przyjmuje pocztę SMTP i pokazuje ją w przeglądarce.

Należy utworzyć plik `mailpit.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mailpit
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mailpit
  template:
    metadata:
      labels:
        app: mailpit
    spec:
      containers:
        - name: mailpit
          image: axllent/mailpit:v1.33
          ports:
            - name: smtp
              containerPort: 1025
            - name: http
              containerPort: 8025
---
apiVersion: v1
kind: Service
metadata:
  name: mailpit
  namespace: monitoring
spec:
  selector:
    app: mailpit
  ports:
    - name: smtp
      port: 1025
      targetPort: 1025
    - name: http
      port: 8025
      targetPort: 8025
```

Konfigurację Alertmanagera dopisuje się do pliku `monitoring-values.yaml`. Należy dodać w nim sekcję `alertmanager` przed sekcją `kubeEtcd`:

```yaml
alertmanager:
  config:
    global:
      smtp_smarthost: 'mailpit.monitoring.svc.cluster.local:1025'
      smtp_from: 'alertmanager@zsr.local'
      smtp_require_tls: false
      resolve_timeout: 1m
    route:
      receiver: mailpit
      group_wait: 10s
      group_interval: 1m
      repeat_interval: 30m
    receivers:
      - name: mailpit
        email_configs:
          - to: 'dyzurny@zsr.local'
            send_resolved: true
      - name: "null"
```

Pole `smtp_require_tls: false` jest konieczne, ponieważ Alertmanager domyślnie wymaga szyfrowania SMTP, a Mailpit go nie używa. Nazwa pola to `smtp_require_tls`; skrócone `require_tls` w tej wersji Alertmanagera nie istnieje i cały obiekt Alertmanagera przestaje być uzgadniany.

Drugi odbiorca o nazwie `null` nie jest ozdobnikiem. Wykres ma domyślną trasę, która kieruje alert `Watchdog` do odbiorcy `null`. Podmieniając listę odbiorców, usuwamy ten wpis i Alertmanager przestaje działać z komunikatem o nieznanym odbiorcy. Zachowanie wpisu `null` rozwiązuje problem.

```bash
kubectl apply -f mailpit.yaml
helm upgrade monitoring prometheus-community/kube-prometheus-stack \
  --version 93.3.0 -n monitoring -f monitoring-values.yaml --wait --timeout 10m
kubectl get alertmanager -n monitoring
kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager
```

Teraz reguła alertu. Wykres udostępnia typ `PrometheusRule`; wystarczy go zastosować, bez ponownej instalacji stosu. Należy utworzyć plik `alert.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: zsr-latencja
  namespace: monitoring
spec:
  groups:
    - name: zsr.rules
      rules:
        - alert: WysokaLatencjaP95
          expr: |
            histogram_quantile(
              0.95,
              sum by (le) (rate(traefik_service_request_duration_seconds_bucket{exported_service=~".*-svc-zsr-.*"}[2m]))
            ) > 0.5
          for: 1m
          labels:
            severity: warning
          annotations:
            summary: "p95 usługi w namespace zsr przekracza 0,5 s"
            description: "p95 = {{ $value | humanizeDuration }}."
```

```bash
kubectl apply -f alert.yaml
kubectl port-forward -n monitoring svc/mailpit 8025:8025
```

W zakładce *Alerts* Prometheusa widać najpierw stan `inactive`: p95 sprawnej usługi wynosi około `0,095` s, czyli mniej niż próg `0,5` s. Aby przejść całą ścieżkę bez wprowadzania awarii, należy na chwilę obniżyć próg w `alert.yaml` do `0,05`, zastosować plik i obserwować przejście przez `pending` do `firing` oraz list w Mailpicie. Wartość `0,095` s pochodzi z interpolacji w pierwszym przedziale histogramu, omówionej w zadaniu C — dlatego próg dobiera się do rzeczywistego rzędu wielkości, a nie do pierwszej liczby odczytanej z wykresu. Po doświadczeniu należy przywrócić próg `0,5` i zastosować plik; alert przejdzie w stan `Resolved`, a dzięki `send_resolved: true` przyjdzie drugi list. Alert trafia do Alertmanagera, a stamtąd jako poczta do Mailpita, którego skrzynkę otwiera się pod `http://localhost:8025`.

Czas do pierwszego listu wynika z trzech nastaw: `scrapeInterval` i `evaluationInterval` wynoszą po 30 s, warunek musi się utrzymywać przez `for: 1m`, a Alertmanager czeka `group_wait: 10s`. Razem daje to około dwóch–trzech minut. Skrócenie tych wartości przyspiesza ćwiczenie, ale zwiększa liczbę fałszywych alertów przy wahaniach ruchu.

Po ustąpieniu przyczyny alert przechodzi w stan `Resolved`, a dzięki `send_resolved: true` przychodzi drugi list. Wygaszanie nie jest natychmiastowe: warunek liczony jest z dwuminutowego okna, więc przez jakiś czas p95 pozostaje zawyżone.

*Weryfikacja:* reguła jest widoczna w Prometheusie i przechodzi do stanu `firing`, Alertmanager pokazuje alert `WysokaLatencjaP95`, a w Mailpicie są dwa listy: `[FIRING:1]` i później `[RESOLVED]`. Należy wyjaśnić, dlaczego sam wykres w Grafanie nie byłby alertem.

#pagebreak()

= E. Ślad i log tej samej operacji

Metryka mówi, że coś jest wolne, ale nie mówi gdzie. Ślad pokazuje drogę żądania, a log wyjaśnia szczegóły. Traefik wysyła ślady protokołem OTLP, więc potrzebny jest odbiorca. Zamiast pełnego stosu śledzenia uruchamiamy OpenTelemetry Collector z eksporterem `debug`, który wypisuje ślady do swojego logu. Ten sam efekt dydaktyczny uzyskuje się bez dodatkowej bazy i bez licencji.

Należy utworzyć plik `collector.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector
  namespace: monitoring
data:
  config.yaml: |
    receivers:
      otlp:
        protocols:
          http:
            endpoint: 0.0.0.0:4318
          grpc:
            endpoint: 0.0.0.0:4317
    processors:
      batch: {}
    exporters:
      debug:
        verbosity: normal
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [batch]
          exporters: [debug]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: otel-collector
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: otel-collector
  template:
    metadata:
      labels:
        app: otel-collector
    spec:
      containers:
        - name: collector
          image: otel/opentelemetry-collector-contrib:0.165.0
          args: ["--config=/etc/otel/config.yaml"]
          ports:
            - name: otlp-grpc
              containerPort: 4317
            - name: otlp-http
              containerPort: 4318
          volumeMounts:
            - name: config
              mountPath: /etc/otel
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              memory: 256Mi
      volumes:
        - name: config
          configMap:
            name: otel-collector
---
apiVersion: v1
kind: Service
metadata:
  name: otel-collector
  namespace: monitoring
spec:
  selector:
    app: otel-collector
  ports:
    - name: otlp-grpc
      port: 4317
      targetPort: 4317
    - name: otlp-http
      port: 4318
      targetPort: 4318
```

Adres Collectora jest już wpisany w `traefik-values.yaml` z zadania B. Nazwa `otel-collector.monitoring.svc.cluster.local` rozwiązuje się wewnątrz klastra, dlatego oba zadania należy wykonać w tej kolejności.

```bash
kubectl apply -f collector.yaml
kubectl rollout status deployment/otel-collector -n monitoring --timeout=120s
kubectl delete job obciazenie -n zsr --ignore-not-found
kubectl run test-sladow --rm -i --restart=Never \
  --image=curlimages/curl:8.23.0 -n zsr -- \
  curl -s -o /dev/null http://traefik.traefik.svc.cluster.local/
kubectl logs -n traefik deployment/traefik --tail=1
```

Z logu dostępu należy odczytać wartości `TraceId` i `SpanId`. Następnie należy odszukać ten sam identyfikator w logu Collectora:

```bash
kubectl logs -n monitoring deployment/otel-collector --tail=3000
```

Jeżeli obciążenie z zadania C nadal działa, log Collectora rośnie bardzo szybko i żądanie sprzed minuty może już nie być widoczne. Dlatego przed tym ćwiczeniem zatrzymuje się zadanie `obciazenie` i wykonuje jedno żądanie.

W logu Collectora widać dwie linie z tym samym identyfikatorem śladu. Pierwsza opisuje punkt wejścia (`GET`, atrybuty żądania: metoda, ścieżka, kod odpowiedzi), druga operację pośrednika (`ReverseProxy`) i zawiera atrybut `url.full`, czyli adres usługi, do której Traefik naprawdę skierował żądanie. Identyfikator `SpanId` z linii `GET` jest identyczny z `SpanId` z logu dostępu, co potwierdza, że oba zapisy opisują tę samą operację.

*Weryfikacja:* identyfikator `TraceId` z logu dostępu występuje w dwóch liniach logu Collectora, a `SpanId` z logu dostępu jest zgodny z identyfikatorem śladu punktu wejścia. Należy wskazać, który atrybut pozwala ustalić adres usługi docelowej i dlaczego metryka tego nie pokazuje.

= F. Diagnoza przypadku

W tym zadaniu pojawia się objaw, którego przyczyna nie jest widoczna w metryce usługi. Należy użyć drugiej usługi — `go-httpbin`, która udostępnia punkt końcowy `/delay/0.5` odpowiadający po pół sekundy.

Należy utworzyć plik `httpbin.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
  namespace: zsr
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
  template:
    metadata:
      labels:
        app: httpbin
    spec:
      containers:
        - name: httpbin
          image: mccutchen/go-httpbin:2.26.0
          ports:
            - name: http
              containerPort: 8080
          resources:
            requests:
              cpu: 50m
              memory: 32Mi
            limits:
              memory: 128Mi
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  namespace: zsr
spec:
  selector:
    app: httpbin
  ports:
    - name: http
      port: 80
      targetPort: 8080
```

Awarię wprowadza zmiana trasy. Należy utworzyć plik `trasa-awaria.yaml`, który kieruje cały ruch na usługę `httpbin` i przepisuje ścieżkę na `/delay/0.5`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: whoami
  namespace: zsr
spec:
  parentRefs:
    - name: aplikacje
      namespace: traefik
      sectionName: http
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      filters:
        - type: URLRewrite
          urlRewrite:
            path:
              type: ReplaceFullPath
              replaceFullPath: /delay/0.5
      backendRefs:
        - name: httpbin
          port: 80
```

```bash
kubectl apply -f httpbin.yaml
kubectl rollout status deployment/httpbin -n zsr --timeout=120s
kubectl apply -f obciazenie.yaml
kubectl apply -f trasa-awaria.yaml
```

Objaw jest widoczny w Prometheusie: p95 rośnie z około `0,095` s do ponad `1` s. Natężenie ruchu i liczba błędów nie zmieniają się. Kolejne kroki należy wykonać w podanej kolejności i po każdym zapisać obserwację:

1. Zapytanie o ruch i udział błędów — bez zmian. To wyklucza przeciążenie i błędy aplikacji jako przyczynę.
2. Zapytanie o p95 — skok. Metryka zawęża obszar poszukiwań do usługi obsługiwanej przez tę trasę.
3. Log dostępu Traefika. Należy porównać `Duration` i `OriginDuration`. W tym przypadku obie wartości wynoszą około `504` ms, a więc czas nie jest tracony w Traefiku, lecz w usłudze docelowej. Pole `ServiceName` wskazuje dodatkowo, że żądanie obsługuje inna usługa niż `whoami`.
4. Log Collectora. Atrybut `url.full` w operacji `ReverseProxy` pokazuje adres `http://.../delay/0.5`, czyli punkt końcowy, który sam z siebie odpowiada z opóźnieniem.
5. Dopiero teraz konfiguracja. `kubectl get httproute whoami -n zsr -o yaml` pokazuje filtr `URLRewrite` i `backendRefs` na usługę `httpbin`.

W czasie utrzymywania się awarii p95 przekracza próg `0,5` s, więc alert z zadania D przejdzie w stan `firing` i przyjdzie kolejny list. Po ustaleniu przyczyny należy przywrócić poprawną trasę przez ponowne zastosowanie `whoami.yaml` i potwierdzić powrót p95 do wartości sprzed zmiany. Alert przejdzie wtedy w stan `Resolved`, a do Mailpita przyjdzie list o wygaszeniu.

```bash
kubectl apply -f whoami.yaml
```

Obciążenie należy pozostawić włączone do chwili, gdy p95 wróci do wartości sprzed zmiany: okno `rate` obejmuje minutę, więc spadek nie jest natychmiastowy. Zatrzymanie zadania `obciazenie` przed odczytem usuwa szereg z powodu braku ruchu i uniemożliwia potwierdzenie powrotu do stanu wyjściowego. Zadanie zatrzymuje się na końcu ćwiczenia poleceniem `kubectl delete job obciazenie`.

*Weryfikacja:* należy przedstawić kolejność dowodów: metryka wskazała usługę, log rozdzielił czas Traefika od czasu usługi, ślad wskazał adres docelowy, a manifest potwierdził przyczynę. Po przywróceniu trasy p95 wraca do wartości wyjściowej, a w Mailpicie pojawia się list `[RESOLVED]`. Należy wskazać, dlaczego samo `kubectl get pods` nie wystarczyłoby do znalezienia tej przyczyny — Pody przez cały czas były gotowe, a kod odpowiedzi wynosił 200.

= G. Brak danych, retencja i kardynalność

Trzy tematy, które najczęściej prowadzą do błędnych wniosków.

*Brak danych to nie zero.* Alert na warunek `up == 0` nie zadziała, jeżeli cel zniknie z listy: szereg przestanie być zbierany, więc zapytanie nie zwróci `0`, lecz pusty wynik. Należy to sprawdzić w Prometheusie:

```promql
up{job="traefik"}
```

```promql
up{job="nie-ma-takiego"}
```

```promql
absent(up{job="traefik"})
```

Pierwsze zapytanie zwraca `1`. Drugie nie zwraca nic, bo taki szereg nie istnieje — i to jest właśnie pułapka. Trzecie zwraca `1` tylko wtedy, gdy szereg zniknął; funkcja `absent` służy do wykrywania braku danych. Prometheus oznacza serię jako nieaktualną po pięciu minutach bez nowych próbek, więc informacja o zniknięciu celu dociera z opóźnieniem. Alert o braku danych musi to uwzględniać.

*Retencja to decyzja kosztowa.* W pliku `monitoring-values.yaml` ustawiono `retention: 6h`. Wydłużenie retencji zwiększa rozmiar bazy i zapotrzebowanie na pamięć oraz dysk, a nie poprawia jakości danych. Retencję dobiera się do pytania, na które mają odpowiadać dane: inna wystarcza do diagnozy bieżącego incydentu, a inna do analizy trendów.

*Etykieta to koszt.* Każda kombinacja wartości etykiet tworzy osobny szereg. Etykieta z identyfikatorem użytkownika, numerem zamówienia czy adresem IP potrafi wygenerować miliony szeregów i zatrzymać Prometheusa. Identyfikator należy umieścić w logu albo w śladzie, a nie w etykiecie metryki. Liczbę szeregów widać w metryce `prometheus_tsdb_head_series`:

```promql
prometheus_tsdb_head_series
```

*Weryfikacja:* należy odróżnić pusty wynik od zera, wskazać, dlaczego `up == 0` nie wykrywa zniknięcia celu, oraz podać przykład etykiety, której nie wolno użyć w metryce.

= Diagnostyka monitoringu

- Obiekt `Alertmanager` ma `RECONCILED: False`: należy odczytać komunikat warunku. Najczęstsze przyczyny to odbiorca `null` usunięty z listy `receivers` oraz nieznane pole konfiguracji, na przykład `require_tls` zamiast `smtp_require_tls`.
- Cel Traefika jest `DOWN`: należy sprawdzić `kubectl get servicemonitor -n traefik` oraz port `metrics` w wydaniu Traefika. Zmiana wartości Helm bez sekcji `providers` wyłącza Traefika i psuje trasy z części II.
- Zapytanie zwraca pusty wynik: należy sprawdzić nazwę etykiety. Dla usług Traefika jest to `exported_service`, a dla punktów wejścia `entrypoint`. Błędna nazwa etykiety nie powoduje błędu, tylko pusty wynik.
- Wartości p95 są zawyżone: tak działa `histogram_quantile` przy zbyt szerokich przedziałach. Należy porównać wynik z pomiarem klienta i dobrać przedziały histogramu do rzędu wielkości mierzonego zjawiska.
- Alert nie pojawia się: należy sprawdzić `for`, `evaluationInterval` i `scrapeInterval`. Łączny czas do pierwszego listu wynosi kilka minut i nie jest błędem.
- Brak poczty w Mailpicie: należy sprawdzić `smtp_require_tls: false`, adres `mailpit.monitoring.svc.cluster.local:1025` oraz stan obiektu Alertmanagera.
- Ślady nie docierają do Collectora: należy sprawdzić, czy adres OTLP w `traefik-values.yaml` wskazuje usługę Collectora i czy `kubectl logs` Collectora nie jest pusty.
- Stos nie mieści się w pamięci: należy sprawdzić `kubectl top pods -n monitoring` i w razie potrzeby uruchomić klaster ponownie z większą pamięcią, na przykład `minikube start -p zsr --memory=6144`. Sam stos zajmuje około 1,2 GB.
- Metryki throttlingu procesora: w nowszych wersjach Kubernetes liczniki `container_cpu_cfs_throttled_*` nie są już eksponowane. Do oceny niedoboru procesora służą metryki ciśnienia, na przykład `container_pressure_cpu_waiting_seconds_total`. Zasady alertów oparte na starych nazwach nie zadziałają.
- Zajęty port lokalny przy `port-forward`: należy zamknąć poprzednie przekierowanie albo użyć innego portu.

= Dalsze kroki i źródła

Po ćwiczeniu warto zestawić pomiar klienta z wartością z histogramu i sprawdzić, jak zmienia się p95 po zawężeniu przedziałów. Naturalnym kolejnym krokiem jest trwały magazyn śladów i logów oraz potraktowanie retencji jako pozycji kosztowej.

#link("https://prometheus.io/docs/prometheus/latest/querying/basics/")[PromQL] · #link("https://prometheus.io/docs/prometheus/latest/querying/functions/#histogram_quantile")[histogram_quantile] · #link("https://prometheus.io/docs/prometheus/latest/querying/basics/#staleness")[Nieaktualność szeregu] · #link("https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/")[Reguły alertów] · #link("https://prometheus.io/docs/alerting/latest/configuration/")[Konfiguracja Alertmanagera] · #link("https://prometheus-operator.dev/docs/api-reference/api/")[PrometheusRule i ServiceMonitor] · #link("https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack")[kube-prometheus-stack] · #link("https://doc.traefik.io/traefik/reference/install-configuration/observability/metrics/")[Metryki Traefika] · #link("https://doc.traefik.io/traefik/reference/install-configuration/observability/tracing/")[Śledzenie w Traefiku] · #link("https://doc.traefik.io/traefik/reference/install-configuration/observability/logs-and-accesslogs/")[Log dostępu Traefika] · #link("https://opentelemetry.io/docs/collector/")[OpenTelemetry Collector] · #link("https://opentelemetry.io/docs/specs/otlp/")[Protokół OTLP] · #link("https://gateway-api.sigs.k8s.io/api-types/httproute/")[HTTPRoute i filtry] · #link("https://fortio.org/")[Fortio] · #link("https://mailpit.axllent.org/")[Mailpit]
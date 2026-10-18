#let blue = rgb("#006288")
#let orange = rgb("#bf5327")
#let pale = rgb("#e8f1f5")

#set document(title: "Docker i Kubernetes — od kontenera do wdrożenia", author: "mgr inż. Jakub Woźniak")
#set page(paper: "a4", margin: (top: 2cm, bottom: 2cm, left: 2.15cm, right: 2.15cm), numbering: "1")
#set text(font: "DejaVu Sans", size: 10pt, lang: "pl")
#set par(justify: false, leading: 0.7em, spacing: 0.8em)
#set heading(numbering: none)
#show heading.where(level: 1): it => block(above: 19pt, below: 8pt, sticky: true)[
  #set text(font: "DejaVu Sans", fill: blue, size: 15pt, weight: "bold")
  #it.body
  #v(4pt)
  #line(length: 100%, stroke: 0.7pt + blue)
]
#show heading.where(level: 2): it => block(above: 12pt, below: 5pt, sticky: true)[
  #set text(font: "DejaVu Sans", fill: blue, size: 11.5pt, weight: "bold")
  #it.body
]
#show heading.where(level: 3): it => block(above: 9pt, below: 4pt, sticky: true)[
  #set text(font: "DejaVu Sans", fill: orange, size: 10.5pt, weight: "bold")
  #it.body
]
#show raw: set text(font: "DejaVu Sans Mono", size: 8pt)
#show raw.where(block: true): it => block(width: 100%, inset: 8pt, fill: pale, breakable: true, it)
#show strong: set text(font: "DejaVu Sans", weight: "bold")

#align(center)[
  #v(30pt)
  #text(font: "DejaVu Sans", size: 11pt, fill: blue)[ZARZĄDZANIE SYSTEMAMI ROZPROSZONYMI]
  #v(20pt)
  #text(font: "DejaVu Sans", size: 28pt, weight: "bold", fill: blue)[Docker i Kubernetes]
  #v(7pt)
  #text(font: "DejaVu Sans", size: 16pt)[Od kontenera do wdrożenia]
  #v(14pt)
  #text(size: 10pt)[Obrazy · sieć · wolumeny · wdrażanie · skalowanie]
  #v(22pt)
  mgr inż. Jakub Woźniak · Politechnika Poznańska
]

= Część I. Docker — konteneryzacja aplikacji

Skrypt prowadzi od budowania obrazu do uruchomienia tej samej aplikacji w Kubernetesie. W części I należy przygotować obrazy Flaska oraz uruchomić Redmine z PostgreSQL. Część II wykorzystuje te doświadczenia do pracy z klastrem; jej zadania A–D dotyczą podstaw, a E–G sond zdrowia, konfiguracji i trwałości danych.

= Cel ćwiczenia

Celem ćwiczenia jest poznanie cyklu życia kontenera, zbudowanie i przeniesienie obrazu aplikacji oraz sprawdzenie komunikacji i trwałości danych w systemie złożonym z kilku kontenerów. Zadanie końcowe polega na uruchomieniu Redmine z bazą PostgreSQL i odtworzeniu obu kontenerów bez utraty danych.

Po wykonaniu ćwiczenia należy umieć odróżnić obraz od kontenera, wyjaśnić rolę procesu głównego, opublikować port, odczytać logi, zbudować obraz z wykorzystaniem pamięci podręcznej, połączyć kontenery po nazwie we wspólnej sieci oraz wskazać, gdzie są przechowywane dane aplikacji.

= Przygotowanie

Wymagana jest znajomość podstawowych poleceń powłoki. Na stanowisku musi działać Docker. Należy pobrać #link("https://www.cs.put.poznan.pl/jwozniak/labs/docker-materialy.zip")[docker-materialy.zip] i rozpakować paczkę. Katalog `materialy/docker/starter` zawiera prostą aplikację Flask, plik zależności, szkielet Dockerfile oraz plik `start.sh` do zapisania sposobu uruchomienia bazy i Redmine.

Ćwiczenia zakładają lokalny silnik Docker. Jeżeli silnik działa na maszynie zdalnej, adres `localhost` w przeglądarce wskazuje komputer lokalny; potrzebny jest wówczas adres maszyny zdalnej lub przekierowanie portów. Na stanowisku należy sprawdzić:

```bash
docker version
docker info
docker image ls
```

Jeżeli `docker info` nie wyświetla informacji o serwerze, należy sprawdzić działanie usługi Docker i uprawnienia na stanowisku. Dalsze polecenia Docker wykonuje się w terminalu stanowiska, o ile nie zaznaczono inaczej.

Obraz jest zapisanym wzorcem aplikacji. `docker run` tworzy z niego kontener i uruchamia jego główny proces. Gdy proces się kończy, kontener przechodzi do stanu zatrzymanego. `docker ps` pokazuje kontenery działające, a `docker ps -a` również zatrzymane.

= A. Praca w kontenerze interaktywnym

Kontener uruchamia proces z obrazu i ma własną warstwę zapisywalną. W kontenerach Linux procesy korzystają z jądra gospodarza; nie jest to osobna maszyna wirtualna. Gdy proces główny się zakończy, kontener zatrzyma się, ale pozostanie dostępny przez `docker ps -a`, dopóki nie zostanie usunięty.

Na stanowisku należy uruchomić powłokę z obrazu Ubuntu:

```bash
docker run --rm -it ubuntu:24.04 bash
```

*W kontenerze* należy wykonać `cat /etc/os-release` i `pwd`, a następnie zakończyć powłokę poleceniem `exit`. Opcja `-it` umożliwia pracę przez terminal, a `--rm` usuwa kontener po zakończeniu powłoki. Obraz pozostaje na dysku i można z niego tworzyć następne kontenery.

Następnie na stanowisku należy uruchomić obraz z określoną wersją Pythona:

```bash
docker run -it --name zsr-python python:3.13-slim sh
```

*W kontenerze* należy wykonać:

```sh
python --version
printf 'dane z kontenera\n' > /tmp/proba.txt
cat /tmp/proba.txt
exit
```

Na stanowisku należy sprawdzić `docker ps` oraz `docker ps -a`, po czym ponownie uruchomić *ten sam* kontener:

```bash
docker start -ai zsr-python
```

Po odczytaniu `/tmp/proba.txt` należy zakończyć powłokę. Następnie na stanowisku należy usunąć `zsr-python` poleceniem `docker rm` i utworzyć nowy kontener z obrazu `python:3.13-slim`. Należy sprawdzić, czy plik `/tmp/proba.txt` nadal istnieje.

*Weryfikacja:* plik jest dostępny po ponownym uruchomieniu tego samego kontenera, lecz nie ma go w nowym kontenerze. Należy wskazać różnicę między ponownym uruchomieniem kontenera a utworzeniem nowego z tego samego obrazu.

= B. Własny obraz

W katalogu `starter` znajduje się aplikacja Flask w pliku `app.py`. Nasłuchuje ona na `0.0.0.0:5000`, aby port opublikowany przez Docker mógł kierować do niej ruch. Plik `requirements.txt` określa zależności. Serwer dołączony do Flask służy w tym ćwiczeniu do uruchomienia przykładu, a nie do wdrożenia produkcyjnego.

== Jak działa Dockerfile

Dockerfile opisuje sposób *budowania obrazu*. Instrukcje są wykonywane w podanej kolejności. Poniższy przykład zakłada, że obok Dockerfile znajduje się plik `komunikat.txt` zawierający jedną linię tekstu:

```dockerfile
FROM alpine:3.23
WORKDIR /demo
COPY komunikat.txt .
RUN test -s komunikat.txt
CMD ["cat", "komunikat.txt"]
```

`FROM` wybiera obraz bazowy, od którego rozpoczyna się budowanie. `WORKDIR` ustawia katalog roboczy dla kolejnych instrukcji i procesu uruchamianego w kontenerze; Docker utworzy ten katalog, jeżeli go nie ma. `COPY komunikat.txt .` kopiuje plik z *kontekstu budowania* do `/demo/komunikat.txt`. Kropka po nazwie pliku oznacza tu bieżący katalog w obrazie, czyli katalog ustawiony przez `WORKDIR`.

`RUN` wykonuje polecenie *podczas budowania obrazu*. W przykładzie budowanie zakończy się błędem, jeżeli skopiowany plik jest pusty. Wynik polecenia, w tym utworzone pliki, staje się częścią obrazu. `CMD` określa polecenie uruchamiane dopiero po wykonaniu `docker run`; tutaj proces `cat` wypisze zawartość pliku i zakończy pracę, więc kontener również się zatrzyma. Zapis `CMD` z tablicą argumentów pozwala wskazać program i jego argumenty bez pośrednictwa powłoki. Polecenie podane na końcu `docker run` może zastąpić `CMD`.

Przy `docker build -t przyklad .` kropka oznacza katalog przekazany jako kontekst budowania. `COPY` może pobierać pliki z tego katalogu, lecz nie z dowolnego miejsca na dysku. Każda instrukcja buduje na wyniku poprzednich; Docker może ponownie wykorzystać zapamiętany wynik kroku, jeżeli jego dane wejściowe się nie zmieniły. Zmiana pliku kopiowanego przez `COPY` wymaga ponownego wykonania tego kroku i kolejnych. Dlatego w obrazie aplikacji zależności kopiuje się i instaluje przed skopiowaniem kodu, który może zmieniać się częściej.

W obrazie Flask plik startowy zawiera już `FROM` i `WORKDIR`. `RUN` powinien zainstalować pakiety z `requirements.txt` *w obrazie*, a `CMD` uruchomić proces serwera *w kontenerze*. Instrukcja `EXPOSE`, jeżeli występuje w Dockerfile, opisuje port aplikacji, lecz sama nie udostępnia go na hoście; służy do tego `docker run -p`.

Należy uzupełnić Dockerfile tak, aby osobno skopiować `requirements.txt`, zainstalować zależności, następnie skopiować `app.py` i ustawić polecenie uruchamiające `python app.py`. Zależności należy instalować poleceniem `pip install --no-cache-dir -r requirements.txt`. Opcja `--no-cache-dir` dotyczy pamięci podręcznej `pip`, a nie pamięci podręcznej warstw obrazu Docker.

W katalogu `starter` należy zbudować obraz i uruchomić z niego kontener:

```bash
docker build --progress=plain -t zsr-flask:v1 .
docker run -d --name zsr-flask-v1 -p 5000:5000 zsr-flask:v1
curl --fail http://localhost:5000
docker logs zsr-flask-v1
```

W zapisie `-p 5000:5000` pierwszy port należy do hosta, drugi do kontenera. Należy sprawdzić identyfikator obrazu oraz obraz użyty przez kontener:

```bash
docker image inspect zsr-flask:v1 --format '{{.Id}}'
docker inspect zsr-flask-v1 --format '{{.Image}}'
```

Następnie należy ponownie zbudować `zsr-flask:v1` bez zmiany plików i sprawdzić w logu kroki oznaczone `CACHED`. W `app.py` należy zmienić tekst `wersja 1` na `wersja 2` oraz dodać trasę `GET /health`, która zwraca odpowiedź `ok`. Po zbudowaniu `zsr-flask:v2` należy uruchomić z niego kontener `zsr-flask-v2` na porcie hosta 5001. Trzeba porównać odpowiedzi na portach 5000 i 5001, sprawdzić nową trasę oraz log budowania obu wersji.

*Weryfikacja:* pierwszy kontener zwraca wersję 1, a drugi wersję 2. Adres `http://localhost:5001/health` odpowiada `ok`, natomiast wersja 1 nie zawiera tej trasy. Należy ustalić, dlaczego zmiana `app.py` nie zmieniła działającego kontenera, oraz wskazać, które kroki budowania powtórzono po zmianie kodu. Rozdzielenie kopiowania zależności i kodu umożliwia ponowne użycie warstwy instalującej pakiety.

= C. Przenoszenie obrazu

Obraz można zapisać do archiwum i wczytać na innym stanowisku bez ponownego budowania. Polecenie `docker save` zapisuje *obraz*, a nie stan działającego kontenera. Należy utworzyć archiwum wersji 2:

```bash
docker save zsr-flask:v2 | gzip > zsr-flask-v2.tar.gz
ls -lh zsr-flask-v2.tar.gz
```

Do sprawdzenia odczytu na tym samym stanowisku należy zatrzymać i usunąć kontener używający `zsr-flask:v2`, a następnie usunąć jego lokalny znacznik. Po wykonaniu `docker load` znacznik powinien pojawić się ponownie:

```bash
docker stop zsr-flask-v2
docker rm zsr-flask-v2
docker image rm zsr-flask:v2
docker load -i zsr-flask-v2.tar.gz
docker image ls zsr-flask
```

Należy ponownie uruchomić wczytany obraz na porcie hosta 5001 i sprawdzić odpowiedź HTTP. Archiwum obrazu nie zawiera danych zapisanych w wolumenach kontenerów.

*Weryfikacja:* `docker load` przywraca nazwę `zsr-flask:v2`, a nowy kontener odpowiada tekstem wersji 2. Należy wyjaśnić różnicę między archiwum obrazu a kopią danych aplikacji.

= D. Wolumeny

Pliki zapisane w warstwie zapisywalnej kontenera znikają wraz z jego usunięciem. Wolumen jest zarządzany przez Docker osobno od kontenera. Aby to sprawdzić, należy utworzyć wolumen i zapisać w nim plik z kontenera jednorazowego:

```bash
docker volume create zsr-proba
docker run --rm -v zsr-proba:/data alpine:3.23 \
  sh -c 'echo 42 > /data/id'
docker run --rm -v zsr-proba:/data alpine:3.23 cat /data/id
```

Pierwszy kontener został usunięty, lecz drugi odczytuje `42`. Należy powtórzyć doświadczenie bez montowania wolumenu i sprawdzić, czy nowy kontener odczyta plik utworzony przez poprzedni. Następnie należy obejrzeć `docker volume inspect zsr-proba` i wskazać, która część zapisu `-v zsr-proba:/data` jest nazwą wolumenu, a która ścieżką w kontenerze.

*Weryfikacja:* zapis na wolumenie jest widoczny w nowym kontenerze, a plik utworzony wyłącznie w warstwie poprzedniego kontenera nie jest dostępny. Wolumen lokalny nie jest kopią zapasową ani repliką danych.

#pagebreak()

= E. Sieć i PostgreSQL

Sieć typu bridge utworzona przez użytkownika pozwala kontenerom rozpoznawać się po nazwach. Redmine i PostgreSQL będą działać w tej samej sieci. Należy utworzyć sieć oraz osobny wolumen bazy:

```bash
docker network create zsr-net
docker volume create zsr-pgdata
```

Na stanowisku należy uruchomić bazę danych:

```bash
docker run -d --name zsr-db --network zsr-net \
  -e POSTGRES_USER=redmine \
  -e POSTGRES_DB=redmine \
  -e POSTGRES_PASSWORD=lab1234 \
  -v zsr-pgdata:/var/lib/postgresql/data \
  postgres:17.11
```

Port bazy nie jest publikowany na hoście. Hasło jest przykładowe i służy wyłącznie do ćwiczenia na lokalnym stanowisku. Wersja 17 obrazu PostgreSQL przechowuje dane pod `/var/lib/postgresql/data`; w wersji 18 ścieżka montowania jest inna. Zmienne `POSTGRES_*` inicjalizują bazę przy pierwszym użyciu pustego wolumenu. Nie zmieniają hasła w bazie, która już istnieje.

Stan należy sprawdzić poleceniami `docker ps -a`, `docker logs zsr-db` i `docker exec zsr-db pg_isready -U redmine -d redmine`. Gdy baza będzie gotowa, należy uruchomić osobny kontener klienta:

```bash
docker run --rm -it --network zsr-net \
  -e PGPASSWORD=lab1234 postgres:17.11 \
  psql -h zsr-db -U redmine -d redmine
```

*W kliencie `psql`* należy sprawdzić bieżącą bazę i użytkownika, a następnie utworzyć tabelę `zsr_proba`, zapisać w niej jeden wiersz i odczytać go. Po zakończeniu połączenia poleceniem `\q` należy zatrzymać i usunąć `zsr-db`, utworzyć go ponownie z tym samym wolumenem i ponownie odczytać wiersz z osobnego kontenera klienta.

*Weryfikacja:* klient łączy się przez nazwę `zsr-db`, mimo że port bazy nie jest wystawiony na hoście. Wiersz pozostaje po usunięciu i odtworzeniu kontenera bazy. Należy wyjaśnić, dlaczego adres `localhost` w kontenerze klienta nie wskazuje bazy.

= F. Redmine z bazą PostgreSQL

Należy uruchomić aplikację Redmine z obrazu `redmine:6.1.5` jako osobny kontener `zsr-redmine`. Konfigurację połączenia z PostgreSQL należy ustalić na podstawie #link("https://hub.docker.com/_/redmine")[dokumentacji obrazu Redmine]. Przydatne są zmienne `REDMINE_DB_POSTGRES`, `REDMINE_DB_USERNAME`, `REDMINE_DB_PASSWORD` i `REDMINE_DB_DATABASE`. Jeżeli nie zostanie wskazany serwer bazy, obraz może użyć SQLite; w tym zadaniu Redmine ma korzystać z kontenera `zsr-db`.

Należy spełnić następujące wymagania:

1. Oba kontenery znajdują się w sieci `zsr-net`, a Redmine łączy się z bazą po nazwie `zsr-db`.
2. Redmine jest dostępny na porcie hosta `3000`. Port PostgreSQL nie jest publikowany na hoście.
3. Baza korzysta z wolumenu `zsr-pgdata`. Pliki przesłane do Redmine mają osobny nazwany wolumen pod `/usr/src/redmine/files`.
4. Konfiguracja Redmine zawiera stałą wartość `SECRET_KEY_BASE`, zachowaną również po odtworzeniu kontenera.

Należy zapisać w `start.sh` sprawdzone polecenie uruchomienia PostgreSQL z poprzedniego zadania oraz polecenie uruchomienia Redmine. Skrypt powinien czekać na gotowość bazy przed uruchomieniem aplikacji. Można wykorzystać poniższą pętlę:

```bash
until docker exec zsr-db pg_isready -U redmine -d redmine; do
  sleep 2
done
```

Po uruchomieniu bazy należy wykonać polecenie uruchamiające Redmine. Inicjalizacja aplikacji i migracje bazy mogą wymagać oczekiwania. Stan należy sprawdzać przez `docker ps -a`, `docker logs zsr-redmine` oraz `docker logs zsr-db`. Aplikacja powinna być dostępna pod `http://localhost:3000`; jeżeli Docker działa na innej maszynie, należy użyć jej adresu podanego przez prowadzącego.

Po uruchomieniu należy zalogować się na konto `admin` z hasłem `admin` i wykonać wymaganą zmianę hasła. Następnie należy utworzyć projekt i zgłoszenie z małym plikiem tekstowym jako załącznikiem. Tytuł projektu i treść pliku posłużą do sprawdzenia trwałości danych.

*Próba trwałości:*

1. Należy zatrzymać oba kontenery przez `docker stop`, a następnie usunąć je przez `docker rm`, zachowując wolumeny i sieć.
2. Należy sprawdzić, czy `docker volume ls` nadal pokazuje `zsr-pgdata` i `zsr-uploads`.
3. Należy uruchomić `bash start.sh` z zapisanymi poleceniami. Skrypt powinien używać tych samych nazw wolumenów, bazy, użytkownika, hasła i klucza Redmine oraz czekać na gotowość bazy przed uruchomieniem aplikacji.
4. Po ponownym otwarciu aplikacji należy potwierdzić obecność projektu i zgłoszenia, pobrać załącznik i porównać jego treść z oryginałem.

Jeśli zapisane polecenia odtwarzają oba kontenery, a dane nadal są dostępne, zadanie jest wykonane. Samo `docker restart` nie sprawdza trwałości po usunięciu kontenera. Baza przechowuje projekt i dane zgłoszenia, a wolumen Redmine przechowuje pliki załączników.

= Odbiór i zakończenie

Do odbioru należy przedstawić Dockerfile, archiwum obrazu, `start.sh`, działającą aplikację i dane po odtworzeniu. Należy wyjaśnić, skąd Redmine zna adres bazy, do czego służą dwa wolumeny oraz dlaczego archiwum obrazu nie zawiera projektu utworzonego w Redmine. Pliki źródłowe i skrypt uruchomieniowy należy zachować w repozytorium lub innym miejscu przechowywania pracy.

Po demonstracji należy zatrzymać kontenery. Usunięcie wolumenów kasuje dane ćwiczenia, dlatego należy je wykonać dopiero po zakończeniu pracy z danymi. Na współdzielonym stanowisku nie należy uruchamiać `docker system prune`.

#pagebreak()

= Diagnostyka problemów

- `docker ps -a` pokazuje kontener `Exited`: należy odczytać `docker logs NAZWA`; proces główny mógł zakończyć się błędem.
- Port hosta jest zajęty: należy sprawdzić `docker ps`, zatrzymać wcześniejszy kontener albo wybrać wolny port hosta.
- Redmine nie łączy się z bazą: należy sprawdzić `docker network inspect zsr-net`, nazwę `zsr-db`, zmienne `REDMINE_DB_*` i gotowość PostgreSQL.
- Dane zniknęły po odtworzeniu: należy sprawdzić `docker inspect zsr-db` i `docker inspect zsr-redmine`, zwłaszcza pole `Mounts`, oraz nazwy wolumenów w `start.sh`.
- Zmienione hasło PostgreSQL nie działa: zmienne `POSTGRES_*` konfigurują bazę przy inicjalizacji pustego katalogu danych. Ponowne użycie wolumenu zachowuje poprzednie hasło.

= Pytania końcowe i źródła

1. Dlaczego plik w `/tmp` przetrwał ponowne uruchomienie kontenera, ale zniknął po utworzeniu nowego?
2. Które elementy zawiera archiwum utworzone przez `docker save`, a których w nim nie ma?
3. Dlaczego klient `psql` łączy się z nazwą `zsr-db`, a nie z `localhost`?
4. Co pozostałoby po usunięciu kontenerów, gdyby zabrakło wolumenu załączników?

#link("https://docs.docker.com/get-started/docker-concepts/building-images/writing-a-dockerfile/")[Dockerfile] · #link("https://docs.docker.com/reference/cli/docker/image/save/")[Zapis obrazu] · #link("https://docs.docker.com/reference/cli/docker/image/load/")[Odczyt obrazu] · #link("https://docs.docker.com/engine/network/drivers/bridge/")[Sieć bridge] · #link("https://docs.docker.com/engine/storage/volumes/")[Wolumeny] · #link("https://hub.docker.com/_/postgres")[Obraz PostgreSQL] · #link("https://hub.docker.com/_/redmine")[Obraz Redmine]

#include "chapters/kubernetes.typ"

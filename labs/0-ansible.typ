#let blue = rgb("#006288")
#let orange = rgb("#bf5327")
#let pale = rgb("#e8f1f5")

#set document(title: "Ansible — automatyzacja konfiguracji serwerów", author: "mgr inż. Jakub Woźniak")
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
  #text(font: "DejaVu Sans", size: 28pt, weight: "bold", fill: blue)[Ansible]
  #v(7pt)
  #text(font: "DejaVu Sans", size: 16pt)[Automatyzacja konfiguracji serwerów]
  #v(14pt)
  #text(size: 10pt)[Inventory · playbooki · szablony · handlery · idempotencja]
  #v(22pt)
  mgr inż. Jakub Woźniak · Politechnika Poznańska
]

= Cel i plan pracy

Skonfigurujesz dwa serwery Nginx z jednej maszyny sterującej. Odczytasz fakty o systemach, użyjesz ich w warunku i szablonie, a następnie sprawdzisz idempotencję playbooka i jego zachowanie po awarii. Zadania A–F prowadzą przez kolejne zastosowania Ansible.

Po ćwiczeniu powinieneś umieć odróżnić `ok`, `changed`, `skipped`, `failed` i `unreachable`, zastosować fakty oraz zmienne grupy i hostów, użyć szablonu Jinja2 oraz uruchamiać handler tylko wtedy, gdy zmieniła się konfiguracja.

= Przygotowanie środowiska

Pobierz paczkę #link("https://www.cs.put.poznan.pl/jwozniak/labs/ansible-materialy.zip")[ansible-materialy.zip] i rozpakuj ją na stanowisku. Vagrant tworzy trzy maszyny Debian 12: `control` (`192.168.56.10`), `node-1` (`192.168.56.11`) i `node-2` (`192.168.56.12`). Adresy należą do prywatnej sieci VM, a nie do publicznego adresu stanowiska. VM używają też NAT do pobierania pakietów.

Na stanowisku, w katalogu `materialy/ansible`, wykonaj:

```bash
vagrant --version
VBoxManage --version
bash prepare.sh
vagrant up
vagrant status
bash trust-hosts.sh
vagrant ssh control
sudo -iu student
```

`prepare.sh` tworzy klucz SSH dla ćwiczenia. `trust-hosts.sh` zapisuje klucze hostów na `control`. Nie wyłączaj sprawdzania tożsamości hostów i nie udostępniaj katalogów `.lab` ani `.vagrant`.

Na `control`, jako `student`, sprawdź połączenia i utwórz katalog projektu:

```bash
ansible --version
ssh student@192.168.56.11 hostname
ssh student@192.168.56.12 hostname
mkdir -p zsr-ansible/templates zsr-ansible/host_vars zsr-ansible/group_vars
cd zsr-ansible
```

Oczekiwane nazwy to `node-1` i `node-2`. Jeśli SSH nie działa, najpierw napraw połączenie; Ansible używa tego samego transportu.

= Inventory i pierwszy playbook

Utwórz plik `inventory.ini`:

```ini
[web]
node-1 ansible_host=192.168.56.11
node-2 ansible_host=192.168.56.12

[web:vars]
ansible_user=student
ansible_python_interpreter=/usr/bin/python3
```

Sprawdź grupę i dostępność hostów:

```bash
ansible-inventory -i inventory.ini --graph
ansible web -i inventory.ini -m ansible.builtin.ping
```

Moduł `ping` sprawdza wykonanie modułu na hoście przez SSH; nie wysyła pakietu ICMP. Nazwy `node-1` i `node-2` są aliasami z inventory.

== Odczyt faktów o hostach

Moduł `ansible.builtin.setup` odczytuje informacje o zarządzanym hoście. Na `control` uruchom go dla obu węzłów, ograniczając wyświetlane dane:

```bash
ansible web -i inventory.ini -m ansible.builtin.setup -a 'filter=ansible_hostname'
ansible web -i inventory.ini -m ansible.builtin.setup -a 'filter=ansible_distribution*'
```

Porównaj `ansible_hostname` na obu hostach oraz nazwę i wersję dystrybucji. W playbooku te dane odczytuje się jako `ansible_facts['hostname']`, `ansible_facts['distribution']` i `ansible_facts['distribution_version']`. `inventory_hostname` pochodzi z inventory, natomiast `ansible_facts['hostname']` jest odczytywany z systemu. W tym środowisku wartości nazw powinny być takie same, ale po zmianie aliasu w inventory mogą się różnić.

Polecenie doraźne `setup` służy tutaj do obejrzenia faktów; nie zapisuje ich na stałe na potrzeby kolejnego polecenia. Playbook zbiera je ponownie na początku uruchomienia. W `web.yml` ustaw to jawnie przez `gather_facts: true` pod `hosts: web`.

Utwórz `web.yml`:

```yaml
---
- name: Przygotuj serwery WWW
  hosts: web
  gather_facts: true
  become: true
  tasks:
    - name: Zainstaluj nginx
      ansible.builtin.apt:
        name: nginx
        state: present
        update_cache: true
        cache_valid_time: 3600

    - name: Umieść stronę laboratoryjną
      ansible.builtin.copy:
        content: "Serwer przygotowany przez Ansible\n"
        dest: /var/www/html/index.html
        owner: root
        group: root
        mode: '0644'

    - name: Uruchom usługę i włącz start po restarcie VM
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: true
```

Uruchom playbook dwa razy i porównaj podsumowania. Drugie uruchomienie powinno dać `changed=0` na obu hostach.

```bash
ansible-playbook -i inventory.ini web.yml --syntax-check
ansible-playbook -i inventory.ini web.yml
curl --fail http://192.168.56.11
curl --fail http://192.168.56.12
ansible-playbook -i inventory.ini web.yml
```

Usuń teraz stronę na jednym hoście i uruchom playbook ponownie. Które zadanie odtworzyło plik? Ile zmian zgłosił każdy host?

```bash
ssh student@192.168.56.11 'sudo rm /var/www/html/index.html'
ansible-playbook -i inventory.ini web.yml
```

= Zadania samodzielne

== A. Fakty, warunek i dwie treści

Zastąp zadanie `copy` modułem `ansible.builtin.template`. Utwórz `templates/index.html.j2` i pliki `host_vars/node-1.yml`, `host_vars/node-2.yml`. Ustaw zmienną `environment_name`: dla `node-1` środowisko testowe, dla `node-2` demonstracyjne. Strona ma pokazywać alias z inventory, `environment_name` oraz nazwę i wersję dystrybucji odczytaną z faktów. Użyj w szablonie `{{ ansible_facts['distribution'] }}` i `{{ ansible_facts['distribution_version'] }}`.

Dodaj w szablonie instrukcję Jinja2 `{% if ... %}` zależną od `ansible_facts['hostname']`: na `node-1` wyświetl napis „Węzeł testowy”, a na `node-2` „Węzeł demonstracyjny”. Następnie dodaj do `web.yml` osobne zadanie `ansible.builtin.copy`, które tworzy plik `/var/www/html/node-info.txt` z tekstem „Węzeł testowy” *tylko* na `node-1`. W tym zadaniu zastosuj `when: ansible_facts['hostname'] == 'node-1'`. Wartość `when` jest wyrażeniem logicznym — nie otaczaj go `{{ ... }}`. Zachowaj właściciela `root` i tryb `0644` dla obu plików.

W szablonie `{{ ... }}` wstawia wartość, a `{% if ... %}` wybiera fragment tekstu. Przykładowa konstrukcja:

```jinja2
{% if ansible_facts['hostname'] == 'node-1' %}
Węzeł testowy
{% else %}
Węzeł demonstracyjny
{% endif %}
```

*Sprawdzenie:* oba serwery zwracają HTTP 200 i różne treści. Strony pokazują właściwą dystrybucję i wersję systemu. `node-info.txt` jest dostępny na `node-1`, a na `node-2` zwraca HTTP 404; zadanie z `when` jest tam oznaczone jako `skipped`. Kolejne uruchomienie playbooka daje `changed=0`. Nie pozostawiaj jednocześnie zadań `copy` i `template` zapisujących `index.html`.

```bash
curl --fail http://192.168.56.11/node-info.txt
curl --silent --output /dev/null --write-out '%{http_code}\n' http://192.168.56.12/node-info.txt
```

== B. Port 8081 i handler

Dodaj w `group_vars/web.yml` zmienną `web_port: 8081`. Utwórz `templates/zsr.conf.j2` i wdrażaj go jako `/etc/nginx/conf.d/zsr.conf`. Zachowaj działanie portu 80. Minimalny szablon:

```nginx
server {
    listen {{ web_port }};
    server_name _;
    root /var/www/html;
    location / {
        try_files $uri $uri/ =404;
    }
}
```

Zadanie zapisujące konfigurację ma powiadamiać handler `Przeładuj nginx` ze stanem `reloaded`. Po zapisaniu pliku dodaj zadanie uruchamiające `nginx -t` z `changed_when: false`, aby błędna konfiguracja przerwała playbook przed handlerem. Nie używaj `ignore_errors` ani `--force-handlers`.

*Sprawdzenie:* oba hosty odpowiadają na portach 80 i 8081. Handler uruchamia się po zmianie konfiguracji, lecz nie przy kolejnym identycznym przebiegu. Czy zmiana samego HTML wymaga przeładowania Nginx?

== C. Przewidywanie i ograniczenie zmian

Zmień `environment_name` na obu hostach. Uruchom:

```bash
ansible-playbook -i inventory.ini web.yml --check --diff
curl --fail http://192.168.56.11
curl --fail http://192.168.56.12
ansible-playbook -i inventory.ini web.yml --limit node-1
```

Po `--check` strony powinny mieć poprzednią treść. Po `--limit node-1` powinna zmienić się tylko strona pierwszego hosta. Tryb `--check` pokazuje przewidywane zmiany, ale nie potwierdza, że usługa uruchomi się poprawnie.

== D. Automatyczna kontrola HTTP

Dodaj do playbooka kontrolę odpowiedzi HTTP po wdrożeniu. Przed nią wykonaj `ansible.builtin.meta: flush_handlers`, aby nowa konfiguracja portu została przeładowana. Użyj `ansible.builtin.uri` z `delegate_to: localhost`, `become: false` i `return_content: true`. Adres zbuduj z `hostvars[inventory_hostname].ansible_host` i `web_port`. Wynik zapisz przez `register`, a modułem `ansible.builtin.assert` sprawdź kod 200 oraz obecność aliasu i nazwy środowiska w treści.

*Sprawdzenie:* poprawna konfiguracja przechodzi kontrolę. Gdy celowo zmienisz oczekiwany tekst w asercji, playbook kończy się błędem. Po przywróceniu warunku kolejny przebieg daje `changed=0`.

== E. Samonaprawa usługi

Zatrzymaj Nginx tylko na `node-2`, po czym uruchom playbook dwukrotnie:

```bash
ssh student@192.168.56.12 'sudo systemctl stop nginx'
curl --fail http://192.168.56.12
ansible-playbook -i inventory.ini web.yml
curl --fail http://192.168.56.12
ansible-playbook -i inventory.ini web.yml
```

Pierwszy `curl` powinien się nie powieść. Wskaż zadanie, które naprawiło stan usługi, oraz wyjaśnij, dlaczego samo `nginx -t` nie wykryłoby zatrzymanego procesu. Drugie wykonanie playbooka powinno mieć `changed=0`.

== F. Niedostępny węzeł

Na stanowisku, w katalogu `materialy/ansible`, wykonaj `vagrant halt node-2`. Na `control` uruchom playbook najpierw dla grupy `web`, a potem z `--limit node-1`. Sprawdź HTTP na `node-1`. Przywróć VM poleceniem `vagrant up node-2` na stanowisku i ponów playbook dla całej grupy.

*Sprawdzenie:* podczas awarii `node-2` ma status `unreachable`, a `node-1` pozostaje zarządzany. Po przywróceniu oba hosty odpowiadają. Wyjaśnij różnicę między `unreachable` i `failed`.

= Zachowanie pracy

Projekt powstaje na VM `control`, a stanowisko może zostać wyczyszczone. Przed końcem zajęć, na stanowisku w katalogu `materialy/ansible`, pobierz archiwum:

```bash
vagrant ssh control -c \
  'sudo -u student tar -C /home/student \
    -czf /tmp/zsr-ansible-backup.tar.gz zsr-ansible &&
   sudo chmod 0644 /tmp/zsr-ansible-backup.tar.gz'
vagrant ssh-config control > ssh-config
scp -F ssh-config control:/tmp/zsr-ansible-backup.tar.gz ./zsr-ansible-backup.tar.gz
tar -tzf zsr-ansible-backup.tar.gz
```

Zapisz archiwum w swoim repozytorium lub chmurze i sprawdź, czy da się je odczytać. Nie dołączaj kluczy SSH ani katalogu `.vagrant`. Po zapisaniu pracy zatrzymaj maszyny przez `vagrant halt`.

= Pytania końcowe

1. Co zmieni dodanie trzeciego hosta do grupy `web`?
2. Które zadania potrzebują `become: true` i dlaczego?
3. Dlaczego drugi przebieg powinien mieć `changed=0`?
4. Co odróżnia kontrolę składni Nginx od próby HTTP wykonanej z `control`?
5. Skąd pochodzą `inventory_hostname` i `ansible_facts['hostname']`? Co oznacza `skipped` przy zadaniu z `when`?

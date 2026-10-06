## Cel zajęć

Zapoznanie z podejściem *Configuration as Code* na przykładzie Ansible. Ćwiczenie obejmuje opisanie docelowej konfiguracji dwóch serwerów w plikach tekstowych, jej zdalne wdrożenie oraz weryfikację, czy kolejne uruchomienie zachowuje idempotencję.

## Wprowadzenie

Ansible automatyzuje konfigurację systemów. Operator zapisuje oczekiwany stan w playbooku YAML, a Ansible łączy się przez SSH z maszynami wskazanymi w inventory i wykonuje zadania przy użyciu modułów. Na zarządzanych maszynach nie jest potrzebny osobny agent Ansible.

Playbook opisuje rezultat do osiągnięcia. Na przykład zadanie `ansible.builtin.apt` z `state: present` zapewnia, że pakiet jest zainstalowany. Jeśli pakiet już istnieje, następne wykonanie nie powinno wprowadzić zmiany. Tę właściwość nazywamy idempotencją. Ułatwia ona bezpieczne powtarzanie wdrożeń i odtwarzanie konfiguracji po awarii.

Inventory przypisuje hostom nazwy, adresy i grupy. Playbook wybiera grupę hostów i kolejno opisuje zadania. Zmienne umożliwiają dostosowanie konfiguracji, a szablony Jinja2 pozwalają wygenerować różne pliki dla poszczególnych serwerów. Handler uruchamia się w odpowiedzi na zmianę, która go powiadomiła, na przykład po zmianie konfiguracji wymagającej przeładowania usługi.

Moduł `ansible.builtin.ping` sprawdza, czy Ansible może wykonać moduł na zarządzanym hoście. Nie jest to test ICMP.

### Efekty uczenia się

Po wykonaniu ćwiczeń student potrafi:

- zbudować inventory i sprawdzić połączenie SSH z hostami;
- napisać playbook używający modułów Ansible oraz uprawnień `become`;
- rozróżnić wyniki `ok`, `changed`, `failed` i `unreachable`;
- zastosować zmienne grup i hostów oraz szablon Jinja2;
- powiązać zmianę konfiguracji z handlerem i zweryfikować idempotencję;
- ograniczyć wykonanie do wybranej grupy lub hosta oraz ocenić wynik `--check --diff`.

## Wymagania i przygotowanie

Wymagane są podstawy terminala, edycji plików i połączeń SSH. Przed rozpoczęciem należy [pobrać paczkę materiałów środowiska (ZIP)](https://www.cs.put.poznan.pl/jwozniak/labs/ansible-materialy.zip), rozpakować ją w katalogu roboczym i przejść do `materialy/ansible`. Projekt Vagrant tworzy trzy maszyny Debian 12:

| Maszyna | Prywatny adres | Rola |
|---|---|---|
| `control` | `192.168.56.10` | Węzeł sterujący Ansible |
| `node-1` | `192.168.56.11` | Pierwszy zarządzany serwer |
| `node-2` | `192.168.56.12` | Drugi zarządzany serwer |

VM korzystają z NAT do pobierania pakietów oraz z sieci host-only do komunikacji między sobą. Adresy w tabeli należą do VM; nazwa stanowiska, np. `lab-net-1.cs.put.poznan.pl`, wskazuje host.

Vagrant przygotowuje konto `student`, Python i SSH na maszynach. Na `control` instaluje również Ansible oraz edytor Nano. Konto `student` ma uprawnienia sudo wewnątrz maszyn wirtualnych. Nginx jest instalowany dopiero przez playbook. Skrypt `prepare.sh` generuje odrębny klucz SSH dla środowiska. Katalogi `.lab` i `.vagrant` zawierają pliki środowiska i klucze; nie należy ich udostępniać.

**Na stanowisku laboratoryjnym, w katalogu `materialy/ansible`, należy wykonać:**

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

Skrypt `trust-hosts.sh` odczytuje klucze hostów za pośrednictwem Vagranta i zapisuje je na maszynie `control`. Pozwala to klientowi SSH weryfikować tożsamość węzłów. Polecenie `sudo -iu student` otwiera powłokę konta, na którym wykonywane są ćwiczenia.

**Następnie na maszynie `control`, jako użytkownik `student`, należy wykonać:**

```bash
ansible --version
ssh student@192.168.56.11 hostname
ssh student@192.168.56.12 hostname
mkdir -p zsr-ansible/templates zsr-ansible/host_vars
cd zsr-ansible
```

Jeśli SSH zgłasza zmianę klucza hosta, należy sprawdzić, czy maszyna została odtworzona, a następnie ponownie uruchomić `bash trust-hosts.sh` na stanowisku. Weryfikacji klucza SSH nie należy wyłączać. W przypadku błędu SSH należy najpierw przywrócić działanie tego połączenia; Ansible korzysta z tego samego transportu.

**Kontrola połączenia:** polecenia `hostname` zwracają nazwy `node-1` i `node-2`.

## Inventory i dostęp do zarządzanych hostów

W katalogu projektu należy utworzyć plik `inventory.ini`:

```ini
[web]
node-1 ansible_host=192.168.56.11
node-2 ansible_host=192.168.56.12

[web:vars]
ansible_user=student
ansible_python_interpreter=/usr/bin/python3
```

Następnie należy wyświetlić grupy inventory i sprawdzić połączenie Ansible z oboma hostami:

```bash
ansible-inventory -i inventory.ini --graph
ansible web -i inventory.ini -m ansible.builtin.ping
```

Wartość `node-1` jest aliasem zdefiniowanym w inventory. `ansible_host` określa adres, z którym Ansible nawiązuje połączenie. Publiczna nazwa DNS stanowiska laboratoryjnego wskazywałaby host, a nie prywatną maszynę `node-1`.

## Playbook konfigurujący serwery WWW

W katalogu `zsr-ansible` należy utworzyć plik `web.yml` z poniższym playbookiem. Wcięcia w YAML należy zapisywać spacjami. Playbook korzysta z modułu `apt`, ponieważ zarządzane maszyny działają pod Debianem:

```yaml
---
- name: Przygotuj serwery WWW
  hosts: web
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

W pierwszej kolejności należy sprawdzić składnię. Następnie należy uruchomić playbook, zweryfikować odpowiedzi HTTP obu serwerów i ponownie uruchomić playbook:

```bash
ansible-playbook -i inventory.ini web.yml --syntax-check
ansible-playbook -i inventory.ini web.yml
curl --fail http://192.168.56.11
curl --fail http://192.168.56.12
ansible-playbook -i inventory.ini web.yml
```

`hosts: web` wybiera grupę hostów. `become: true` podnosi uprawnienia na zarządzanych maszynach. `state: present` zapewnia obecność pakietu bez wymuszania aktualizacji przy każdym wykonaniu. `enabled: true` włącza usługę podczas startu systemu.

Należy porównać podsumowanie pierwszego i drugiego uruchomienia. Przy drugim przebiegu oba hosty powinny raportować `changed=0`. Playbook nadal wykonuje kontrolę stanu; brak zmian oznacza, że konfiguracja odpowiada deklarowanemu rezultatowi.

```{=typst}
#pagebreak()
```

### Odtworzenie zmienionego pliku

Na maszynie `control` należy usunąć stronę zarządzaną przez playbook z pierwszego hosta, a następnie ponownie uruchomić playbook:

```bash
ssh student@192.168.56.11 'sudo rm /var/www/html/index.html'
ansible-playbook -i inventory.ini web.yml
```

Po wykonaniu playbooka należy sprawdzić, które zadanie odtworzyło plik i jak zmieniło się podsumowanie hostów. Oczekiwany rezultat to jedna zmiana na `node-1` i brak zmian na `node-2`.

## Zadania

### A. Szablon i konfiguracja hostów

Należy zastąpić stałą treść strony szablonem `templates/index.html.j2`. Strona ma wyświetlać alias hosta oraz jego przeznaczenie: `node-1` obsługuje środowisko testowe, a `node-2` środowisko demonstracyjne. Przeznaczenie każdego hosta należy zdefiniować osobno w `host_vars/node-1.yml` i `host_vars/node-2.yml`.

Do obu hostów należy zastosować ten sam playbook i szablon. Nazwy plików `host_vars` muszą odpowiadać aliasom z inventory. Szablon może korzystać ze zmiennej wbudowanej `inventory_hostname` oraz własnej zmiennej `environment_name`; plik docelowy należy wdrożyć modułem `ansible.builtin.template`.

**Kryteria weryfikacji:** oba serwery zwracają HTTP 200, strony pokazują różne środowiska, a ponowne wykonanie playbooka nie wprowadza zmian.

### B. Konfiguracja Nginx i handler

Należy skonfigurować dodatkowy serwer Nginx na porcie `8081`, zachowując działanie portu 80. Plik `.conf` należy umieścić w `/etc/nginx/conf.d/`. Minimalny blok serwera ma następującą postać:

```nginx
server {
    listen 8081;
    server_name _;
    root /var/www/html;
    location / {
        try_files $uri $uri/ =404;
    }
}
```

Port `web_port` należy zdefiniować jako zmienną grupy w `group_vars/web.yml`, a szablon zapisać jako `templates/zsr.conf.j2`. Jeśli wymagane katalogi nie istnieją, należy je utworzyć.

Zmiana pliku konfiguracyjnego ma powiadamiać handler przeładowujący usługę. Następnie należy dodać zadanie `nginx -t`, które sprawdza konfigurację po wdrożeniu pliku i przed zadaniem uruchamiającym usługę. Walidacja nie zmienia stanu systemu, dlatego zadanie powinno zawierać `changed_when: false`. Błąd walidacji ma przerwać playbook przed wykonaniem handlera. Nie należy stosować `ignore_errors` ani `--force-handlers`.

**Wskazówka:** zadanie zapisujące konfigurację używa `notify: Przeładuj nginx`. Handler o tej nazwie znajduje się w sekcji `handlers` na tym samym poziomie wcięcia co `tasks` i korzysta z `ansible.builtin.service` ze stanem `reloaded`. Wielokrotne powiadomienie tego samego handlera w ramach jednego przebiegu powoduje jedno jego wykonanie.

Na maszynie `control` należy sprawdzić adresy `http://192.168.56.11:8081` i `http://192.168.56.12:8081`. Po potwierdzeniu działania portu 80 należy ponownie uruchomić playbook bez zmian.

**Kryteria weryfikacji:** port 8081 działa na obu hostach; handler uruchamia się po zmianie konfiguracji, a nie przy kolejnym przebiegu. Czy zmiana HTML wymaga przeładowania Nginx?

### C. Ograniczenie zakresu zmian

W plikach `host_vars` należy zmienić przeznaczenie obu hostów. Następnie należy uruchomić playbook w trybie sprawdzającym:

```bash
ansible-playbook -i inventory.ini web.yml --check --diff
curl --fail http://192.168.56.11
curl --fail http://192.168.56.12
ansible-playbook -i inventory.ini web.yml --limit node-1
```

Po wykonaniu `--check` strony powinny zachować poprzednią treść. Uruchomienie z `--limit node-1` powinno zmienić tylko stronę `node-1`, mimo że zmieniono konfigurację obu hostów. Na koniec należy ponownie sprawdzić obie strony i ustalić, czy zmiana HTML uruchomiła handler.

`--check` nie symuluje pełnego działania systemu. Wynik zależy od obsługi tego trybu przez użyte moduły i istniejącego stanu hosta; powodzenie polecenia nie gwarantuje poprawnego uruchomienia usługi.

## Weryfikacja rezultatów

Końcowa weryfikacja obejmuje działające strony na obu hostach, zmienne hostów, konfigurację dodatkowego portu oraz podsumowania dwóch kolejnych uruchomień playbooka.

Pytania kontrolne:

1. Jak zmieni się zakres zarządzania po dodaniu kolejnego hosta do grupy `web`?
2. Które zadania wymagają podniesienia uprawnień i dlaczego?
3. Który opis konfiguracji jest źródłem stanu docelowego po ręcznej zmianie na serwerze?

## Zachowanie pracy i zakończenie

Pliki projektu powstają na maszynie `control`. Przed zakończeniem należy przenieść katalog `zsr-ansible` na stanowisko laboratoryjne, a następnie zapisać go w repozytorium lub własnej chmurze plikowej.

Należy wrócić do terminala stanowiska: otworzyć inne okno terminala albo wyjść z powłoki `student` i z maszyny wirtualnej poleceniami `exit`. Następnie w katalogu `materialy/ansible` należy utworzyć archiwum projektu, pobrać je i sprawdzić jego zawartość:

```bash
vagrant ssh control -c \
  'sudo -u student tar -C /home/student \
    -czf /tmp/zsr-ansible-backup.tar.gz zsr-ansible &&
   sudo chmod 0644 /tmp/zsr-ansible-backup.tar.gz'
vagrant ssh-config control > ssh-config
scp -F ssh-config control:/tmp/zsr-ansible-backup.tar.gz ./zsr-ansible-backup.tar.gz
tar -tzf zsr-ansible-backup.tar.gz
```

Archiwum powinno zawierać pliki projektu. Po zapisaniu pracy należy ją zweryfikować w docelowym repozytorium lub chmurze. Do archiwum nie należy dołączać kluczy SSH ani katalogu `.vagrant`.

Na zakończenie należy zatrzymać maszyny poleceniem `vagrant halt`. Polecenie `vagrant destroy` usuwa maszyny wirtualne i ich lokalne dane; można je wykonać wyłącznie z katalogu tego projektu, po sprawdzeniu kopii plików. VM nie są potrzebne do kolejnego laboratorium Docker.

## Diagnostyka

| Objaw | Pierwsza kontrola |
|:---|:---|
| `UNREACHABLE` | Czy SSH z `control` działa do tego samego adresu i konta |
| Brak interpretera Python | Czy VM ma `/usr/bin/python3` |
| Błąd sudo | Konto i polityka sudo w zarządzanej VM |
| Kolejny przebieg wciąż zgłasza zmiany | Zmienne wartości w szablonie i użycie modułów zamiast `shell` |
| Handler nie uruchomił się | Czy zadanie zgłosiło `changed` i czy nazwa `notify` odpowiada nazwie handlera |
| Nginx odrzuca konfigurację | Wynik `nginx -t`; należy poprawić szablon i ponownie uruchomić playbook. Walidacja zapobiega reloadowi, lecz nie cofa błędnego pliku już zapisanego na dysku |

## Źródła

- [Ansible: inventory](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html)
- [Ansible: playbooki](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_intro.html)
- [Ansible: handlery](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_handlers.html)
- [Vagrant: wiele maszyn](https://developer.hashicorp.com/vagrant/docs/multi-machine)

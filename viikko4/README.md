# Viikko 4

Tässä tehtävässä tein palvelimen B ja laitoin tietokannan kopioitumaan palvelimelta A palvelimelle B.

## Varmuuskopiointi

Tein backup-website.sh-skriptin, joka kopioi A-palvelimen verkkosivut B-palvelimelle kerran tunnissa.

Varmuuskopiot tallentuvat B-palvelimella kansioon /var/backups/website/.

## Ajastus

Varmuuskopiointi käynnistyy automaattisesti cron-ajastuksella.

Ajastuksen tiedot löytyvät tiedostosta crontab.txt.

## Testaus

Testasin varmuuskopioinnin ja tiedostojen palauttamisen. Molemmat toimivat.

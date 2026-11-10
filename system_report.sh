#!/usr/bin/env bash

# Funktio levytilan tarkistukseen (vaatimus: funktio ja if-lause)
check_disk_status() {
    local usage_percent=$1
    # Poistetaan prosenttimerkki pois vertailua varten (esim. "4%" -> "4")
    local num=$(echo "$usage_percent" | tr -d '%')
    
    if [ "$num" -ge 80 ]; then
        echo "WARNING"
    else
        echo "OK"
    fi
}

# Kerätään tiedot muuttujiin komentosubstituutiolla
GENERATED_AT=$(date '+%Y-%m-%d %H:%M:%S')
UPTIME_INFO=$(uptime -p)

# Käytetään putkea (|) ja awkkia levytilan hakemiseen
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')
DISK_STATUS=$(check_disk_status "$DISK_USAGE")

# Keskusmuistin tiedot free-komennolla
RAM_TOTAL=$(free -m | awk 'NR==2 {print $2}')
RAM_AVAIL=$(free -m | awk 'NR==2 {print $7}')

# Tulostetaan tiedot testiksi komentoriville
echo "--- PALVELIMEN RAPORTTI ---"
echo "Aika: $GENERATED_AT"
echo "Uptime: $UPTIME_INFO"
echo "Levytila (/): $DISK_USAGE (Tila: $DISK_STATUS)"
echo "RAM yhteensä: $RAM_TOTAL MB, Vapaana: $RAM_AVAIL MB"
#!/usr/bin/env bash

# Funktio levytilan tarkistukseen
check_disk_status() {
    local usage_percent=$1
    local num=$(echo "$usage_percent" | tr -d '%')
    
    if [ "$num" -ge 80 ]; then
        echo "WARNING"
    else
        echo "OK"
    fi
}

# Kerätään tiedot muuttujiin
GENERATED_AT=$(date '+%Y-%m-%d %H:%M:%S')
UPTIME_INFO=$(uptime -p)

DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')
DISK_STATUS=$(check_disk_status "$DISK_USAGE")

RAM_TOTAL=$(free -m | awk 'NR==2 {print $2}')
RAM_AVAIL=$(free -m | awk 'NR==2 {print $7}')

# Määritellään minne HTML-raportti tallennetaan (Nginxin juureen)
REPORT_DIR="/var/www/html/viikko3"
sudo mkdir -p "$REPORT_DIR"

# Kirjoitetaan HTML-tiedosto
sudo tee "$REPORT_DIR/index.html" > /dev/null <<EOF
<!DOCTYPE html>
<html lang="fi">
<head>
    <meta charset="UTF-8">
    <title>Palvelimen tilaraportti</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f9f9f9; color: #333; }
        .card { background: white; padding: 25px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); max-width: 600px; }
        h1 { color: #2c3e50; font-size: 24px; }
        ul { line-height: 1.6; }
        .ok { color: green; font-weight: bold; }
        .warning { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Palvelimen tilaraportti</h1>
        <p><strong>Raportti päivitetty:</strong> $GENERATED_AT</p>
        <hr>
        <ul>
            <li><strong>Toiminta-aika (Uptime):</strong> $UPTIME_INFO</li>
            <li><strong>Levytilan käyttö (/):</strong> $DISK_USAGE &mdash; Tila: <span class="$(echo $DISK_STATUS | tr '[:upper:]' '[:lower:]')">$DISK_STATUS</span></li>
            <li><strong>Keskusmuisti (RAM):</strong> Kokonaan $RAM_TOTAL MB, Vapaana $RAM_AVAIL MB</li>
        </ul>
    </div>
</body>
</html>
EOF

echo "HTML-raportti generoitu onnistuneesti osoitteeseen http://195.148.20.250/viikko3/"

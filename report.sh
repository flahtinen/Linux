#!/usr/bin/env bash

OUTPUT_DIR="/var/www/html/viikko3"
TEMP_FILE="$(mktemp)"
GITHUB_URL="https://github.com/flahtinen/Linux"

# Funktio: levytilan status 80 % rajalla
get_disk_status() {
    local usage=$1
    if [ "$usage" -ge 80 ]; then
        echo "WARNING"
    else
        echo "OK"
    fi
}

GENERATED_AT=$(date '+%Y-%m-%d %H:%M:%S %Z')
UPTIME_TEXT=$(uptime -p)
DISK_PERCENT=$(df -P / | awk 'NR == 2 {print $5}' | tr -d '%')
DISK_USAGE="${DISK_PERCENT}%"
DISK_STATUS=$(get_disk_status "$DISK_PERCENT")
MEM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
MEM_AVAILABLE=$(free -m | awk '/^Mem:/ {print $7}')

cat > "$TEMP_FILE" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Week 3 – Server Status Report</title>
    <style>
        body {
            font-family: system-ui, sans-serif;
            max-width: 900px;
            margin: 40px auto;
            padding: 0 20px;
            line-height: 1.6;
            background: #f1f5f9;
            color: #172033;
        }

        h1, h2 {
            color: #173b65;
        }

        section {
            margin: 24px 0;
            padding: 24px;
            background: white;
            border-radius: 12px;
        }

        .table-container {
            overflow-x: auto;
        }

        table {
            border-collapse: collapse;
            width: 100%;
        }

        th, td {
            border: 1px solid #cbd5e1;
            padding: 12px;
            text-align: left;
        }

        th {
            background: #dbeafe;
        }

        code {
            background: #e2e8f0;
            padding: 2px 5px;
            border-radius: 4px;
            overflow-wrap: anywhere;
        }

        a {
            color: #1746a2;
        }

        .note {
            color: #475569;
        }
    </style>
</head>
<body>
    <header>
        <h1>Server Status Report</h1>
        <p>Week 3: Linux command line and Bash scripting</p>
        <p>This page shows a server status report. A Bash script
            collects the time, uptime, disk usage and RAM of the server.
            The report updates every minute. Below you can find the
            commands I used, how the script works, my tests and a link
            to GitHub. The report below updates
            by itself every minute.</p>
    </header>

    <section>
        <h2>Current server status</h2>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th scope="col">Information</th>
                        <th scope="col">Value</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <th scope="row">Report generated</th>
                        <td>$GENERATED_AT</td>
                    </tr>
                    <tr>
                        <th scope="row">Server uptime</th>
                        <td>$UPTIME_TEXT</td>
                    </tr>
                    <tr>
                        <th scope="row">Root filesystem disk usage</th>
                        <td>$DISK_USAGE</td>
                    </tr>
                    <tr>
                        <th scope="row">Disk space status</th>
                        <td>$DISK_STATUS</td>
                    </tr>
                    <tr>
                        <th scope="row">Total RAM</th>
                        <td>$MEM_TOTAL MiB</td>
                    </tr>
                    <tr>
                        <th scope="row">Available RAM</th>
                        <td>$MEM_AVAILABLE MiB</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <p>
            Disk space status is <strong>OK</strong> below 80% usage
            and <strong>WARNING</strong> at 80% or above.
        </p>

        <p class="note">
            Bash generates this report once per minute.
            Wait approximately 1–2 minutes and reload the page
            to see a new generation time.
        </p>
    </section>

    <section>
        <h2>Commands used</h2>
        <ul>
            <li>
                <code>date</code>:
                displays the current date, time and time zone
                using the format specified in the script.
            </li>
            <li>
                <code>uptime -p</code>:
                displays how long the server has been running.
            </li>
            <li>
                <code>df -P / | awk 'NR == 2 {print &#36;5}'</code>:
                passes filesystem information to awk, which extracts
                the usage percentage from the second row.
            </li>
            <li>
                <code>free -m</code>:
                displays memory information in mebibytes (MiB).
            </li>
        </ul>
    </section>

    <section>
        <h2>How the script works</h2>
        <p>
            The script collects server information using Linux commands
            and stores the results in Bash variables through command
            substitution. A function uses an if statement to determine
            the disk space status.
        </p>
        <p>
            The script generates a temporary HTML file and then moves
            the completed file into place as index.html.
            Nginx serves this file at /viikko3/.
        </p>
        <p>
                    <p>
            I made a function called get_disk_status. It checks how full
            the disk is. If the number is 80 or more, it says WARNING.
            If the number is smaller, it says OK. I learned that the
            function must be written before the place where I use it.
        </p>
        </p>
    </section>

    <section>
        <h2>Scheduling</h2>
        <p>
                    <p>
            I used cron to make the report update by itself.
            I opened the crontab with crontab -e and added this line:
            * * * * * /home/ubuntu/viikko3/report.sh >/dev/null 2>&1
        </p>
        <p>
            The five stars mean that the script runs every minute.
            I found out that the server already had another cron job from
            Week 2, so I did not remove it and just added my line below it.
        </p>
        <p>
            To make sure it keeps working after a reboot, I checked that cron
            starts automatically with systemctl is-enabled cron
            (the answer was enabled). Then I rebooted the server.
            After the reboot the uptime was 2 minutes and the report had
            updated again, so it works.
        </p>
        </p>
    </section>

    <section>
        <h2>Test results</h2>

        <h3>Syntax check and manual execution</h3>
        <p>
        <p>
            I checked the syntax with bash -n report.sh and there were
            no errors. Then I ran the script by hand and opened the
            page in the browser. The report showed the time, uptime,
            disk usage, disk status and RAM correctly.
        </p>

        <h3>Disk space status tests</h3>
        <p>
        <p>
            I tested the disk status function with three test numbers.
            I loaded only the function and called it by hand with each
            number. The real disk usage was not changed, so I did not
            need to restore anything.
        </p>
        </p>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th scope="col">Test input</th>
                        <th scope="col">Expected status</th>
                        <th scope="col">Actual status</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>50%</td>
                        <td>OK</td>
                        <td>OK</td>
                    </tr>
                    <tr>
                        <td>80%</td>
                        <td>WARNING</td>
                        <td>WARNING</td>
                    </tr>
                    <tr>
                        <td>90%</td>
                        <td>WARNING</td>
                        <td>WARNING</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <h3>Automatic updates</h3>
        <p>
        <p>
            I checked the update time of index.html with ls -l.
            The first update was at 18:32 and the next one was at 18:33.
            The time changed by one minute, so cron runs the script
            every minute. The time also changes when I reload the page
            in the browser.
        </p>
        </p>

        <h3>Reboot test</h3>
        <p>
        <p>
            I rebooted the virtual machine on 15 November 2026 at 18:34
            (EET). I logged in again at 18:37 and the uptime was 2 minutes,
            so the reboot worked. The report page opened in the browser
            and index.html had been updated at 18:38 without me doing
            anything. This means that cron started again by itself
            after the reboot.
        </p>
        </p>
    </section>

    <section>
        <h2>A problem solved or a lesson learned</h2>
        <p>I learned what piping means. A pipe is the | sign and it
            sends the output of one command to the next command. At first
            it was hard to understand. Then I tried it step by step.</p>
    </section>

    <footer>
        <p><a href="$GITHUB_URL">View the source code on GitHub</a></p>
    </footer>
</body>
</html>
EOF

chmod 644 "$TEMP_FILE"
mv -f "$TEMP_FILE" "$OUTPUT_DIR/index.html"

# Linux
# Week 3: Bash server status report

A Bash script (report.sh) collects the time, uptime, root disk
usage and RAM of my server and writes an HTML report.

- report.sh: the script
- crontab.txt: cron entry that runs the script every minute

The disk status is OK below 80% and WARNING at 80% or above.

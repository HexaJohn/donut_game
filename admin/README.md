# Donut Admin

A Mac app for watching the party server: who's online, every table (with its
seats and chat), and the daily usage counts. Read-only, and nothing is saved
on the Mac.

    ./run.sh

It reads AWS with the CLI's credentials (`aws configure`; set `AWS_PROFILE`
for another profile) and finds the server from the `donut-game` stack. While
open it lists and reads the tables bucket every 10 seconds, re-reading only
tables that changed: well under a cent an hour.

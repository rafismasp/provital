#!/bin/bash
git log --since="last year" --pretty=format:'%h,%an,%ar,%s' > "//192.168.131.40/laporan it/IT Developer/Git Repo/ERP Provital/log.csv"
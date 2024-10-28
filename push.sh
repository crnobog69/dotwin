#!/bin/bash

# Скрипта која аутоматизује `git add`, `git commit` и `git push`

git add .
git commit -m "❄️"
git push github main
git push codeberg main
git push gitlab main

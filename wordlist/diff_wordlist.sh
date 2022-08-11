#!/bin/bash
before="$(wc -l "${1}" | awk '{print $1}')"
filtered_wordlist="${1/.*}-filtered.words"
cp "${1}" /dev/shm/"${filtered_wordlist}"

printf "Removing too short words...\n"
orig="$(wc -l "/dev/shm/${filtered_wordlist}" | awk '{print $1}')"
awk 'length > 8' "/dev/shm/${filtered_wordlist}" > "/dev/shm/${filtered_wordlist}-temp"
mv "/dev/shm/${filtered_wordlist}-temp" "/dev/shm/${filtered_wordlist}"
new="$(wc -l "/dev/shm/${filtered_wordlist}" | awk '{print $1}')"
minus=$((orig-new))
printf "removed ${minus} too short words, words remaining: ${new}\n"
if [ "${new}" = "0" ]; then
  printf "No words remaining, broken\n"
  exit 1
fi

printf "Removing too long words...\n"
orig="$(wc -l "/dev/shm/${filtered_wordlist}" | awk '{print $1}')"
awk 'length < 64' "/dev/shm/${filtered_wordlist}" > "/dev/shm/${filtered_wordlist}-temp"
mv "/dev/shm/${filtered_wordlist}-temp" "/dev/shm/${filtered_wordlist}"
new="$(wc -l "/dev/shm/${filtered_wordlist}" | awk '{print $1}')"
minus=$((orig-new))
printf "removed ${minus} too long words, words remaining: ${new}\n"
if [ "${new}" = "0" ]; then
  printf "No words remaining, broken\n"
  exit 1
fi

printf "Removing common dict words...\n"
for i in $(find /usr/share/dict/skullsecurity -type f) $(find /usr/share/dict/raft-wordlists -type f)  $(find /usr/share/dict/seclists/Passwords -type f) $(find /usr/share/dict/theHarvester -type f)$(find /usr/share/dict -maxdepth 1 -type f) ; do
  if [ -e "${i}" ] && [ ! -L "${i}" ]; then
    if [ "${i/.csv}" != "${i}" ] || [ "${i/.gz}" != "${i}" ] || [ "${i/.tgz}" != "${i}" ] || [ "${i/.bz2}" != "${i}" ]; then
      printf "Skipping ${i}...\n"
      continue
    fi
    [ "${i}" = "/usr/share/dict/seclists/Passwords/Leaked-Databases/rockyou.txt.tar.gz" ] && continue
    [ "${i}" = "/usr/share/dict/seclists/Passwords/Leaked-Databases/rockyou-withcount.txt.tar.gz" ] && continue
    [ "${i}" = "/usr/share/dict/seclists/Payloads/Zip-Bombs/r.tar.gz" ] && continue
    [ "${i}" = "/usr/share/dict/seclists/Payloads/Zip-Bombs/r.gz" ] && continue
    printf "Processing ${i}... "
    orig="$(wc -l "/dev/shm/${filtered_wordlist}" | awk '{print $1}')"
    diff -Naur "${i}" "/dev/shm/${filtered_wordlist}" | grep -v '^+++' | grep '^+' --color=never | cut -c 2- > "/dev/shm/${filtered_wordlist}-temp"
    mv "/dev/shm/${filtered_wordlist}-temp" "/dev/shm/${filtered_wordlist}"
    new="$(wc -l "/dev/shm/${filtered_wordlist}" | awk '{print $1}')"
    minus=$((orig-new))
    printf "removed ${minus}, words remaining: ${new}\n" 
    if [ "${new}" = "0" ]; then
      printf "No words remaining, broken\n"
      exit 1
    fi
  fi
done
after="$(wc -l "/dev/shm/${filtered_wordlist}" | awk '{print $1}')"
result=$((before-after))
cp "/dev/shm/${filtered_wordlist}" .
printf "We began with ${before} words and removed ${result} for a new total of ${after}\n"

#!/bin/bash

# greatings="Hello from the script"
# echo "$greatings"
# echo "script running from $PWD"

# if ! [ -d "test_dir" ];  then
#   mkdir test_dir && echo "---test_dir created---"
# fi

# rm -ir test_dir && echo "---test_dir removed---"

# if [[ $1 -gt $2 ]]; then
#   echo "$1 is greater than $2"
# fi


# if (( $1 > $2 )); then
#   echo "$1 is greater than $2"
# fi

path=$PWD
fssm_path=./fssm/fetched_statuses
summary_file=rpd_summary.txt
date=$(date +%Y-%m-%d_%H:%M:%S)

if ! [[ "$path" == */var/log ]]; then
  echo "Run script in */var/log, not $path"
  exit 1
fi

# echo "path is $path"
# echo "fssm path is $fssm_path"

if ! [[ -f "$summary_file" ]]; then
  touch "$summary_file"
  # echo "Summary file created"
  # echo "Summary file exists"
else
  echo "----File recreated on $date----" > $summary_file

fi


if [ -f "$fssm_path/SYSTEM/system_data.txt" ]; then
  # echo "SYSTEM/system_data.txt found"
  rpd_date=$(grep -i 'time date' -A3 "$fssm_path/SYSTEM/system_data.txt" | awk 'NR == 3')
  rpd_uptime=$(grep -i 'time uptime' -A3 "$fssm_path/SYSTEM/system_data.txt" | awk 'NR == 3')
  printf "\nRpd_Date: %s\n" "$rpd_date" >> $summary_file 
  printf "Rpd_Uptime: %s\n" "$rpd_uptime" >> $summary_file
fi

if [ -f "$fssm_path/GENERAL/general_info.txt" ]; then
  # echo "GENERAL/general_info.txt found"
  version=$(grep -i 'nsg-version' -A3 "$fssm_path/GENERAL/general_info.txt" | awk 'NR == 3')
  mode=$(grep -i 'change_mode check' -A3 "$fssm_path/GENERAL/general_info.txt" | awk 'NR == 3')
  rpd_pn=$(grep -i "time exor --read-mechanical-stamp'" -A3 "$fssm_path/GENERAL/general_info.txt" | awk 'NR == 3' | cut -d "'" -f 4)
  rpd_sn=$(grep -i "time exor --read-mechanical-stamp'" -A3 "$fssm_path/GENERAL/general_info.txt" | awk 'NR == 3' | cut -d "'" -f 8)

  printf "\nVersion: %s\n" "$version" >> $summary_file
  printf "Mode: %s\n" "$mode" >> $summary_file
  printf "\nPN: %s\n" "$rpd_pn" >> $summary_file
  printf "SN: %s\n" "$rpd_sn" >> $summary_file
   
fi

if [ -f "$fssm_path/NETWORK/ip_summary_show.txt" ]; then
  # echo "NETWORK/ip_summary_show.txt found"
  rpd_ip=$(grep -i "tap1:" -A6 "$fssm_path/NETWORK/ip_summary_show.txt" | grep -i "inet" | awk '{print $2}')
  rpd_mac=$(grep -i "tap1:" -A6 "$fssm_path/NETWORK/ip_summary_show.txt" | grep -i "ether" | awk '{print $2}')

  printf "\nRpd_IP: %s\n" "$rpd_ip" >> $summary_file
  printf "Rpd_MAC: %s\n" "$rpd_mac" >> $summary_file
fi

if [ -d "$path/../../etc/harmonic/nsg/journal" ]; then
  echo "etc/harmonic/nsg/ journal folder found"
  
  if [ ! -d "journals_backup" ]; then
    mkdir "journals_backup" && echo "journals_backup folder created"
    journals_backup_path="$path/journals_backup/"
    # echo "journals_backup path is $journals_backup_path"
  else
    journals_backup_path="$path/journals_backup/"
  fi

  cd "$path/../../etc/harmonic/nsg/journal" && journal_path="$PWD"
  # echo "journal path is $journal_path"


  for folder in */; do
    echo "processing folder: $folder"
    for inner_folder in "$folder"*; do
      echo "processing folder: $inner_folder"
      if [ -d "$inner_folder" ]; then
        echo "folder $inner_folder found"
        for file in "$inner_folder"/*; do
          if [ -f "$file" ] &&  [ ! -s "$file" ]; then
            echo "file $file found"
            
          fi
        done
        # echo "Processing journals..."
        TZ=UTC journalctl --directory="$inner_folder" --output=short-full > "$journals_backup_path$(basename $inner_folder).log"
      fi
    done
  cd "$path" || continue
  done
else
  echo "journal not found in etc/harmonic/nsg/"
fi

if [ -d "$path/../../run/log/journal" ]; then
  echo "run/log/ journal folder found"

  if [ ! -d "journals_backup" ]; then
    mkdir "journals_backup" && echo "journals_backup folder created"
    journals_backup_path="$path/journals_backup/"
    # echo "journals_backup path is $journals_backup_path"
  else
    journals_backup_path="$path/journals_backup/"
  fi

  cd "$path/../../run/log/journal" && journal_path="$PWD"
  # echo "journal path is $journal_path"

  for folder in */; do
    echo "processing folder: $folder"
    modify_date=$(stat -c %y $folder | awk '{print $1"_"$2}' | sed 's/:/-/g' | cut -d. -f1)
    for file in "$folder"*; do
      if [ -f "$file" ] && [ -s "$file" ]; then
        echo "file $file found"
      fi
    done
    # echo "Processing journals..."
    TZ=UTC journalctl --directory="$folder" --output=short-full > "$journals_backup_path$(basename $modify_date).log" 
  done
  cd "$path" || continue
else
  echo "Journal not found in run/log/"
fi

cat $summary_file
echo ""
echo "Journals available in $journals_backup_path"






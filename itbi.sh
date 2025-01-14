#!/bin/bash

#Acesta este meniul principal

meniu_principal() {
    	echo "Meniu"
    	echo "1. XML --> TXT"
	echo "2. TXT --> XML"
    	echo "3. Iesire"
    	echo "Alege o optiune:"
}

#Vedem daca exista fisierul

existenta_fisier() {
    local file=$1
    if [ ! -f "$file" ]; then
        echo "Eroare: Fisierul $file nu exista"
        return 1
    fi
    return 0
}

#Aici validam formatul fisierului

validare_format() {
    local file=$1
    local extensie=$2

    if [[ $file =~ \.$extensie$ ]]; then
        return 0
    else
        echo "Eroare: Fisierul trebuie sa aiba extensia .$extensie"
        return 1
    fi
}

#Validare pentru XML in TXT

xml_to_txt_validare() {
    printf "Introduceti numele fișierului XML (de intrare):\n"
    read input_file

    # Verificam daca fisierul de intrare exista
    if ! existenta_fisier "$input_file"; then
        return 1
    fi

    # Verificam extensia fisierului de intrare (trebuie sa fie XML)
    if ! validare_format "$input_file" "xml"; then
        return 1
    fi

    echo "Introduceti numele fisierului TXT (de iesire):"
    read output_file

    # Verificam daca fisierul de iesire exista
    if ! existenta_fisier "$output_file"; then
        touch "$output_file"
        echo "Fisierul $output_file a fost creat."
    fi

    # Verificam extensia fisierului de iesire (trebuie sa fie TXT)
    if ! validare_format "$output_file" "txt"; then
        rm "$output_file"
        return 1
    fi

    # Returnam numele fisierelor valide
    return 0
}

#Din XML in TXT

xml_to_txt(){
 	if xml_to_txt_validare; then
        	echo "Fișiere valide: Intrare=$input_file, Ieșire=$output_file"
        	local indent=-1
        	while IFS= read -r line; do
        	        local ok=0 #pt a verifica daca e tag de deschidere si sa adauge ":"
        		#if [[ "$line" == *"<root>"* || "$line" == *"</root>"* ]]; then    #da skip la root
			 #   continue
			#fi
			
			if echo "$line" | grep -q '<.*<' || ! echo "$line" | grep -q '<'; then
    				ok=1				#daca e linie de forma cu doua taguri sau niciuna, face pe ok 1
			fi

        		linie_modificata=""
        		#Aduagam endline unde trebuie
        		
        		if ! echo "$line" | grep -q '<.*<'; then
        			linie_plusendline=$(echo "$line" | sed -E 's/>([^\n])/>\n\1/g')
        		else
        			
				linie_plusendline="$line"
        		fi
        		linie_fara_spatiu=$(echo "$linie_plusendline" | sed 's/^[[:space:]]*//')
        		((indent+=1))
        		

        		
 			if echo "$line" | grep -q '<.*>'; then
    				# Adaugă ':' după primul '>'
    				line=$(echo "$line" | sed -E 's/^(<[^>]+>)(\n)/\1:\2/')
			fi

        		
        		if echo "$line" | grep -qE '^[[:space:]]*</[^>]+>$'; then     #verifica daca e de forma tag de inchidere si da skip la linie
        			((indent-=2))
    				continue
			fi
			
			
			

			
			# Verificăm dacă linia conține un tag de închidere de tipul </...> și îl eliminăm
			if echo "$line" | grep -qE '</[^>]+>'; then
   				 # Eliminăm tag-urile de închidere indiferent de ce caractere sunt înainte sau după
    				linie_fara_spatiu=$(echo "$linie_fara_spatiu" | sed 's/<\/[^>]*>//g')
			fi

#################################################################################################
#####                      CAZUL CU <NAME>jOHN</NAME>

    # Elimină spațiile inutile
    line=$(echo "$line" | sed 's/^[ \t]*//;s/[ \t]*$//')

    # Verifică dacă linia conține formatul <tag>content</tag>
    if echo "$line" | grep -qE '^<[^>]+>.*<\/[^>]+>$'; then
        # Extrage tag-ul dintre <>
        tag=$(echo "$line" | sed -E 's/^<([^>]+)>.*<\/[^>]+>$/\1/')

        # Extrage conținutul dintre tag-uri
        content=$(echo "$line" | sed -E 's/^<[^>]+>(.*)<\/[^>]+>$/\1/')
        
        # Adaugă ':' după tag
        tag="${tag}:"

        # Construiește linia formatată
        linie_fara_spatiu=$(printf '%s\n%s\n' \
            "$(printf '\t%.0s' $(seq 1 $indent))$tag" \
            "$(printf '\t%.0s' $(seq 1 $((indent + 1))))$content")
            ((ok = 2))
	fi	
###################################################################################################

			if [[ "$line" == *"root"* ]]; then
				linie_fara_spatiu=$(echo "$linie_fara_spatiu" | sed 's/<//g')		# daca este tag de deschidere elimina < si pe urm linie de cod elimina >
        		 linie_fara_spatiu=$(echo "$linie_fara_spatiu" | sed 's/>//g')
        		 	if [[ "$ok" -eq 0 ]]; then
    					linie_fara_spatiu="${linie_fara_spatiu}:"      #adauga: daca e tag
			 	fi
			 	
    				echo "$linie_fara_spatiu" >> $output_file
    				continue  # Continuăm cu următoarea linie fără a o modifica
			fi
			
			if [ "$ok" -ne 2 ]; then
        		 linie_modificata+="$(printf '%s%s\n' "$(printf '\t%.0s' $(seq 1 $indent))" "$linie_fara_spatiu")"
        		 else
        		 	linie_modificata="$linie_fara_spatiu"
        		 fi
        		 linie_modificata=$(echo "$linie_modificata" | sed 's/<//g')		# daca este tag de deschidere elimina < si pe urm linie de cod elimina >
        		 linie_modificata=$(echo "$linie_modificata" | sed 's/>//g')
        		 if [[ "$ok" -eq 0 ]]; then
    				linie_modificata="${linie_modificata}:"      #adauga: daca e tag
			 fi
			 
			if [[ "$line" == *\</* ]]; then
            			((indent-=1))
        		fi
        		
        		if [[ "$line" != "<"* ]]; then     #daca nu exista < la inceputul cuvantului
        			((indent-=1))
			fi

		    	echo "$linie_modificata" >> $output_file

		done < $input_file
		
	else
        	echo "Eroare: Fișierele nu sunt valide."
    	fi
}

#Validare pentru in XML

txt_to_xml_validare() {
    printf "Introduceti numele fișierului TXT (de intrare):\n"
    read input_file

    # Verificam daca fisierul de intrare exista
    if ! existenta_fisier "$input_file"; then
        return 1
    fi

    # Verificam extensia fisierului de intrare (trebuie sa fie TXT)
    if ! validare_format "$input_file" "txt"; then
        return 1
    fi

    echo "Introduceti numele fisierului XML (de iesire):"
    read output_file

    # Verificam daca fisierul de iesire exista
    if ! existenta_fisier "$output_file"; then
        touch "$output_file"
        echo "Fisierul $output_file a fost creat."
    fi

    # Verificam extensia fisierului de iesire (trebuie sa fie XML)
    if ! validare_format "$output_file" "xml"; then
        rm "$output_file"
        return 1
    fi

    # Returnam numele fisierelor valide
    return 0  
}

#Din TXT in XML


txt_to_xml(){
 	if txt_to_xml_validare; then
        	echo "Fișiere valide: Intrare=$input_file, Ieșire=$output_file"
        	
		#initializam aici stiva pentru a tine minte ordinea tag-urilor curente
		declare -a tag_stack=()

		#ierarhia (prin stiva) incepe cu root
		tag_stack+=("root")

		#aici facem citirea fisierului pe linii
		while IFS= read -r line; do
  			#eliminam spatiile albe
  			trimmed_line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  			#daca linia este goala in fisier, sarim peste ea si mergem la urmatoarea linie
  			if [[ -z "$trimmed_line" ]]; then
    				continue
  			fi

  			#numaram tab-urile de la inceputul liniei pentru a determina indentarea
  			indent_level=$(echo "$line" | sed 's/^\(\t*\).*/\1/' | wc -c)

  			#calculam adancimea locului in care suntem acum cu ajutorul stivei si al indentarii
  			depth=$((indent_level - 1))  # Fiecare tab reprezintă un nivel

  			#ajustam stiva in functie de adancime
  			while (( ${#tag_stack[@]} > depth + 1 )); do
    				# Închidem ultimul tag
    				last_tag=${tag_stack[-1]}
    				echo "$(printf '%*s' $((2 * (depth))))</$last_tag>" >> "$output_file"
    				tag_stack=("${tag_stack[@]::${#tag_stack[@]}-1}")  # Scoatem ultimul element din stivă
  			done

  			#verificam daca linia se termina cu ":" (adica este un tag)
  			if [[ "$trimmed_line" == *:* ]]; then
   		 		#este un tag, eliminam ":"
    				tag_name=$(echo "$trimmed_line" | cut -d':' -f1 | tr '[:upper:]' '[:lower:]')
				#aici verificam daca nu cumva e root, pe care il prelucram separat
    				if [[ "${tag_stack[-1]}" == "root" && ${#tag_stack[@]} -eq 1 ]]; then
      					echo "<$tag_name>" >> "$output_file"
    				else
       					echo "$(printf '\t%.0s' $(seq 1 $depth))<$tag_name>" >> "$output_file"
    				fi
				#aici adaugam in stiva
    				tag_stack+=("$tag_name")
  			else
    				#este doar o valoare (adica continutul tag-ului)
    				current_tag=${tag_stack[-1]}
    				echo "$(printf '\t%.0s' $(seq 1 $depth))$trimmed_line" >> "$output_file"

    				#inchidem tag-ul după valoare
    				echo "$(printf '\t%.0s' $(seq 2 $depth))</$current_tag>" >> "$output_file"
    		
    				tag_stack=("${tag_stack[@]::${#tag_stack[@]}-1}")  # scoatem ultimul element din stivă
  			fi
		done < "$input_file"

	#inchidem toate tag-urile ramase deschise
	while [[ ${#tag_stack[@]} -gt 1 ]]; do
  		last_tag=${tag_stack[-1]}
  		#aici inchidem orice este deschis, mai putin root, care este prelucrat separat
  		if [[ "$last_tag" == "root" ]]; then
    			echo "</$last_tag>" >> "$output_file"
  		else
    			echo "$(printf '\t%.0s' $(seq 1 $(( ${#tag_stack[@]} - 2 ))))</$last_tag>" >> "$output_file"
 	 	fi
  		tag_stack=("${tag_stack[@]::${#tag_stack[@]}-1}")  # scoatem ultimul element din stiva
	done


	echo "$output_file a fost generat"

        	 	
	else
        	echo "Eroare: Fișierele nu sunt valide."
    	fi
}


#Acesta este programul "main"

while true; do
    	meniu_principal
    	read choice
    	case $choice in
        1)
            	xml_to_txt
            	;;
        2)
            	txt_to_xml
            	;;
        3)
            	echo "Ieșire"
            	break
            	;;
        *)	
            	echo "Optiune gresita"
            	;;
    	esac
done
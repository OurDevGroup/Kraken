css_minify() {
	echo	
	local demandwareServer=$(read_conf "deploy" "demandwareServer" $demandwareServer)	
	local minifyCSS=$(read_conf $demandwareServer "minifyCSS" "N")
	
	if [ "$(upper $minifyCSS)" == "Y" ]; then
		read -n 1 -p "Would you like to minify all .css files [Y/n]? " t_minifyCSS
	else
		read -n 1 -p "Would you like to minify all .css files [y/N]? " t_minifyCSS
	fi
	minifyCSS=${t_minifyCSS:-"$(upper $minifyCSS)"}
	
	write_conf $demandwareServer "minifyCSS" $(upper "$minifyCSS")
	
	if [[ "$(upper $minifyCSS)" == "Y" ]]; then	
		if ! gem spec cssminify > /dev/null 2>&1; then	
			echo
			local installMinify="N"
			read -n 1 -p "Gem cssminify is not installed, do you want to install it [Y/n]? " installMinify
			installMinify=${installMinify:-"Y"}	
					
			if [[ "$installMinify" == "y" || "$installMinify" == "Y" ]]; then	
				sudo gem install cssminify
			else 
				exit 1
			fi
		fi	
		
		echo
		echo "Minifying .css files."
		
        cd ${homedir}
        
		for cartridge in "${cartridges[@]}"; do	
            echo
			cd ${homedir}/${cartridge}
			echo ${cartridge}
				
			if [ -d ${homedir}/${cartridge}/cartridge/static ]; then				
				
				file_list=()
				while IFS= read -d $'\0' -r file; do
					file_list=("${file_list[@]}" "$file")
				done < <(find "${homedir}/${cartridge}/cartridge/static" -name "*.css" ! -name '*.min.css' -print0)
				
				cd ${deploydir}/bin
				for file in "${file_list[@]}" ; do
					echo "Minifying CSS $file"
					local cssFile=${file}
					#if [ iscygwin ]; then
					#	cssFile=$(cygpath -w $file)
					#fi
								
					$(which ruby) cssmin.rb $file >> ${file}.tmp
								
					#java -jar yuicompressor-2.4.8.jar --type css "${cssFile}" > ${file}.tmp
					if [[ -f ${file}.tmp && -s ${file}.tmp ]]; then
						mv ${file}.tmp ${file}
					else
						rm ${file}.tmp							
					fi

				done
			else
            echo "bad"
			fi

		done		
	fi	
}

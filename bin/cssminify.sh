css_minify() {
	local demandwareServer=$(read_conf "deploy" "demandwareServer" $demandwareServer)		
	local minifyCSS=$(prompt $demandwareServer "minifyCSS" $bool false "Would you like to minify all .css files" true "" true)
	echo
	
	if [ $minifyCSS == true ]; then	
		if ! gem spec cssminify > /dev/null 2>&1; then	
			echo
			local installMinify="N"
			read -n 1 -p "Gem cssminify is not installed, do you want to install it [Y/n]? " installMinify
			installMinify=${installMinify:-"Y"}	
					
			if [[ "$installMinify" == "y" || "$installMinify" == "Y" ]]; then	
				gem install cssminify
			else 
				exit 1
			fi
		fi	
				
		echo "Minifying .css files."
		echo
		
		for cartridge in "${cartridges[@]}"; do	
			echo		
			local cartPath=$(scp_cartridge_path "$cartridge")
			cd ${homedir}/${cartPath}
			echo ${cartridge}
				
			if [ -d ${homedir}/${cartPath}/cartridge/static ]; then				
				
				file_list=()
				while IFS= read -d $'\0' -r file; do
					file_list=("${file_list[@]}" "$file")
				done < <(find "${homedir}/${cartPath}/cartridge/static" -name "*.css" ! -name '*.min.css' -print0)
				
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
			
			fi

		done		
	fi	
}

js_minify() {
	echo	
	local demandwareServer=$(read_conf "deploy" "demandwareServer" $demandwareServer)
	local minifyJS=$(read_conf $demandwareServer "minifyJS" "N")
	
	if [ "$(upper $minifyJS)" == "Y" ]; then
		read -n 1 -p "Would you like to minify all Javascript files [Y/n]? " t_minifyJS
	else
		read -n 1 -p "Would you like to minify all Javascript files [y/N]? " t_minifyJS
	fi
	minifyJS=${t_minifyJS:-$(upper $minifyJS)}	
	
	write_conf $demandwareServer "minifyJS" $(upper $minifyJS)
		
	if [[ "$(upper $minifyJS)" == "Y" ]]; then
		if ! gem spec uglifier > /dev/null 2>&1; then	
			echo
			local installMinify="N"
			read -n 1 -p "Gem uglifier is not installed, do you want to install it [Y/n]? " installMinify
			installMinify=${installMinify:-"Y"}	
					
			if [[ "$installMinify" == "y" || "$installMinify" == "Y" ]]; then	
				sudo gem install uglifier
			else 
				exit 1
			fi
		fi
		
		echo
		echo "Minifying .js files."
		
		for cartridge in "${cartridges[@]}"; do				
			echo
			cd ${homedir}/${cartridge}
			echo ${cartridge}
		
			if [ -d ${homedir}/${cartridge}/cartridge/static ]; then
		
				file_list=()
				while IFS= read -d $'\0' -r file; do
					file_list=("${file_list[@]}" "$file")
				done < <(find "${homedir}/${cartridge}/cartridge/static" -name "*.js" ! -name '*.min.js' -print0)
				
				cd ${deploydir}/bin
				for file in "${file_list[@]}" ; do
					echo "Minifying Javascript $file"
					local jsFile=${file}
					#if [ iscygwin ]; then
					#	jsFile=$(cygpath -w $file)
					#fi
					
					$(which ruby) jsmin.rb $file >> ${file}.tmp
					
					#cp ${file} ${file}.bak
					#java -jar yuicompressor-2.4.8.jar --type js "${jsFile}" > ${file}.tmp
					if [[ -f ${file}.tmp && -s ${file}.tmp ]]; then
						mv ${file}.tmp ${file}
					else
						rm ${file}.tmp
					fi
					#rm ${file}.bak

				done
				
			fi

		done		
	fi	
}

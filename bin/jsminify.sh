js_minify() {	
	local demandwareServer=$(read_conf "deploy" "demandwareServer" $demandwareServer)
	local minifyJS=$(prompt $demandwareServer "minifyJS" $bool false "Would you like to minify all Javascript files" true "" true)
	local skipCartridges=false
	echo

	if [ $minifyJS == true ]; then
		if ! gem spec uglifier > /dev/null 2>&1; then
			echo
			local installMinify="N"
			read -n 1 -p "Gem uglifier is not installed, do you want to install it [Y/n]? " installMinify
			installMinify=${installMinify:-"Y"}

			if [[ "$installMinify" == "y" || "$installMinify" == "Y" ]]; then
				gem install uglifier
			else
				skipCartridges=true
			fi
		fi

		echo "Minifying .js files."
		echo

		if [ $skipCartridges == false ]; then
			for cartridge in "${cartridges[@]}"; do
				echo
				local cartPath=$(scp_cartridge_path "$cartridge")
				cd ${homedir}/${cartPath}
				echo ${cartridge}

				if [ -d ${homedir}/${cartPath}/cartridge/static ]; then

					file_list=()
					while IFS= read -d $'\0' -r file; do
						file_list=("${file_list[@]}" "$file")
					done < <(find "${homedir}/${cartPath}/cartridge/static" -name "*.js" ! -name '*.min.js' -print0)

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
	fi
}

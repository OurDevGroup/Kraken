
scss_compile() {
	local demandwareServer=$(read_conf "deploy" "demandwareServer" $demandwareServer)
	local compileSASS=$(prompt $demandwareServer "minifySASS" $bool false "Would you like to compile all Sass .scss files" true "" true)
	echo

	if [ $compileSASS == true ]; then
		if ! gem spec sass > /dev/null 2>&1; then
			echo
			local installSass="N"
			read -n 1 -p "Gem sass is not installed, do you want to install it [Y/n]? " installSass
			installSass=${installSass:-"Y"}

			if [[ "$installSass" == "y" || "$installSass" == "Y" ]]; then
        echo "Superuser authentication is required to install Sass."
				sudo gem install sass
			else
				exit 1
			fi
		fi

		echo "Compiling .scss files."
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
				done < <(find "${homedir}/${cartPath}/cartridge/static" -name "*.scss" -print0)

				cd ${deploydir}/bin
				for file in "${file_list[@]}" ; do
					echo "Compiling SCSS $file"

					sass --update $file:${file%.*}.css
				done

			fi

		done
	fi
}

source ${deploydir}/bin/sass.sh
source ${deploydir}/bin/less.sh
source ${deploydir}/bin/jsminify.sh
source ${deploydir}/bin/cssminify.sh

minify() {
	scss_compile
	less_compile	
	js_minify
	css_minify
}

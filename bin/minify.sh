source ${deploydir}/bin/jsminify.sh
source ${deploydir}/bin/cssminify.sh

minify() {
	js_minify
	css_minify
}
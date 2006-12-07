#! /bin/sh
#
# GenBuildNumber

INCREMENT=0
if [ $# -gt 0 ] ; then
    for option; do
        case "${option}" in
            -increment)
                INCREMENT=1;
                ;;
        esac;
    done;
fi

VAR_FILE="build_vars/build_number"
VERS_FILE="build_vars/version_number"

if [ "${BUILD_STYLE}" == "Development" ] ; then
        VAR_FILE="build_vars/build_number.$USER"
else
        ocvs update $VAR_FILE
fi

#
# Generate new build number
#
if [ ! -f $VAR_FILE ]; then
        echo 1 > $VAR_FILE
else
    if [ $INCREMENT -gt 0 ] ; then
        expr  `cat $VAR_FILE ` + 1 > build_number.new
        mv build_number.new $VAR_FILE
	fi
fi
if [ "${BUILD_STYLE}" == "Development" ] ; then
        echo "D"`cat $VAR_FILE` > build_number.temp
else
#        ocvs commit -F $VAR_FILE -f $VAR_FILE
        cp $VAR_FILE build_number.temp
fi

#
# Replace placeholders in Info.plist
# Note that Info.plist is not generated from scratch each build
#
echo "Build:" `cat build_number.temp`

chmod 777 "${TARGET_BUILD_DIR}/${CONTENTS_FOLDER_PATH}"
mv "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}" temp.plist
perl -spi -e s/#BUILD_NUMBER#/`cat build_number.temp `/ temp.plist
perl -spi -e s/#VERSION_NUMBER#/`cat ${VERS_FILE} `/ temp.plist
mv temp.plist "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

rm build_number.temp

chmod 555 "${TARGET_BUILD_DIR}/${CONTENTS_FOLDER_PATH}"

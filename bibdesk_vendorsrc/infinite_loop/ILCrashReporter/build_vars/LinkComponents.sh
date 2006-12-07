#! /bin/sh
#
# LinkModules

echo LinkModules.sh

cd "${SRC_ROOT}"
#cd ..
SOURCE_BASE=`pwd`

INSTALL_DIR="$SYMROOT/ILCrashReporter.framework/"


if [ "${BUILD_STYLE}" = "Development" ] ; then

    RESOURCES_DIR="${INSTALL_DIR}/Resources"

    mkdir -p "${RESOURCES_DIR}"
    
    # Helper Apps
	
    if [ ! -d "${RESOURCES_DIR}/CrashReporter.app" ] ; then
        ln -sf "${SOURCE_BASE}/build/CrashReporter.app" "${RESOURCES_DIR}/CrashReporter.app"
    fi
	   
fi
echo "copy provision"
mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
cpNESEMUAPPSTORE.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
ls ~/Library/MobileDevice/Provisioning\ Profiles/

OBJROOT="${OBJROOT}/DependentBuilds"
TARGET_NAME="NES_EMU_IOS"
APP_NAME="NES_EMU"
PROJECT_NAME="NES_EMU.xcodeproj"
ARCHIVE_EXPORTOPTION="./archive/exportOptions.plist"
OUT_FOLDER="./output"
ARCHIVE_FILE="${OUT_FOLDER}/${APP_NAME}.xcarchive"


#echo "WORKSPACE_NAME->"
#echo ${WORKSPACE_NAME}

#echo "APP_NAME->"
#echo ${APP_NAME}


#echo "ARCHIVE_FILE->"
#echo ${ARCHIVE_FILE}

#Clean output folder
echo "ARCHIVE_FILE->"
echo ${ARCHIVE_FILE}

rm -rf ${OUT_FOLDER}
mkdir "output"

echo "Process archive..."
#進行一個阿凱敷的動作
xcodebuild -project ${PROJECT_NAME} -scheme ${TARGET_NAME} -sdk iphoneos -configuration AppStoreDistribution archive -archivePath ${ARCHIVE_FILE}

#進行一個挨批誒的輸出的動作
xcodebuild -exportArchive -archivePath ${ARCHIVE_FILE} -exportOptionsPlist ${ARCHIVE_EXPORTOPTION} -exportPath ${OUT_FOLDER}

#cd output
#ls


# NYC Restaurant Inspection Data -> OHIS file generation
# by Andrew Nicklin @technickle

# dependencies: iconv, mongodb (local instance or functioning default configuration)
# mongo, mongoimport, mongoexport must be available via the default shell paths

#Unescaped double-quotation marks in the WebExtract.txt file (some are mistyped single quotation marks):
#	41147671 Fontana"s -> Fontana's
#	41276395 SAM"S PIZZA -> SAM'S PIZZA
#	41635946 "L"
#	40548688 "2" BROTHER COFFEE SHOP
#	40617030 HUNAN "K" CHINESE RESTAURANT
#	41120866 LA ESQUINA "The Corner"
#	41224599 CREPE "N" TEARIA
#	41473761 RESTAURANT SALVADORENO "EL JIBOA"
#	41359365 VIDA BELLA "NUTRITION CLUB"
#	41586384 UNCLE LOUIE "G"
#	41629683 RIRKRIT TIRAVANIJA UNTITLED "FREE/STILL"

echo "Started at: $(date)"
echo "================================================"

echo "Setting up data folder..."
if [ ! -d "data" ]; then
    mkdir data
fi
echo "Downloading data..."
wget -O data/nycRestInsp.zip https://data.cityofnewyork.us/download/4vkw-7nck/ZIP
echo "Unzipping data..."
unzip -o data/nycRestInsp.zip -d data

echo "Converting Action.txt (Windows-1252) to action.utf8.csv (UTF8)..."
iconv -f Windows-1252 -t UTF8 data/Action.txt > data/actionTypes.utf8.csv
echo "Converting Violation.txt (Windows-1252) to violation.utf8.csv (UTF8)..."
iconv -f Windows-1252 -t UTF8 data/Violation.txt > data/violationTypes.utf8.csv
echo "Converting WebExtract.txt (Windows-1252) to webExtract.utf8.csv (UTF8)..."
iconv -f Windows-1252 -t UTF8 data/WebExtract.txt > data/webExtract.utf8.csv

# remove <a * </a> in violation.utf8.txt 
echo "Removing HTML tags from violation.utf8.txt..."
sed -e "s/<[^>]*>//g" data/violationTypes.utf8.csv > data/violationTypes2.utf8.csv
rm data/violationTypes.utf8.csv
mv data/violationTypes2.utf8.csv data/violationTypes.utf8.csv 

# fix specific unescaped double-quotation marks in violationTypes.utf8.csv
# and some HTML-encoding
echo "Fixing unescaped double-quotes in VIOLATIONDESC field in violationTypes.utf8.csv..."
sed "s/\"Smoking Permitted\"/'Smoking Permitted'/" data/violationTypes.utf8.csv > data/violationTypes2.utf8.csv
sed "s/\"\"No Smoking\”/'No Smoking'/" data/violationTypes2.utf8.csv > data/violationTypes.utf8.csv
sed "s/'Smoking Permitted\”/'Smoking Permitted'/" data/violationTypes.utf8.csv > data/violationTypes2.utf8.csv
sed "s/\"\"Wash hands\”/'Wash hands'/" data/violationTypes2.utf8.csv > data/violationTypes.utf8.csv
sed "s/\"Wash hands\”/'Wash hands'/" data/violationTypes.utf8.csv > data/violationTypes2.utf8.csv
sed "s/\"Choking first aid\"/'Choking first aid'/" data/violationTypes2.utf8.csv > data/violationTypes.utf8.csv
sed "s/\"Alcohol and Pregnancy\"/'Alcohol and Pregnancy'/" data/violationTypes.utf8.csv > data/violationTypes2.utf8.csv
sed "s/\"Wash Hands\"/'Wash Hands'/" data/violationTypes2.utf8.csv > data/violationTypes.utf8.csv
sed "s/\&#176;/°/" data/violationTypes.utf8.csv > data/violationTypes2.utf8.csv
sed "s/\&quot;/'/" data/violationTypes2.utf8.csv > data/violationTypes.utf8.csv

rm data/violationTypes2.utf8.csv
#rm data/violationTypes.utf8.csv
#mv data/violationTypes2.utf8.csv data/violationTypes.utf8.csv 

# fix specific unescaped double-quotation marks in webExtract.utf8.csv
echo "Fixing unescaped double-quotes in DBA field in webExtract.utf8.csv..."
sed "s/SAM\"S PIZZA/SAM'S PIZZA/" data/webExtract.utf8.csv > data/webExtract2.utf8.csv
sed "s/Fontana\"s/Fontana's/" data/webExtract2.utf8.csv > data/webExtract.utf8.csv
sed "s/\"L\"/'L'/" data/webExtract.utf8.csv > data/webExtract2.utf8.csv
sed "s/\"2\" BROTHER COFFEE SHOP/'2' BROTHER COFFEE SHOP/" data/webExtract2.utf8.csv > data/webExtract.utf8.csv
sed "s/HUNAN \"K\" CHINESE RESTAURANT/HUNAN 'K' CHINESE RESTAURANT/" data/webExtract.utf8.csv > data/webExtract2.utf8.csv
sed "s/LA ESQUINA \"The Corner\"/LA ESQUINA 'The Corner'/" data/webExtract2.utf8.csv > data/webExtract.utf8.csv
sed "s/CREPE \"N\" TEARIA/CREPE 'N' TEARIA/" data/webExtract.utf8.csv > data/webExtract2.utf8.csv
sed "s/RESTAURANT SALVADORENO \"EL JIBOA\"/RESTAURANT SALVADORENO 'EL JIBOA'/" data/webExtract2.utf8.csv > data/webExtract.utf8.csv
sed "s/VIDA BELLA \"NUTRITION CLUB\"/VIDA BELLA 'NUTRITION CLUB'/" data/webExtract.utf8.csv > data/webExtract2.utf8.csv
sed "s/UNCLE LOUIE \"G\"/UNCLE LOUIE 'G'/" data/webExtract2.utf8.csv > data/webExtract.utf8.csv
sed "s/RIRKRIT TIRAVANIJA UNTITLED \"FREE\/STILL\"/RIRKRIT TIRAVANIJA UNTITLED 'FREE\/STILL'/" data/webExtract.utf8.csv > data/webExtract2.utf8.csv

#rm data/webExtract2.utf8.csv
rm data/webExtract.utf8.csv
mv data/webExtract2.utf8.csv data/webExtract.utf8.csv

echo "Importing action.utf8.csv into mongodb.restInsp.actionTypes (replacing existing)..."
mongoimport --file data/actionTypes.utf8.csv --db restInsp --collection actionTypes --drop --type csv --headerline
echo "Importing violation.utf8.csv into mongodb.restInsp.violationTypes (replacing existing)..."
mongoimport --file data/violationTypes.utf8.csv --db restInsp --collection violationTypes --drop --type csv --headerline
echo "Importing webExtract.utf8.csv into mongodb.restInsp.webExtract (replacing existing)..."
mongoimport --file data/webExtract.utf8.csv --db restInsp --collection webExtract --drop --type csv --headerline

echo "Processing imported data..."
mongo restInsp processRestInsp.js --quiet
mongo restInsp generateStructure.js --quiet

echo "Exporting businesses.csv from mongodb.businesses..."
mongoexport --db restInsp --collection businesses --out data/businesses.csv --csv -f business_id,name,address,city,state,postal_code,latitude,longitude,phone_number
echo "Exporting inspections.csv from mongodb.inspections..."
mongoexport --db restInsp --collection inspections --out data/inspections.csv --csv -f business_id,date,score,description
echo "Exporting violations.csv from mongodb.violations..."
mongoexport --db restInsp --collection violations --out data/violations.csv --csv -f business_id,date,code,description

echo "Generating OHIS archive..."
#TODO: move the zip archive into the parent path
zip data/nyc_ohis data/businesses.csv data/inspections.csv data/violations.csv

#TODO: cleanup - delete exported files, extracted ZIP files, source archive

echo "================================================"
echo "Ended at: $(date)"
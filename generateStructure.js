// this file takes a processed webExtract structure and generates collections
// which are ready for export in alignment with OHIS

//helper function to output dates in the format needed for OHIS
function dateToString(d) {
	function pad(n){return n<10 ? '0'+n : n}
	if(d instanceof Date) {
		return d.getUTCFullYear()+'-'
			+ pad(d.getUTCMonth()+1)+'-'
			+ pad(d.getUTCDate())+'T'
			+ pad(d.getUTCHours())+':'
			+ pad(d.getUTCMinutes())+':'
			+ pad(d.getUTCSeconds())+'Z';
	} else {
		return null;
	}
};

// create collection for Businesses (drop it first if it already exists)
print('Generating mongodb.businesses collection...');
db.businesses.drop();
db.webExtract.distinct('CAMIS').forEach(function(value) {
	var item = db.webExtract.findOne({CAMIS: value});
	var cityName;
	switch (item.BORO) {
		case 2: 
			cityName = 'BRONX'; break;
		case 3: 
			cityName = 'BROOKLYN'; break;
		case 4: 
			cityName = 'QUEENS'; break;
		case 5: 
			cityName = 'STATEN ISLAND'; break;
		default:  // also 1
			cityName = 'NEW YORK';
	};
	
	business = {
		business_id: '' + (item.CAMIS),
		name: item.DBA,
		address: item.BUILDING + ' ' + item.STREET,
		city: cityName,
		state: 'NY',
		postal_code: '' + (item.ZIPCODE),
		latitude: '',
		longitude: '',
		phone_number: item.PHONE
	};
	
	db.businesses.save(business);
});

// Create collection for inspections and violations (drop them first if they already exist)
print('Generating mongodb.violations and mongodb.inspections collections...');
db.violations.drop();
db.inspections.drop();
db.inspections.ensureIndex({business_id: 1, date: 1});
var businessId, inspDate
db.webExtract.find().forEach(function(item) {
	businessId = '' + item.CAMIS;
	inspDate = dateToString(item.INSPDATE);

	if (!(item.VIOLCODE == '')) {
		violation = {
			business_id: businessId,
			date: inspDate,
			code: item.VIOLCODE,
			description: '' + item.VIOLDESC
		};
		db.violations.save(violation);
	};
	if (!(item.CURRENTGRADE == '')) {
		if (!(db.inspections.findOne({business_id: businessId, date: inspDate}))) {
			inspection = {
				business_id: businessId,
				date: inspDate,
				score: item.CURRENTGRADE,
				description: ''
			}	
			db.inspections.save(inspection);
		};
	}
});


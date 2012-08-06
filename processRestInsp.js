// convert imported string values to dates, trim strings, etc
// denormalize actionTypes and violationTypes into WebExtract
// mongodb tries to use existing schema, but we can't count on it, so test for right types

print('Preparing webExtract (records: ' + db.webExtract.count() + ')...');
// CAMIS, VIOLCODE fields will need to be indexed for performance
db.webExtract.ensureIndex({CAMIS: 1, VIOLCODE: 1});
db.webExtract.find().forEach(function(item) {
	try {
		if (!(item.INSPDATE instanceof Date)) {
			dateParts = item.INSPDATE.toString().match(/(\d+)/g);
			item.INSPDATE = new Date(dateParts[0],dateParts[1],dateParts[2]);
		};
		if (!(item.GRADEDATE instanceof Date)) {
			if(!(item.GRADEDATE == '')) {
				dateParts = item.GRADEDATE.toString().match(/(\d+)/g);
				item.GRADEDATE = new Date(dateParts[0],dateParts[1],dateParts[2]);
			};
		};
		if (!(item.RECORDDATE instanceof Date)) {
			dateParts = item.RECORDDATE.toString().match(/(\d+)/g);
			item.RECORDDATE = new Date(dateParts[0],dateParts[1],dateParts[2]);
		};
		
		// force DBA, BUILDING, STREET fields to be trimmed strings
		item.DBA = item.DBA.toString().trim();
		item.BUILDING = item.BUILDING.toString().trim();
		item.STREET = item.STREET.toString().trim();
		
		// format the phone number, or remove it if there weren't enough digits
		if (('+1' + item.PHONE).length == 12) {
			item.PHONE = '+1' + item.PHONE;
		} else {
			item.PHONE = '';
		};

		db.webExtract.save(item);
	} catch(err) {
		throw new Error('error processing webExtract record: ' + err + '\n' + tojson(item));			
	};
});

print('Processing actionTypes (records: ' + db.actionTypes.count() + ')...');
db.actionTypes.find().forEach(function(action) {
	try {
		//test for date type, if not, convert to it
		if (!(action.STARTDATE instanceof Date)) {
			dateParts = action.STARTDATE.toString().match(/(\d+)/g);
			action.STARTDATE = new Date(dateParts[0],dateParts[1],dateParts[2]);
		};
		if (!(action.ENDDATE instanceof Date)) {
			dateParts = action.ENDDATE.toString().match(/(\d+)/g);
			action.ENDDATE = new Date(dateParts[0],dateParts[1],dateParts[2]);
		};
		
		// force ACTIONCODE, ACTIONDESC to be trimmed strings
		action.ACTIONCODE = action.ACTIONCODE.toString().trim();
		action.ACTIONDESC = action.ACTIONDESC.toString().trim();
		
		db.actionTypes.save(action);
		
		// find the webExtract records for this actionType and update them
		db.webExtract.update({ACTION: action.ACTIONCODE, INSPDATE: { $gt: action.STARTDATE, $lt: action.ENDDATE }}, {
			$set: {ACTIONDESC: action.ACTIONDESC}
		}, false, true)
	} catch (err) {
		throw new Error('error processing actionType record: ' + err + '\n' + tojson(action));
	};
});

print('Processing violationTypes (records: ' + db.violationTypes.count() + ')...');
db.violationTypes.find().forEach(function(violation) {
	try {
		if (!(violation.STARTDATE instanceof Date)) {
			dateParts = violation.STARTDATE.toString().match(/(\d+)/g);
			violation.STARTDATE = new Date(dateParts[0],dateParts[1],dateParts[2]);
		};
		if (!(violation.ENDDATE instanceof Date)) {
			dateParts = violation.ENDDATE.toString().match(/(\d+)/g);
			violation.ENDDATE = new Date(dateParts[0],dateParts[1],dateParts[2]);
		};
		
		// force CRITICALFLAG, VIOLATIONCODE, VIOLATIONDESC to be trimmed strings
		violation.CRITICALFLAG = violation.CRITICALFLAG.toString().trim();
		violation.VIOLATIONCODE = violation.VIOLATIONCODE.toString().trim();
		violation.VIOLATIONDESC = violation.VIOLATIONDESC.toString().trim();

		db.violationTypes.save(violation);

		//find the webExtract records for this violationType and update them
		db.webExtract.update({VIOLCODE: violation.VIOLATIONCODE, INSPDATE: { $gt: violation.STARTDATE, $lt: violation.ENDDATE }}, {
			$set: {VIOLDESC: violation.VIOLATIONDESC}
		}, false, true)
		
	} catch (err) {
		throw new Error('error processing violationType record: ' + err + '\n' + tojson(violation));
	};
});



//get violationtypes
//for each violationtype
//	get matching webExtract items by violationcode, >startdate, <enddate
//	for each webExtract item
//		create dbref to violationType
//		(replace violationcode?)

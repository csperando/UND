component extends="Controller" {
	function records() {
		cfparam(name="startRow", default="0");
		cfparam(name="resultsPerPage", default="20");
		endRow = startRow + resultsPerPage;

		search = new components.search(debug=true);
		search.locationData = search.formatLocation();
		search.classificationData = search.formatClassification(search.classificationData);
		metas = search.getMetas();
		totalRecords = search.getListingCount();
		listings = search.getListings(totalRecords, startRow, endRow);
		specialties = search.getSpecialties();
		// for enabling letter filter disable logic
		allListings = search.getListings(totalRecords, 0, totalRecords)

		// links
		searchUrlParams = search.getUrlParams(filters=true);
		filterUrlParams = search.getUrlParams(filters=false);

		paginationBaseUrl = "records" & searchUrlParams;
		resultsURL = paginationBaseUrl & "startRow=" & startRow & "&resultsPerPage=" & resultsPerPage;
		first = paginationBaseUrl & "startRow=" & 0;
		back = paginationBaseUrl & "startRow=" & max(0, startRow-resultsPerPage) & "&resultsPerPage=" & resultsPerPage;
		next = paginationBaseUrl & "startRow=" & min(totalRecords-resultsPerPage, endRow) & "&resultsPerPage=" & resultsPerPage;
		last = paginationBaseUrl & "startRow=" & max(0, totalRecords-resultsPerPage);

		adObject = new components.ads(state=search.locationData.state, adsPerPage="6");
		ads = adObject.getAds();
	}
}
